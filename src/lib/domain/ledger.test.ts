import { describe, expect, it } from "vitest";
import {
  calculateReportAmount,
  computeGroupSummary,
  computePersonalSummary,
  dismissAllTransferredDebts,
  dismissTransferredDebt,
  processPayment,
  processReportConfirmation,
  processReportRejection,
  reassignKeeper,
} from "./ledger";
import { Debt, Report, SystemConfig, User } from "./types";

describe("Swear Jar Domain Ledger Engine", () => {
  const keeperId = "user_sarah_keeper";
  const reporterId = "user_alex_reporter";
  const friendId = "user_jordan_friend";

  const mockUsers: User[] = [
    {
      uid: keeperId,
      email: "sarah@example.com",
      displayName: "Sarah (Keeper)",
      photoURL: null,
      gcashNumber: "09171234567",
      roles: ["member", "keeper", "admin"],
      status: "approved",
      createdAt: "2026-08-01T00:00:00Z",
      updatedAt: "2026-08-01T00:00:00Z",
    },
    {
      uid: reporterId,
      email: "alex@example.com",
      displayName: "Alex",
      photoURL: null,
      gcashNumber: "09189876543",
      roles: ["member"],
      status: "approved",
      createdAt: "2026-08-01T00:00:00Z",
      updatedAt: "2026-08-01T00:00:00Z",
    },
    {
      uid: friendId,
      email: "jordan@example.com",
      displayName: "Jordan",
      photoURL: null,
      gcashNumber: null,
      roles: ["member"],
      status: "approved",
      createdAt: "2026-08-01T00:00:00Z",
      updatedAt: "2026-08-01T00:00:00Z",
    },
  ];

  const mockConfig: SystemConfig = {
    activeKeeperId: keeperId,
    currentRatePerSwear: 50,
    groupName: "The Squad",
    totalSwearsAllTime: 12,
    updatedAt: "2026-08-01T00:00:00Z",
  };

  describe("calculateReportAmount", () => {
    it("calculates basic count * rate", () => {
      expect(calculateReportAmount(1, 50)).toBe(50);
      expect(calculateReportAmount(3, 50)).toBe(150);
      expect(calculateReportAmount(2, 75)).toBe(150);
    });

    it("clamps swear count between 1 and 99 and floors fractional counts", () => {
      expect(calculateReportAmount(0, 50)).toBe(50);
      expect(calculateReportAmount(-5, 50)).toBe(50);
      expect(calculateReportAmount(150, 50)).toBe(4950); // 99 * 50
      expect(calculateReportAmount(3.7, 50)).toBe(150); // 3 * 50
    });
  });

  describe("processReportConfirmation - Normal Member Swear", () => {
    const normalReport: Report = {
      id: "rep_101",
      reporterId,
      accusedId: friendId,
      count: 2,
      note: "Dropped phone in soup",
      rateApplied: 50,
      totalAmount: 100,
      status: "pending",
      reviewedBy: null,
      reviewedAt: null,
      rejectionReason: null,
      createdAt: "2026-08-15T10:00:00Z",
    };

    it("creates an active debt owed to the current Keeper", () => {
      const result = processReportConfirmation(
        normalReport,
        keeperId,
        [],
        keeperId
      );

      expect(result.updatedReport.status).toBe("confirmed");
      expect(result.updatedReport.reviewedBy).toBe(keeperId);
      expect(result.newDebts).toHaveLength(1);

      const debt = result.newDebts[0];
      expect(debt.debtorId).toBe(friendId);
      expect(debt.recipientId).toBe(keeperId);
      expect(debt.originalAmount).toBe(100);
      expect(debt.remainingBalance).toBe(100);
      expect(debt.status).toBe("active");
      expect(debt.isTransferred).toBe(false);
      expect(debt.transferredFromKeeperId).toBeNull();
    });
  });

  describe("processReportConfirmation - Special 'When Keeper Swears' Transfer Rule", () => {
    const keeperSwearReport: Report = {
      id: "rep_201",
      reporterId, // Alex caught the Keeper!
      accusedId: keeperId, // Sarah (Keeper) swore
      count: 1,
      note: "Spilled tea during presentation",
      rateApplied: 50,
      totalAmount: 50,
      status: "pending",
      reviewedBy: null,
      reviewedAt: null,
      rejectionReason: null,
      createdAt: "2026-08-15T11:00:00Z",
    };

    it("transfers active unpaid Keeper debts to Reporter and cancels Reporter debt owed to Keeper", () => {
      const existingDebts: Debt[] = [
        // Debt 1: Jordan owes Keeper ₱100 (active) -> should transfer to Alex
        {
          id: "debt_jordan_to_keeper",
          reportId: "rep_01",
          debtorId: friendId,
          recipientId: keeperId,
          originalAmount: 100,
          remainingBalance: 100,
          status: "active",
          isTransferred: false,
          transferredFromKeeperId: null,
          payments: [],
          createdAt: "2026-08-10T00:00:00Z",
          resolvedAt: null,
        },
        // Debt 2: Alex (Reporter) owes Keeper ₱50 (active) -> should be CANCELLED (no self-debt)
        {
          id: "debt_alex_to_keeper",
          reportId: "rep_02",
          debtorId: reporterId,
          recipientId: keeperId,
          originalAmount: 50,
          remainingBalance: 50,
          status: "active",
          isTransferred: false,
          transferredFromKeeperId: null,
          payments: [],
          createdAt: "2026-08-11T00:00:00Z",
          resolvedAt: null,
        },
        // Debt 3: Jordan already paid Keeper ₱50 (paid) -> should stay paid & untouched
        {
          id: "debt_jordan_paid",
          reportId: "rep_03",
          debtorId: friendId,
          recipientId: keeperId,
          originalAmount: 50,
          remainingBalance: 0,
          status: "paid",
          isTransferred: false,
          transferredFromKeeperId: null,
          payments: [{ id: "p1", amount: 50, recordedBy: keeperId, recordedAt: "2026-08-12T00:00:00Z" }],
          createdAt: "2026-08-12T00:00:00Z",
          resolvedAt: "2026-08-12T00:00:00Z",
        },
      ];

      const result = processReportConfirmation(
        keeperSwearReport,
        keeperId,
        existingDebts,
        keeperId
      );

      // Verify updated existing debts
      const updatedJordanDebt = result.updatedExistingDebts.find(
        (d) => d.id === "debt_jordan_to_keeper"
      );
      expect(updatedJordanDebt?.recipientId).toBe(reporterId);
      expect(updatedJordanDebt?.isTransferred).toBe(true);
      expect(updatedJordanDebt?.transferredFromKeeperId).toBe(keeperId);
      expect(updatedJordanDebt?.status).toBe("active");

      // Verify reporter's previous debt is cancelled
      const updatedAlexDebt = result.updatedExistingDebts.find(
        (d) => d.id === "debt_alex_to_keeper"
      );
      expect(updatedAlexDebt?.status).toBe("dismissed");
      expect(updatedAlexDebt?.remainingBalance).toBe(0);
      expect(updatedAlexDebt?.isTransferred).toBe(true);

      // Verify paid debt is untouched
      const updatedPaidDebt = result.updatedExistingDebts.find(
        (d) => d.id === "debt_jordan_paid"
      );
      expect(updatedPaidDebt?.recipientId).toBe(keeperId);
      expect(updatedPaidDebt?.status).toBe("paid");

      // Verify new debt created for Keeper's swear owed to Reporter
      expect(result.newDebts).toHaveLength(1);
      const newKeeperDebt = result.newDebts[0];
      expect(newKeeperDebt.debtorId).toBe(keeperId);
      expect(newKeeperDebt.recipientId).toBe(reporterId);
      expect(newKeeperDebt.originalAmount).toBe(50);
      expect(newKeeperDebt.remainingBalance).toBe(50);
      expect(newKeeperDebt.isTransferred).toBe(true);
      expect(newKeeperDebt.transferredFromKeeperId).toBe(keeperId);
    });
  });

  describe("processReportRejection", () => {
    it("updates report status to rejected with rejection reason", () => {
      const report: Report = {
        id: "rep_301",
        reporterId,
        accusedId: friendId,
        count: 1,
        note: "False alarm",
        rateApplied: 50,
        totalAmount: 50,
        status: "pending",
        reviewedBy: null,
        reviewedAt: null,
        rejectionReason: null,
        createdAt: "2026-08-15T10:00:00Z",
      };

      const rejected = processReportRejection(
        report,
        keeperId,
        "We agreed this was not a swear"
      );
      expect(rejected.status).toBe("rejected");
      expect(rejected.reviewedBy).toBe(keeperId);
      expect(rejected.rejectionReason).toBe("We agreed this was not a swear");
    });
  });

  describe("processPayment", () => {
    const activeDebt: Debt = {
      id: "debt_pay_test",
      reportId: "rep_10",
      debtorId: friendId,
      recipientId: keeperId,
      originalAmount: 100,
      remainingBalance: 100,
      status: "active",
      isTransferred: false,
      transferredFromKeeperId: null,
      payments: [],
      createdAt: "2026-08-15T00:00:00Z",
      resolvedAt: null,
    };

    it("processes partial payment and decrements remainingBalance", () => {
      const afterPartial = processPayment(activeDebt, 40, keeperId);
      expect(afterPartial.remainingBalance).toBe(60);
      expect(afterPartial.status).toBe("active");
      expect(afterPartial.resolvedAt).toBeNull();
      expect(afterPartial.payments).toHaveLength(1);
      expect(afterPartial.payments[0].amount).toBe(40);
      expect(afterPartial.payments[0].recordedBy).toBe(keeperId);

      // Process second partial payment that clears the debt
      const afterFull = processPayment(afterPartial, 60, keeperId);
      expect(afterFull.remainingBalance).toBe(0);
      expect(afterFull.status).toBe("paid");
      expect(afterFull.resolvedAt).not.toBeNull();
      expect(afterFull.payments).toHaveLength(2);
    });

    it("caps payment at remaining balance when overpaid", () => {
      const afterOverpay = processPayment(activeDebt, 150, keeperId);
      expect(afterOverpay.remainingBalance).toBe(0);
      expect(afterOverpay.status).toBe("paid");
      expect(afterOverpay.payments[0].amount).toBe(100);
    });

    it("throws error when recording payment on non-active debt or amount <= 0", () => {
      const paidDebt: Debt = { ...activeDebt, status: "paid", remainingBalance: 0 };
      expect(() => processPayment(paidDebt, 50, keeperId)).toThrow();
      expect(() => processPayment(activeDebt, 0, keeperId)).toThrow();
      expect(() => processPayment(activeDebt, -10, keeperId)).toThrow();
    });
  });

  describe("reassignKeeper", () => {
    it("migrates only active non-transferred debts to new Keeper", () => {
      const debts: Debt[] = [
        {
          id: "d1",
          reportId: "r1",
          debtorId: friendId,
          recipientId: keeperId,
          originalAmount: 50,
          remainingBalance: 50,
          status: "active",
          isTransferred: false,
          transferredFromKeeperId: null,
          payments: [],
          createdAt: "2026-08-01T00:00:00Z",
          resolvedAt: null,
        },
        {
          id: "d2_transferred",
          reportId: "r2",
          debtorId: keeperId,
          recipientId: reporterId,
          originalAmount: 50,
          remainingBalance: 50,
          status: "active",
          isTransferred: true,
          transferredFromKeeperId: keeperId,
          payments: [],
          createdAt: "2026-08-02T00:00:00Z",
          resolvedAt: null,
        },
        {
          id: "d3_paid",
          reportId: "r3",
          debtorId: friendId,
          recipientId: keeperId,
          originalAmount: 50,
          remainingBalance: 0,
          status: "paid",
          isTransferred: false,
          transferredFromKeeperId: null,
          payments: [{ id: "p", amount: 50, recordedBy: keeperId, recordedAt: "2026-08-03T00:00:00Z" }],
          createdAt: "2026-08-03T00:00:00Z",
          resolvedAt: "2026-08-03T00:00:00Z",
        },
      ];

      const newKeeperId = friendId;
      const migrated = reassignKeeper(newKeeperId, keeperId, debts);

      expect(migrated[0].recipientId).toBe(newKeeperId);
      expect(migrated[1].recipientId).toBe(reporterId); // Transferred debt stays with reporter
      expect(migrated[2].recipientId).toBe(keeperId); // Paid debt stays with old recipient
    });
  });

  describe("dismissTransferredDebt & dismissAllTransferredDebts", () => {
    const transferredDebt: Debt = {
      id: "d_trans",
      reportId: "r_t",
      debtorId: friendId,
      recipientId: reporterId,
      originalAmount: 100,
      remainingBalance: 100,
      status: "active",
      isTransferred: true,
      transferredFromKeeperId: keeperId,
      payments: [],
      createdAt: "2026-08-10T00:00:00Z",
      resolvedAt: null,
    };

    it("allows reporter to dismiss individual transferred debt", () => {
      const dismissed = dismissTransferredDebt(transferredDebt, reporterId);
      expect(dismissed.status).toBe("dismissed");
      expect(dismissed.remainingBalance).toBe(0);
      expect(dismissed.resolvedAt).not.toBeNull();
    });

    it("prevents non-holder from dismissing transferred debt", () => {
      expect(() => dismissTransferredDebt(transferredDebt, "wrong_user")).toThrow();
    });

    it("dismisses all active transferred debts for a reporter", () => {
      const debts = [transferredDebt];
      const dismissedList = dismissAllTransferredDebts(debts, reporterId);
      expect(dismissedList[0].status).toBe("dismissed");
      expect(dismissedList[0].remainingBalance).toBe(0);
    });
  });

  describe("computePersonalSummary & computeGroupSummary", () => {
    const debts: Debt[] = [
      {
        id: "d_1",
        reportId: "r_1",
        debtorId: reporterId,
        recipientId: keeperId,
        originalAmount: 100,
        remainingBalance: 50,
        status: "active",
        isTransferred: false,
        transferredFromKeeperId: null,
        payments: [{ id: "p1", amount: 50, recordedBy: keeperId, recordedAt: "2026-08-10T00:00:00Z" }],
        createdAt: "2026-08-10T00:00:00Z",
        resolvedAt: null,
      },
    ];

    const reports: Report[] = [
      {
        id: "r_1",
        reporterId: friendId,
        accusedId: reporterId,
        count: 2,
        note: null,
        rateApplied: 50,
        totalAmount: 100,
        status: "confirmed",
        reviewedBy: keeperId,
        reviewedAt: "2026-08-10T00:00:00Z",
        rejectionReason: null,
        createdAt: "2026-08-10T00:00:00Z",
      },
    ];

    it("computes personal summary correctly", () => {
      const summary = computePersonalSummary(
        reporterId,
        debts,
        reports,
        mockUsers,
        mockConfig
      );

      expect(summary.totalOwed).toBe(50);
      expect(summary.totalPaid).toBe(50);
      expect(summary.totalSwears).toBe(2);
      expect(summary.recipient?.user?.uid).toBe(keeperId);
      expect(summary.recipient?.isKeeper).toBe(true);
    });

    it("computes group summary correctly", () => {
      const groupSummary = computeGroupSummary(
        debts,
        reports,
        mockUsers,
        mockConfig
      );

      expect(groupSummary.totalOutstanding).toBe(50);
      expect(groupSummary.totalCollected).toBe(50);
      expect(groupSummary.totalSwears).toBe(2);
      expect(groupSummary.activeDebtsCount).toBe(1);
    });
  });
});
