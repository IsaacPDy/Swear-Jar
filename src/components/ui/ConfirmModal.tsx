"use client";

import React, { useEffect } from "react";
import { NeonButton } from "./NeonButton";
import { AlertTriangle, Info, X } from "lucide-react";
import clsx from "clsx";

interface ConfirmModalProps {
  isOpen: boolean;
  onClose: () => void;
  onConfirm: () => void;
  title: string;
  description: React.ReactNode;
  confirmLabel?: string;
  cancelLabel?: string;
  confirmVariant?: "primary" | "destructive" | "success";
  isLoading?: boolean;
  type?: "warning" | "danger" | "info";
}

export const ConfirmModal: React.FC<ConfirmModalProps> = ({
  isOpen,
  onClose,
  onConfirm,
  title,
  description,
  confirmLabel = "Confirm",
  cancelLabel = "Cancel",
  confirmVariant = "primary",
  isLoading = false,
  type = "warning",
}) => {
  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      if (e.key === "Escape" && isOpen && !isLoading) {
        onClose();
      }
    };
    window.addEventListener("keydown", handleKeyDown);
    return () => window.removeEventListener("keydown", handleKeyDown);
  }, [isOpen, isLoading, onClose]);

  if (!isOpen) return null;

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4">
      {/* Backdrop */}
      <div
        className="fixed inset-0 bg-black/75 backdrop-blur-sm transition-opacity"
        onClick={() => !isLoading && onClose()}
      />

      {/* Modal Card */}
      <div className="relative w-full max-w-md bg-midnight-elevated border border-white/15 rounded-3xl p-6 shadow-2xl z-10 animate-in fade-in zoom-in-95 duration-200">
        <div className="flex items-start justify-between gap-3 mb-4">
          <div className="flex items-center gap-3">
            <div
              className={clsx(
                "p-2.5 rounded-2xl shrink-0",
                type === "danger" && "bg-neon-crimson/20 text-red-400 border border-neon-crimson/30",
                type === "warning" && "bg-neon-amber/20 text-amber-300 border border-neon-amber/30",
                type === "info" && "bg-neon-info/20 text-sky-300 border border-neon-info/30"
              )}
            >
              {type === "danger" || type === "warning" ? (
                <AlertTriangle className="w-5 h-5" />
              ) : (
                <Info className="w-5 h-5" />
              )}
            </div>
            <h3 className="text-lg font-bold text-white leading-snug">{title}</h3>
          </div>

          <button
            onClick={onClose}
            disabled={isLoading}
            className="text-slate-400 hover:text-white p-1 rounded-lg hover:bg-white/5 transition-colors disabled:opacity-50"
            aria-label="Close"
          >
            <X className="w-5 h-5" />
          </button>
        </div>

        <div className="text-sm text-slate-300 mb-6 leading-relaxed bg-midnight-surface/60 p-4 rounded-2xl border border-white/5">
          {description}
        </div>

        <div className="flex items-center justify-end gap-3">
          <NeonButton
            variant="ghost"
            size="md"
            onClick={onClose}
            disabled={isLoading}
          >
            {cancelLabel}
          </NeonButton>
          <NeonButton
            variant={confirmVariant}
            size="md"
            onClick={onConfirm}
            isLoading={isLoading}
          >
            {confirmLabel}
          </NeonButton>
        </div>
      </div>
    </div>
  );
};
