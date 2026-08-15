"use client";

import React, { useState } from "react";
import Link from "next/link";
import { useApp } from "../../../context/AppContext";
import { NeonCard } from "../../../components/ui/NeonCard";
import { Avatar } from "../../../components/ui/Avatar";
import { NeonButton } from "../../../components/ui/NeonButton";
import {
  Shield,
  Smartphone,
  Check,
  RotateCcw,
  LogOut,
  HelpCircle,
  Crown,
  Zap,
} from "lucide-react";

export default function ProfilePage() {
  const {
    currentUser,
    systemConfig,
    isAdmin,
    isKeeper,
    updateGcashNumber,
    resetDemoData,
    logout,
    isDemoMode,
  } = useApp();

  const [gcashInput, setGcashInput] = useState(currentUser?.gcashNumber || "");
  const [isSavingGcash, setIsSavingGcash] = useState(false);

  if (!currentUser) return null;

  const handleSaveGcash = async (e: React.FormEvent) => {
    e.preventDefault();
    setIsSavingGcash(true);
    await updateGcashNumber(currentUser.uid, gcashInput);
    setIsSavingGcash(false);
  };

  return (
    <div className="space-y-4">
      {/* Header */}
      <div>
        <h1 className="text-xl font-bold font-display text-white">Your Profile</h1>
        <p className="text-xs text-slate-400">Account settings and group standing</p>
      </div>

      {/* User Info Card */}
      <NeonCard variant="elevated" className="p-5 space-y-4 text-center">
        <div className="flex flex-col items-center">
          <Avatar user={currentUser} size="xl" />
          <h2 className="text-lg font-bold font-display text-white mt-3">
            {currentUser.displayName}
          </h2>
          <p className="text-xs text-slate-400">{currentUser.email}</p>

          {/* Role Badges */}
          <div className="flex flex-wrap items-center justify-center gap-1.5 mt-3">
            {isKeeper && (
              <span className="inline-flex items-center gap-1 px-2.5 py-1 rounded-full text-xs font-bold bg-amber-500/20 text-amber-300 border border-amber-500/40">
                <Crown className="w-3.5 h-3.5" />
                Active Keeper
              </span>
            )}
            {isAdmin && (
              <span className="inline-flex items-center gap-1 px-2.5 py-1 rounded-full text-xs font-bold bg-neon-magenta/20 text-pink-300 border border-neon-magenta/40">
                <Zap className="w-3.5 h-3.5" />
                Admin
              </span>
            )}
            <span className="inline-flex items-center gap-1 px-2.5 py-1 rounded-full text-xs font-medium bg-slate-800 text-slate-300 border border-white/10">
              Approved Member
            </span>
          </div>
        </div>
      </NeonCard>

      {/* GCash Settings Form */}
      <NeonCard className="p-4 space-y-3">
        <div className="flex items-center gap-2">
          <div className="p-2 rounded-xl bg-sky-950/60 border border-sky-500/30 text-sky-400">
            <Smartphone className="w-4 h-4" />
          </div>
          <div>
            <h3 className="text-xs font-bold text-white uppercase tracking-wider">
              Your GCash Mobile Number
            </h3>
            <p className="text-[11px] text-slate-400">
              Shown to group members when they owe you penalties
            </p>
          </div>
        </div>

        <form onSubmit={handleSaveGcash} className="space-y-2 pt-1">
          <div className="flex gap-2">
            <input
              type="text"
              value={gcashInput}
              onChange={(e) => setGcashInput(e.target.value)}
              placeholder="e.g. 0917 123 4567"
              className="flex-1 bg-midnight-base border border-white/15 rounded-xl px-3 py-2 text-xs text-white font-mono placeholder-slate-500 focus:outline-none focus:border-neon-magenta"
            />
            <NeonButton
              type="submit"
              variant="secondary"
              size="sm"
              isLoading={isSavingGcash}
              leftIcon={<Check className="w-3.5 h-3.5" />}
            >
              Save
            </NeonButton>
          </div>
        </form>
      </NeonCard>

      {/* Admin Console Shortcut (if Admin) */}
      {isAdmin && (
        <NeonCard glow="magenta" className="p-4 space-y-2 bg-gradient-to-br from-midnight-surface to-[#221028]">
          <div className="flex items-start justify-between">
            <div className="flex items-center gap-2.5">
              <div className="p-2 rounded-xl bg-neon-magenta/20 text-neon-magenta">
                <Shield className="w-5 h-5" />
              </div>
              <div>
                <h3 className="text-sm font-bold text-white">Admin Console</h3>
                <p className="text-[11px] text-slate-300">
                  Approve signups, reassign Keeper, update penalty rate
                </p>
              </div>
            </div>
          </div>
          <Link href="/admin" className="block pt-2">
            <NeonButton variant="primary" size="sm" className="w-full">
              Open Admin Console
            </NeonButton>
          </Link>
        </NeonCard>
      )}

      {/* Group Rules & Reference */}
      <NeonCard className="p-4 space-y-2.5">
        <div className="flex items-center gap-2 text-slate-300">
          <HelpCircle className="w-4 h-4 text-neon-magenta" />
          <h3 className="text-xs font-bold uppercase tracking-wider text-white">
            Group Rules Summary
          </h3>
        </div>
        <div className="text-[11px] text-slate-400 space-y-1.5 leading-relaxed bg-midnight-base/50 p-3 rounded-xl border border-white/5">
          <p>
            • <strong>Current Rate:</strong> ₱{systemConfig?.currentRatePerSwear || 50} per verified swear.
          </p>
          <p>
            • <strong>Designated Keeper:</strong> Holds active group debt pool and records payments.
          </p>
          <p>
            • <strong>Keeper Swear Transfer Rule:</strong> If the Keeper swears, all unpaid debts transfer to the reporter and reporter debts are forgiven.
          </p>
        </div>
      </NeonCard>

      {/* Actions: Demo Reset & Sign Out */}
      <div className="space-y-2 pt-2">
        {isDemoMode && (
          <NeonButton
            variant="outline"
            size="md"
            className="w-full"
            leftIcon={<RotateCcw className="w-4 h-4 text-slate-400" />}
            onClick={resetDemoData}
          >
            Reset Demo Data to Initial State
          </NeonButton>
        )}

        <NeonButton
          variant="ghost"
          size="md"
          className="w-full text-slate-400 hover:text-red-300 hover:bg-red-950/20"
          leftIcon={<LogOut className="w-4 h-4" />}
          onClick={logout}
        >
          {isDemoMode ? "Log Out of Demo Persona" : "Sign Out"}
        </NeonButton>
      </div>
    </div>
  );
}
