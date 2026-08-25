import 'package:flutter_test/flutter_test.dart';
import 'package:swear_jar/domain/models/models.dart';
import 'package:swear_jar/domain/ledger_engine.dart';

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
  });
}
