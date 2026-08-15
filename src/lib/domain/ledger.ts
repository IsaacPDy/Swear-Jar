import { Debt, GroupSummary, Payment, PersonalSummary, Report, SystemConfig, User } from "./types";

/**
 * Calculates total penalty amount given count (1-99) and rate per swear.
 */
export function calculateReportAmount(count: number, ratePerSwear: number): number {
  const sanitizedCount = Math.max(1, Math.min(99, Math.floor(count || 1)));
  const sanitizedRate = Math.max(0, ratePerSwear);
  return sanitizedCount * sanitizedRate;
}

export interface ConfirmReportResult {
  updatedReport: Report;
  newDebts: Debt[];
  updatedExistingDebts: Debt[];
  summaryMessage: string;
}

/**
 * Processes confirmation of a swear report according to group rules.
 * Handles both normal member reports and the special "When the Keeper Swears" transfer rule.
 */
export function processReportConfirmation(
  report: Report,
  currentKeeperId: string,
  existingDebts: Debt[],
  reviewedBy: string,
  timestamp: string = new Date().toISOString()
): ConfirmReportResult {
  const updatedReport: Report = {
    ...report,
    status: "confirmed",
    reviewedBy,
    reviewedAt: timestamp,
    rejectionReason: null,
  };

  const isKeeperSwear = report.accusedId === currentKeeperId;
  const newDebtId = `debt_${report.id}_${Date.now()}`;

  if (!isKeeperSwear) {
    // Normal member swear: Debt is owed to the current Keeper
    const newDebt: Debt = {
      id: newDebtId,
      reportId: report.id,
      debtorId: report.accusedId,
      recipientId: currentKeeperId,
      originalAmount: report.totalAmount,
      remainingBalance: report.totalAmount,
      status: "active",
      isTransferred: false,
      transferredFromKeeperId: null,
      payments: [],
      createdAt: timestamp,
      resolvedAt: null,
    };

    return {
      updatedReport,
      newDebts: [newDebt],
      updatedExistingDebts: existingDebts,
      summaryMessage: `Report confirmed. ₱${report.totalAmount} debt created owed to the Keeper.`,
    };
  }

  // SPECIAL KEEPER SWEAR RULE:
  // 1. All active unpaid debts currently owed to the Keeper transfer to the Reporter.
  // 2. If the Reporter already owed debts to the Keeper, those debts are immediately cancelled/cleared (no self-debt).
  // 3. The newly created debt for the Keeper's swear is owed by the Keeper to the Reporter.

  const reporterId = report.reporterId;
  let cancelledCount = 0;
  let transferredCount = 0;

  const updatedExistingDebts: Debt[] = existingDebts.map((debt) => {
    // Only process active debts owed to the swearing Keeper
    if (debt.recipientId !== currentKeeperId || debt.status !== "active") {
      return debt;
    }

    // Invariant: No Self-Debt
    // If the reporter previously owed the keeper, cancel this debt immediately.
    if (debt.debtorId === reporterId) {
      cancelledCount++;
      return {
        ...debt,
        status: "dismissed",
        remainingBalance: 0,
        resolvedAt: timestamp,
        isTransferred: true,
        transferredFromKeeperId: currentKeeperId,
      };
    }

    // Otherwise, transfer the debt owed by other members from the Keeper to the Reporter
    transferredCount++;
    return {
      ...debt,
      recipientId: reporterId,
      isTransferred: true,
      transferredFromKeeperId: currentKeeperId,
    };
  });

  // Create the new debt from the Keeper's swear, owed directly to the Reporter
  const newKeeperDebt: Debt = {
    id: newDebtId,
    reportId: report.id,
    debtorId: currentKeeperId,
    recipientId: reporterId,
    originalAmount: report.totalAmount,
    remainingBalance: report.totalAmount,
    status: "active",
    isTransferred: true,
    transferredFromKeeperId: currentKeeperId,
    payments: [],
    createdAt: timestamp,
    resolvedAt: null,
  };

  const summaryMessage = `KEEPER CAUGHT SWEARING! All unpaid Keeper balances transferred to Reporter (${transferredCount} debts transferred, ${cancelledCount} reporter debts forgiven).`;

  return {
    updatedReport,
    newDebts: [newKeeperDebt],
    updatedExistingDebts,
    summaryMessage,
  };
}

/**
 * Rejects a report with an optional reason.
 */
export function processReportRejection(
  report: Report,
  reviewedBy: string,
  rejectionReason: string = "Rejected by Keeper",
  timestamp: string = new Date().toISOString()
): Report {
  return {
    ...report,
    status: "rejected",
    reviewedBy,
    reviewedAt: timestamp,
    rejectionReason,
  };
}

/**
 * Records a partial or full payment on an active debt.
 */
export function processPayment(
  debt: Debt,
  amount: number,
  recordedBy: string,
  timestamp: string = new Date().toISOString()
): Debt {
  if (debt.status !== "active") {
    throw new Error(`Cannot record payment on a ${debt.status} debt.`);
  }

  if (amount <= 0) {
    throw new Error("Payment amount must be greater than 0.");
  }

  const paymentAmount = Math.min(amount, debt.remainingBalance);
  const newBalance = Math.max(0, debt.remainingBalance - paymentAmount);
  const isFullyPaid = newBalance === 0;

  const paymentEntry: Payment = {
    id: `pay_${Date.now()}_${Math.random().toString(36).substring(2, 7)}`,
    amount: paymentAmount,
    recordedBy,
    recordedAt: timestamp,
  };

  return {
    ...debt,
    remainingBalance: newBalance,
    status: isFullyPaid ? "paid" : "active",
    resolvedAt: isFullyPaid ? timestamp : debt.resolvedAt,
    payments: [...debt.payments, paymentEntry],
  };
}

/**
 * Migrates active debts owed to the old Keeper to the newly appointed Keeper.
 * Paid and transferred debts remain untouched.
 */
export function reassignKeeper(
  newKeeperId: string,
  oldKeeperId: string,
  debts: Debt[]
): Debt[] {
  if (newKeeperId === oldKeeperId) return debts;

  return debts.map((debt) => {
    // Only migrate active debts that are owed to the old Keeper and not transferred to a reporter
    if (
      debt.recipientId === oldKeeperId &&
      debt.status === "active" &&
      !debt.isTransferred
    ) {
      return {
        ...debt,
        recipientId: newKeeperId,
      };
    }
    return debt;
  });
}

/**
 * Dismisses/forgives a transferred debt held by a reporter who caught the Keeper.
 */
export function dismissTransferredDebt(
  debt: Debt,
  reporterId: string,
  timestamp: string = new Date().toISOString()
): Debt {
  if (debt.recipientId !== reporterId || !debt.isTransferred) {
    throw new Error("Only the holder of a transferred debt can dismiss it.");
  }

  return {
    ...debt,
    status: "dismissed",
    remainingBalance: 0,
    resolvedAt: timestamp,
  };
}

/**
 * Dismisses all active transferred debts held by a specific reporter.
 */
export function dismissAllTransferredDebts(
  debts: Debt[],
  reporterId: string,
  timestamp: string = new Date().toISOString()
): Debt[] {
  return debts.map((debt) => {
    if (
      debt.recipientId === reporterId &&
      debt.isTransferred &&
      debt.status === "active"
    ) {
      return {
        ...debt,
        status: "dismissed",
        remainingBalance: 0,
        resolvedAt: timestamp,
      };
    }
    return debt;
  });
}

/**
 * Computes personal summary metrics for a given user.
 */
export function computePersonalSummary(
  userId: string,
  debts: Debt[],
  reports: Report[],
  users: User[],
  systemConfig: SystemConfig | null
): PersonalSummary {
  const activeDebts = debts.filter(
    (d) => d.debtorId === userId && d.status === "active"
  );
  
  const totalOwed = activeDebts.reduce((sum, d) => sum + d.remainingBalance, 0);

  // Total swears by this user in confirmed reports
  const confirmedReports = reports.filter(
    (r) => r.accusedId === userId && r.status === "confirmed"
  );
  const totalSwears = confirmedReports.reduce((sum, r) => sum + r.count, 0);

  // Total paid by this user across all debts
  const userDebts = debts.filter((d) => d.debtorId === userId);
  let totalPaid = 0;
  userDebts.forEach((d) => {
    d.payments.forEach((p) => {
      totalPaid += p.amount;
    });
  });

  // Find primary recipient for user's active debts
  let recipientUser: User | null = null;
  let isKeeper = false;
  let isTransferredRecipient = false;

  if (activeDebts.length > 0) {
    const primaryDebt = activeDebts[0];
    recipientUser = users.find((u) => u.uid === primaryDebt.recipientId) || null;
    isKeeper = primaryDebt.recipientId === systemConfig?.activeKeeperId;
    isTransferredRecipient = primaryDebt.isTransferred;
  } else if (systemConfig?.activeKeeperId) {
    recipientUser = users.find((u) => u.uid === systemConfig.activeKeeperId) || null;
    isKeeper = true;
  }

  // Transferred debts where current user is the recipient (because they caught the Keeper)
  const transferredDebtsHeld = debts.filter(
    (d) => d.recipientId === userId && d.isTransferred && d.status === "active"
  );

  const personalReports = reports.filter(
    (r) => r.accusedId === userId || r.reporterId === userId
  );

  return {
    userId,
    totalOwed,
    totalSwears,
    totalPaid,
    recipient: recipientUser
      ? {
          user: recipientUser,
          isKeeper,
          isTransferredRecipient,
        }
      : null,
    activeDebts,
    transferredDebtsHeld,
    personalReports,
  };
}

/**
 * Computes group-wide summary metrics.
 */
export function computeGroupSummary(
  debts: Debt[],
  reports: Report[],
  users: User[],
  systemConfig: SystemConfig | null
): GroupSummary {
  const activeDebts = debts.filter((d) => d.status === "active");
  const totalOutstanding = activeDebts.reduce(
    (sum, d) => sum + d.remainingBalance,
    0
  );

  let totalCollected = 0;
  debts.forEach((d) => {
    d.payments.forEach((p) => {
      totalCollected += p.amount;
    });
  });

  const confirmedReports = reports.filter((r) => r.status === "confirmed");
  const totalSwears = confirmedReports.reduce((sum, r) => sum + r.count, 0);

  const pendingReports = reports.filter((r) => r.status === "pending");

  const activeKeeper =
    users.find((u) => u.uid === systemConfig?.activeKeeperId) || null;

  return {
    totalCollected,
    totalOutstanding,
    totalSwears,
    activeKeeper,
    activeDebtsCount: activeDebts.length,
    pendingReportsCount: pendingReports.length,
  };
}
