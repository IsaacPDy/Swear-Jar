import React from "react";
import clsx from "clsx";

interface NeonCardProps extends React.HTMLAttributes<HTMLDivElement> {
  children: React.ReactNode;
  className?: string;
  glow?: "none" | "magenta" | "mint" | "amber" | "info";
  variant?: "surface" | "elevated" | "interactive";
}

export const NeonCard: React.FC<NeonCardProps> = ({
  children,
  className,
  glow = "none",
  variant = "surface",
  ...props
}) => {
  return (
    <div
      className={clsx(
        "rounded-2xl border transition-all duration-200",
        variant === "surface" && "bg-midnight-surface/90 border-midnight-border",
        variant === "elevated" && "bg-midnight-elevated/95 border-white/10 shadow-lg",
        variant === "interactive" &&
          "bg-midnight-surface/90 border-midnight-border hover:border-white/20 hover:bg-midnight-surface cursor-pointer",
        glow === "magenta" && "border-neon-magenta/40 shadow-neon-magenta",
        glow === "mint" && "border-neon-mint/40 shadow-neon-mint",
        glow === "amber" && "border-neon-amber/40 shadow-neon-amber",
        glow === "info" && "border-neon-info/40 shadow-neon-info",
        className
      )}
      {...props}
    >
      {children}
    </div>
  );
};
