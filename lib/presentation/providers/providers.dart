import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:swear_jar/data/mock/mock_data_service.dart';
import 'package:swear_jar/data/services/firebase_service.dart';
import 'package:swear_jar/data/repositories/repositories.dart';
import 'package:swear_jar/domain/ledger_engine.dart';
import 'package:swear_jar/domain/models/models.dart';

final firebaseInitErrorProvider = StateProvider<String?>((ref) => null);

final isLiveModeProvider = StateProvider<bool>((ref) => true);

final mockDataServiceProvider = Provider<MockDataService>((ref) {
  final service = MockDataService();
  ref.onDispose(() => service.dispose());
  return service;
});

final firebaseDataServiceProvider = Provider<FirebaseDataService>((ref) {
  final service = FirebaseDataService();
  ref.onDispose(() => service.dispose());
  return service;
});

final authRepositoryProvider = Provider<IAuthRepository>((ref) {
  final isLive = ref.watch(isLiveModeProvider);
  return isLive
      ? ref.watch(firebaseDataServiceProvider)
      : ref.watch(mockDataServiceProvider);
});

final reportRepositoryProvider = Provider<IReportRepository>((ref) {
  final isLive = ref.watch(isLiveModeProvider);
  return isLive
      ? ref.watch(firebaseDataServiceProvider)
      : ref.watch(mockDataServiceProvider);
});

final ledgerRepositoryProvider = Provider<ILedgerRepository>((ref) {
  final isLive = ref.watch(isLiveModeProvider);
  return isLive
      ? ref.watch(firebaseDataServiceProvider)
      : ref.watch(mockDataServiceProvider);
});

final userRepositoryProvider = Provider<IUserRepository>((ref) {
  final isLive = ref.watch(isLiveModeProvider);
  return isLive
      ? ref.watch(firebaseDataServiceProvider)
      : ref.watch(mockDataServiceProvider);
});

final configRepositoryProvider = Provider<IConfigRepository>((ref) {
  final isLive = ref.watch(isLiveModeProvider);
  return isLive
      ? ref.watch(firebaseDataServiceProvider)
      : ref.watch(mockDataServiceProvider);
});

final currentUserProvider = StreamProvider<AppUser?>((ref) {
  return ref.watch(authRepositoryProvider).userStream;
});

final usersListProvider = StreamProvider<List<AppUser>>((ref) {
  return ref.watch(userRepositoryProvider).watchUsers();
});

final reportsListProvider = StreamProvider<List<SwearReport>>((ref) {
  return ref.watch(reportRepositoryProvider).watchReports();
});

final debtsListProvider = StreamProvider<List<DebtObligation>>((ref) {
  return ref.watch(ledgerRepositoryProvider).watchDebts();
});

final systemConfigProvider = StreamProvider<SystemConfig>((ref) {
  return ref.watch(configRepositoryProvider).watchConfig();
});

final approvedUsersProvider = Provider<List<AppUser>>((ref) {
  final users = ref.watch(usersListProvider).valueOrNull ?? [];
  return users.where((u) => u.isApproved).toList();
});

final pendingUsersProvider = Provider<List<AppUser>>((ref) {
  final users = ref.watch(usersListProvider).valueOrNull ?? [];
  return users.where((u) => u.isPending).toList();
});

final activeKeeperProvider = Provider<AppUser?>((ref) {
  final config = ref.watch(systemConfigProvider).valueOrNull;
  final users = ref.watch(usersListProvider).valueOrNull ?? [];
  if (users.isEmpty) return null;

  if (config != null && config.activeKeeperId.isNotEmpty) {
    try {
      return users.firstWhere((u) => u.id == config.activeKeeperId);
    } catch (_) {}
  }

  try {
    return users.firstWhere((u) => u.isKeeper);
  } catch (_) {
    return null;
  }
});

/// Filters out any orphaned debt obligations whose linked report no longer exists
/// or is not confirmed, and triggers background Firestore reconciliation in Live mode.
final validDebtsProvider = Provider<List<DebtObligation>>((ref) {
  final debtsAsync = ref.watch(debtsListProvider);
  final debts = debtsAsync.valueOrNull ?? [];
  final reportsAsync = ref.watch(reportsListProvider);

  if (!reportsAsync.hasValue) {
    return debts;
  }

  final reports = reportsAsync.value ?? [];
  final confirmedReportIds = reports
      .where((r) => r.isConfirmed)
      .map((r) => r.id)
      .toSet();

  if (ref.watch(isLiveModeProvider) && debtsAsync.hasValue) {
    final config = ref.watch(systemConfigProvider).valueOrNull;
    final firebaseService = ref.read(firebaseDataServiceProvider);
    Future.microtask(() {
      firebaseService.reconcileLedgerWithReports(
        reports: reports,
        debts: debts,
        config: config,
      );
    });
  }

  return debts.where((d) => confirmedReportIds.contains(d.reportId)).toList();
});

final allTimeSwearsCountProvider = Provider<int>((ref) {
  final reportsAsync = ref.watch(reportsListProvider);
  if (reportsAsync.hasValue) {
    final reports = reportsAsync.value ?? [];
    return reports
        .where((r) => r.isConfirmed)
        .fold<int>(0, (sum, r) => sum + r.count);
  }
  final config = ref.watch(systemConfigProvider).valueOrNull;
  return config?.totalSwearsAllTime ?? 0;
});

final activeDebtsProvider = Provider<List<DebtObligation>>((ref) {
  final debts = ref.watch(validDebtsProvider);
  return debts.where((d) => d.isActive).toList();
});

final myDebtsProvider = Provider<List<DebtObligation>>((ref) {
  final user = ref.watch(currentUserProvider).valueOrNull;
  if (user == null) return [];
  final debts = ref.watch(activeDebtsProvider);
  return debts.where((d) => d.debtorId == user.id).toList();
});

final myTotalDebtAmountProvider = Provider<double>((ref) {
  final myDebts = ref.watch(myDebtsProvider);
  return myDebts.fold<double>(0.0, (sum, debt) => sum + debt.remainingBalance);
});

final myTotalCollectedAmountProvider = Provider<double>((ref) {
  final user = ref.watch(currentUserProvider).valueOrNull;
  if (user == null) return 0.0;
  final allDebts = ref.watch(validDebtsProvider);
  return allDebts
      .where((d) => d.debtorId == user.id)
      .fold<double>(0.0, (sum, debt) => sum + debt.collectedAmount);
});

final groupTotalActiveDebtProvider = Provider<double>((ref) {
  final debts = ref.watch(activeDebtsProvider);
  return debts.fold<double>(0.0, (sum, debt) => sum + debt.remainingBalance);
});

final groupTotalCollectedProvider = Provider<double>((ref) {
  final allDebts = ref.watch(validDebtsProvider);
  return allDebts.fold<double>(0.0, (sum, debt) => sum + debt.collectedAmount);
});

final activeMemberBalancesProvider = Provider<List<MemberLedgerSummary>>((ref) {
  final allDebts = ref.watch(validDebtsProvider);
  final keeper = ref.watch(activeKeeperProvider);
  return LedgerEngine.buildMemberLedgerSummaries(
    allDebts: allDebts,
    defaultRecipientId: keeper?.id ?? '',
    groupByRecipientAndTransfer: true,
  ).where((s) => s.hasActiveBalance).toList();
});

final memberLedgerHistoryProvider = Provider<List<MemberLedgerSummary>>((ref) {
  final allDebts = ref.watch(validDebtsProvider);
  final keeper = ref.watch(activeKeeperProvider);
  return LedgerEngine.buildMemberLedgerSummaries(
    allDebts: allDebts,
    defaultRecipientId: keeper?.id ?? '',
    groupByRecipientAndTransfer: false,
  );
});

final paymentHistoryProvider = Provider<List<PaymentHistoryItem>>((ref) {
  final allDebts = ref.watch(validDebtsProvider);
  return LedgerEngine.buildPaymentHistory(allDebts: allDebts);
});

final transferredDebtsOwedToMeProvider = Provider<List<DebtObligation>>((ref) {
  final user = ref.watch(currentUserProvider).valueOrNull;
  if (user == null) return [];
  final debts = ref.watch(activeDebtsProvider);
  return debts.where((d) => d.isTransferred && d.recipientId == user.id).toList();
});

final pendingReportsProvider = Provider<List<SwearReport>>((ref) {
  final reports = ref.watch(reportsListProvider).valueOrNull ?? [];
  return reports.where((r) => r.isPending).toList();
});
