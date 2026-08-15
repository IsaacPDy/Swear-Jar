export type Role = "member" | "keeper" | "admin";
export type UserStatus = "pending" | "approved" | "rejected";
export type ReportStatus = "pending" | "confirmed" | "rejected";
export type DebtStatus = "active" | "paid" | "dismissed";

export interface User {
  uid: string;
  email: string;
  displayName: string;
  photoURL: string | null;
  gcashNumber: string | null;
  roles: Role[];
  status: UserStatus;
  createdAt: string;
  updatedAt: string;
}

export interface SystemConfig {
  activeKeeperId: string;
  currentRatePerSwear: number;
  groupName: string;
  totalSwearsAllTime: number;
  updatedAt: string;
}

export interface Report {
  id: string;
  reporterId: string;
  accusedId: string;
  count: number;
  note: string | null;
  rateApplied: number;
  totalAmount: number;
  status: ReportStatus;
  reviewedBy: string | null;
  reviewedAt: string | null;
  rejectionReason: string | null;
  createdAt: string;
}

export interface Payment {
  id: string;
  amount: number;
  recordedBy: string;
  recordedAt: string;
}

export interface Debt {
  id: string;
  reportId: string;
  debtorId: string;
  recipientId: string;
  originalAmount: number;
  remainingBalance: number;
  status: DebtStatus;
  isTransferred: boolean;
  transferredFromKeeperId: string | null;
  payments: Payment[];
  createdAt: string;
  resolvedAt: string | null;
}

export interface PersonalSummary {
  userId: string;
  totalOwed: number;
  totalSwears: number;
  totalPaid: number;
  recipient: {
    user: User | null;
    isKeeper: boolean;
    isTransferredRecipient: boolean;
  } | null;
  activeDebts: Debt[];
  transferredDebtsHeld: Debt[]; // Debts where current user is recipient because they caught the Keeper
  personalReports: Report[];
}

export interface GroupSummary {
  totalCollected: number;
  totalOutstanding: number;
  totalSwears: number;
  activeKeeper: User | null;
  activeDebtsCount: number;
  pendingReportsCount: number;
}
