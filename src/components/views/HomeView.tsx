"use client";

import React from "react";
import Link from "next/link";
import { useApp } from "../../context/AppContext";
import { NeonCard } from "../ui/NeonCard";
import { CurrencyDisplay } from "../ui/CurrencyDisplay";
import { GCashBadge } from "../ui/GCashBadge";
import { StatusPill } from "../ui/StatusPill";
import { JarVisual } from "../ui/JarVisual";
import { NeonButton } from "../ui/NeonButton";
import { Avatar } from "../ui/Avatar";
import { formatDate } from "../../lib/utils/formatters";
import { Plus, ArrowUpRight, Flame, ShieldAlert, Sparkles, CheckCircle } from "lucide-react";

export const HomeView: React.FC = () => {
  const { currentUser, personalSummary, systemConfig, users } = useApp();

  if (!currentUser || !personalSummary) return null;

  const hasDebt = personalSummary.totalOwed > 0;
  const recipient = personalSummary.recipient?.user;
  const isTransferredCreditor = personalSummary.recipient?.isTransferredRecipient;

  // Calculate Jar Visual Fill based on group and personal activity
  const fillPercentage = Math.min(85, Math.max(20, (personalSummary.totalSwears * 15) || 30));

  return (
    <div className="space-y-5">
      {/* Hero Welcome & Swear Jar Status */}
      <div className="flex items-center justify-between pt-1">
        <div>
          <h1 className="text-xl font-bold font-display text-white">
            Hey, {currentUser.displayName.split(" ")[0]}! 👋
          </h1>
          <p className="text-xs text-slate-400 font-medium">
            Here is your personal Swear Jar standing
          </p>
        </div>

        <Link href="/report">
          <NeonButton
            variant="primary"
            size="sm"
            leftIcon={<Plus className="w-3.5 h-3.5" />}
          >
            Report
          </NeonButton>
        </Link>
      </div>

      {/* Main Personal Balance Card */}
      <NeonCard
        variant="elevated"
        glow={hasDebt ? "magenta" : "mint"}
        className="p-5 relative overflow-hidden"
      >
        {/* Subtle decorative background gradient */}
        <div className="absolute top-0 right-0 w-36 h-36 bg-neon-magenta/10 rounded-full blur-3xl pointer-events-none" />

        <div className="flex items-start justify-between">
          <div>
            <span className="text-xs font-bold tracking-wider text-slate-400 uppercase">
              Your Outstanding Balance
            </span>
            <div className="mt-1">
              <CurrencyDisplay
                amount={personalSummary.totalOwed}
                size="hero"
                glow={hasDebt}
              />
            </div>
          </div>

          <div className="shrink-0">
            {hasDebt ? (
              <StatusPill status="active" label="Unpaid Balance" />
            ) : (
              <StatusPill status="paid" label="All Cleared" />
            )}
          </div>
        </div>

        {/* Recipient Information / GCash Badge */}
        <div className="mt-4 pt-4 border-t border-white/10 flex flex-col gap-2">
          {hasDebt && recipient ? (
            <div className="space-y-2">
              <div className="flex items-center justify-between text-xs">
                <span className="text-slate-400">Payable to:</span>
                <div className="flex items-center gap-1.5 font-semibold text-white">
                  <Avatar user={recipient} size="sm" showBadges={false} />
                  <span>{recipient.displayName}</span>
                  {isTransferredCreditor ? (
                    <span className="text-[10px] text-amber-400 font-bold bg-amber-950/60 border border-amber-500/30 px-1.5 py-0.5 rounded">
                      Transferred
                    </span>
                  ) : (
                    <span className="text-[10px] text-amber-400 font-bold bg-amber-950/60 border border-amber-500/30 px-1.5 py-0.5 rounded">
                      Keeper 👑
                    </span>
                  )}
                </div>
              </div>

              {recipient.gcashNumber && (
                <div className="flex items-center justify-between pt-1">
                  <span className="text-xs text-slate-400">GCash Details:</span>
                  <GCashBadge number={recipient.gcashNumber} />
                </div>
              )}
            </div>
          ) : (
            <div className="flex items-center gap-2 text-xs text-emerald-300 font-medium">
              <CheckCircle className="w-4 h-4 text-emerald-400 shrink-0" />
              <span>You have zero unpaid penalties. Keep up the clean language!</span>
            </div>
          )}
        </div>
      </NeonCard>

      {/* Special Notice if user holds transferred debts (they caught the Keeper) */}
      {personalSummary.transferredDebtsHeld.length > 0 && (
        <NeonCard glow="amber" className="p-4 bg-amber-950/30 border-neon-amber/40">
          <div className="flex items-start gap-3">
            <div className="p-2 rounded-xl bg-neon-amber/20 text-amber-300 shrink-0">
              <ShieldAlert className="w-5 h-5" />
            </div>
            <div className="space-y-1">
              <h4 className="text-xs font-bold text-amber-200">
                You Caught The Keeper Swearing! 🎯
              </h4>
              <p className="text-[11px] text-amber-300/80 leading-relaxed">
                You currently hold {personalSummary.transferredDebtsHeld.length} transferred debt(s). You have the authority to collect payments or forgive them in the <strong>Jar</strong> tab.
              </p>
              <Link
                href="/jar"
                className="inline-flex items-center gap-1 text-xs font-bold text-amber-300 hover:underline pt-1"
              >
                <span>Manage Transferred Debts</span>
                <ArrowUpRight className="w-3 h-3" />
              </Link>
            </div>
          </div>
        </NeonCard>
      )}

      {/* Interactive Swear Jar Visual & Quick Stats Grid */}
      <div className="grid grid-cols-2 gap-3">
        <NeonCard className="p-4 flex flex-col justify-between">
          <div className="flex items-center gap-2 text-slate-400 text-xs font-semibold">
            <Flame className="w-4 h-4 text-neon-magenta" />
            <span>Total Swears</span>
          </div>
          <div className="my-2">
            <span className="text-3xl font-display font-black text-white">
              {personalSummary.totalSwears}
            </span>
          </div>
          <span className="text-[11px] text-slate-400">
            Rate: ₱{systemConfig?.currentRatePerSwear || 50} / swear
          </span>
        </NeonCard>

        <NeonCard className="p-4 flex flex-col justify-between">
          <div className="flex items-center gap-2 text-slate-400 text-xs font-semibold">
            <Sparkles className="w-4 h-4 text-neon-mint" />
            <span>Total Paid</span>
          </div>
          <div className="my-2">
            <CurrencyDisplay amount={personalSummary.totalPaid} size="lg" />
          </div>
          <span className="text-[11px] text-slate-400">Settled obligations</span>
        </NeonCard>
      </div>

      {/* Playful Swear Jar Mascot Container */}
      <NeonCard className="p-5 flex flex-col items-center justify-center text-center">
        <JarVisual
          fillLevel={fillPercentage}
          totalSwears={personalSummary.totalSwears}
        />
        <p className="text-xs text-slate-400 mt-3">
          Tap the jar to make it rattle! Each verified swear funds the squad pot.
        </p>
      </NeonCard>

      {/* Personal Activity Feed */}
      <div className="space-y-3 pt-2">
        <div className="flex items-center justify-between">
          <h3 className="text-sm font-bold font-display text-white uppercase tracking-wider">
            Your Activity History
          </h3>
          <Link href="/reports" className="text-xs text-neon-magenta hover:underline font-semibold">
            View All
          </Link>
        </div>

        {personalSummary.personalReports.length === 0 ? (
          <NeonCard className="p-6 text-center text-xs text-slate-400">
            No personal swear reports on record yet.
          </NeonCard>
        ) : (
          <div className="space-y-2">
            {personalSummary.personalReports.slice(0, 5).map((report) => {
              const isAccused = report.accusedId === currentUser.uid;
              const accusedUser = users.find((u) => u.uid === report.accusedId);
              const reporterUser = users.find((u) => u.uid === report.reporterId);

              return (
                <NeonCard key={report.id} className="p-3.5 flex items-center justify-between gap-3">
                  <div className="flex items-center gap-3 min-w-0">
                    <Avatar user={isAccused ? reporterUser : accusedUser} size="sm" />
                    <div className="min-w-0">
                      <p className="text-xs font-bold text-white truncate">
                        {isAccused ? "Reported on you" : `Reported ${accusedUser?.displayName}`}
                      </p>
                      <p className="text-[11px] text-slate-400 truncate">
                        {report.count} {report.count === 1 ? "swear" : "swears"} • {formatDate(report.createdAt)}
                      </p>
                    </div>
                  </div>

                  <div className="text-right shrink-0 flex flex-col items-end gap-1">
                    <CurrencyDisplay amount={report.totalAmount} size="sm" />
                    <StatusPill status={report.status} />
                  </div>
                </NeonCard>
              );
            })}
          </div>
        )}
      </div>
    </div>
  );
};
