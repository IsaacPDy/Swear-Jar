import 'dart:async';
import 'package:uuid/uuid.dart';
import 'package:swear_jar/domain/models/models.dart';
import 'package:swear_jar/domain/ledger_engine.dart';
import 'package:swear_jar/data/repositories/repositories.dart';

class MockDataService
    implements
        IAuthRepository,
        IReportRepository,
        ILedgerRepository,
        IUserRepository,
        IConfigRepository {
  static const _uuid = Uuid();

  AppUser? _currentUser;
  late final StreamController<AppUser?> _authController;
  late final StreamController<List<AppUser>> _usersController;
  late final StreamController<List<SwearReport>> _reportsController;
  late final StreamController<List<DebtObligation>> _debtsController;
  late final StreamController<SystemConfig> _configController;

  final List<AppUser> _users = [];
  final List<SwearReport> _reports = [];
  final List<DebtObligation> _debts = [];
  late SystemConfig _config;

  MockDataService() {
    _authController = StreamController<AppUser?>.broadcast();
    _usersController = StreamController<List<AppUser>>.broadcast();
    _reportsController = StreamController<List<SwearReport>>.broadcast();
    _debtsController = StreamController<List<DebtObligation>>.broadcast();
    _configController = StreamController<SystemConfig>.broadcast();

    _seedData();
  }

  void _seedData() {
    final now = DateTime.now();

    final leo = AppUser(
      id: 'user_leo',
      email: 'leo@swearjar.app',
      displayName: 'Leo (Keeper & Admin)',
      gcashNumber: '09171112233',
      roles: const [UserRole.member, UserRole.keeper, UserRole.admin],
      status: UserStatus.approved,
      createdAt: now.subtract(const Duration(days: 30)),
      updatedAt: now,
    );

    final fiona = AppUser(
      id: 'user_fiona',
      email: 'fiona@swearjar.app',
      displayName: 'Fiona',
      gcashNumber: '09172223344',
      roles: const [UserRole.member],
      status: UserStatus.approved,
      createdAt: now.subtract(const Duration(days: 25)),
      updatedAt: now,
    );

    final sam = AppUser(
      id: 'user_sam',
      email: 'sam@swearjar.app',
      displayName: 'Sam',
      gcashNumber: '09183334455',
      roles: const [UserRole.member],
      status: UserStatus.approved,
      createdAt: now.subtract(const Duration(days: 20)),
      updatedAt: now,
    );

    final alex = AppUser(
      id: 'user_alex',
      email: 'alex@swearjar.app',
      displayName: 'Alex (Pending)',
      gcashNumber: null,
      roles: const [UserRole.member],
      status: UserStatus.pending,
      createdAt: now.subtract(const Duration(hours: 3)),
      updatedAt: now,
    );

    _users.addAll([leo, fiona, sam, alex]);

    _config = SystemConfig(
      activeKeeperId: leo.id,
      currentRatePerSwear: 50.0,
      groupName: 'The Swear Jar Crew',
      totalSwearsAllTime: 12,
      updatedAt: now,
    );

    final rep1 = SwearReport(
      id: 'rep_1',
      reporterId: fiona.id,
      accusedId: sam.id,
      count: 2,
      note: 'During game night rage',
      rateApplied: 50.0,
      totalAmount: 100.0,
      status: ReportStatus.confirmed,
      reviewedBy: leo.id,
      reviewedAt: now.subtract(const Duration(days: 2)),
      createdAt: now.subtract(const Duration(days: 2, hours: 1)),
    );

    final debt1 = DebtObligation(
      id: 'debt_1',
      reportId: rep1.id,
      debtorId: sam.id,
      recipientId: leo.id,
      originalAmount: 100.0,
      remainingBalance: 50.0,
      status: DebtStatus.active,
      payments: [
        PaymentRecord(
          id: 'pay_1',
          debtId: 'debt_1',
          amount: 50.0,
          recordedBy: leo.id,
          recordedAt: now.subtract(const Duration(days: 1)),
          note: 'GCash sent',
        ),
      ],
      createdAt: now.subtract(const Duration(days: 2)),
    );

    final rep2 = SwearReport(
      id: 'rep_2',
      reporterId: sam.id,
      accusedId: fiona.id,
      count: 1,
      note: 'Dropped coffee',
      rateApplied: 50.0,
      totalAmount: 50.0,
      status: ReportStatus.confirmed,
      reviewedBy: leo.id,
      reviewedAt: now.subtract(const Duration(days: 1)),
      createdAt: now.subtract(const Duration(days: 1, hours: 2)),
    );

    final debt2 = DebtObligation(
      id: 'debt_2',
      reportId: rep2.id,
      debtorId: fiona.id,
      recipientId: leo.id,
      originalAmount: 50.0,
      remainingBalance: 50.0,
      status: DebtStatus.active,
      createdAt: now.subtract(const Duration(days: 1)),
    );

    final rep3Pending = SwearReport(
      id: 'rep_3',
      reporterId: fiona.id,
      accusedId: sam.id,
      count: 1,
      note: 'Traffic incident shout',
      rateApplied: 50.0,
      totalAmount: 50.0,
      status: ReportStatus.pending,
      createdAt: now.subtract(const Duration(minutes: 30)),
    );

    _reports.addAll([rep1, rep2, rep3Pending]);
    _debts.addAll([debt1, debt2]);

    _currentUser = fiona;
    _broadcastAll();
  }

  void _broadcastAll() {
    _authController.add(_currentUser);
    _usersController.add(List.unmodifiable(_users));
    _reportsController.add(List.unmodifiable(_reports));
    _debtsController.add(List.unmodifiable(_debts));
    _configController.add(_config);
  }

  @override
  Stream<AppUser?> get userStream async* {
    yield _currentUser;
    yield* _authController.stream;
  }

  @override
  AppUser? get currentUser => _currentUser;

  @override
  Future<void> signInWithGoogle() async {
    _currentUser = _users.firstWhere((u) => u.isApproved);
    _authController.add(_currentUser);
  }

  @override
  Future<void> signInWithDemo(String userId) async {
    final found = _users.firstWhere(
      (u) => u.id == userId,
      orElse: () => _users.first,
    );
    _currentUser = found;
    _authController.add(_currentUser);
  }

  @override
  Future<void> signOut() async {
    _currentUser = null;
    _authController.add(null);
  }

  @override
  Future<void> updateProfile({String? displayName, String? gcashNumber}) async {
    if (_currentUser == null) return;
    final index = _users.indexWhere((u) => u.id == _currentUser!.id);
    if (index != -1) {
      final updated = _users[index].copyWith(
        displayName: displayName,
        gcashNumber: gcashNumber,
        updatedAt: DateTime.now(),
      );
      _users[index] = updated;
      _currentUser = updated;
      _authController.add(_currentUser);
      _usersController.add(List.unmodifiable(_users));
    }
  }

  @override
  Stream<List<SwearReport>> watchReports() async* {
    yield List.unmodifiable(_reports);
    yield* _reportsController.stream;
  }

  @override
  Future<SwearReport> submitReport({
    required String reporterId,
    required String accusedId,
    required int count,
    String? note,
    required double rateApplied,
  }) async {
    final now = DateTime.now();
    final newReport = SwearReport(
      id: _uuid.v4(),
      reporterId: reporterId,
      accusedId: accusedId,
      count: count,
      note: note,
      rateApplied: rateApplied,
      totalAmount: count * rateApplied,
      status: ReportStatus.pending,
      createdAt: now,
    );

    _reports.insert(0, newReport);
    _reportsController.add(List.unmodifiable(_reports));
    return newReport;
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
      existingActiveDebts: _debts.where((d) => d.isActive).toList(),
      now: DateTime.now(),
    );

    final reportIndex = _reports.indexWhere((r) => r.id == report.id);
    if (reportIndex != -1) {
      _reports[reportIndex] = result.updatedReport;
    }

    _debts.insert(0, result.createdDebt);

    for (final updated in result.updatedDebts) {
      final idx = _debts.indexWhere((d) => d.id == updated.id);
      if (idx != -1) {
        _debts[idx] = updated;
      }
    }

    _config = _config.copyWith(
      totalSwearsAllTime: _config.totalSwearsAllTime + report.count,
      updatedAt: DateTime.now(),
    );

    _reportsController.add(List.unmodifiable(_reports));
    _debtsController.add(List.unmodifiable(_debts));
    _configController.add(_config);

    return result;
  }

  @override
  Future<SwearReport> rejectReport({
    required SwearReport report,
    required String reviewerId,
    String? reason,
  }) async {
    final rejected = LedgerEngine.rejectReport(
      report: report,
      reviewerId: reviewerId,
      reason: reason,
      now: DateTime.now(),
    );

    final idx = _reports.indexWhere((r) => r.id == report.id);
    if (idx != -1) {
      _reports[idx] = rejected;
      _reportsController.add(List.unmodifiable(_reports));
    }
    return rejected;
  }

  @override
  Stream<List<DebtObligation>> watchDebts() async* {
    yield List.unmodifiable(_debts);
    yield* _debtsController.stream;
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
      now: DateTime.now(),
    );

    final idx = _debts.indexWhere((d) => d.id == debt.id);
    if (idx != -1) {
      _debts[idx] = updatedDebt;
      _debtsController.add(List.unmodifiable(_debts));
    }
    return updatedDebt;
  }

  @override
  Future<DebtObligation> dismissTransferredDebt({
    required DebtObligation debt,
    required String dismissedBy,
    String? reason,
  }) async {
    final dismissed = LedgerEngine.dismissTransferredDebt(
      debt: debt,
      dismissedBy: dismissedBy,
      reason: reason,
      now: DateTime.now(),
    );

    final idx = _debts.indexWhere((d) => d.id == debt.id);
    if (idx != -1) {
      _debts[idx] = dismissed;
      _debtsController.add(List.unmodifiable(_debts));
    }
    return dismissed;
  }

  @override
  Future<void> migrateDebtsToNewKeeper({
    required List<DebtObligation> activeDebts,
    required String oldKeeperId,
    required String newKeeperId,
  }) async {
    final migrated = LedgerEngine.migrateDebtsToNewKeeper(
      activeDebts: _debts,
      oldKeeperId: oldKeeperId,
      newKeeperId: newKeeperId,
    );

    _debts.clear();
    _debts.addAll(migrated);
    _debtsController.add(List.unmodifiable(_debts));
  }

  @override
  Stream<List<AppUser>> watchUsers() async* {
    yield List.unmodifiable(_users);
    yield* _usersController.stream;
  }

  @override
  Future<void> approveUser(String userId) async {
    final idx = _users.indexWhere((u) => u.id == userId);
    if (idx != -1) {
      final updated = _users[idx].copyWith(
        status: UserStatus.approved,
        updatedAt: DateTime.now(),
      );
      _users[idx] = updated;
      if (_currentUser?.id == userId) {
        _currentUser = updated;
        _authController.add(_currentUser);
      }
      _usersController.add(List.unmodifiable(_users));
    }
  }

  @override
  Future<void> rejectUser(String userId) async {
    final idx = _users.indexWhere((u) => u.id == userId);
    if (idx != -1) {
      final updated = _users[idx].copyWith(
        status: UserStatus.rejected,
        updatedAt: DateTime.now(),
      );
      _users[idx] = updated;
      if (_currentUser?.id == userId) {
        _currentUser = updated;
        _authController.add(_currentUser);
      }
      _usersController.add(List.unmodifiable(_users));
    }
  }

  @override
  Future<void> toggleAdminRole(String userId, bool makeAdmin) async {
    final idx = _users.indexWhere((u) => u.id == userId);
    if (idx != -1) {
      final currentRoles = List<UserRole>.from(_users[idx].roles);
      if (makeAdmin && !currentRoles.contains(UserRole.admin)) {
        currentRoles.add(UserRole.admin);
      } else if (!makeAdmin) {
        currentRoles.remove(UserRole.admin);
      }
      final updated = _users[idx].copyWith(
        roles: currentRoles,
        updatedAt: DateTime.now(),
      );
      _users[idx] = updated;
      if (_currentUser?.id == userId) {
        _currentUser = updated;
        _authController.add(_currentUser);
      }
      _usersController.add(List.unmodifiable(_users));
    }
  }

  @override
  Future<void> appointKeeper(
      String newKeeperId, String oldKeeperId, List<DebtObligation> debts) async {
    for (int i = 0; i < _users.length; i++) {
      if (_users[i].id == oldKeeperId) {
        final roles = List<UserRole>.from(_users[i].roles)..remove(UserRole.keeper);
        _users[i] = _users[i].copyWith(roles: roles, updatedAt: DateTime.now());
      } else if (_users[i].id == newKeeperId) {
        final roles = List<UserRole>.from(_users[i].roles);
        if (!roles.contains(UserRole.keeper)) roles.add(UserRole.keeper);
        _users[i] = _users[i].copyWith(roles: roles, updatedAt: DateTime.now());
      }
    }

    await migrateDebtsToNewKeeper(
      activeDebts: debts,
      oldKeeperId: oldKeeperId,
      newKeeperId: newKeeperId,
    );

    _config = _config.copyWith(
      activeKeeperId: newKeeperId,
      updatedAt: DateTime.now(),
    );

    _usersController.add(List.unmodifiable(_users));
    _configController.add(_config);
  }

  @override
  Stream<SystemConfig> watchConfig() async* {
    yield _config;
    yield* _configController.stream;
  }

  @override
  Future<void> updateRate(double newRate) async {
    _config = _config.copyWith(
      currentRatePerSwear: newRate,
      updatedAt: DateTime.now(),
    );
    _configController.add(_config);
  }

  @override
  Future<void> updateKeeper(String newKeeperId) async {
    final oldKeeper = _config.activeKeeperId;
    await appointKeeper(newKeeperId, oldKeeper, _debts);
  }

  void dispose() {
    _authController.close();
    _usersController.close();
    _reportsController.close();
    _debtsController.close();
    _configController.close();
  }
}
