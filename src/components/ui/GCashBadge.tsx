"use client";

import React, { useState } from "react";
import { Check, Copy, Smartphone } from "lucide-react";
import clsx from "clsx";

interface GCashBadgeProps {
  number: string;
  name?: string;
  className?: string;
}

export const GCashBadge: React.FC<GCashBadgeProps> = ({ number, name, className }) => {
  const [copied, setCopied] = useState(false);

  const handleCopy = async (e: React.MouseEvent) => {
    e.stopPropagation();
    try {
      await navigator.clipboard.writeText(number.replace(/\s+/g, ""));
      setCopied(true);
      setTimeout(() => setCopied(false), 2000);
    } catch {
      // Fallback
    }
  };

  return (
    <button
      onClick={handleCopy}
      type="button"
      className={clsx(
        "inline-flex items-center gap-1.5 px-3 py-1.5 rounded-lg bg-sky-950/60 border border-sky-500/30 text-sky-200 text-xs font-medium hover:bg-sky-900/60 hover:border-sky-400 transition-all duration-150 group active:scale-95",
        className
      )}
      title="Tap to copy GCash number"
    >
      <Smartphone className="w-3.5 h-3.5 text-sky-400 shrink-0" />
      <span className="font-semibold text-sky-300">GCash:</span>
      <span className="font-mono tracking-wider">{number}</span>
      <span className="ml-1 text-sky-400/70 group-hover:text-sky-300">
        {copied ? (
          <Check className="w-3.5 h-3.5 text-emerald-400 animate-pulse" />
        ) : (
          <Copy className="w-3.5 h-3.5" />
        )}
      </span>
    </button>
  );
};
