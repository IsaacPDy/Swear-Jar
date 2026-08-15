"use client";

import React from "react";
import { useApp } from "../../context/AppContext";
import { NeonCard } from "../../components/ui/NeonCard";
import { NeonButton } from "../../components/ui/NeonButton";
import { Avatar } from "../../components/ui/Avatar";
import { JarVisual } from "../../components/ui/JarVisual";
import { Sparkles } from "lucide-react";
import { useRouter } from "next/navigation";

export default function LoginPage() {
  const { loginWithGoogle, switchDemoUser, users, currentUser, isDemoMode } = useApp();
  const router = useRouter();

  const handleSelectDemoPersona = (uid: string) => {
    switchDemoUser(uid);
    router.push("/");
  };

  return (
    <div className="min-h-[85vh] flex flex-col items-center justify-center space-y-6 text-center max-w-sm mx-auto">
      {/* Brand Hero */}
      <div className="space-y-2 flex flex-col items-center">
        <JarVisual fillLevel={55} totalSwears={47} />
        <h1 className="text-3xl font-extrabold font-display text-white tracking-tight mt-2">
          SWEAR JAR <span className="text-neon-magenta text-glow">2.0</span>
        </h1>
        <p className="text-xs text-slate-400 max-w-xs leading-relaxed">
          The real-time social accountability ledger for close friend groups.
        </p>
      </div>

      {/* Google Sign In Card */}
      <NeonCard glow="magenta" className="p-5 w-full space-y-4">
        <NeonButton
          variant="primary"
          size="lg"
          className="w-full font-bold shadow-neon-magenta"
          onClick={loginWithGoogle}
        >
          Sign In with Google
        </NeonButton>

        <p className="text-[11px] text-slate-400">
          New members require Admin approval before accessing group reports.
        </p>
      </NeonCard>

      {/* Demo Personas for Instant Testing */}
      {isDemoMode && (
        <NeonCard className="p-4 w-full space-y-3">
          <div className="flex items-center justify-center gap-1.5 text-emerald-400 text-xs font-bold">
            <Sparkles className="w-3.5 h-3.5" />
            <span>Interactive Demo Mode</span>
          </div>
          <p className="text-[11px] text-slate-400">
            Select a persona to explore the app instantly:
          </p>

          <div className="space-y-1.5">
            {users.map((u) => {
              const isSelected = u.uid === currentUser?.uid;
              const isKeeper = u.roles.includes("keeper");
              const isAdmin = u.roles.includes("admin");
              const isPending = u.status === "pending";

              return (
                <button
                  key={u.uid}
                  onClick={() => handleSelectDemoPersona(u.uid)}
                  className="w-full flex items-center justify-between p-2 rounded-xl bg-midnight-elevated/70 border border-white/5 hover:border-neon-magenta hover:bg-midnight-elevated transition-all text-left"
                >
                  <div className="flex items-center gap-2.5">
                    <Avatar user={u} size="sm" showBadges={false} />
                    <div>
                      <p className="text-xs font-bold text-white">
                        {u.displayName}
                      </p>
                      <p className="text-[10px] text-slate-400">
                        {isPending
                          ? "⏳ Pending Approval"
                          : isKeeper && isAdmin
                          ? "👑 Keeper & ⚡ Admin"
                          : isKeeper
                          ? "👑 Active Keeper"
                          : "👤 Member"}
                      </p>
                    </div>
                  </div>

                  {isSelected && (
                    <span className="text-[10px] bg-neon-magenta text-white px-2 py-0.5 rounded-full font-bold">
                      Active
                    </span>
                  )}
                </button>
              );
            })}
          </div>
        </NeonCard>
      )}
    </div>
  );
}
