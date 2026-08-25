import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:swear_jar/data/mock/mock_data_service.dart';
import 'package:swear_jar/data/services/firebase_service.dart';
import 'package:swear_jar/data/repositories/repositories.dart';
import 'package:swear_jar/domain/models/models.dart';

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
  if (config == null) return null;
  try {
    return users.firstWhere((u) => u.id == config.activeKeeperId);
  } catch (_) {
    return null;
  }
});

final activeDebtsProvider = Provider<List<DebtObligation>>((ref) {
  final debts = ref.watch(debtsListProvider).valueOrNull ?? [];
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

final groupTotalActiveDebtProvider = Provider<double>((ref) {
  final debts = ref.watch(activeDebtsProvider);
  return debts.fold<double>(0.0, (sum, debt) => sum + debt.remainingBalance);
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
