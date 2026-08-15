"use client";

import React from "react";
import Link from "next/link";
import { usePathname } from "next/navigation";
import { useApp } from "../../context/AppContext";
import { Home, FileText, Plus, Landmark, User as UserIcon } from "lucide-react";
import clsx from "clsx";

export const BottomTabBar: React.FC = () => {
  const pathname = usePathname();
  const { reports, isKeeper, isAdmin } = useApp();

  // Pending reviews count (visible to Keeper or Admin)
  const pendingCount = reports.filter((r) => r.status === "pending").length;
  const showPendingBadge = (isKeeper || isAdmin) && pendingCount > 0;

  const tabs = [
    {
      label: "Home",
      href: "/",
      icon: Home,
      isActive: pathname === "/",
    },
    {
      label: "Reports",
      href: "/reports",
      icon: FileText,
      isActive: pathname === "/reports",
      badge: showPendingBadge ? pendingCount : null,
    },
    {
      label: "Report",
      href: "/report",
      icon: Plus,
      isCenterAction: true,
      isActive: pathname === "/report",
    },
    {
      label: "Jar",
      href: "/jar",
      icon: Landmark,
      isActive: pathname === "/jar",
    },
    {
      label: "Profile",
      href: "/profile",
      icon: UserIcon,
      isActive: pathname === "/profile",
    },
  ];

  return (
    <nav className="fixed bottom-0 left-0 right-0 z-30 bg-midnight-base/95 backdrop-blur-xl border-t border-white/10 px-2 py-2">
      <div className="flex items-center justify-around max-w-md mx-auto relative">
        {tabs.map((tab) => {
          if (tab.isCenterAction) {
            return (
              <div key={tab.href} className="relative -top-5 flex flex-col items-center">
                <Link
                  href={tab.href}
                  className={clsx(
                    "w-13 h-13 p-3 rounded-full bg-gradient-to-tr from-neon-magenta to-[#ff409f] text-white flex items-center justify-center shadow-neon-magenta hover:shadow-neon-magenta-lg hover:scale-105 active:scale-95 transition-all border-2 border-midnight-base animate-pulse-glow",
                    tab.isActive && "ring-2 ring-pink-300"
                  )}
                  aria-label="Report Swear"
                >
                  <Plus className="w-6 h-6 stroke-[2.5]" />
                </Link>
                <span
                  className={clsx(
                    "text-[10px] font-bold mt-1 tracking-tight transition-colors",
                    tab.isActive ? "text-neon-magenta" : "text-slate-400"
                  )}
                >
                  Report
                </span>
              </div>
            );
          }

          const Icon = tab.icon;

          return (
            <Link
              key={tab.href}
              href={tab.href}
              className={clsx(
                "flex flex-col items-center justify-center py-1 px-3 rounded-xl transition-all relative",
                tab.isActive
                  ? "text-neon-magenta"
                  : "text-slate-400 hover:text-slate-200"
              )}
            >
              <div className="relative">
                <Icon className={clsx("w-5 h-5", tab.isActive && "stroke-[2.5]")} />
                {tab.badge && (
                  <span className="absolute -top-1.5 -right-2.5 bg-neon-amber text-slate-950 text-[10px] font-extrabold w-4 h-4 rounded-full flex items-center justify-center shadow-neon-amber animate-pulse">
                    {tab.badge}
                  </span>
                )}
              </div>
              <span
                className={clsx(
                  "text-[10px] font-medium mt-1 tracking-tight",
                  tab.isActive && "font-bold text-white"
                )}
              >
                {tab.label}
              </span>
            </Link>
          );
        })}
      </div>
    </nav>
  );
};
