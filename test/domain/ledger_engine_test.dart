import 'package:flutter_test/flutter_test.dart';
import 'package:swear_jar/domain/models/models.dart';
import 'package:swear_jar/domain/ledger_engine.dart';
import 'package:swear_jar/data/mock/mock_data_service.dart';

void main() {
  group('LedgerEngine', () {
    const keeperId = 'keeper_user_1';
    const memberAliceId = 'alice_user_2';
    const memberBobId = 'bob_user_3';

    test('calculateTotal calculates count * rateApplied correctly', () {
      expect(LedgerEngine.calculateTotal(1, 50.0), 50.0);
      expect(LedgerEngine.calculateTotal(3, 50.0), 150.0);
      expect(LedgerEngine.calculateTotal(10, 25.0), 250.0);
    });

    test('confirmReport for normal member creates active debt to Keeper', () {
      final report = SwearReport(
        id: 'report_1',
        reporterId: memberAliceId,
        accusedId: memberBobId,
        count: 2,
        rateApplied: 50.0,
        totalAmount: 100.0,
        status: ReportStatus.pending,
        createdAt: DateTime(2026, 1, 1),
      );

      final result = LedgerEngine.confirmReport(
        report: report,
        activeKeeperId: keeperId,
        reviewerId: keeperId,
        existingActiveDebts: [],
      );

      expect(result.updatedReport.status, ReportStatus.confirmed);
      expect(result.updatedReport.reviewedBy, keeperId);
      expect(result.createdDebt.debtorId, memberBobId);
      expect(result.createdDebt.recipientId, keeperId);
      expect(result.createdDebt.originalAmount, 100.0);
      expect(result.createdDebt.remainingBalance, 100.0);
      expect(result.createdDebt.status, DebtStatus.active);
      expect(result.createdDebt.isTransferred, isFalse);
    });

    test('When Keeper Swears: Keeper debts transfer to reporter & reporter debt is forgiven', () {
      // Existing debts:
      // 1. Bob owes Keeper 100
      // 2. Alice (the reporter) owes Keeper 50
      final debtBob = DebtObligation(
        id: 'debt_bob',
        reportId: 'rep_bob',
        debtorId: memberBobId,
        recipientId: keeperId,
        originalAmount: 100.0,
        remainingBalance: 100.0,
        status: DebtStatus.active,
        createdAt: DateTime(2026, 1, 1),
      );

      final debtAlice = DebtObligation(
        id: 'debt_alice',
        reportId: 'rep_alice',
        debtorId: memberAliceId,
        recipientId: keeperId,
        originalAmount: 50.0,
        remainingBalance: 50.0,
        status: DebtStatus.active,
        createdAt: DateTime(2026, 1, 1),
      );

      // Alice catches Keeper swearing!
      final reportKeeper = SwearReport(
        id: 'report_keeper_swear',
        reporterId: memberAliceId,
        accusedId: keeperId, // Accused is the Keeper!
        count: 1,
        rateApplied: 50.0,
        totalAmount: 50.0,
        status: ReportStatus.pending,
        createdAt: DateTime(2026, 1, 2),
      );

      final result = LedgerEngine.confirmReport(
        report: reportKeeper,
        activeKeeperId: keeperId,
        reviewerId: keeperId,
        existingActiveDebts: [debtBob, debtAlice],
      );

      // Invariant 1: Confirmed report
      expect(result.updatedReport.status, ReportStatus.confirmed);

      // Invariant 2: New debt created for Keeper's own swear, payable to Alice
      expect(result.createdDebt.debtorId, keeperId);
      expect(result.createdDebt.recipientId, memberAliceId);
      expect(result.createdDebt.originalAmount, 50.0);
      expect(result.createdDebt.isTransferred, isTrue);

      // Invariant 3: Alice's own debt to Keeper is CANCELLED / FORGIVEN
      expect(result.cancelledReporterDebts.length, 1);
      final cancelledDebt = result.cancelledReporterDebts.first;
      expect(cancelledDebt.id, 'debt_alice');
      expect(cancelledDebt.remainingBalance, 0.0);
      expect(cancelledDebt.status, DebtStatus.paid);

      // Invariant 4: Bob's debt to Keeper is TRANSFERRED to Alice
      expect(result.transferredDebts.length, 1);
      final transferredDebt = result.transferredDebts.first;
      expect(transferredDebt.id, 'debt_bob');
      expect(transferredDebt.recipientId, memberAliceId);
      expect(transferredDebt.isTransferred, isTrue);
      expect(transferredDebt.transferredFromKeeperId, keeperId);
    });

    test('recordPayment handles partial and full payments properly', () {
      final initialDebt = DebtObligation(
        id: 'debt_1',
        reportId: 'rep_1',
        debtorId: memberBobId,
        recipientId: keeperId,
        originalAmount: 100.0,
        remainingBalance: 100.0,
        status: DebtStatus.active,
        createdAt: DateTime(2026, 1, 1),
      );

      // Partial payment of 40
      final partial = LedgerEngine.recordPayment(
        debt: initialDebt,
        amount: 40.0,
        recordedBy: keeperId,
        note: 'GCash partial',
      );

      expect(partial.remainingBalance, 60.0);
      expect(partial.status, DebtStatus.active);
      expect(partial.payments.length, 1);
      expect(partial.payments.first.amount, 40.0);

      // Full final payment of remaining 60
      final full = LedgerEngine.recordPayment(
        debt: partial,
        amount: 60.0,
        recordedBy: keeperId,
        note: 'GCash balance settled',
      );

      expect(full.remainingBalance, 0.0);
      expect(full.status, DebtStatus.paid);
      expect(full.resolvedAt, isNotNull);
      expect(full.payments.length, 2);
    });

    test('dismissTransferredDebt sets balance to 0 and status to dismissed', () {
      final transferredDebt = DebtObligation(
        id: 'debt_transferred',
        reportId: 'rep_x',
        debtorId: memberBobId,
        recipientId: memberAliceId,
        originalAmount: 100.0,
        remainingBalance: 100.0,
        status: DebtStatus.active,
        isTransferred: true,
        transferredFromKeeperId: keeperId,
        createdAt: DateTime(2026, 1, 1),
      );

      final dismissed = LedgerEngine.dismissTransferredDebt(
        debt: transferredDebt,
        dismissedBy: memberAliceId,
        reason: 'Bob bought me coffee',
      );

      expect(dismissed.remainingBalance, 0.0);
      expect(dismissed.status, DebtStatus.dismissed);
      expect(dismissed.resolvedAt, isNotNull);
      expect(dismissed.payments.length, 1);
    });

    test('migrateDebtsToNewKeeper transfers non-transferred active debts only', () {
      final normalDebt = DebtObligation(
        id: 'debt_normal',
        reportId: 'rep_1',
        debtorId: memberBobId,
        recipientId: 'old_keeper',
        originalAmount: 50.0,
        remainingBalance: 50.0,
        status: DebtStatus.active,
        isTransferred: false,
        createdAt: DateTime(2026, 1, 1),
      );

      final transferredDebt = DebtObligation(
        id: 'debt_transferred',
        reportId: 'rep_2',
        debtorId: memberBobId,
        recipientId: memberAliceId, // Held by Alice
        originalAmount: 50.0,
        remainingBalance: 50.0,
        status: DebtStatus.active,
        isTransferred: true,
        createdAt: DateTime(2026, 1, 1),
      );

      final migrated = LedgerEngine.migrateDebtsToNewKeeper(
        activeDebts: [normalDebt, transferredDebt],
        oldKeeperId: 'old_keeper',
        newKeeperId: 'new_keeper',
      );

      expect(migrated.first.recipientId, 'new_keeper');
      expect(migrated.last.recipientId, memberAliceId); // Preserved!
    });

    test('updateReport adjusts confirmed report, linked debt balance, and swearCountDelta', () {
      final confirmedReport = SwearReport(
        id: 'rep_confirmed_1',
        reporterId: memberAliceId,
        accusedId: memberBobId,
        count: 2,
        note: 'Initial note',
        rateApplied: 50.0,
        totalAmount: 100.0,
        status: ReportStatus.confirmed,
        swearDate: DateTime(2026, 1, 5),
        createdAt: DateTime(2026, 1, 5),
      );

      // Linked debt where 40 has already been paid (remaining 60)
      final linkedDebt = DebtObligation(
        id: 'debt_confirmed_1',
        reportId: 'rep_confirmed_1',
        debtorId: memberBobId,
        recipientId: keeperId,
        originalAmount: 100.0,
        remainingBalance: 60.0,
        status: DebtStatus.active,
        createdAt: DateTime(2026, 1, 5),
      );

      final newDate = DateTime(2026, 1, 3);
      final updateRes = LedgerEngine.updateReport(
        report: confirmedReport,
        accusedId: memberBobId,
        count: 4, // Increased from 2 to 4 (+2 swears -> 200 total)
        swearDate: newDate,
        note: 'Audited note',
        existingDebts: [linkedDebt],
      );

      expect(updateRes.updatedReport.count, 4);
      expect(updateRes.updatedReport.totalAmount, 200.0);
      expect(updateRes.updatedReport.swearDate, newDate);
      expect(updateRes.updatedReport.note, 'Audited note');
      expect(updateRes.swearCountDelta, 2);

      expect(updateRes.updatedDebt, isNotNull);
      expect(updateRes.updatedDebt!.originalAmount, 200.0);
      // 40 was already paid, so remaining balance should be 200 - 40 = 160
      expect(updateRes.updatedDebt!.remainingBalance, 160.0);
      expect(updateRes.updatedDebt!.status, DebtStatus.active);
    });

    test('deleteReport removes linked debt and returns negative swearCountDelta for confirmed report', () {
      final confirmedReport = SwearReport(
        id: 'rep_del_1',
        reporterId: memberAliceId,
        accusedId: memberBobId,
        count: 3,
        rateApplied: 50.0,
        totalAmount: 150.0,
        status: ReportStatus.confirmed,
        createdAt: DateTime(2026, 1, 5),
      );

      final linkedDebt = DebtObligation(
        id: 'debt_del_1',
        reportId: 'rep_del_1',
        debtorId: memberBobId,
        recipientId: keeperId,
        originalAmount: 150.0,
        remainingBalance: 150.0,
        status: DebtStatus.active,
        createdAt: DateTime(2026, 1, 5),
      );

      final delRes = LedgerEngine.deleteReport(
        report: confirmedReport,
        existingDebts: [linkedDebt],
      );

      expect(delRes.deletedReportId, 'rep_del_1');
      expect(delRes.deletedDebtIds, ['debt_del_1']);
      expect(delRes.swearCountDelta, -3);
    });

    test('deleteUserHistory deletes only reports/debts where user is accused/debtor and keeps reports filed against others', () {
      final bobAccusedConfirmed = SwearReport(
        id: 'rep_bob_accused_1',
        reporterId: memberAliceId,
        accusedId: memberBobId,
        count: 4,
        rateApplied: 50.0,
        totalAmount: 200.0,
        status: ReportStatus.confirmed,
        createdAt: DateTime(2026, 1, 5),
      );

      final bobAccusedPending = SwearReport(
        id: 'rep_bob_accused_2',
        reporterId: memberAliceId,
        accusedId: memberBobId,
        count: 2,
        rateApplied: 50.0,
        totalAmount: 100.0,
        status: ReportStatus.pending,
        createdAt: DateTime(2026, 1, 6),
      );

      final bobReportedAlice = SwearReport(
        id: 'rep_bob_reporter_1',
        reporterId: memberBobId,
        accusedId: memberAliceId,
        count: 1,
        rateApplied: 50.0,
        totalAmount: 50.0,
        status: ReportStatus.confirmed,
        createdAt: DateTime(2026, 1, 7),
      );

      final bobDebt = DebtObligation(
        id: 'debt_bob_1',
        reportId: 'rep_bob_accused_1',
        debtorId: memberBobId,
        recipientId: keeperId,
        originalAmount: 200.0,
        remainingBalance: 200.0,
        status: DebtStatus.active,
        createdAt: DateTime(2026, 1, 5),
      );

      final aliceDebt = DebtObligation(
        id: 'debt_alice_1',
        reportId: 'rep_bob_reporter_1',
        debtorId: memberAliceId,
        recipientId: keeperId,
        originalAmount: 50.0,
        remainingBalance: 50.0,
        status: DebtStatus.active,
        createdAt: DateTime(2026, 1, 7),
      );

      final res = LedgerEngine.deleteUserHistory(
        userId: memberBobId,
        existingReports: [
          bobAccusedConfirmed,
          bobAccusedPending,
          bobReportedAlice,
        ],
        existingDebts: [bobDebt, aliceDebt],
      );

      expect(res.deletedUserId, memberBobId);
      expect(
        res.deletedReportIds,
        containsAll(['rep_bob_accused_1', 'rep_bob_accused_2']),
      );
      expect(res.deletedReportIds, isNot(contains('rep_bob_reporter_1')));
      expect(res.deletedDebtIds, ['debt_bob_1']);
      expect(res.swearCountDelta, -4);
    });

    test('MockDataService supports manual user creation, Google login assignment, account unlinking, and full user deletion', () async {
      final service = MockDataService();
      addTearDown(() => service.dispose());

      // 1. Create a manual user
      final manualUser = await service.createManualUser(
        displayName: 'Marco',
        gcashNumber: '09179998877',
      );
      expect(manualUser.isApproved, isTrue);
      expect(manualUser.hasLinkedAccount, isFalse);
      expect(manualUser.gcashNumber, '09179998877');

      // 2. Submit and confirm a report against the manual user
      final report = await service.submitReport(
        reporterId: 'user_leo',
        accusedId: manualUser.id,
        count: 3,
        rateApplied: 50.0,
      );
      final debtsBefore = await service.watchDebts().first;
      await service.confirmReport(
        report: report,
        activeKeeperId: 'user_leo',
        reviewerId: 'user_leo',
        existingDebts: debtsBefore,
      );

      // 3. Assign pending Google user ('user_alex') to the manual user ('Marco')
      await service.assignPendingUserToExisting(
        pendingUserId: 'user_alex',
        targetUserId: manualUser.id,
      );

      final usersAfterAssign = await service.watchUsers().first;
      expect(usersAfterAssign.any((u) => u.id == 'user_alex'), isFalse);
      final linkedMarco =
          usersAfterAssign.firstWhere((u) => u.id == manualUser.id);
      expect(linkedMarco.hasLinkedAccount, isTrue);
      expect(linkedMarco.email, 'alex@swearjar.app');
      expect(linkedMarco.authUid, 'user_alex');
      expect(linkedMarco.displayName, 'Marco');

      // 4. Unlink Google account from Marco (keep profile and history)
      await service.unlinkUserAccount(manualUser.id);
      final usersAfterUnlink = await service.watchUsers().first;
      final unlinkedMarco =
          usersAfterUnlink.firstWhere((u) => u.id == manualUser.id);
      expect(unlinkedMarco.hasLinkedAccount, isFalse);
      expect(unlinkedMarco.email, isEmpty);
      expect(unlinkedMarco.authUid, isNull);

      final reportsAfterUnlink = await service.watchReports().first;
      expect(reportsAfterUnlink.any((r) => r.id == report.id), isTrue);

      // 5. Delete Marco completely (wipe profile and history)
      final debtsBeforeDelete = await service.watchDebts().first;
      await service.deleteUserCompletely(
        userId: manualUser.id,
        existingReports: reportsAfterUnlink,
        existingDebts: debtsBeforeDelete,
      );

      final usersAfterDelete = await service.watchUsers().first;
      final reportsAfterDelete = await service.watchReports().first;
      final debtsAfterDelete = await service.watchDebts().first;
      expect(usersAfterDelete.any((u) => u.id == manualUser.id), isFalse);
      expect(reportsAfterDelete.any((r) => r.accusedId == manualUser.id), isFalse);
      expect(debtsAfterDelete.any((d) => d.debtorId == manualUser.id), isFalse);
    });

    test('SwearLanguage and SwearReport swearBreakdown serialize and persist in MockDataService', () async {
      final service = MockDataService();
      addTearDown(() => service.dispose());

      final initialConfig = await service.watchConfig().first;
      expect(initialConfig.swearLanguages, isNotEmpty);

      final customLanguages = [
        ...initialConfig.swearLanguages,
        const SwearLanguage(
          id: 'bisaya',
          name: 'Bisaya',
          swears: ['Yawa', 'Atay', 'Piste'],
        ),
      ];
      await service.updateSwearLanguages(customLanguages);

      final updatedConfig = await service.watchConfig().first;
      expect(
        updatedConfig.swearLanguages.any((l) => l.name == 'Bisaya'),
        isTrue,
      );
      final bisaya =
          updatedConfig.swearLanguages.firstWhere((l) => l.name == 'Bisaya');
      expect(bisaya.swears, ['Yawa', 'Atay', 'Piste']);

      final submitted = await service.submitReport(
        reporterId: 'user_fiona',
        accusedId: 'user_sam',
        count: 4,
        note: 'Ranked match',
        swearBreakdown: const {'Yawa': 2, 'Piste': 1},
        rateApplied: 50.0,
      );

      expect(submitted.count, 4);
      expect(submitted.swearBreakdown, {'Yawa': 2, 'Piste': 1});

      final roundTrip = SwearReport.fromMap(submitted.toMap());
      expect(roundTrip.swearBreakdown, {'Yawa': 2, 'Piste': 1});
    });
  });
}
