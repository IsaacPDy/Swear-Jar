import React from "react";
import clsx from "clsx";
import { CheckCircle2, Clock, XCircle, ArrowRightLeft, Sparkles } from "lucide-react";

export type StatusPillType =
  | "pending"
  | "confirmed"
  | "rejected"
  | "paid"
  | "active"
  | "dismissed"
  | "transferred";

interface StatusPillProps {
  status: StatusPillType;
  label?: string;
  className?: string;
}

export const StatusPill: React.FC<StatusPillProps> = ({ status, label, className }) => {
  const config = {
    pending: {
      defaultLabel: "Pending Review",
      icon: Clock,
      style: "bg-neon-amber/15 text-amber-300 border-neon-amber/30",
    },
    confirmed: {
      defaultLabel: "Confirmed",
      icon: CheckCircle2,
      style: "bg-neon-magenta/15 text-pink-300 border-neon-magenta/30",
    },
    rejected: {
      defaultLabel: "Rejected",
      icon: XCircle,
      style: "bg-neon-crimson/15 text-red-300 border-neon-crimson/30",
    },
    paid: {
      defaultLabel: "Paid",
      icon: CheckCircle2,
      style: "bg-neon-mint/15 text-emerald-300 border-neon-mint/30",
    },
    active: {
      defaultLabel: "Active Debt",
      icon: Sparkles,
      style: "bg-sky-500/15 text-sky-300 border-sky-500/30",
    },
    dismissed: {
      defaultLabel: "Forgiven",
      icon: CheckCircle2,
      style: "bg-slate-700/40 text-slate-400 border-slate-600/30",
    },
    transferred: {
      defaultLabel: "Transferred",
      icon: ArrowRightLeft,
      style: "bg-neon-amber/15 text-amber-300 border-neon-amber/30",
    },
  }[status] || {
    defaultLabel: status,
    icon: Sparkles,
    style: "bg-slate-800 text-slate-300 border-slate-700",
  };

  const Icon = config.icon;

  return (
    <span
      className={clsx(
        "inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-xs font-semibold border tracking-wide",
        config.style,
        className
      )}
    >
      <Icon className="w-3.5 h-3.5 shrink-0" />
      <span>{label || config.defaultLabel}</span>
    </span>
  );
};
