"use client";

import React from "react";
import Link from "next/link";
import { usePathname } from "next/navigation";
import { useApp } from "../../context/AppContext";
import { Avatar } from "../ui/Avatar";
import { Shield, Sparkles } from "lucide-react";
import clsx from "clsx";

export const TopNavbar: React.FC = () => {
  const { systemConfig, currentUser, isAdmin, isDemoMode } = useApp();
  const pathname = usePathname();

  return (
    <header className="sticky top-0 z-30 w-full bg-midnight-base/90 backdrop-blur-md border-b border-white/8 px-4 py-3">
      <div className="flex items-center justify-between max-w-md mx-auto">
        {/* Brand Logo & Group Title */}
        <Link href="/" className="flex items-center gap-2.5 group">
          <div className="w-8 h-8 rounded-xl bg-gradient-to-br from-neon-magenta to-purple-600 flex items-center justify-center shadow-neon-magenta group-hover:scale-105 transition-transform">
            <span className="text-white font-display font-extrabold text-sm tracking-tighter">
              SJ
            </span>
          </div>
          <div>
            <div className="flex items-center gap-1.5">
              <span className="font-display font-extrabold text-sm tracking-wider text-white group-hover:text-pink-300 transition-colors">
                SWEAR JAR
              </span>
              <span className="text-[10px] font-bold text-neon-magenta bg-neon-magenta/10 px-1.5 py-0.2 rounded border border-neon-magenta/20">
                2.0
              </span>
            </div>
            <p className="text-[11px] text-slate-400 font-medium truncate max-w-[140px] sm:max-w-[180px]">
              {systemConfig?.groupName || "Friend Group"}
            </p>
          </div>
        </Link>

        {/* Right Actions: Admin Link + Avatar */}
        <div className="flex items-center gap-2">
          {isDemoMode && (
            <span className="hidden sm:inline-flex items-center gap-1 text-[10px] font-semibold text-emerald-300 bg-emerald-950/60 border border-emerald-500/30 px-2 py-0.5 rounded-full">
              <Sparkles className="w-2.5 h-2.5" />
              Demo
            </span>
          )}

          {isAdmin && (
            <Link
              href="/admin"
              className={clsx(
                "p-1.5 rounded-xl border transition-all text-xs font-semibold flex items-center gap-1",
                pathname === "/admin"
                  ? "bg-neon-magenta/20 border-neon-magenta text-pink-300 shadow-neon-magenta"
                  : "bg-midnight-elevated border-white/10 text-slate-300 hover:text-white hover:border-white/20"
              )}
              title="Admin Console"
            >
              <Shield className="w-4 h-4 text-neon-magenta" />
              <span className="hidden sm:inline text-xs">Admin</span>
            </Link>
          )}

          {currentUser && (
            <Link href="/profile" className="hover:opacity-90 transition-opacity">
              <Avatar user={currentUser} size="sm" />
            </Link>
          )}
        </div>
      </div>
    </header>
  );
};
