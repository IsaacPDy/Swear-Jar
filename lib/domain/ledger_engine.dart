import 'package:uuid/uuid.dart';
import 'models/models.dart';

class ReportConfirmationResult {
  final SwearReport updatedReport;
  final DebtObligation createdDebt;
  final List<DebtObligation> updatedDebts;
  final List<DebtObligation> transferredDebts;
  final List<DebtObligation> cancelledReporterDebts;

  const ReportConfirmationResult({
    required this.updatedReport,
    required this.createdDebt,
    this.updatedDebts = const [],
    this.transferredDebts = const [],
    this.cancelledReporterDebts = const [],
  });
}

class LedgerEngine {
  static const _uuid = Uuid();

  /// Calculate total financial penalty for a swear report
  static double calculateTotal(int count, double rateApplied) {
    if (count < 1) return rateApplied;
    return count * rateApplied;
  }

  /// Confirm a swear report with full invariant enforcement.
  ///
  /// Invariants enforced:
  /// 1. Consequence rate captured in report is locked.
  /// 2. If accused is a normal member:
  ///    - A new active debt is created with debtor = accusedId, recipient = activeKeeperId.
  /// 3. If accused is the Keeper ("When the Keeper Swears" transfer rule):
  ///    - All currently active debts where recipient == activeKeeperId are transferred to the reporter.
  ///    - If the reporter owed any active debt to the Keeper, that debt is cancelled/forgiven immediately.
  ///    - A new debt is created with debtor = accusedId (Keeper), recipient = reporterId.
  static ReportConfirmationResult confirmReport({
    required SwearReport report,
    required String activeKeeperId,
    required String reviewerId,
    required List<DebtObligation> existingActiveDebts,
    DateTime? now,
  }) {
    final timestamp = now ?? DateTime.now();
    final totalAmount = calculateTotal(report.count, report.rateApplied);

    final confirmedReport = report.copyWith(
      status: ReportStatus.confirmed,
      totalAmount: totalAmount,
      reviewedBy: reviewerId,
      reviewedAt: timestamp,
    );

    final isKeeperAccused = report.accusedId == activeKeeperId;

    if (!isKeeperAccused) {
      // Normal swear report confirmation
      final newDebt = DebtObligation(
        id: _uuid.v4(),
        reportId: report.id,
        debtorId: report.accusedId,
        recipientId: activeKeeperId,
        originalAmount: totalAmount,
        remainingBalance: totalAmount,
        status: DebtStatus.active,
        isTransferred: false,
        createdAt: timestamp,
      );

      return ReportConfirmationResult(
        updatedReport: confirmedReport,
        createdDebt: newDebt,
        updatedDebts: [],
      );
    } else {
      // Keeper was caught swearing!
      final reporterId = report.reporterId;
      final transferred = <DebtObligation>[];
      final cancelled = <DebtObligation>[];
      final allUpdated = <DebtObligation>[];

      for (final debt in existingActiveDebts) {
        if (!debt.isActive) continue;

        // If the debt was owed TO the Keeper
        if (debt.recipientId == activeKeeperId) {
          // If the debtor was the Reporter themselves: cancel / forgive the debt
          if (debt.debtorId == reporterId) {
            final cancelledDebt = debt.copyWith(
              remainingBalance: 0.0,
              status: DebtStatus.paid,
              resolvedAt: timestamp,
              payments: [
                ...debt.payments,
                PaymentRecord(
                  id: _uuid.v4(),
                  debtId: debt.id,
                  amount: debt.remainingBalance,
                  recordedBy: 'SYSTEM_KEEPER_SWEAR_OFFSET',
                  recordedAt: timestamp,
                  note: 'Auto-cancelled because reporter caught the Keeper swearing',
                ),
              ],
            );
            cancelled.add(cancelledDebt);
            allUpdated.add(cancelledDebt);
          } else {
            // Transfer this active debt to the Reporter
            final transferredDebt = debt.copyWith(
              recipientId: reporterId,
              isTransferred: true,
              transferredFromKeeperId: activeKeeperId,
            );
            transferred.add(transferredDebt);
            allUpdated.add(transferredDebt);
          }
        }
      }

      // Create new debt for the Keeper's swear, payable to Reporter
      final newKeeperDebt = DebtObligation(
        id: _uuid.v4(),
        reportId: report.id,
        debtorId: activeKeeperId,
        recipientId: reporterId,
        originalAmount: totalAmount,
        remainingBalance: totalAmount,
        status: DebtStatus.active,
        isTransferred: true,
        transferredFromKeeperId: activeKeeperId,
        createdAt: timestamp,
      );

      return ReportConfirmationResult(
        updatedReport: confirmedReport,
        createdDebt: newKeeperDebt,
        updatedDebts: allUpdated,
        transferredDebts: transferred,
        cancelledReporterDebts: cancelled,
      );
    }
  }

  /// Reject a swear report
  static SwearReport rejectReport({
    required SwearReport report,
    required String reviewerId,
    String? reason,
    DateTime? now,
  }) {
    final timestamp = now ?? DateTime.now();
    return report.copyWith(
      status: ReportStatus.rejected,
      reviewedBy: reviewerId,
      reviewedAt: timestamp,
      rejectionReason: reason ?? 'Rejected by Keeper',
    );
  }

  /// Record a payment (partial or full) towards an active debt
  static DebtObligation recordPayment({
    required DebtObligation debt,
    required double amount,
    required String recordedBy,
    String? note,
    DateTime? now,
  }) {
    if (amount <= 0) {
      throw ArgumentError('Payment amount must be greater than zero');
    }

    final timestamp = now ?? DateTime.now();
    final actualPayment =
        amount > debt.remainingBalance ? debt.remainingBalance : amount;
    final newRemaining = debt.remainingBalance - actualPayment;
    final isFullyPaid = newRemaining <= 0.001; // account for double precision

    final paymentRecord = PaymentRecord(
      id: _uuid.v4(),
      debtId: debt.id,
      amount: actualPayment,
      recordedBy: recordedBy,
      recordedAt: timestamp,
      note: note,
    );

    return debt.copyWith(
      remainingBalance: isFullyPaid ? 0.0 : newRemaining,
      status: isFullyPaid ? DebtStatus.paid : DebtStatus.active,
      resolvedAt: isFullyPaid ? timestamp : null,
      payments: [...debt.payments, paymentRecord],
    );
  }

  /// Dismiss a transferred debt (exclusive action for the Reporter holding it)
  static DebtObligation dismissTransferredDebt({
    required DebtObligation debt,
    required String dismissedBy,
    String? reason,
    DateTime? now,
  }) {
    final timestamp = now ?? DateTime.now();
    final paymentRecord = PaymentRecord(
      id: _uuid.v4(),
      debtId: debt.id,
      amount: debt.remainingBalance,
      recordedBy: dismissedBy,
      recordedAt: timestamp,
      note: reason ?? 'Dismissed by recipient',
    );

    return debt.copyWith(
      remainingBalance: 0.0,
      status: DebtStatus.dismissed,
      resolvedAt: timestamp,
      payments: [...debt.payments, paymentRecord],
    );
  }

  /// Appoint a new Keeper and transfer active standard debts to the new Keeper.
  /// Note: Transferred debts remain with their original reporters.
  static List<DebtObligation> migrateDebtsToNewKeeper({
    required List<DebtObligation> activeDebts,
    required String oldKeeperId,
    required String newKeeperId,
  }) {
    return activeDebts.map((debt) {
      if (!debt.isActive) return debt;
      // Do not reassign transferred debts
      if (debt.isTransferred) return debt;
      // Reassign active debts owed to oldKeeperId to newKeeperId
      if (debt.recipientId == oldKeeperId) {
        return debt.copyWith(recipientId: newKeeperId);
      }
      return debt;
    }).toList();
  }
}
