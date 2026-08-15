"use client";

import React from "react";
import { useApp } from "../../context/AppContext";
import { CheckCircle2, AlertTriangle, AlertCircle, Info, X } from "lucide-react";
import clsx from "clsx";

export const ToastContainer: React.FC = () => {
  const { toasts, removeToast } = useApp();

  if (toasts.length === 0) return null;

  return (
    <div className="fixed top-4 right-4 z-50 flex flex-col gap-2 max-w-sm w-full px-4 pointer-events-none">
      {toasts.map((t) => {
        const isSuccess = t.type === "success";
        const isError = t.type === "error";
        const isWarning = t.type === "warning";

        return (
          <div
            key={t.id}
            className={clsx(
              "pointer-events-auto flex items-start gap-3 p-3.5 rounded-xl border text-sm shadow-xl transition-all duration-300 transform translate-y-0",
              isSuccess && "bg-[#10B981]/15 border-[#10B981]/40 text-[#ECFDF5] shadow-neon-mint/20",
              isError && "bg-[#EF4444]/15 border-[#EF4444]/40 text-[#FEF2F2]",
              isWarning && "bg-[#F59E0B]/15 border-[#F59E0B]/40 text-[#FFFBEB] shadow-neon-amber/20",
              !isSuccess && !isError && !isWarning && "bg-[#131B2E] border-white/10 text-white shadow-neon-magenta/10"
            )}
          >
            <div className="mt-0.5 shrink-0">
              {isSuccess && <CheckCircle2 className="w-4 h-4 text-[#10B981]" />}
              {isError && <AlertCircle className="w-4 h-4 text-[#EF4444]" />}
              {isWarning && <AlertTriangle className="w-4 h-4 text-[#F59E0B]" />}
              {!isSuccess && !isError && !isWarning && <Info className="w-4 h-4 text-[#38BDF8]" />}
            </div>

            <p className="flex-1 text-xs font-medium leading-relaxed">{t.message}</p>

            <button
              onClick={() => removeToast(t.id)}
              className="text-white/50 hover:text-white transition-colors shrink-0 p-0.5"
              aria-label="Close notification"
            >
              <X className="w-3.5 h-3.5" />
            </button>
          </div>
        );
      })}
    </div>
  );
};
