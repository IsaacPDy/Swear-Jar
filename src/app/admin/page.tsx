"use client";

import React, { useState } from "react";
import Link from "next/link";
import { useApp } from "../../context/AppContext";
import { NeonCard } from "../../components/ui/NeonCard";
import { Avatar } from "../../components/ui/Avatar";
import { NeonButton } from "../../components/ui/NeonButton";
import { ConfirmModal } from "../../components/ui/ConfirmModal";
import {
  Shield,
  Crown,
  Users,
  Check,
  X,
  ArrowLeft,
  DollarSign,
  Zap,
  Info,
  ShieldCheck,
} from "lucide-react";
import { User } from "../../lib/domain/types";
import clsx from "clsx";

export default function AdminPage() {
  const {
    currentUser,
    users,
    systemConfig,
    isAdmin,
    approveUser,
    rejectUser,
    appointKeeper,
    updatePenaltyRate,
    toggleUserAdmin,
  } = useApp();

  const [rateInput, setRateInput] = useState<number>(systemConfig?.currentRatePerSwear || 50);
  const [isUpdatingRate, setIsUpdatingRate] = useState(false);

  // Modal states for Keeper reassignment
  const [selectedNewKeeper, setSelectedNewKeeper] = useState<User | null>(null);
  const [isAppointing, setIsAppointing] = useState(false);

  if (!isAdmin) {
    return (
      <div className="space-y-4 text-center py-12">
        <div className="w-14 h-14 mx-auto rounded-2xl bg-neon-crimson/20 border border-neon-crimson/30 text-red-400 flex items-center justify-center">
          <Shield className="w-7 h-7" />
        </div>
        <h1 className="text-xl font-bold font-display text-white">Admin Access Required</h1>
        <p className="text-xs text-slate-400 max-w-xs mx-auto">
          You must have the Admin role to access the Swear Jar group administrative console.
        </p>
        <Link href="/">
          <NeonButton variant="secondary" size="sm">
            Return to Home
          </NeonButton>
        </Link>
      </div>
    );
  }

  const pendingUsers = users.filter((u) => u.status === "pending");
  const approvedUsers = users.filter((u) => u.status === "approved");
  const currentKeeper = users.find((u) => u.uid === systemConfig?.activeKeeperId);

  const handleRateSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (rateInput <= 0) return;
    setIsUpdatingRate(true);
    await updatePenaltyRate(rateInput);
    setIsUpdatingRate(false);
  };

  const handleConfirmKeeperHandoff = async () => {
    if (!selectedNewKeeper) return;
    setIsAppointing(true);
    await appointKeeper(selectedNewKeeper.uid);
    setIsAppointing(false);
    setSelectedNewKeeper(null);
  };

  return (
    <div className="space-y-5">
      {/* Top Header */}
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-2">
          <Link
            href="/profile"
            className="p-2 rounded-xl bg-midnight-surface border border-white/10 text-slate-400 hover:text-white transition-colors"
          >
            <ArrowLeft className="w-4 h-4" />
          </Link>
          <div>
            <h1 className="text-xl font-bold font-display text-white flex items-center gap-2">
              <span>Admin Console</span>
              <ShieldCheck className="w-4 h-4 text-neon-magenta" />
            </h1>
            <p className="text-xs text-slate-400">
              Manage group members, designated Keeper, and penalty consequences
            </p>
          </div>
        </div>
      </div>

      {/* 1. Pending Approvals Queue */}
      <NeonCard
        glow={pendingUsers.length > 0 ? "amber" : "none"}
        className="p-4 space-y-3"
      >
        <div className="flex items-center justify-between">
          <div className="flex items-center gap-2">
            <Users className="w-4 h-4 text-amber-400" />
            <h2 className="text-xs font-bold text-white uppercase tracking-wider">
              Pending Signups ({pendingUsers.length})
            </h2>
          </div>
          {pendingUsers.length > 0 && (
            <span className="text-[10px] font-bold bg-neon-amber/20 text-amber-300 border border-neon-amber/40 px-2 py-0.5 rounded-full animate-pulse">
              Action Needed
            </span>
          )}
        </div>

        {pendingUsers.length === 0 ? (
          <p className="text-xs text-slate-500 py-2">
            No pending user signup requests at this time.
          </p>
        ) : (
          <div className="space-y-2">
            {pendingUsers.map((user) => (
              <div
                key={user.uid}
                className="flex items-center justify-between p-3 rounded-xl bg-midnight-elevated/70 border border-white/10"
              >
                <div className="flex items-center gap-2.5 min-w-0">
                  <Avatar user={user} size="sm" showBadges={false} />
                  <div className="min-w-0">
                    <p className="text-xs font-bold text-white truncate">
                      {user.displayName}
                    </p>
                    <p className="text-[10px] text-slate-400 truncate">
                      {user.email}
                    </p>
                  </div>
                </div>

                <div className="flex items-center gap-1.5 shrink-0">
                  <NeonButton
                    variant="destructive"
                    size="sm"
                    onClick={() => rejectUser(user.uid)}
                    title="Reject Signup"
                  >
                    <X className="w-3.5 h-3.5" />
                  </NeonButton>
                  <NeonButton
                    variant="success"
                    size="sm"
                    onClick={() => approveUser(user.uid)}
                    title="Approve Member"
                  >
                    <Check className="w-3.5 h-3.5" />
                    <span>Approve</span>
                  </NeonButton>
                </div>
              </div>
            ))}
          </div>
        )}
      </NeonCard>

      {/* 2. Keeper Designation & Debt Migration */}
      <NeonCard className="p-4 space-y-3">
        <div className="flex items-center justify-between">
          <div className="flex items-center gap-2">
            <Crown className="w-4 h-4 text-amber-400" />
            <h2 className="text-xs font-bold text-white uppercase tracking-wider">
              Designated Keeper
            </h2>
          </div>
        </div>

        {currentKeeper && (
          <div className="p-3 bg-midnight-elevated/70 border border-amber-500/30 rounded-xl flex items-center justify-between">
            <div className="flex items-center gap-2.5">
              <Avatar user={currentKeeper} size="sm" />
              <div>
                <p className="text-xs font-bold text-white flex items-center gap-1">
                  <span>{currentKeeper.displayName}</span>
                  <span className="text-[10px] text-amber-400 font-bold bg-amber-950/80 px-1 rounded">
                    Active
                  </span>
                </p>
                <p className="text-[10px] text-slate-400">{currentKeeper.email}</p>
              </div>
            </div>
          </div>
        )}

        {/* Member list to reassign keeper */}
        <div className="pt-2">
          <label className="block text-[11px] font-semibold text-slate-300 mb-2">
            Appoint a new Keeper:
          </label>
          <div className="grid grid-cols-2 gap-2">
            {approvedUsers.map((user) => {
              const isCurrent = user.uid === systemConfig?.activeKeeperId;

              return (
                <button
                  key={user.uid}
                  disabled={isCurrent}
                  onClick={() => setSelectedNewKeeper(user)}
                  className={clsx(
                    "flex items-center gap-2 p-2 rounded-xl border text-left transition-all",
                    isCurrent
                      ? "bg-amber-500/10 border-amber-500/40 text-amber-200 opacity-60 cursor-default"
                      : "bg-midnight-base/80 border-white/10 hover:border-neon-magenta hover:bg-midnight-elevated text-slate-300"
                  )}
                >
                  <Avatar user={user} size="sm" showBadges={false} />
                  <div className="min-w-0">
                    <p className="text-xs font-bold text-white truncate">
                      {user.displayName.split(" ")[0]}
                    </p>
                    <p className="text-[10px] text-slate-400">
                      {isCurrent ? "Current" : "Appoint"}
                    </p>
                  </div>
                </button>
              );
            })}
          </div>
        </div>
      </NeonCard>

      {/* 3. Consequence Rate per Swear Adjustment */}
      <NeonCard className="p-4 space-y-3">
        <div className="flex items-center gap-2">
          <DollarSign className="w-4 h-4 text-neon-magenta" />
          <h2 className="text-xs font-bold text-white uppercase tracking-wider">
            Penalty Consequence Rate
          </h2>
        </div>

        <form onSubmit={handleRateSubmit} className="space-y-3">
          <div className="flex items-center gap-2">
            <div className="relative flex-1">
              <span className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-400 font-bold">
                ₱
              </span>
              <input
                type="number"
                min="1"
                step="5"
                value={rateInput}
                onChange={(e) => setRateInput(Math.max(1, parseInt(e.target.value, 10) || 0))}
                className="w-full bg-midnight-base border border-white/15 rounded-xl pl-8 pr-3 py-2 text-sm text-white font-mono font-bold focus:outline-none focus:border-neon-magenta"
              />
            </div>
            <NeonButton
              type="submit"
              variant="primary"
              size="sm"
              isLoading={isUpdatingRate}
            >
              Update Rate
            </NeonButton>
          </div>

          <div className="flex items-start gap-1.5 text-[11px] text-slate-400 bg-midnight-base/50 p-2.5 rounded-xl border border-white/5">
            <Info className="w-3.5 h-3.5 text-neon-info shrink-0 mt-0.5" />
            <p>
              Modifying the penalty rate applies strictly to <strong>future</strong> swear reports. Existing reports retain their frozen consequence rate.
            </p>
          </div>
        </form>
      </NeonCard>

      {/* 4. Member Role Management */}
      <NeonCard className="p-4 space-y-3">
        <div className="flex items-center gap-2">
          <Zap className="w-4 h-4 text-pink-400" />
          <h2 className="text-xs font-bold text-white uppercase tracking-wider">
            Member Roles & Privileges
          </h2>
        </div>

        <div className="space-y-2">
          {approvedUsers.map((user) => {
            const userIsAdmin = user.roles.includes("admin");
            const isSelf = user.uid === currentUser?.uid;

            return (
              <div
                key={user.uid}
                className="flex items-center justify-between p-2.5 rounded-xl bg-midnight-elevated/50 border border-white/5"
              >
                <div className="flex items-center gap-2.5 min-w-0">
                  <Avatar user={user} size="sm" />
                  <div className="min-w-0">
                    <p className="text-xs font-bold text-white truncate">
                      {user.displayName} {isSelf && "(You)"}
                    </p>
                    <p className="text-[10px] text-slate-400">
                      {userIsAdmin ? "⚡ Admin & Member" : "Member"}
                    </p>
                  </div>
                </div>

                {!isSelf && (
                  <NeonButton
                    variant={userIsAdmin ? "destructive" : "outline"}
                    size="sm"
                    onClick={() => toggleUserAdmin(user.uid)}
                  >
                    {userIsAdmin ? "Revoke Admin" : "Make Admin"}
                  </NeonButton>
                )}
              </div>
            );
          })}
        </div>
      </NeonCard>

      {/* Keeper Appointment Confirmation Modal */}
      {selectedNewKeeper && (
        <ConfirmModal
          isOpen={Boolean(selectedNewKeeper)}
          onClose={() => setSelectedNewKeeper(null)}
          onConfirm={handleConfirmKeeperHandoff}
          isLoading={isAppointing}
          title="Appoint New Keeper"
          confirmLabel="Confirm Keeper Handoff"
          confirmVariant="primary"
          type="warning"
          description={
            <div className="space-y-3">
              <p>
                Are you sure you want to appoint{" "}
                <strong className="text-white">
                  {selectedNewKeeper.displayName}
                </strong>{" "}
                as the active Keeper?
              </p>
              <div className="p-3 bg-midnight-base rounded-xl border border-white/10 text-xs text-slate-300 space-y-1">
                <p className="font-bold text-amber-300">Automated Debt Migration:</p>
                <p>• All active unpaid debts owed to the old Keeper will be transferred to {selectedNewKeeper.displayName.split(" ")[0]}.</p>
                <p>• Paid and settled debts will remain archived without alteration.</p>
              </div>
            </div>
          }
        />
      )}
    </div>
  );
}
