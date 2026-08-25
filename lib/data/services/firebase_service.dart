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
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );

  AppUser? _cachedCurrentUser;
  StreamSubscription? _userDocSubscription;
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
      if (fbUser == null) {
        _cachedCurrentUser = null;
        _userStreamController.add(null);
        return;
      }

      final docRef = _firestore.collection('users').doc(fbUser.uid);
      _userDocSubscription = docRef.snapshots().listen((snapshot) async {
        if (!snapshot.exists) {
          // If the document doesn't exist yet, we bootstrap or create it
          await _bootstrapUser(fbUser);
        } else {
          final data = snapshot.data() ?? {};
          final user = AppUser.fromMap(data, id: snapshot.id);
          _cachedCurrentUser = user;
          _userStreamController.add(user);
        }
      }, onError: (e) {
        debugPrint('Error listening to user document: $e');
      });
    });
  }

  Future<void> _bootstrapUser(User fbUser) async {
    final usersSnapshot = await _firestore.collection('users').limit(2).get();
    final isFirstUser = usersSnapshot.docs.isEmpty;

    final now = DateTime.now();
    final roles = isFirstUser
        ? [UserRole.member, UserRole.admin, UserRole.keeper]
        : [UserRole.member];
    final status = isFirstUser ? UserStatus.approved : UserStatus.pending;

    final newUser = AppUser(
      id: fbUser.uid,
      email: fbUser.email ?? '',
      displayName: fbUser.displayName?.isNotEmpty == true
          ? fbUser.displayName!
          : (fbUser.email?.split('@').first ?? 'User'),
      photoUrl: fbUser.photoURL,
      gcashNumber: null,
      roles: roles,
      status: status,
      createdAt: now,
      updatedAt: now,
    );

    final batch = _firestore.batch();
    final userRef = _firestore.collection('users').doc(fbUser.uid);
    batch.set(userRef, newUser.toMap());

    if (isFirstUser) {
      final configRef = _firestore.collection('config').doc('system');
      final initialConfig = SystemConfig(
        activeKeeperId: fbUser.uid,
        currentRatePerSwear: 50.0,
        groupName: 'Our Friend Group',
        totalSwearsAllTime: 0,
        updatedAt: now,
      );
      batch.set(configRef, initialConfig.toMap(), SetOptions(merge: true));
    }

    await batch.commit();
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
        await _auth.signInWithPopup(googleProvider);
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
          throw Exception('Sign-in cancelled (popup was closed).');
        case 'unauthorized-domain':
          throw Exception(
              'Domain not authorized. Please add this domain to Firebase Console > Authentication > Settings > Authorized domains.');
        case 'popup-blocked':
          throw Exception('Sign-in popup was blocked by browser. Please allow popups for this site.');
        case 'cancelled-popup-request':
          throw Exception('Sign-in popup request was cancelled.');
        default:
          throw Exception(e.message ?? 'Authentication failed (${e.code}).');
      }
    } catch (e) {
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

    final user = AppUser.fromMap(doc.data()!, id: doc.id);
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
      final oldUser = AppUser.fromMap(oldDoc.data()!, id: oldDoc.id);
      final oldRoles = List<UserRole>.from(oldUser.roles)..remove(UserRole.keeper);
      batch.update(_firestore.collection('users').doc(oldKeeperId), {
        'roles': oldRoles.map((r) => r.toStr()).toList(),
        'updatedAt': now,
      });
    }

    // 2. Update new keeper roles
    final newDoc = await _firestore.collection('users').doc(newKeeperId).get();
    if (newDoc.exists) {
      final newUser = AppUser.fromMap(newDoc.data()!, id: newDoc.id);
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

  // -------------------------------------------------------------
  // REPORT REPOSITORY
  // -------------------------------------------------------------

  @override
  Stream<List<SwearReport>> watchReports() {
    return _firestore
        .collection('reports')
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => SwearReport.fromMap(doc.data(), id: doc.id))
          .toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  @override
  Future<SwearReport> submitReport({
    required String reporterId,
    required String accusedId,
    required int count,
    String? note,
    required double rateApplied,
  }) async {
    final id = _uuid.v4();
    final report = SwearReport(
      id: id,
      reporterId: reporterId,
      accusedId: accusedId,
      count: count,
      note: note,
      rateApplied: rateApplied,
      totalAmount: count * rateApplied,
      status: ReportStatus.pending,
      createdAt: DateTime.now(),
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

  // -------------------------------------------------------------
  // LEDGER REPOSITORY
  // -------------------------------------------------------------

  @override
  Stream<List<DebtObligation>> watchDebts() {
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
  }) async {
    final updatedDebt = LedgerEngine.recordPayment(
      debt: debt,
      amount: amount,
      recordedBy: recordedBy,
      note: note,
    );

    await _firestore
        .collection('debts')
        .doc(debt.id)
        .set(updatedDebt.toMap());

    return updatedDebt;
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
      return SystemConfig.fromMap(snapshot.data()!);
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

  void dispose() {
    _userDocSubscription?.cancel();
    _userStreamController.close();
  }
}
