import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:uuid/uuid.dart';
import 'package:swear_jar/domain/models/models.dart';
import 'package:swear_jar/domain/ledger_engine.dart';
import 'package:swear_jar/data/repositories/repositories.dart';

class FirebaseDataService
    implements
        IAuthRepository,
        IReportRepository,
        ILedgerRepository,
        IUserRepository,
        IConfigRepository {
  static const _uuid = Uuid();

  FirebaseAuth get _auth => FirebaseAuth.instance;
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;
  late final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );

  AppUser? _cachedCurrentUser;
  StreamSubscription? _userDocSubscription;
  bool _hasResolvedUserForCurrentAuth = false;
  bool _isBootstrapping = false;
  final StreamController<AppUser?> _userStreamController =
      StreamController<AppUser?>.broadcast();

  FirebaseDataService() {
    _initAuthListener();
  }

  void _initAuthListener() {
    if (Firebase.apps.isEmpty) {
      debugPrint('Firebase is not initialized. Skipping auth listener.');
      return;
    }
    _auth.authStateChanges().listen((User? fbUser) async {
      await _userDocSubscription?.cancel();
      _hasResolvedUserForCurrentAuth = false;
      _isBootstrapping = false;

      if (fbUser == null) {
        _cachedCurrentUser = null;
        _userStreamController.add(null);
        return;
      }

      _userDocSubscription =
          _firestore.collection('users').snapshots().listen((snapshot) async {
        try {
          final allUsers = snapshot.docs
              .map((doc) => AppUser.fromMap(doc.data(), id: doc.id))
              .toList();

          final matchingUsers =
              allUsers.where((u) => u.authUid == fbUser.uid).toList();

          if (matchingUsers.isNotEmpty) {
            // Prefer approved profile if multiple temporarily exist
            matchingUsers.sort((a, b) {
              if (a.isApproved && !b.isApproved) return -1;
              if (!a.isApproved && b.isApproved) return 1;
              return 0;
            });
            final user = matchingUsers.first;
            _hasResolvedUserForCurrentAuth = true;
            _cachedCurrentUser = user;
            _userStreamController.add(user);
          } else {
            if (_hasResolvedUserForCurrentAuth) {
              // The user's account was unlinked or profile was deleted while signed in
              _hasResolvedUserForCurrentAuth = false;
              await signOut();
            } else if (!_isBootstrapping) {
              _isBootstrapping = true;
              try {
                await _bootstrapUser(fbUser, existingUsers: allUsers);
              } finally {
                _isBootstrapping = false;
              }
            }
          }
        } catch (e, stack) {
          debugPrint('Error handling user snapshot: $e\n$stack');
        }
      }, onError: (e) {
        debugPrint('Error listening to user document: $e');
      });
    });
  }

  Future<void> _bootstrapUser(
    User fbUser, {
    required List<AppUser> existingUsers,
  }) async {
    try {
      final isFirstUser = existingUsers.isEmpty;

      final now = DateTime.now();
      final roles = isFirstUser
          ? [UserRole.member, UserRole.admin, UserRole.keeper]
          : [UserRole.member];
      final status = isFirstUser ? UserStatus.approved : UserStatus.pending;

      final String displayName;
      if (fbUser.displayName != null && fbUser.displayName!.trim().isNotEmpty) {
        displayName = fbUser.displayName!.trim();
      } else if (fbUser.email != null && fbUser.email!.contains('@')) {
        displayName = fbUser.email!.split('@').first;
      } else {
        displayName = 'Member';
      }

      // If a document with ID == fbUser.uid already exists (e.g., an unlinked profile),
      // allocate a fresh document ID so we don't overwrite the existing member profile.
      final idCollision = existingUsers.any((u) => u.id == fbUser.uid);
      final docId = idCollision ? _uuid.v4() : fbUser.uid;

      final newUser = AppUser(
        id: docId,
        authUid: fbUser.uid,
        email: fbUser.email ?? '',
        displayName: displayName,
        photoUrl: fbUser.photoURL,
        gcashNumber: null,
        roles: roles,
        status: status,
        createdAt: now,
        updatedAt: now,
      );

      final batch = _firestore.batch();
      final userRef = _firestore.collection('users').doc(docId);
      batch.set(userRef, newUser.toMap(), SetOptions(merge: true));

      if (isFirstUser) {
        final configRef = _firestore.collection('config').doc('system');
        final initialConfig = SystemConfig(
          activeKeeperId: docId,
          currentRatePerSwear: 50.0,
          groupName: 'Our Friend Group',
          totalSwearsAllTime: 0,
          swearLanguages: const [
            SwearLanguage(
              id: 'english',
              name: 'English',
              swears: [
                'Damn',
                'Fuck',
                'Shit',
                'Wtf',
                'Bitch',
                'Asshole',
                'Crap',
                'Dumbass',
                'Hell',
              ],
            ),
            SwearLanguage(
              id: 'tagalog',
              name: 'Tagalog',
              swears: ['Putangina', 'Gago', 'Tangina', 'Tarantado', 'Ulol'],
            ),
          ],
          updatedAt: now,
        );
        batch.set(configRef, initialConfig.toMap(), SetOptions(merge: true));
      }

      _hasResolvedUserForCurrentAuth = true;
      await batch.commit();
    } catch (e, stack) {
      debugPrint('Error bootstrapping user: $e\n$stack');
    }
  }

  @override
  Stream<AppUser?> get userStream => _userStreamController.stream;

  @override
  AppUser? get currentUser => _cachedCurrentUser;

  @override
  Future<void> signInWithGoogle() async {
    if (Firebase.apps.isEmpty) {
      throw Exception('Firebase is not initialized. Please verify Firebase setup.');
    }
    try {
      if (kIsWeb) {
        final GoogleAuthProvider googleProvider = GoogleAuthProvider();
        googleProvider.addScope('email');
        googleProvider.addScope('profile');
        googleProvider.setCustomParameters({'prompt': 'select_account'});
        try {
          await _auth.signInWithPopup(googleProvider);
        } catch (popupError) {
          final errStr = popupError.toString();
          debugPrint('Popup sign in did not complete ($errStr), attempting redirect fallback...');
          try {
            await _auth.signInWithRedirect(googleProvider);
          } catch (redirectError) {
            debugPrint('Redirect fallback error: $redirectError');
          }
        }
      } else {
        final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
        if (googleUser == null) return; // User cancelled

        final GoogleSignInAuthentication googleAuth =
            await googleUser.authentication;

        final OAuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        await _auth.signInWithCredential(credential);
      }
    } on FirebaseAuthException catch (e) {
      debugPrint('Firebase Auth Error [${e.code}]: ${e.message}');
      switch (e.code) {
        case 'popup-closed-by-user':
          // User intentionally closed the popup, do not show an error
          return;
        case 'unauthorized-domain':
          throw Exception(
              'Domain not authorized. Please add this domain to Firebase Console > Authentication > Settings > Authorized domains.');
        case 'popup-blocked':
        case 'cancelled-popup-request':
          // Popup blocked, already falling back or cancelled
          return;
        default:
          throw Exception(e.message ?? 'Authentication failed (${e.code}).');
      }
    } catch (e) {
      final msg = e.toString();
      if (msg.contains('Null check operator') ||
          msg.contains('popup-closed') ||
          msg.contains('popup_closed') ||
          msg.contains('cancelled')) {
        // Internal SDK popup blocking artifact on iOS/Safari, suppress
        debugPrint('Suppressed popup artifact error: $msg');
        return;
      }
      debugPrint('Google Sign In Error: $e');
      rethrow;
    }
  }

  @override
  Future<void> signInWithDemo(String userId) async {
    throw UnsupportedError('Demo quick sign-in is not supported in Live Firebase mode');
  }

  @override
  Future<void> signOut() async {
    await _auth.signOut();
    if (!kIsWeb) {
      try {
        await _googleSignIn.signOut();
      } catch (_) {}
    }
    _cachedCurrentUser = null;
    _userStreamController.add(null);
  }

  @override
  Future<void> updateProfile({String? displayName, String? gcashNumber}) async {
    final user = _cachedCurrentUser;
    if (user == null) return;

    final updates = <String, dynamic>{
      'updatedAt': DateTime.now().toIso8601String(),
    };
    if (displayName != null) updates['displayName'] = displayName;
    if (gcashNumber != null) updates['gcashNumber'] = gcashNumber;

    await _firestore.collection('users').doc(user.id).update(updates);
  }

  // -------------------------------------------------------------
  // USER REPOSITORY
  // -------------------------------------------------------------

  @override
  Stream<List<AppUser>> watchUsers() {
    if (Firebase.apps.isEmpty) {
      return Stream.value(<AppUser>[]);
    }
    return _firestore.collection('users').snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => AppUser.fromMap(doc.data(), id: doc.id))
          .toList();
    });
  }

  @override
  Future<void> approveUser(String userId) async {
    await _firestore.collection('users').doc(userId).update({
      'status': UserStatus.approved.toStr(),
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  @override
  Future<void> rejectUser(String userId) async {
    await _firestore.collection('users').doc(userId).update({
      'status': UserStatus.rejected.toStr(),
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  @override
  Future<void> toggleAdminRole(String userId, bool makeAdmin) async {
    final doc = await _firestore.collection('users').doc(userId).get();
    if (!doc.exists) return;

    final user = AppUser.fromMap(doc.data() ?? {}, id: doc.id);
    final updatedRoles = List<UserRole>.from(user.roles);
    if (makeAdmin && !updatedRoles.contains(UserRole.admin)) {
      updatedRoles.add(UserRole.admin);
    } else if (!makeAdmin) {
      updatedRoles.remove(UserRole.admin);
    }

    await _firestore.collection('users').doc(userId).update({
      'roles': updatedRoles.map((r) => r.toStr()).toList(),
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  @override
  Future<void> appointKeeper(
    String newKeeperId,
    String oldKeeperId,
    List<DebtObligation> debts,
  ) async {
    final batch = _firestore.batch();
    final now = DateTime.now().toIso8601String();

    // 1. Update old keeper roles
    final oldDoc = await _firestore.collection('users').doc(oldKeeperId).get();
    if (oldDoc.exists) {
      final oldUser = AppUser.fromMap(oldDoc.data() ?? {}, id: oldDoc.id);
      final oldRoles = List<UserRole>.from(oldUser.roles)..remove(UserRole.keeper);
      batch.update(_firestore.collection('users').doc(oldKeeperId), {
        'roles': oldRoles.map((r) => r.toStr()).toList(),
        'updatedAt': now,
      });
    }

    // 2. Update new keeper roles
    final newDoc = await _firestore.collection('users').doc(newKeeperId).get();
    if (newDoc.exists) {
      final newUser = AppUser.fromMap(newDoc.data() ?? {}, id: newDoc.id);
      final newRoles = List<UserRole>.from(newUser.roles);
      if (!newRoles.contains(UserRole.keeper)) {
        newRoles.add(UserRole.keeper);
      }
      batch.update(_firestore.collection('users').doc(newKeeperId), {
        'roles': newRoles.map((r) => r.toStr()).toList(),
        'updatedAt': now,
      });
    }

    // 3. Update active debts belonging to old Keeper
    for (final debt in debts) {
      if (debt.isActive && !debt.isTransferred && debt.recipientId == oldKeeperId) {
        batch.update(_firestore.collection('debts').doc(debt.id), {
          'recipientId': newKeeperId,
        });
      }
    }

    // 4. Update system config
    batch.update(_firestore.collection('config').doc('system'), {
      'activeKeeperId': newKeeperId,
      'updatedAt': now,
    });

    await batch.commit();
  }

  @override
  Future<AppUser> createManualUser({
    required String displayName,
    String? gcashNumber,
  }) async {
    final id = _uuid.v4();
    final now = DateTime.now();
    final trimmedName = displayName.trim();
    final trimmedGcash = gcashNumber?.trim();

    final newUser = AppUser(
      id: id,
      authUid: null,
      email: '',
      displayName: trimmedName.isEmpty ? 'Member' : trimmedName,
      photoUrl: null,
      gcashNumber:
          (trimmedGcash == null || trimmedGcash.isEmpty) ? null : trimmedGcash,
      roles: const [UserRole.member],
      status: UserStatus.approved,
      createdAt: now,
      updatedAt: now,
    );

    await _firestore.collection('users').doc(id).set(newUser.toMap());
    return newUser;
  }

  @override
  Future<void> assignPendingUserToExisting({
    required String pendingUserId,
    required String targetUserId,
  }) async {
    if (pendingUserId == targetUserId) return;

    final pendingDoc =
        await _firestore.collection('users').doc(pendingUserId).get();
    final targetDoc =
        await _firestore.collection('users').doc(targetUserId).get();
    if (!pendingDoc.exists || !targetDoc.exists) return;

    final pendingUser =
        AppUser.fromMap(pendingDoc.data() ?? {}, id: pendingDoc.id);
    final targetUser =
        AppUser.fromMap(targetDoc.data() ?? {}, id: targetDoc.id);

    final linkedAuthUid =
        (pendingUser.authUid != null && pendingUser.authUid!.isNotEmpty)
            ? pendingUser.authUid!
            : pendingUser.id;

    final updatedTarget = targetUser.copyWith(
      authUid: linkedAuthUid,
      email: pendingUser.email,
      photoUrl: pendingUser.photoUrl ?? targetUser.photoUrl,
      gcashNumber:
          (targetUser.gcashNumber == null || targetUser.gcashNumber!.isEmpty)
              ? pendingUser.gcashNumber
              : targetUser.gcashNumber,
      status: UserStatus.approved,
      updatedAt: DateTime.now(),
    );

    final batch = _firestore.batch();
    batch.set(
      _firestore.collection('users').doc(targetUserId),
      updatedTarget.toMap(),
    );
    batch.delete(_firestore.collection('users').doc(pendingUserId));
    await batch.commit();
  }

  @override
  Future<void> unlinkUserAccount(String userId) async {
    final doc = await _firestore.collection('users').doc(userId).get();
    if (!doc.exists) return;

    final user = AppUser.fromMap(doc.data() ?? {}, id: doc.id);
    final unlinked = user.copyWith(
      clearAuthUid: true,
      email: '',
      clearPhotoUrl: true,
      updatedAt: DateTime.now(),
    );

    await _firestore.collection('users').doc(userId).set(unlinked.toMap());
  }

  @override
  Future<void> deleteUserCompletely({
    required String userId,
    required List<SwearReport> existingReports,
    required List<DebtObligation> existingDebts,
  }) async {
    final result = LedgerEngine.deleteUserHistory(
      userId: userId,
      existingReports: existingReports,
      existingDebts: existingDebts,
    );

    final batch = _firestore.batch();

    batch.delete(_firestore.collection('users').doc(userId));

    for (final reportId in result.deletedReportIds) {
      batch.delete(_firestore.collection('reports').doc(reportId));
    }

    for (final debtId in result.deletedDebtIds) {
      batch.delete(_firestore.collection('debts').doc(debtId));
    }

    if (result.swearCountDelta != 0) {
      batch.set(
        _firestore.collection('config').doc('system'),
        {
          'totalSwearsAllTime': FieldValue.increment(result.swearCountDelta),
          'updatedAt': DateTime.now().toIso8601String(),
        },
        SetOptions(merge: true),
      );
    }

    await batch.commit();
  }

  // -------------------------------------------------------------
  // REPORT REPOSITORY
  // -------------------------------------------------------------

  @override
  Stream<List<SwearReport>> watchReports() {
    if (Firebase.apps.isEmpty) {
      return Stream.value(<SwearReport>[]);
    }
    return _firestore
        .collection('reports')
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => SwearReport.fromMap(doc.data(), id: doc.id))
          .toList();
      list.sort((a, b) {
        final cmp = b.swearDate.compareTo(a.swearDate);
        if (cmp != 0) return cmp;
        return b.createdAt.compareTo(a.createdAt);
      });
      return list;
    });
  }

  @override
  Future<SwearReport> submitReport({
    required String reporterId,
    required String accusedId,
    required int count,
    String? note,
    Map<String, int>? swearBreakdown,
    required double rateApplied,
    DateTime? swearDate,
  }) async {
    final id = _uuid.v4();
    final now = DateTime.now();
    final report = SwearReport(
      id: id,
      reporterId: reporterId,
      accusedId: accusedId,
      count: count,
      note: note,
      swearBreakdown: swearBreakdown ?? const {},
      rateApplied: rateApplied,
      totalAmount: count * rateApplied,
      status: ReportStatus.pending,
      swearDate: swearDate ?? now,
      createdAt: now,
    );

    await _firestore.collection('reports').doc(id).set(report.toMap());
    return report;
  }

  @override
  Future<ReportConfirmationResult> confirmReport({
    required SwearReport report,
    required String activeKeeperId,
    required String reviewerId,
    required List<DebtObligation> existingDebts,
  }) async {
    final result = LedgerEngine.confirmReport(
      report: report,
      activeKeeperId: activeKeeperId,
      reviewerId: reviewerId,
      existingActiveDebts: existingDebts,
    );

    final batch = _firestore.batch();

    // 1. Update report
    batch.set(
      _firestore.collection('reports').doc(result.updatedReport.id),
      result.updatedReport.toMap(),
    );

    // 2. Created debt
    batch.set(
      _firestore.collection('debts').doc(result.createdDebt.id),
      result.createdDebt.toMap(),
    );

    // 3. Transferred debts
    for (final debt in result.transferredDebts) {
      batch.set(
        _firestore.collection('debts').doc(debt.id),
        debt.toMap(),
      );
    }

    // 4. Cancelled debts
    for (final debt in result.cancelledReporterDebts) {
      batch.set(
        _firestore.collection('debts').doc(debt.id),
        debt.toMap(),
      );
    }

    // 5. Increment total swear counter in config
    batch.set(
      _firestore.collection('config').doc('system'),
      {
        'totalSwearsAllTime': FieldValue.increment(report.count),
        'updatedAt': DateTime.now().toIso8601String(),
      },
      SetOptions(merge: true),
    );

    await batch.commit();
    return result;
  }

  @override
  Future<SwearReport> rejectReport({
    required SwearReport report,
    required String reviewerId,
    String? reason,
  }) async {
    final updated = LedgerEngine.rejectReport(
      report: report,
      reviewerId: reviewerId,
      reason: reason,
    );

    await _firestore
        .collection('reports')
        .doc(report.id)
        .set(updated.toMap());

    return updated;
  }

  @override
  Future<ReportUpdateResult> updateReport({
    required SwearReport report,
    required String accusedId,
    required int count,
    required DateTime swearDate,
    String? note,
    Map<String, int>? swearBreakdown,
    required List<DebtObligation> existingDebts,
  }) async {
    final result = LedgerEngine.updateReport(
      report: report,
      accusedId: accusedId,
      count: count,
      swearDate: swearDate,
      note: note,
      swearBreakdown: swearBreakdown,
      existingDebts: existingDebts,
    );

    final batch = _firestore.batch();

    batch.set(
      _firestore.collection('reports').doc(result.updatedReport.id),
      result.updatedReport.toMap(),
    );

    if (result.updatedDebt != null) {
      batch.set(
        _firestore.collection('debts').doc(result.updatedDebt!.id),
        result.updatedDebt!.toMap(),
      );
    }

    if (result.swearCountDelta != 0) {
      batch.set(
        _firestore.collection('config').doc('system'),
        {
          'totalSwearsAllTime': FieldValue.increment(result.swearCountDelta),
          'updatedAt': DateTime.now().toIso8601String(),
        },
        SetOptions(merge: true),
      );
    }

    await batch.commit();
    return result;
  }

  @override
  Future<ReportDeletionResult> deleteReport({
    required SwearReport report,
    required List<DebtObligation> existingDebts,
  }) async {
    final result = LedgerEngine.deleteReport(
      report: report,
      existingDebts: existingDebts,
    );

    final batch = _firestore.batch();

    batch.delete(_firestore.collection('reports').doc(result.deletedReportId));

    for (final debtId in result.deletedDebtIds) {
      batch.delete(_firestore.collection('debts').doc(debtId));
    }

    if (result.swearCountDelta != 0) {
      batch.set(
        _firestore.collection('config').doc('system'),
        {
          'totalSwearsAllTime': FieldValue.increment(result.swearCountDelta),
          'updatedAt': DateTime.now().toIso8601String(),
        },
        SetOptions(merge: true),
      );
    }

    await batch.commit();
    return result;
  }

  // -------------------------------------------------------------
  // LEDGER REPOSITORY
  // -------------------------------------------------------------

  @override
  Stream<List<DebtObligation>> watchDebts() {
    if (Firebase.apps.isEmpty) {
      return Stream.value(<DebtObligation>[]);
    }
    return _firestore
        .collection('debts')
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => DebtObligation.fromMap(doc.data(), id: doc.id))
          .toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  @override
  Future<DebtObligation> recordPayment({
    required DebtObligation debt,
    required double amount,
    required String recordedBy,
    String? note,
    DateTime? paidAt,
  }) async {
    final updatedDebt = LedgerEngine.recordPayment(
      debt: debt,
      amount: amount,
      recordedBy: recordedBy,
      note: note,
      now: paidAt,
    );

    await _firestore
        .collection('debts')
        .doc(debt.id)
        .set(updatedDebt.toMap());

    return updatedDebt;
  }

  @override
  Future<List<DebtObligation>> recordMemberPayment({
    required List<DebtObligation> activeDebts,
    required double amount,
    required String recordedBy,
    String? note,
    DateTime? paidAt,
  }) async {
    final updatedDebts = LedgerEngine.recordMemberPayment(
      activeDebts: activeDebts,
      amount: amount,
      recordedBy: recordedBy,
      note: note,
      now: paidAt,
    );

    if (updatedDebts.isNotEmpty) {
      final batch = _firestore.batch();
      for (final updated in updatedDebts) {
        batch.set(
          _firestore.collection('debts').doc(updated.id),
          updated.toMap(),
        );
      }
      await batch.commit();
    }

    return updatedDebts;
  }

  @override
  Future<List<DebtObligation>> updatePaymentHistoryItem({
    required PaymentHistoryItem item,
    required List<DebtObligation> allDebts,
    required double newAmount,
    required DateTime newDate,
    String? newNote,
    required String updatedBy,
  }) async {
    final updatedDebts = LedgerEngine.updatePaymentHistoryItem(
      item: item,
      allDebts: allDebts,
      newAmount: newAmount,
      newDate: newDate,
      newNote: newNote,
      updatedBy: updatedBy,
    );

    if (updatedDebts.isNotEmpty) {
      final batch = _firestore.batch();
      for (final updated in updatedDebts) {
        batch.set(
          _firestore.collection('debts').doc(updated.id),
          updated.toMap(),
        );
      }
      await batch.commit();
    }

    return updatedDebts;
  }

  @override
  Future<DebtObligation> dismissTransferredDebt({
    required DebtObligation debt,
    required String dismissedBy,
    String? reason,
  }) async {
    final updatedDebt = LedgerEngine.dismissTransferredDebt(
      debt: debt,
      dismissedBy: dismissedBy,
      reason: reason,
    );

    await _firestore
        .collection('debts')
        .doc(debt.id)
        .set(updatedDebt.toMap());

    return updatedDebt;
  }

  @override
  Future<List<DebtObligation>> dismissMemberTransferredDebts({
    required List<DebtObligation> activeDebts,
    required String dismissedBy,
    String? reason,
  }) async {
    final dismissedDebts = LedgerEngine.dismissMemberTransferredDebts(
      activeDebts: activeDebts,
      dismissedBy: dismissedBy,
      reason: reason,
    );

    if (dismissedDebts.isNotEmpty) {
      final batch = _firestore.batch();
      for (final dismissed in dismissedDebts) {
        batch.set(
          _firestore.collection('debts').doc(dismissed.id),
          dismissed.toMap(),
        );
      }
      await batch.commit();
    }

    return dismissedDebts;
  }

  @override
  Future<void> migrateDebtsToNewKeeper({
    required List<DebtObligation> activeDebts,
    required String oldKeeperId,
    required String newKeeperId,
  }) async {
    final migrated = LedgerEngine.migrateDebtsToNewKeeper(
      activeDebts: activeDebts,
      oldKeeperId: oldKeeperId,
      newKeeperId: newKeeperId,
    );

    final batch = _firestore.batch();
    for (final debt in migrated) {
      batch.set(_firestore.collection('debts').doc(debt.id), debt.toMap());
    }
    await batch.commit();
  }

  // -------------------------------------------------------------
  // CONFIG REPOSITORY
  // -------------------------------------------------------------

  @override
  Stream<SystemConfig> watchConfig() {
    if (Firebase.apps.isEmpty) {
      return Stream.value(
        SystemConfig(
          activeKeeperId: '',
          currentRatePerSwear: 50.0,
          groupName: 'Our Friend Group',
          totalSwearsAllTime: 0,
          updatedAt: DateTime.now(),
        ),
      );
    }
    return _firestore.collection('config').doc('system').snapshots().map((snapshot) {
      if (!snapshot.exists || snapshot.data() == null) {
        return SystemConfig(
          activeKeeperId: '',
          currentRatePerSwear: 50.0,
          groupName: 'Our Friend Group',
          totalSwearsAllTime: 0,
          updatedAt: DateTime.now(),
        );
      }
      return SystemConfig.fromMap(snapshot.data() ?? {});
    });
  }

  @override
  Future<void> updateRate(double newRate) async {
    await _firestore.collection('config').doc('system').set({
      'currentRatePerSwear': newRate,
      'updatedAt': DateTime.now().toIso8601String(),
    }, SetOptions(merge: true));
  }

  @override
  Future<void> updateKeeper(String newKeeperId) async {
    await _firestore.collection('config').doc('system').set({
      'activeKeeperId': newKeeperId,
      'updatedAt': DateTime.now().toIso8601String(),
    }, SetOptions(merge: true));
  }

  @override
  Future<void> updateSwearLanguages(List<SwearLanguage> languages) async {
    await _firestore.collection('config').doc('system').set({
      'swearLanguages': languages.map((l) => l.toMap()).toList(),
      'updatedAt': DateTime.now().toIso8601String(),
    }, SetOptions(merge: true));
  }

  void dispose() {
    _userDocSubscription?.cancel();
    _userStreamController.close();
  }
}
