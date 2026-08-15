"use client";

import React, { useEffect } from "react";
import { usePathname, useRouter } from "next/navigation";
import { TopNavbar } from "./TopNavbar";
import { BottomTabBar } from "./BottomTabBar";
import { ToastContainer } from "../ui/ToastContainer";
import { PersonaSwitcher } from "../ui/PersonaSwitcher";
import { useApp } from "../../context/AppContext";
import { Clock, ShieldAlert, Sparkles } from "lucide-react";
import { NeonButton } from "../ui/NeonButton";

export const AppShell: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const pathname = usePathname();
  const router = useRouter();
  const { currentUser, isDemoMode, switchDemoUser, isLoading } = useApp();

  const isAuthPage = pathname === "/login" || pathname === "/pending";

  // Redirect to /login if unauthenticated on protected routes
  useEffect(() => {
    if (!isLoading && !currentUser && !isAuthPage) {
      router.push("/login");
    }
  }, [isLoading, currentUser, isAuthPage, router]);

  // Loading Screen while verifying auth status
  if (isLoading) {
    return (
      <div className="min-h-screen bg-midnight-base text-slate-100 flex items-center justify-center p-4 selection:bg-neon-magenta selection:text-white">
        <div className="flex flex-col items-center gap-3">
          <div className="w-10 h-10 border-2 border-neon-magenta border-t-transparent rounded-full animate-spin" />
          <p className="text-xs text-slate-400 font-medium">Loading Swear Jar...</p>
        </div>
      </div>
    );
  }

  // Not authenticated on a protected route — show clean redirect state
  if (!currentUser && !isAuthPage) {
    return (
      <div className="min-h-screen bg-midnight-base text-slate-100 flex items-center justify-center p-4 selection:bg-neon-magenta selection:text-white">
        <div className="flex flex-col items-center gap-3">
          <div className="w-10 h-10 border-2 border-neon-magenta border-t-transparent rounded-full animate-spin" />
          <p className="text-xs text-slate-400 font-medium">Redirecting to sign in...</p>
        </div>
      </div>
    );
  }

  // Auth Screen Dedicated Clean Center Layout
  if (isAuthPage) {
    return (
      <div className="min-h-screen bg-midnight-base text-slate-100 flex items-center justify-center p-4 selection:bg-neon-magenta selection:text-white relative overflow-hidden">
        {/* Subtle background ambient glows */}
        <div className="absolute -top-32 -left-32 w-80 h-80 bg-neon-magenta/15 rounded-full blur-3xl pointer-events-none" />
        <div className="absolute -bottom-32 -right-32 w-80 h-80 bg-neon-cyan/15 rounded-full blur-3xl pointer-events-none" />
        <ToastContainer />
        <main className="w-full flex items-center justify-center relative z-10">
          {children}
        </main>
      </div>
    );
  }

  // Pending Approval Gate Screen
  if (currentUser && currentUser.status === "pending" && pathname !== "/pending") {
    return (
      <div className="min-h-screen bg-midnight-base text-white flex flex-col items-center justify-center p-6 relative">
        <ToastContainer />
        <PersonaSwitcher />

        <div className="w-full max-w-sm bg-midnight-surface border border-white/10 rounded-3xl p-6 text-center shadow-2xl space-y-4">
          <div className="w-14 h-14 mx-auto rounded-2xl bg-neon-amber/20 border border-neon-amber/40 text-amber-300 flex items-center justify-center shadow-neon-amber">
            <Clock className="w-7 h-7" />
          </div>

          <h2 className="text-xl font-bold font-display">Approval Pending</h2>
          <p className="text-sm text-slate-300 leading-relaxed">
            Welcome, <span className="text-white font-semibold">{currentUser.displayName}</span>! Your account has been registered, but you need an Admin to approve your membership before you can access group reports and ledger balances.
          </p>

          <div className="p-3 bg-midnight-elevated rounded-xl border border-white/5 text-xs text-slate-400 text-left space-y-1">
            <p className="font-semibold text-slate-300">Account status:</p>
            <p>• Email: {currentUser.email}</p>
            <p>• Status: <span className="text-amber-400 font-bold">Pending Review</span></p>
          </div>

          {isDemoMode && (
            <div className="pt-2 border-t border-white/10 space-y-2">
              <p className="text-xs text-slate-400">Testing Demo Mode?</p>
              <NeonButton
                variant="primary"
                size="sm"
                className="w-full"
                leftIcon={<Sparkles className="w-4 h-4" />}
                onClick={() => switchDemoUser("user_sarah")}
              >
                Switch to Sarah (Admin) to Approve
              </NeonButton>
            </div>
          )}
        </div>
      </div>
    );
  }

  // Rejected User Gate Screen
  if (currentUser && currentUser.status === "rejected") {
    return (
      <div className="min-h-screen bg-midnight-base text-white flex flex-col items-center justify-center p-6 relative">
        <ToastContainer />
        <PersonaSwitcher />

        <div className="w-full max-w-sm bg-midnight-surface border border-neon-crimson/30 rounded-3xl p-6 text-center shadow-2xl space-y-4">
          <div className="w-14 h-14 mx-auto rounded-2xl bg-neon-crimson/20 border border-neon-crimson/40 text-red-300 flex items-center justify-center">
            <ShieldAlert className="w-7 h-7" />
          </div>

          <h2 className="text-xl font-bold font-display text-red-300">Access Denied</h2>
          <p className="text-sm text-slate-300 leading-relaxed">
            Your request to join this private Swear Jar group was not approved by an Admin.
          </p>

          {isDemoMode && (
            <NeonButton
              variant="outline"
              size="sm"
              className="w-full mt-4"
              onClick={() => switchDemoUser("user_sarah")}
            >
              Switch to Sarah (Admin)
            </NeonButton>
          )}
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-midnight-base text-slate-100 flex flex-col items-center selection:bg-neon-magenta selection:text-white">
      <ToastContainer />

      {/* Frame Container for mobile & desktop */}
      <div className="w-full max-w-md min-h-screen flex flex-col bg-midnight-base border-x border-white/5 relative shadow-2xl">
        <TopNavbar />

        <main className="flex-1 pb-24 px-4 pt-4">{children}</main>

        <BottomTabBar />
        <PersonaSwitcher />
      </div>
    </div>
  );
};
