"use client";

import React, { useState } from "react";
import { useApp } from "../../context/AppContext";
import { NeonCard } from "../ui/NeonCard";
import { CurrencyDisplay } from "../ui/CurrencyDisplay";
import { GCashBadge } from "../ui/GCashBadge";
import { StatusPill } from "../ui/StatusPill";
import { Avatar } from "../ui/Avatar";
import { NeonButton } from "../ui/NeonButton";
import { ConfirmModal } from "../ui/ConfirmModal";
import { Debt } from "../../lib/domain/types";
import { formatDate } from "../../lib/utils/formatters";
import {
  Landmark,
  ShieldAlert,
  CreditCard,
  HeartHandshake,
  CheckCircle2,
  History,
  Crown,
} from "lucide-react";
import clsx from "clsx";

export const JarView: React.FC = () => {
  const {
    debts,
    users,
    currentUser,
    systemConfig,
    groupSummary,
    isKeeper,
    isAdmin,
    recordPayment,
    dismissTransferredDebt,
    dismissAllTransferredDebts,
  } = useApp();

  const [activeTab, setActiveTab] = useState<"active" | "transferred" | "settled">("active");

  // Payment Modal state
  const [payModalDebt, setPayModalDebt] = useState<Debt | null>(null);
  const [payAmount, setPayAmount] = useState<number>(0);
  const [isSubmitting, setIsSubmitting] = useState(false);

  // Dismiss Modal state
  const [dismissModalDebt, setDismissModalDebt] = useState<Debt | null>(null);
  const [dismissAllModal, setDismissAllModal] = useState(false);

  const activeKeeper = groupSummary.activeKeeper;

  // Filtered Debt buckets
  const activeKeeperDebts = debts.filter(
    (d) => d.status === "active" && !d.isTransferred && d.recipientId === systemConfig?.activeKeeperId
  );

  const transferredDebts = debts.filter(
    (d) => d.status === "active" && d.isTransferred
  );

  // Transferred debts specifically held by currentUser
  const myTransferredDebts = debts.filter(
    (d) => d.status === "active" && d.isTransferred && d.recipientId === currentUser?.uid
  );

  const settledDebts = debts.filter(
    (d) => d.status === "paid" || d.status === "dismissed"
  );

  const openPaymentModal = (debt: Debt) => {
    setPayModalDebt(debt);
    setPayAmount(debt.remainingBalance);
  };

  const handleRecordPayment = async () => {
    if (!payModalDebt || payAmount <= 0) return;
    setIsSubmitting(true);
    await recordPayment(payModalDebt.id, payAmount);
    setIsSubmitting(false);
    setPayModalDebt(null);
  };

  const handleDismissDebt = async () => {
    if (!dismissModalDebt) return;
    setIsSubmitting(true);
    await dismissTransferredDebt(dismissModalDebt.id);
    setIsSubmitting(false);
    setDismissModalDebt(null);
  };

  const handleDismissAll = async () => {
    setIsSubmitting(true);
    await dismissAllTransferredDebts();
    setIsSubmitting(false);
    setDismissAllModal(false);
  };

  return (
    <div className="space-y-4">
      {/* Header & Group Pot Summary */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-xl font-bold font-display text-white">Group Jar Ledger</h1>
          <p className="text-xs text-slate-400">
            Collective squad debt obligations and resolution tracking
          </p>
        </div>
      </div>

      {/* Aggregate Group Pot Card */}
      <NeonCard glow="mint" className="p-5 space-y-4 relative overflow-hidden">
        <div className="absolute top-0 right-0 w-32 h-32 bg-neon-mint/10 rounded-full blur-3xl pointer-events-none" />

        <div className="grid grid-cols-2 gap-4">
          <div>
            <span className="text-[11px] font-bold text-slate-400 uppercase tracking-wider block">
              Total Outstanding
            </span>
            <div className="mt-1">
              <CurrencyDisplay amount={groupSummary.totalOutstanding} size="xl" glow />
            </div>
            <p className="text-[10px] text-slate-400 mt-0.5">
              {activeKeeperDebts.length + transferredDebts.length} active obligations
            </p>
          </div>

          <div>
            <span className="text-[11px] font-bold text-slate-400 uppercase tracking-wider block">
              Total Collected
            </span>
            <div className="mt-1">
              <CurrencyDisplay amount={groupSummary.totalCollected} size="xl" />
            </div>
            <p className="text-[10px] text-emerald-400 font-medium mt-0.5 flex items-center gap-1">
              <CheckCircle2 className="w-3 h-3" /> Settled squad funds
            </p>
          </div>
        </div>

        {/* Active Keeper Pill */}
        {activeKeeper && (
          <div className="pt-3 border-t border-white/10 flex items-center justify-between">
            <div className="flex items-center gap-2">
              <Avatar user={activeKeeper} size="sm" />
              <div>
                <p className="text-xs font-bold text-white flex items-center gap-1">
                  <span>{activeKeeper.displayName}</span>
                  <Crown className="w-3 h-3 text-amber-400" />
                </p>
                <p className="text-[10px] text-slate-400">Designated Keeper</p>
              </div>
            </div>

            {activeKeeper.gcashNumber && (
              <GCashBadge number={activeKeeper.gcashNumber} />
            )}
          </div>
        )}
      </NeonCard>

      {/* Segmented Tabs */}
      <div className="flex p-1 bg-midnight-elevated/80 border border-white/10 rounded-xl">
        <button
          onClick={() => setActiveTab("active")}
          className={clsx(
            "flex-1 py-2 text-xs font-bold rounded-lg transition-all flex items-center justify-center gap-1.5",
            activeTab === "active"
              ? "bg-neon-magenta text-white shadow-neon-magenta"
              : "text-slate-400 hover:text-slate-200"
          )}
        >
          <Landmark className="w-3.5 h-3.5" />
          <span>Active Debts ({activeKeeperDebts.length})</span>
        </button>

        <button
          onClick={() => setActiveTab("transferred")}
          className={clsx(
            "flex-1 py-2 text-xs font-bold rounded-lg transition-all flex items-center justify-center gap-1.5",
            activeTab === "transferred"
              ? "bg-neon-amber text-slate-950 font-black shadow-neon-amber"
              : "text-slate-400 hover:text-slate-200"
          )}
        >
          <ShieldAlert className="w-3.5 h-3.5" />
          <span>Transferred ({transferredDebts.length})</span>
        </button>

        <button
          onClick={() => setActiveTab("settled")}
          className={clsx(
            "flex-1 py-2 text-xs font-bold rounded-lg transition-all flex items-center justify-center gap-1.5",
            activeTab === "settled"
              ? "bg-neon-mint text-slate-950 font-black shadow-neon-mint"
              : "text-slate-400 hover:text-slate-200"
          )}
        >
          <History className="w-3.5 h-3.5" />
          <span>Settled ({settledDebts.length})</span>
        </button>
      </div>

      {/* 1. Active Keeper Debts View */}
      {activeTab === "active" && (
        <div className="space-y-3">
          {activeKeeperDebts.length === 0 ? (
            <NeonCard className="p-8 text-center text-xs text-slate-400">
              No active debts owed to the Keeper. The squad is completely paid up! 🎉
            </NeonCard>
          ) : (
            activeKeeperDebts.map((debt) => {
              const debtor = users.find((u) => u.uid === debt.debtorId);
              const isDebtorCurrent = debt.debtorId === currentUser?.uid;
              const canCollect = isKeeper || isAdmin;

              return (
                <NeonCard key={debt.id} className="p-4 space-y-3">
                  <div className="flex items-start justify-between gap-3">
                    <div className="flex items-center gap-3">
                      <Avatar user={debtor} size="md" />
                      <div>
                        <h4 className="text-sm font-bold text-white flex items-center gap-1.5">
                          <span>{debtor?.displayName || "Member"}</span>
                          {isDebtorCurrent && (
                            <span className="text-[10px] bg-neon-magenta/20 text-pink-300 px-1.5 py-0.5 rounded font-bold">
                              You
                            </span>
                          )}
                        </h4>
                        <p className="text-[11px] text-slate-400">
                          Owes Keeper • {formatDate(debt.createdAt)}
                        </p>
                      </div>
                    </div>

                    <div className="text-right">
                      <CurrencyDisplay amount={debt.remainingBalance} size="md" />
                      {debt.remainingBalance < debt.originalAmount && (
                        <p className="text-[10px] text-slate-400 font-mono">
                          orig. ₱{debt.originalAmount}
                        </p>
                      )}
                    </div>
                  </div>

                  {/* Payment Progress Bar (if partial payments exist) */}
                  {debt.payments.length > 0 && (
                    <div className="space-y-1">
                      <div className="flex justify-between text-[10px] text-slate-400">
                        <span>Paid: ₱{debt.originalAmount - debt.remainingBalance}</span>
                        <span>{Math.round(((debt.originalAmount - debt.remainingBalance) / debt.originalAmount) * 100)}%</span>
                      </div>
                      <div className="w-full h-1.5 bg-midnight-base rounded-full overflow-hidden">
                        <div
                          className="h-full bg-neon-mint transition-all"
                          style={{
                            width: `${((debt.originalAmount - debt.remainingBalance) / debt.originalAmount) * 100}%`,
                          }}
                        />
                      </div>
                    </div>
                  )}

                  {/* Action: Keeper / Admin Record Payment */}
                  {canCollect && (
                    <div className="pt-2 border-t border-white/10 flex justify-end">
                      <NeonButton
                        variant="success"
                        size="sm"
                        leftIcon={<CreditCard className="w-3.5 h-3.5" />}
                        onClick={() => openPaymentModal(debt)}
                      >
                        Record Payment
                      </NeonButton>
                    </div>
                  )}
                </NeonCard>
              );
            })
          )}
        </div>
      )}

      {/* 2. Transferred Debts View */}
      {activeTab === "transferred" && (
        <div className="space-y-3">
          {/* Header Action: Dismiss All if user holds transferred debts */}
          {myTransferredDebts.length > 0 && (
            <NeonCard glow="amber" className="p-4 bg-amber-950/20 border-neon-amber/40 space-y-2">
              <div className="flex items-start justify-between gap-2">
                <div>
                  <h4 className="text-xs font-bold text-amber-200">
                    You caught the Keeper swearing! 🎯
                  </h4>
                  <p className="text-[11px] text-amber-300/80">
                    You hold {myTransferredDebts.length} transferred obligation(s). You may collect or forgive them.
                  </p>
                </div>
                <NeonButton
                  variant="outline"
                  size="sm"
                  leftIcon={<HeartHandshake className="w-3.5 h-3.5" />}
                  onClick={() => setDismissAllModal(true)}
                  className="text-amber-300 border-amber-500/40 hover:bg-amber-950"
                >
                  Forgive All
                </NeonButton>
              </div>
            </NeonCard>
          )}

          {transferredDebts.length === 0 ? (
            <NeonCard className="p-8 text-center text-xs text-slate-400">
              No transferred debts currently active. The Keeper has not been caught recently!
            </NeonCard>
          ) : (
            transferredDebts.map((debt) => {
              const debtor = users.find((u) => u.uid === debt.debtorId);
              const recipient = users.find((u) => u.uid === debt.recipientId);
              const isCurrentUserRecipient = debt.recipientId === currentUser?.uid;

              return (
                <NeonCard
                  key={debt.id}
                  glow={isCurrentUserRecipient ? "amber" : "none"}
                  className="p-4 space-y-3 border-amber-500/20"
                >
                  <div className="flex items-start justify-between gap-3">
                    <div className="flex items-center gap-3">
                      <Avatar user={debtor} size="md" />
                      <div>
                        <h4 className="text-sm font-bold text-white">
                          {debtor?.displayName || "Member"}
                        </h4>
                        <p className="text-[11px] text-amber-300 font-medium">
                          Owed to: <span className="font-bold">{recipient?.displayName}</span>
                        </p>
                      </div>
                    </div>

                    <div className="text-right">
                      <CurrencyDisplay amount={debt.remainingBalance} size="md" />
                      <StatusPill status="transferred" />
                    </div>
                  </div>

                  {recipient?.gcashNumber && (
                    <div className="flex items-center justify-between text-xs pt-1">
                      <span className="text-slate-400">Pay to recipient:</span>
                      <GCashBadge number={recipient.gcashNumber} />
                    </div>
                  )}

                  {/* Actions for the Holder of the Transferred Debt */}
                  {isCurrentUserRecipient && (
                    <div className="pt-2 border-t border-white/10 flex items-center justify-end gap-2">
                      <NeonButton
                        variant="ghost"
                        size="sm"
                        leftIcon={<HeartHandshake className="w-3.5 h-3.5" />}
                        onClick={() => setDismissModalDebt(debt)}
                        className="text-amber-300 hover:bg-amber-950/40"
                      >
                        Forgive Debt
                      </NeonButton>
                      <NeonButton
                        variant="success"
                        size="sm"
                        leftIcon={<CreditCard className="w-3.5 h-3.5" />}
                        onClick={() => openPaymentModal(debt)}
                      >
                        Record Payment
                      </NeonButton>
                    </div>
                  )}
                </NeonCard>
              );
            })
          )}
        </div>
      )}

      {/* 3. Settled Debts View */}
      {activeTab === "settled" && (
        <div className="space-y-2">
          {settledDebts.length === 0 ? (
            <NeonCard className="p-8 text-center text-xs text-slate-400">
              No settled debts in history yet.
            </NeonCard>
          ) : (
            settledDebts.map((debt) => {
              const debtor = users.find((u) => u.uid === debt.debtorId);
              const isPaid = debt.status === "paid";

              return (
                <NeonCard key={debt.id} className="p-3 flex items-center justify-between gap-3 opacity-80">
                  <div className="flex items-center gap-3">
                    <Avatar user={debtor} size="sm" />
                    <div>
                      <p className="text-xs font-bold text-white">
                        {debtor?.displayName}
                      </p>
                      <p className="text-[10px] text-slate-400">
                        {isPaid ? "Settled in full" : "Forgiven / Cancelled"} • {formatDate(debt.resolvedAt || debt.createdAt)}
                      </p>
                    </div>
                  </div>

                  <div className="text-right flex flex-col items-end gap-1">
                    <CurrencyDisplay amount={debt.originalAmount} size="sm" />
                    <StatusPill status={debt.status} />
                  </div>
                </NeonCard>
              );
            })
          )}
        </div>
      )}

      {/* Payment Recording Modal */}
      {payModalDebt && (
        <ConfirmModal
          isOpen={Boolean(payModalDebt)}
          onClose={() => setPayModalDebt(null)}
          onConfirm={handleRecordPayment}
          isLoading={isSubmitting}
          title="Record Payment"
          confirmLabel={`Record ₱${payAmount} Payment`}
          confirmVariant="success"
          type="info"
          description={
            <div className="space-y-4">
              <p className="text-xs text-slate-300">
                Record a partial or full payment received from{" "}
                <strong className="text-white">
                  {users.find((u) => u.uid === payModalDebt.debtorId)?.displayName}
                </strong>
                .
              </p>

              <div>
                <label className="block text-xs font-bold text-slate-300 mb-1">
                  Payment Amount (₱):
                </label>
                <div className="flex items-center gap-2">
                  <input
                    type="number"
                    min="1"
                    max={payModalDebt.remainingBalance}
                    value={payAmount}
                    onChange={(e) => {
                      const val = parseFloat(e.target.value);
                      if (!isNaN(val)) {
                        setPayAmount(Math.min(payModalDebt.remainingBalance, Math.max(1, val)));
                      }
                    }}
                    className="flex-1 bg-midnight-base border border-white/15 rounded-xl px-3 py-2 text-sm text-white font-mono font-bold focus:outline-none focus:border-neon-mint"
                  />
                  <NeonButton
                    type="button"
                    variant="outline"
                    size="sm"
                    onClick={() => setPayAmount(payModalDebt.remainingBalance)}
                  >
                    Full ₱{payModalDebt.remainingBalance}
                  </NeonButton>
                </div>
                <p className="text-[11px] text-slate-400 mt-1">
                  Remaining after payment: ₱{Math.max(0, payModalDebt.remainingBalance - payAmount)}
                </p>
              </div>
            </div>
          }
        />
      )}

      {/* Dismiss Transferred Debt Modal */}
      {dismissModalDebt && (
        <ConfirmModal
          isOpen={Boolean(dismissModalDebt)}
          onClose={() => setDismissModalDebt(null)}
          onConfirm={handleDismissDebt}
          isLoading={isSubmitting}
          title="Forgive Transferred Debt"
          confirmLabel="Yes, Forgive Debt"
          confirmVariant="destructive"
          type="warning"
          description={
            <p className="text-xs text-slate-300">
              Are you sure you want to forgive the remaining{" "}
              <strong className="text-white">
                ₱{dismissModalDebt.remainingBalance}
              </strong>{" "}
              owed by{" "}
              <strong className="text-white">
                {users.find((u) => u.uid === dismissModalDebt.debtorId)?.displayName}
              </strong>
              ? This action is permanent and clears the balance.
            </p>
          }
        />
      )}

      {/* Dismiss ALL Transferred Debts Modal */}
      {dismissAllModal && (
        <ConfirmModal
          isOpen={dismissAllModal}
          onClose={() => setDismissAllModal(false)}
          onConfirm={handleDismissAll}
          isLoading={isSubmitting}
          title="Forgive ALL Transferred Debts"
          confirmLabel="Forgive All Debts"
          confirmVariant="destructive"
          type="warning"
          description={
            <p className="text-xs text-slate-300">
              You are about to forgive all {myTransferredDebts.length} transferred debts currently owed to you. Everyone&apos;s transferred balance with you will be reset to ₱0.
            </p>
          }
        />
      )}
    </div>
  );
};
