"use client";

import React, { useState } from "react";
import { useApp } from "../../../context/AppContext";
import { NeonCard } from "../../../components/ui/NeonCard";
import { StatusPill } from "../../../components/ui/StatusPill";
import { CurrencyDisplay } from "../../../components/ui/CurrencyDisplay";
import { NeonButton } from "../../../components/ui/NeonButton";
import { Avatar } from "../../../components/ui/Avatar";
import { ConfirmModal } from "../../../components/ui/ConfirmModal";
import { formatDate } from "../../../lib/utils/formatters";
import { Report } from "../../../lib/domain/types";
import { Check, X, ShieldAlert, AlertCircle, Sparkles, MessageSquare } from "lucide-react";
import clsx from "clsx";

type TabFilter = "all" | "pending" | "confirmed" | "rejected";

export default function ReportsPage() {
  const { reports, users, isKeeper, isAdmin, systemConfig, confirmReport, rejectReport } = useApp();
  const [selectedFilter, setSelectedFilter] = useState<TabFilter>("all");

  // Modal states
  const [confirmModalReport, setConfirmModalReport] = useState<Report | null>(null);
  const [rejectModalReport, setRejectModalReport] = useState<Report | null>(null);
  const [rejectReason, setRejectReason] = useState("");
  const [isSubmitting, setIsSubmitting] = useState(false);

  const filteredReports = reports.filter((r) => {
    if (selectedFilter === "all") return true;
    return r.status === selectedFilter;
  });

  const pendingCount = reports.filter((r) => r.status === "pending").length;

  const handleConfirmAction = async () => {
    if (!confirmModalReport) return;
    setIsSubmitting(true);
    await confirmReport(confirmModalReport.id);
    setIsSubmitting(false);
    setConfirmModalReport(null);
  };

  const handleRejectAction = async () => {
    if (!rejectModalReport) return;
    setIsSubmitting(true);
    await rejectReport(rejectModalReport.id, rejectReason || "Rejected by Keeper");
    setIsSubmitting(false);
    setRejectModalReport(null);
    setRejectReason("");
  };

  return (
    <div className="space-y-4">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-xl font-bold font-display text-white">Reports Feed</h1>
          <p className="text-xs text-slate-400">
            Social accountability log for all reported swears
          </p>
        </div>
        {pendingCount > 0 && (
          <span className="text-xs font-bold bg-neon-amber/20 text-amber-300 border border-neon-amber/40 px-2.5 py-1 rounded-full animate-pulse">
            {pendingCount} Pending
          </span>
        )}
      </div>

      {/* Filter Tabs */}
      <div className="flex p-1 bg-midnight-elevated/80 border border-white/10 rounded-xl">
        {(["all", "pending", "confirmed", "rejected"] as TabFilter[]).map((tab) => (
          <button
            key={tab}
            onClick={() => setSelectedFilter(tab)}
            className={clsx(
              "flex-1 py-1.5 text-xs font-bold rounded-lg capitalize transition-all",
              selectedFilter === tab
                ? "bg-neon-magenta text-white shadow-neon-magenta"
                : "text-slate-400 hover:text-slate-200"
            )}
          >
            {tab}
            {tab === "pending" && pendingCount > 0 && (
              <span className="ml-1 px-1.5 py-0.2 text-[10px] rounded-full bg-white/20">
                {pendingCount}
              </span>
            )}
          </button>
        ))}
      </div>

      {/* Reports List */}
      {filteredReports.length === 0 ? (
        <NeonCard className="p-8 text-center space-y-2">
          <p className="text-sm font-semibold text-slate-300">No reports found</p>
          <p className="text-xs text-slate-500">
            There are no reports in the &apos;{selectedFilter}&apos; category right now.
          </p>
        </NeonCard>
      ) : (
        <div className="space-y-3">
          {filteredReports.map((report) => {
            const reporter = users.find((u) => u.uid === report.reporterId);
            const accused = users.find((u) => u.uid === report.accusedId);
            const reviewer = users.find((u) => u.uid === report.reviewedBy);
            const isKeeperAccused = report.accusedId === systemConfig?.activeKeeperId;
            const isPending = report.status === "pending";
            const canReview = (isKeeper || isAdmin) && isPending;

            return (
              <NeonCard
                key={report.id}
                glow={isKeeperAccused && isPending ? "amber" : "none"}
                className={clsx(
                  "p-4 space-y-3 relative transition-all",
                  isKeeperAccused && isPending && "border-neon-amber/50 bg-amber-950/20"
                )}
              >
                {/* Keeper Swear Special Banner */}
                {isKeeperAccused && isPending && (
                  <div className="flex items-center gap-2 p-2 rounded-xl bg-neon-amber/20 border border-neon-amber/40 text-amber-300 text-xs font-semibold">
                    <ShieldAlert className="w-4 h-4 shrink-0" />
                    <span>
                      <strong>Keeper Accused!</strong> Confirming will transfer Keeper debts to reporter.
                    </span>
                  </div>
                )}

                {/* Main Report Header */}
                <div className="flex items-start justify-between gap-3">
                  <div className="flex items-center gap-3">
                    <Avatar user={accused} size="md" />
                    <div>
                      <h3 className="text-sm font-bold text-white flex items-center gap-1.5">
                        <span>{accused?.displayName || "Unknown"}</span>
                        {isKeeperAccused && (
                          <span className="text-[10px] bg-amber-500 text-slate-950 px-1 rounded font-black">
                            KEEPER
                          </span>
                        )}
                      </h3>
                      <p className="text-xs text-slate-400">
                        Reported by{" "}
                        <span className="text-slate-300 font-medium">
                          {reporter?.displayName || "Member"}
                        </span>
                      </p>
                    </div>
                  </div>

                  <div className="text-right flex flex-col items-end gap-1">
                    <CurrencyDisplay amount={report.totalAmount} size="md" />
                    <StatusPill status={report.status} />
                  </div>
                </div>

                {/* Swear Count & Locked Rate Bar */}
                <div className="flex items-center justify-between text-xs bg-midnight-elevated/60 px-3 py-2 rounded-xl border border-white/5">
                  <span className="text-slate-300 font-medium">
                    {report.count} {report.count === 1 ? "Swear" : "Swears"} × ₱{report.rateApplied}
                  </span>
                  <span className="text-slate-400 font-mono text-[11px]">
                    {formatDate(report.createdAt)}
                  </span>
                </div>

                {/* Optional Note */}
                {report.note && (
                  <div className="flex items-start gap-2 text-xs text-slate-300 bg-midnight-base/50 p-2.5 rounded-xl border border-white/5">
                    <MessageSquare className="w-3.5 h-3.5 text-slate-400 mt-0.5 shrink-0" />
                    <p className="italic">&ldquo;{report.note}&rdquo;</p>
                  </div>
                )}

                {/* Review Details (if reviewed) */}
                {report.reviewedBy && (
                  <div className="text-[11px] text-slate-400 pt-1 flex items-center justify-between border-t border-white/5">
                    <span>
                      Reviewed by: <strong className="text-slate-300">{reviewer?.displayName || "Keeper"}</strong>
                    </span>
                    {report.rejectionReason && (
                      <span className="text-red-300 italic">
                        Reason: {report.rejectionReason}
                      </span>
                    )}
                  </div>
                )}

                {/* Keeper / Admin Review Actions */}
                {canReview && (
                  <div className="pt-2 border-t border-white/10 flex items-center justify-end gap-2">
                    <NeonButton
                      variant="destructive"
                      size="sm"
                      leftIcon={<X className="w-3.5 h-3.5" />}
                      onClick={() => setRejectModalReport(report)}
                    >
                      Reject
                    </NeonButton>
                    <NeonButton
                      variant="primary"
                      size="sm"
                      leftIcon={<Check className="w-3.5 h-3.5" />}
                      onClick={() => setConfirmModalReport(report)}
                    >
                      Confirm Report
                    </NeonButton>
                  </div>
                )}
              </NeonCard>
            );
          })}
        </div>
      )}

      {/* Confirmation Modal */}
      {confirmModalReport && (
        <ConfirmModal
          isOpen={Boolean(confirmModalReport)}
          onClose={() => setConfirmModalReport(null)}
          onConfirm={handleConfirmAction}
          isLoading={isSubmitting}
          title="Confirm Swear Report"
          confirmLabel="Confirm & Create Debt"
          confirmVariant="primary"
          type={confirmModalReport.accusedId === systemConfig?.activeKeeperId ? "warning" : "info"}
          description={
            <div className="space-y-3">
              <p>
                Are you sure you want to verify this swear penalty of{" "}
                <strong className="text-white">
                  ₱{confirmModalReport.totalAmount}
                </strong>{" "}
                against{" "}
                <strong className="text-white">
                  {users.find((u) => u.uid === confirmModalReport.accusedId)?.displayName}
                </strong>
                ?
              </p>

              {confirmModalReport.accusedId === systemConfig?.activeKeeperId ? (
                <div className="p-3 bg-neon-amber/20 border border-neon-amber/40 rounded-xl text-amber-200 text-xs font-medium space-y-1">
                  <p className="font-bold flex items-center gap-1.5 text-amber-300">
                    <ShieldAlert className="w-4 h-4" />
                    Special Keeper Swear Rule Activated:
                  </p>
                  <p>• All unpaid debts owed to the Keeper will transfer to the Reporter.</p>
                  <p>• Any existing debt the Reporter owes to the Keeper will be cancelled.</p>
                  <p>• This new ₱{confirmModalReport.totalAmount} debt is owed by Keeper to Reporter.</p>
                </div>
              ) : (
                <p className="text-xs text-slate-400">
                  This will create an active ₱{confirmModalReport.totalAmount} debt obligation payable to the Keeper.
                </p>
              )}
            </div>
          }
        />
      )}

      {/* Reject Modal */}
      {rejectModalReport && (
        <ConfirmModal
          isOpen={Boolean(rejectModalReport)}
          onClose={() => {
            setRejectModalReport(null);
            setRejectReason("");
          }}
          onConfirm={handleRejectAction}
          isLoading={isSubmitting}
          title="Reject Swear Report"
          confirmLabel="Reject Report"
          confirmVariant="destructive"
          type="danger"
          description={
            <div className="space-y-3">
              <p>
                Rejecting this report will dismiss the obligation without creating a debt.
              </p>
              <div>
                <label className="block text-xs font-semibold text-slate-300 mb-1">
                  Reason for rejection:
                </label>
                <input
                  type="text"
                  value={rejectReason}
                  onChange={(e) => setRejectReason(e.target.value)}
                  placeholder="e.g., False alarm, not a swear word"
                  className="w-full bg-midnight-base border border-white/15 rounded-xl px-3 py-2 text-xs text-white placeholder-slate-500 focus:outline-none focus:border-neon-magenta"
                />
              </div>
            </div>
          }
        />
      )}
    </div>
  );
}
