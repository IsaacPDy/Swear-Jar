"use client";

import React, { useState } from "react";
import { useApp } from "../../context/AppContext";
import { Avatar } from "./Avatar";
import { Users, RotateCcw, ChevronUp, ChevronDown } from "lucide-react";
import clsx from "clsx";

export const PersonaSwitcher: React.FC = () => {
  const { users, currentUser, switchDemoUser, resetDemoData, isDemoMode } = useApp();
  const [isOpen, setIsOpen] = useState(false);

  if (!isDemoMode) return null;

  return (
    <div className="fixed bottom-20 right-3 sm:right-6 z-40">
      {/* Floating Toggle Trigger */}
      <button
        onClick={() => setIsOpen(!isOpen)}
        className="flex items-center gap-2 px-3 py-2 rounded-full bg-midnight-elevated/95 border border-neon-magenta/40 shadow-neon-magenta text-xs font-semibold text-white hover:bg-midnight-surface transition-all backdrop-blur-md"
        title="Switch Demo Persona"
      >
        <Users className="w-3.5 h-3.5 text-neon-magenta" />
        <span className="hidden sm:inline text-slate-300">View as:</span>
        <span className="text-pink-300 font-bold truncate max-w-[100px]">
          {currentUser?.displayName.split(" ")[0] || "Select"}
        </span>
        {isOpen ? <ChevronDown className="w-3.5 h-3.5" /> : <ChevronUp className="w-3.5 h-3.5" />}
      </button>

      {/* Popover Menu */}
      {isOpen && (
        <div className="absolute bottom-12 right-0 w-72 bg-midnight-elevated/95 border border-white/15 rounded-2xl p-3 shadow-2xl backdrop-blur-xl animate-in fade-in slide-in-from-bottom-2 duration-150">
          <div className="flex items-center justify-between pb-2 mb-2 border-b border-white/10">
            <span className="text-xs font-bold text-slate-300 uppercase tracking-wider">
              Switch Demo Persona
            </span>
            <button
              onClick={() => {
                resetDemoData();
                setIsOpen(false);
              }}
              className="text-[11px] text-slate-400 hover:text-white flex items-center gap-1 hover:underline"
              title="Reset mock data to initial showcase"
            >
              <RotateCcw className="w-3 h-3" />
              <span>Reset</span>
            </button>
          </div>

          <div className="space-y-1.5 max-h-64 overflow-y-auto">
            {users.map((user) => {
              const isSelected = user.uid === currentUser?.uid;
              const isKeeper = user.roles.includes("keeper");
              const isAdmin = user.roles.includes("admin");
              const isPending = user.status === "pending";

              return (
                <button
                  key={user.uid}
                  onClick={() => {
                    switchDemoUser(user.uid);
                    setIsOpen(false);
                  }}
                  className={clsx(
                    "w-full flex items-center justify-between p-2 rounded-xl text-left transition-all",
                    isSelected
                      ? "bg-neon-magenta/20 border border-neon-magenta/50 text-white"
                      : "hover:bg-white/5 border border-transparent text-slate-300"
                  )}
                >
                  <div className="flex items-center gap-2.5 min-w-0">
                    <Avatar user={user} size="sm" showBadges={false} />
                    <div className="min-w-0">
                      <p className="text-xs font-bold text-white truncate">
                        {user.displayName}
                      </p>
                      <p className="text-[10px] text-slate-400 truncate">
                        {isPending
                          ? "⏳ Pending Gate"
                          : isKeeper && isAdmin
                          ? "👑 Keeper & ⚡ Admin"
                          : isKeeper
                          ? "👑 Active Keeper"
                          : isAdmin
                          ? "⚡ Admin"
                          : "👤 Member"}
                      </p>
                    </div>
                  </div>

                  {isSelected && (
                    <span className="w-2 h-2 rounded-full bg-neon-magenta shrink-0 animate-pulse" />
                  )}
                </button>
              );
            })}
          </div>
        </div>
      )}
    </div>
  );
};
