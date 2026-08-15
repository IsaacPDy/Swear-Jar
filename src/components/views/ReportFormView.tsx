"use client";

import React, { useState } from "react";
import { useRouter } from "next/navigation";
import { useApp } from "../../context/AppContext";
import { NeonCard } from "../ui/NeonCard";
import { Avatar } from "../ui/Avatar";
import { CurrencyDisplay } from "../ui/CurrencyDisplay";
import { NeonButton } from "../ui/NeonButton";
import { calculateReportAmount } from "../../lib/domain/ledger";
import { Minus, Plus, MessageSquare, Send, ShieldAlert } from "lucide-react";
import clsx from "clsx";
import confetti from "canvas-confetti";

export const ReportFormView: React.FC = () => {
  const router = useRouter();
  const { users, currentUser, systemConfig, submitReport } = useApp();

  const [selectedAccusedId, setSelectedAccusedId] = useState<string>(
    users.find((u) => u.uid !== currentUser?.uid)?.uid || currentUser?.uid || ""
  );
  const [count, setCount] = useState<number>(1);
  const [note, setNote] = useState<string>("");
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [isJarShaking, setIsJarShaking] = useState(false);

  const rate = systemConfig?.currentRatePerSwear || 50;
  const totalAmount = calculateReportAmount(count, rate);

  const isKeeperAccused = selectedAccusedId === systemConfig?.activeKeeperId;

  const handleIncrement = () => setCount((c) => Math.min(99, c + 1));
  const handleDecrement = () => setCount((c) => Math.max(1, c - 1));

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!selectedAccusedId) return;

    setIsSubmitting(true);
    setIsJarShaking(true);

    // Blast celebratory / playful confetti
    confetti({
      particleCount: 40,
      spread: 70,
      origin: { y: 0.7 },
      colors: ["#FF007F", "#F59E0B", "#38BDF8", "#10B981"],
    });

    const success = await submitReport(selectedAccusedId, count, note);

    setTimeout(() => {
      setIsSubmitting(false);
      setIsJarShaking(false);
      if (success) {
        router.push("/reports");
      }
    }, 600);
  };

  return (
    <div className="space-y-4 max-w-md mx-auto">
      {/* Title */}
      <div>
        <h1 className="text-xl font-bold font-display text-white">Report a Swear</h1>
        <p className="text-xs text-slate-400">
          Hold your squad accountable. Consequence locked at ₱{rate}/swear.
        </p>
      </div>

      <form onSubmit={handleSubmit} className="space-y-4">
        {/* 1. Accused Member Picker */}
        <div className="space-y-2">
          <label className="block text-xs font-bold text-slate-300 uppercase tracking-wider">
            1. Who swore?
          </label>
          <div className="grid grid-cols-2 gap-2.5">
            {users
              .filter((u) => u.status === "approved")
              .map((user) => {
                const isSelected = user.uid === selectedAccusedId;
                const isSelf = user.uid === currentUser?.uid;
                const isKeeper = user.uid === systemConfig?.activeKeeperId;

                return (
                  <button
                    key={user.uid}
                    type="button"
                    onClick={() => setSelectedAccusedId(user.uid)}
                    className={clsx(
                      "flex items-center gap-2.5 p-3 rounded-2xl border text-left transition-all",
                      isSelected
                        ? "bg-neon-magenta/20 border-neon-magenta shadow-neon-magenta text-white"
                        : "bg-midnight-surface/80 border-white/10 hover:border-white/20 text-slate-300"
                    )}
                  >
                    <Avatar user={user} size="sm" />
                    <div className="min-w-0">
                      <p className="text-xs font-bold truncate">
                        {isSelf ? "Myself" : user.displayName.split(" ")[0]}
                      </p>
                      <p className="text-[10px] text-slate-400 truncate">
                        {isKeeper ? "👑 Keeper" : isSelf ? "Confession" : "Friend"}
                      </p>
                    </div>
                  </button>
                );
              })}
          </div>
        </div>

        {/* Keeper Swear Notice Banner */}
        {isKeeperAccused && (
          <div className="p-3 bg-neon-amber/20 border border-neon-amber/40 rounded-2xl flex items-start gap-2.5 text-amber-200 text-xs">
            <ShieldAlert className="w-5 h-5 text-amber-300 shrink-0 mt-0.5" />
            <div>
              <strong className="text-amber-300 font-bold block">
                Keeper Swear Rule will apply!
              </strong>
              If confirmed by Keeper, all active unpaid balances will transfer to you, and your existing debts will be forgiven!
            </div>
          </div>
        )}

        {/* 2. Swear Count Selector */}
        <NeonCard className="p-4 space-y-3">
          <div className="flex items-center justify-between">
            <label className="text-xs font-bold text-slate-300 uppercase tracking-wider">
              2. Swear Count (1–99)
            </label>
            <span className="text-xs text-slate-400 font-mono">
              ₱{rate} each
            </span>
          </div>

          <div className="flex items-center justify-center gap-4 py-2">
            <button
              type="button"
              onClick={handleDecrement}
              disabled={count <= 1}
              className="w-12 h-12 rounded-2xl bg-midnight-elevated border border-white/10 flex items-center justify-center text-white hover:border-neon-magenta hover:text-neon-magenta active:scale-95 disabled:opacity-30 disabled:pointer-events-none transition-all"
              aria-label="Decrease swear count"
            >
              <Minus className="w-5 h-5" />
            </button>

            <div className="text-center min-w-[100px]">
              <input
                type="number"
                min="1"
                max="99"
                value={count}
                onChange={(e) => {
                  const val = parseInt(e.target.value, 10);
                  if (!isNaN(val)) setCount(Math.max(1, Math.min(99, val)));
                }}
                className="w-24 text-center font-display font-black text-4xl bg-transparent border-b-2 border-neon-magenta/50 focus:border-neon-magenta text-white focus:outline-none"
              />
              <p className="text-[11px] text-slate-400 mt-1 font-semibold">
                {count === 1 ? "swear" : "swears"}
              </p>
            </div>

            <button
              type="button"
              onClick={handleIncrement}
              disabled={count >= 99}
              className="w-12 h-12 rounded-2xl bg-midnight-elevated border border-white/10 flex items-center justify-center text-white hover:border-neon-magenta hover:text-neon-magenta active:scale-95 disabled:opacity-30 disabled:pointer-events-none transition-all"
              aria-label="Increase swear count"
            >
              <Plus className="w-5 h-5" />
            </button>
          </div>

          {/* Quick Presets */}
          <div className="flex items-center justify-center gap-2 pt-1">
            {[1, 2, 3, 5, 10].map((preset) => (
              <button
                key={preset}
                type="button"
                onClick={() => setCount(preset)}
                className={clsx(
                  "px-3 py-1 rounded-lg text-xs font-bold border transition-all",
                  count === preset
                    ? "bg-neon-magenta text-white border-neon-magenta"
                    : "bg-midnight-base/60 text-slate-400 border-white/10 hover:text-white"
                )}
              >
                +{preset}
              </button>
            ))}
          </div>
        </NeonCard>

        {/* 3. Optional Context Note */}
        <div className="space-y-1.5">
          <label className="block text-xs font-bold text-slate-300 uppercase tracking-wider flex items-center gap-1.5">
            <MessageSquare className="w-3.5 h-3.5 text-slate-400" />
            <span>3. Context / What happened? (Optional)</span>
          </label>
          <textarea
            rows={2}
            value={note}
            onChange={(e) => setNote(e.target.value)}
            placeholder="e.g. Spilled iced latte during the squad Discord call..."
            className="w-full bg-midnight-surface border border-white/10 rounded-2xl p-3 text-xs text-white placeholder-slate-500 focus:outline-none focus:border-neon-magenta focus:ring-1 focus:ring-neon-magenta resize-none transition-all"
          />
        </div>

        {/* 4. Consequence Calculation Summary & Submit */}
        <NeonCard glow="magenta" className="p-4 space-y-3 bg-gradient-to-b from-midnight-surface to-[#1a1528]">
          <div className="flex items-center justify-between">
            <span className="text-xs text-slate-400 font-medium">Total Obligation</span>
            <div className="text-right">
              <CurrencyDisplay amount={totalAmount} size="lg" glow />
              <p className="text-[10px] text-slate-400 font-mono">
                {count} × ₱{rate} locked in
              </p>
            </div>
          </div>

          <NeonButton
            type="submit"
            variant="primary"
            size="lg"
            className={clsx("w-full py-4 text-base font-bold", isJarShaking && "animate-jar-shake")}
            isLoading={isSubmitting}
            leftIcon={<Send className="w-4 h-4" />}
          >
            Submit to Swear Jar (₱{totalAmount})
          </NeonButton>
        </NeonCard>
      </form>
    </div>
  );
};
