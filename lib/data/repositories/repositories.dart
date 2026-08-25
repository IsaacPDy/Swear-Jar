import 'package:swear_jar/domain/models/models.dart';
import 'package:swear_jar/domain/ledger_engine.dart';

abstract class IAuthRepository {
  Stream<AppUser?> get userStream;
  AppUser? get currentUser;
  Future<void> signInWithGoogle();
  Future<void> signInWithDemo(String userId);
  Future<void> signOut();
  Future<void> updateProfile({String? displayName, String? gcashNumber});
}

abstract class IReportRepository {
  Stream<List<SwearReport>> watchReports();
  Future<SwearReport> submitReport({
    required String reporterId,
    required String accusedId,
    required int count,
    String? note,
    required double rateApplied,
  });
  Future<ReportConfirmationResult> confirmReport({
    required SwearReport report,
    required String activeKeeperId,
    required String reviewerId,
    required List<DebtObligation> existingDebts,
  });
  Future<SwearReport> rejectReport({
    required SwearReport report,
    required String reviewerId,
    String? reason,
  });
}

abstract class ILedgerRepository {
  Stream<List<DebtObligation>> watchDebts();
  Future<DebtObligation> recordPayment({
    required DebtObligation debt,
    required double amount,
    required String recordedBy,
    String? note,
  });
  Future<DebtObligation> dismissTransferredDebt({
    required DebtObligation debt,
    required String dismissedBy,
    String? reason,
  });
  Future<void> migrateDebtsToNewKeeper({
    required List<DebtObligation> activeDebts,
    required String oldKeeperId,
    required String newKeeperId,
  });
}

abstract class IUserRepository {
  Stream<List<AppUser>> watchUsers();
  Future<void> approveUser(String userId);
  Future<void> rejectUser(String userId);
  Future<void> toggleAdminRole(String userId, bool makeAdmin);
  Future<void> appointKeeper(String newKeeperId, String oldKeeperId, List<DebtObligation> debts);
}

abstract class IConfigRepository {
  Stream<SystemConfig> watchConfig();
  Future<void> updateRate(double newRate);
  Future<void> updateKeeper(String newKeeperId);
}
