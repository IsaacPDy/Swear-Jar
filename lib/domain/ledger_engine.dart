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

class ReportUpdateResult {
  final SwearReport updatedReport;
  final DebtObligation? updatedDebt;
  final int swearCountDelta;

  const ReportUpdateResult({
    required this.updatedReport,
    this.updatedDebt,
    required this.swearCountDelta,
  });
}

class ReportDeletionResult {
  final String deletedReportId;
  final List<String> deletedDebtIds;
  final int swearCountDelta;

  const ReportDeletionResult({
    required this.deletedReportId,
    this.deletedDebtIds = const [],
    required this.swearCountDelta,
  });
}

class UserDeletionResult {
  final String deletedUserId;
  final List<String> deletedReportIds;
  final List<String> deletedDebtIds;
  final int swearCountDelta;

  const UserDeletionResult({
    required this.deletedUserId,
    this.deletedReportIds = const [],
    this.deletedDebtIds = const [],
    required this.swearCountDelta,
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

  /// Record a payment (partial or full) towards a member's active debts (oldest first, FIFO).
  /// Returns the list of modified DebtObligations.
  static List<DebtObligation> recordMemberPayment({
    required List<DebtObligation> activeDebts,
    required double amount,
    required String recordedBy,
    String? note,
    DateTime? now,
  }) {
    if (amount <= 0) {
      throw ArgumentError('Payment amount must be greater than zero');
    }

    final timestamp = now ?? DateTime.now();
    final sorted = activeDebts
        .where((d) => d.isActive && d.remainingBalance > 0.001)
        .toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

    double remainingToApply = amount;
    final updatedDebts = <DebtObligation>[];

    for (final debt in sorted) {
      if (remainingToApply <= 0.001) break;
      final paymentForDebt = remainingToApply > debt.remainingBalance
          ? debt.remainingBalance
          : remainingToApply;
      if (paymentForDebt <= 0.001) continue;

      final updated = recordPayment(
        debt: debt,
        amount: paymentForDebt,
        recordedBy: recordedBy,
        note: note,
        now: timestamp,
      );
      updatedDebts.add(updated);
      remainingToApply -= paymentForDebt;
    }

    return updatedDebts;
  }

  /// Dismiss all active transferred debts in a member summary group.
  static List<DebtObligation> dismissMemberTransferredDebts({
    required List<DebtObligation> activeDebts,
    required String dismissedBy,
    String? reason,
    DateTime? now,
  }) {
    final timestamp = now ?? DateTime.now();
    return activeDebts
        .where((d) => d.isActive && d.remainingBalance > 0.001)
        .map((debt) => dismissTransferredDebt(
              debt: debt,
              dismissedBy: dismissedBy,
              reason: reason,
              now: timestamp,
            ))
        .toList();
  }

  /// Aggregate debts into per-person ledger summaries so the UI shows total per person
  /// ("To Be Received" and "Collected Already") rather than individual report transactions.
  static List<MemberLedgerSummary> buildMemberLedgerSummaries({
    required List<DebtObligation> allDebts,
    String defaultRecipientId = '',
    bool groupByRecipientAndTransfer = false,
  }) {
    final grouped = <String, List<DebtObligation>>{};
    for (final debt in allDebts) {
      final key = groupByRecipientAndTransfer
          ? '${debt.debtorId}|${debt.recipientId}|${debt.isTransferred}'
          : debt.debtorId;
      grouped.putIfAbsent(key, () => []).add(debt);
    }

    final summaries = <MemberLedgerSummary>[];
    for (final entry in grouped.entries) {
      final debts = entry.value;
      if (debts.isEmpty) continue;

      double toBeReceived = 0.0;
      double collectedAlready = 0.0;
      DateTime? lastActivity;

      for (final d in debts) {
        if (d.isActive) {
          toBeReceived += d.remainingBalance;
        }
        collectedAlready += d.collectedAmount;

        DateTime candidate = d.resolvedAt ?? d.createdAt;
        for (final p in d.payments) {
          if (p.recordedAt.isAfter(candidate)) {
            candidate = p.recordedAt;
          }
        }
        if (lastActivity == null || candidate.isAfter(lastActivity)) {
          lastActivity = candidate;
        }
      }

      if (toBeReceived <= 0.001 && collectedAlready <= 0.001) {
        continue;
      }

      final activeRecipient = debts
              .where((d) => d.isActive)
              .map((d) => d.recipientId)
              .firstOrNull ??
          (defaultRecipientId.isNotEmpty
              ? defaultRecipientId
              : debts.first.recipientId);

      summaries.add(
        MemberLedgerSummary(
          debtorId: debts.first.debtorId,
          recipientId: groupByRecipientAndTransfer
              ? debts.first.recipientId
              : activeRecipient,
          isTransferred: groupByRecipientAndTransfer
              ? debts.first.isTransferred
              : debts.any((d) => d.isActive && d.isTransferred),
          totalIncurred: collectedAlready + toBeReceived,
          collectedAlready: collectedAlready,
          toBeReceived: toBeReceived,
          debts: debts,
          lastActivityAt: lastActivity,
        ),
      );
    }

    summaries.sort((a, b) {
      final activeCmp = b.toBeReceived.compareTo(a.toBeReceived);
      if (activeCmp.abs() > 0.001) return activeCmp;
      final collectedCmp = b.collectedAlready.compareTo(a.collectedAlready);
      if (collectedCmp.abs() > 0.001) return collectedCmp;
      return (b.lastActivityAt ?? DateTime.fromMillisecondsSinceEpoch(0))
          .compareTo(
              a.lastActivityAt ?? DateTime.fromMillisecondsSinceEpoch(0));
    });

    return summaries;
  }

  /// Extract chronological payment history entries across all debts (newest first),
  /// merging split FIFO records created at the same timestamp into a single payment entry.
  static List<PaymentHistoryItem> buildPaymentHistory({
    required List<DebtObligation> allDebts,
  }) {
    final groupedByAction = <String, PaymentHistoryItem>{};

    for (final debt in allDebts) {
      final realPayments = debt.payments
          .where((p) => p.recordedBy != 'SYSTEM_KEEPER_SWEAR_OFFSET')
          .toList();
      if (realPayments.isEmpty) continue;

      final effectivePayments = debt.isDismissed && realPayments.isNotEmpty
          ? realPayments.sublist(0, realPayments.length - 1)
          : realPayments;

      double runningPaid = 0.0;
      for (final p in effectivePayments) {
        if (p.amount <= 0.001) continue;
        runningPaid += p.amount;
        final isPartialForThisDebt =
            runningPaid < debt.originalAmount - 0.001 ||
                p.amount < debt.originalAmount - 0.001;

        final actionSecond = p.recordedAt.millisecondsSinceEpoch ~/ 1000;
        final groupKey =
            '${debt.debtorId}|${debt.recipientId}|${p.recordedBy}|${p.note ?? ""}|$actionSecond';

        final existing = groupedByAction[groupKey];
        if (existing == null) {
          groupedByAction[groupKey] = PaymentHistoryItem(
            id: p.id,
            debtorId: debt.debtorId,
            recipientId: debt.recipientId,
            amount: p.amount,
            recordedBy: p.recordedBy,
            recordedAt: p.recordedAt,
            note: p.note,
            isPartial: isPartialForThisDebt,
          );
        } else {
          groupedByAction[groupKey] = PaymentHistoryItem(
            id: existing.id,
            debtorId: existing.debtorId,
            recipientId: existing.recipientId,
            amount: existing.amount + p.amount,
            recordedBy: existing.recordedBy,
            recordedAt: p.recordedAt.isAfter(existing.recordedAt)
                ? p.recordedAt
                : existing.recordedAt,
            note: existing.note,
            isPartial: isPartialForThisDebt && debt.remainingBalance > 0.001,
          );
        }
      }
    }

    final items = groupedByAction.values.toList()
      ..sort((a, b) => b.recordedAt.compareTo(a.recordedAt));
    return items;
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

  /// Audit/update an existing report (count, date, accused member, or note).
  /// If the report is already confirmed, recalculates and updates its linked debt
  /// and returns the swear count delta to update totalSwearsAllTime.
  static ReportUpdateResult updateReport({
    required SwearReport report,
    required String accusedId,
    required int count,
    required DateTime swearDate,
    String? note,
    Map<String, int>? swearBreakdown,
    required List<DebtObligation> existingDebts,
    DateTime? now,
  }) {
    final safeCount = count.clamp(1, 99);
    final newTotalAmount = calculateTotal(safeCount, report.rateApplied);
    final trimmedNote = note?.trim();

    final updatedReport = report.copyWith(
      accusedId: accusedId,
      count: safeCount,
      swearDate: swearDate,
      note: (trimmedNote == null || trimmedNote.isEmpty) ? null : trimmedNote,
      clearNote: trimmedNote == null || trimmedNote.isEmpty,
      swearBreakdown: swearBreakdown,
      totalAmount: newTotalAmount,
    );

    final swearCountDelta = report.isConfirmed ? (safeCount - report.count) : 0;

    DebtObligation? updatedDebt;
    if (report.isConfirmed) {
      final matchingIndex =
          existingDebts.indexWhere((d) => d.reportId == report.id);
      if (matchingIndex != -1) {
        final existingDebt = existingDebts[matchingIndex];
        final paidSoFar =
            (existingDebt.originalAmount - existingDebt.remainingBalance)
                .clamp(0.0, double.infinity);

        if (existingDebt.isDismissed) {
          updatedDebt = existingDebt.copyWith(
            debtorId: accusedId,
            originalAmount: newTotalAmount,
            remainingBalance: 0.0,
          );
        } else {
          final newRemaining =
              (newTotalAmount - paidSoFar).clamp(0.0, double.infinity);
          final isNowPaid = newRemaining <= 0.001;
          final timestamp = now ?? DateTime.now();

          updatedDebt = DebtObligation(
            id: existingDebt.id,
            reportId: existingDebt.reportId,
            debtorId: accusedId,
            recipientId: existingDebt.recipientId,
            originalAmount: newTotalAmount,
            remainingBalance: isNowPaid ? 0.0 : newRemaining,
            status: isNowPaid ? DebtStatus.paid : DebtStatus.active,
            isTransferred: existingDebt.isTransferred,
            transferredFromKeeperId: existingDebt.transferredFromKeeperId,
            payments: List.from(existingDebt.payments),
            createdAt: existingDebt.createdAt,
            resolvedAt:
                isNowPaid ? (existingDebt.resolvedAt ?? timestamp) : null,
          );
        }
      }
    }

    return ReportUpdateResult(
      updatedReport: updatedReport,
      updatedDebt: updatedDebt,
      swearCountDelta: swearCountDelta,
    );
  }

  /// Delete a report and identify any linked debt obligations and swear count delta to roll back.
  static ReportDeletionResult deleteReport({
    required SwearReport report,
    required List<DebtObligation> existingDebts,
  }) {
    final linkedDebtIds = existingDebts
        .where((d) => d.reportId == report.id)
        .map((d) => d.id)
        .toList();

    final swearCountDelta = report.isConfirmed ? -report.count : 0;

    return ReportDeletionResult(
      deletedReportId: report.id,
      deletedDebtIds: linkedDebtIds,
      swearCountDelta: swearCountDelta,
    );
  }

  /// Identify all swear reports and debts belonging to a deleted user (where they are the accused/debtor)
  /// while preserving reports they filed against other members.
  static UserDeletionResult deleteUserHistory({
    required String userId,
    required List<SwearReport> existingReports,
    required List<DebtObligation> existingDebts,
  }) {
    final userAccusedReports =
        existingReports.where((r) => r.accusedId == userId).toList();
    final deletedReportIds = userAccusedReports.map((r) => r.id).toSet();

    int confirmedSwearsRemoved = 0;
    for (final report in userAccusedReports) {
      if (report.isConfirmed) {
        confirmedSwearsRemoved += report.count;
      }
    }

    final deletedDebtIds = existingDebts
        .where(
            (d) => d.debtorId == userId || deletedReportIds.contains(d.reportId))
        .map((d) => d.id)
        .toList();

    return UserDeletionResult(
      deletedUserId: userId,
      deletedReportIds: deletedReportIds.toList(),
      deletedDebtIds: deletedDebtIds,
      swearCountDelta: -confirmedSwearsRemoved,
    );
  }

  /// Format a DateTime into a canonical 'YYYY-MM' month filter key.
  static String monthKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}';
  }

  /// Extract all selectable months (all months of the current year up to `now`,
  /// plus any additional months present in `reports`), sorted newest first.
  static List<DateTime> extractReportMonths(
    List<SwearReport> reports, {
    DateTime? now,
  }) {
    final current = now ?? DateTime.now();
    final monthSet = <String, DateTime>{};

    // Include all months of the current year up to the current month
    for (int m = 1; m <= current.month; m++) {
      final dt = DateTime(current.year, m);
      monthSet[monthKey(dt)] = dt;
    }

    // Also include any month that has at least one report
    for (final r in reports) {
      final dt = DateTime(r.swearDate.year, r.swearDate.month);
      monthSet[monthKey(dt)] = dt;
    }

    final months = monthSet.values.toList()
      ..sort((a, b) => b.compareTo(a));
    return months;
  }

  /// Compute analytics for "People Who Swore" and "Words Said" from a list of reports.
  /// By default, rejected reports are excluded so invalid/rejected reports do not skew counts,
  /// unless `includeRejected` is true (e.g. when specifically inspecting the Rejected filter).
  static ReportAnalyticsSummary computeReportAnalytics(
    List<SwearReport> reports, {
    bool includeRejected = false,
  }) {
    final eligible = includeRejected
        ? reports
        : reports.where((r) => !r.isRejected).toList();

    if (eligible.isEmpty) {
      return const ReportAnalyticsSummary(
        totalSwears: 0,
        totalReports: 0,
        totalPenaltyAmount: 0.0,
      );
    }

    int totalSwears = 0;
    double totalPenaltyAmount = 0.0;

    final personSwears = <String, int>{};
    final personReports = <String, int>{};
    final personAmount = <String, double>{};

    final wordCounts = <String, int>{};
    final wordDisplayLabels = <String, String>{};
    int unspecifiedWordCount = 0;

    for (final report in eligible) {
      totalSwears += report.count;
      totalPenaltyAmount += report.totalAmount;

      final uid = report.accusedId;
      personSwears[uid] = (personSwears[uid] ?? 0) + report.count;
      personReports[uid] = (personReports[uid] ?? 0) + 1;
      personAmount[uid] = (personAmount[uid] ?? 0.0) + report.totalAmount;

      int breakdownSum = 0;
      for (final entry in report.swearBreakdown.entries) {
        final rawWord = entry.key.trim();
        final c = entry.value;
        if (rawWord.isEmpty || c <= 0) continue;
        breakdownSum += c;
        final normalized = rawWord.toLowerCase();
        wordDisplayLabels.putIfAbsent(normalized, () => rawWord);
        wordCounts[normalized] = (wordCounts[normalized] ?? 0) + c;
      }

      if (report.count > breakdownSum) {
        unspecifiedWordCount += (report.count - breakdownSum);
      }
    }

    final peopleStats = personSwears.entries.map((e) {
      final uid = e.key;
      final swears = e.value;
      return SwearPersonStat(
        userId: uid,
        swearCount: swears,
        reportCount: personReports[uid] ?? 0,
        totalAmount: personAmount[uid] ?? 0.0,
        shareOfSwears: totalSwears > 0 ? (swears / totalSwears).clamp(0.0, 1.0) : 0.0,
      );
    }).toList()
      ..sort((a, b) {
        final cmp = b.swearCount.compareTo(a.swearCount);
        if (cmp != 0) return cmp;
        final amtCmp = b.totalAmount.compareTo(a.totalAmount);
        if (amtCmp != 0) return amtCmp;
        return a.userId.compareTo(b.userId);
      });

    final totalWordDenominator = wordCounts.values.fold<int>(0, (s, c) => s + c) +
        unspecifiedWordCount;

    final wordStats = wordCounts.entries.map((e) {
      final label = wordDisplayLabels[e.key] ?? e.key;
      final c = e.value;
      return SwearWordStat(
        word: label,
        count: c,
        shareOfWords: totalWordDenominator > 0
            ? (c / totalWordDenominator).clamp(0.0, 1.0)
            : 0.0,
        isUnspecified: false,
      );
    }).toList()
      ..sort((a, b) {
        final cmp = b.count.compareTo(a.count);
        if (cmp != 0) return cmp;
        return a.word.toLowerCase().compareTo(b.word.toLowerCase());
      });

    if (unspecifiedWordCount > 0) {
      wordStats.add(
        SwearWordStat(
          word: 'Unspecified / Other',
          count: unspecifiedWordCount,
          shareOfWords: totalWordDenominator > 0
              ? (unspecifiedWordCount / totalWordDenominator).clamp(0.0, 1.0)
              : 0.0,
          isUnspecified: true,
        ),
      );
    }

    return ReportAnalyticsSummary(
      totalSwears: totalSwears,
      totalReports: eligible.length,
      totalPenaltyAmount: totalPenaltyAmount,
      peopleStats: peopleStats,
      wordStats: wordStats,
    );
  }
}

