import React from "react";
import clsx from "clsx";

interface CurrencyDisplayProps {
  amount: number;
  size?: "sm" | "md" | "lg" | "xl" | "hero";
  className?: string;
  glow?: boolean;
}

export const CurrencyDisplay: React.FC<CurrencyDisplayProps> = ({
  amount,
  size = "md",
  className,
  glow = false,
}) => {
  const formatted = new Intl.NumberFormat("en-PH", {
    minimumFractionDigits: 0,
    maximumFractionDigits: 2,
  }).format(amount);

  return (
    <div
      className={clsx(
        "inline-flex items-baseline font-display font-extrabold tracking-tight text-white",
        size === "sm" && "text-base",
        size === "md" && "text-xl",
        size === "lg" && "text-2xl",
        size === "xl" && "text-3xl",
        size === "hero" && "text-4xl sm:text-5xl",
        glow && "neon-text-glow text-pink-50",
        className
      )}
    >
      <span className="text-[0.75em] font-semibold text-slate-400 mr-1 select-none">₱</span>
      <span>{formatted}</span>
    </div>
  );
};
