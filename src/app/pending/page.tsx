"use client";

import React from "react";
import { useApp } from "../../context/AppContext";
import { Clock, Sparkles } from "lucide-react";
import { NeonButton } from "../../components/ui/NeonButton";
import { useRouter } from "next/navigation";

export default function PendingPage() {
  const { currentUser, switchDemoUser, isDemoMode } = useApp();
  const router = useRouter();

  const handleApproveAsAdmin = () => {
    switchDemoUser("user_sarah");
    router.push("/admin");
  };

  return (
    <div className="min-h-[80vh] flex flex-col items-center justify-center p-4 text-center max-w-sm mx-auto space-y-4">
      <div className="w-16 h-16 mx-auto rounded-3xl bg-neon-amber/20 border border-neon-amber/40 text-amber-300 flex items-center justify-center shadow-neon-amber">
        <Clock className="w-8 h-8" />
      </div>

      <h1 className="text-2xl font-bold font-display text-white">
        Approval Pending
      </h1>

      <p className="text-xs text-slate-300 leading-relaxed">
        Welcome{currentUser ? `, ${currentUser.displayName}` : ""}! Your membership request is currently awaiting approval from an Admin.
      </p>

      <div className="w-full p-4 bg-midnight-surface rounded-2xl border border-white/10 text-xs text-slate-400 text-left space-y-1.5">
        <p className="font-semibold text-slate-200">Account status:</p>
        <p>• Email: {currentUser?.email || "Checking..."}</p>
        <p>
          • Status: <span className="text-amber-400 font-bold">Pending Review</span>
        </p>
      </div>

      {isDemoMode && (
        <div className="w-full pt-3 space-y-2 border-t border-white/10">
          <p className="text-xs text-slate-400">Testing Demo Mode?</p>
          <NeonButton
            variant="primary"
            size="md"
            className="w-full font-bold"
            leftIcon={<Sparkles className="w-4 h-4" />}
            onClick={handleApproveAsAdmin}
          >
            Switch to Admin (Sarah) to Approve
          </NeonButton>
        </div>
      )}
    </div>
  );
}
