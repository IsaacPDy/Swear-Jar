import React from "react";
import clsx from "clsx";
import { Loader2 } from "lucide-react";

interface NeonButtonProps extends React.ButtonHTMLAttributes<HTMLButtonElement> {
  variant?: "primary" | "secondary" | "success" | "destructive" | "outline" | "ghost";
  size?: "sm" | "md" | "lg";
  isLoading?: boolean;
  leftIcon?: React.ReactNode;
  rightIcon?: React.ReactNode;
}

export const NeonButton: React.FC<NeonButtonProps> = ({
  children,
  className,
  variant = "primary",
  size = "md",
  isLoading = false,
  leftIcon,
  rightIcon,
  disabled,
  ...props
}) => {
  return (
    <button
      disabled={disabled || isLoading}
      className={clsx(
        "inline-flex items-center justify-center font-medium rounded-xl transition-all duration-200 active:scale-[0.98] disabled:opacity-50 disabled:pointer-events-none disabled:cursor-not-allowed",
        // Sizes
        size === "sm" && "px-3 py-1.5 text-xs gap-1.5",
        size === "md" && "px-4 py-2.5 text-sm gap-2",
        size === "lg" && "px-6 py-3.5 text-base gap-2.5 font-semibold",
        // Variants
        variant === "primary" &&
          "bg-neon-magenta text-white hover:bg-neon-magenta-hover shadow-neon-magenta hover:shadow-neon-magenta-lg",
        variant === "secondary" &&
          "bg-midnight-elevated text-white hover:bg-[#253254] border border-white/10",
        variant === "success" &&
          "bg-neon-mint text-slate-950 font-semibold hover:bg-[#0ea372] shadow-neon-mint",
        variant === "destructive" &&
          "bg-neon-crimson/20 border border-neon-crimson/50 text-red-200 hover:bg-neon-crimson/30",
        variant === "outline" &&
          "bg-transparent border border-white/15 text-white hover:border-neon-magenta/60 hover:text-neon-magenta",
        variant === "ghost" &&
          "bg-transparent text-slate-300 hover:text-white hover:bg-white/5",
        className
      )}
      {...props}
    >
      {isLoading ? (
        <Loader2 className="w-4 h-4 animate-spin shrink-0" />
      ) : (
        leftIcon && <span className="shrink-0">{leftIcon}</span>
      )}
      <span>{children}</span>
      {!isLoading && rightIcon && <span className="shrink-0">{rightIcon}</span>}
    </button>
  );
};
