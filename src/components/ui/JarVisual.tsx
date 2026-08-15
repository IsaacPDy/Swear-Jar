"use client";

import React, { useState } from "react";
import clsx from "clsx";
import confetti from "canvas-confetti";

interface JarVisualProps {
  fillLevel?: number; // 0 to 100
  isShaking?: boolean;
  totalSwears?: number;
  className?: string;
  onTap?: () => void;
  interactive?: boolean;
}

export const JarVisual: React.FC<JarVisualProps> = ({
  fillLevel = 45,
  isShaking = false,
  totalSwears,
  className,
  onTap,
  interactive = true,
}) => {
  const [localShake, setLocalShake] = useState(false);

  const handleClick = () => {
    if (!interactive) return;
    setLocalShake(true);
    setTimeout(() => setLocalShake(false), 400);

    // Fire minor coin sparkle confetti
    confetti({
      particleCount: 15,
      spread: 60,
      origin: { y: 0.6 },
      colors: ["#FF007F", "#F59E0B", "#38BDF8", "#10B981"],
    });

    if (onTap) onTap();
  };

  const clampedFill = Math.max(10, Math.min(90, fillLevel));

  return (
    <div
      onClick={handleClick}
      className={clsx(
        "relative flex flex-col items-center justify-center select-none transition-transform",
        interactive && "cursor-pointer active:scale-95 group",
        (isShaking || localShake) && "animate-jar-shake",
        className
      )}
      title={interactive ? "Tap the jar!" : undefined}
    >
      {/* Jar Glass Container SVG */}
      <div className="relative w-36 h-48 sm:w-44 sm:h-56 flex items-center justify-center">
        {/* Neon Glow Aura Behind Jar */}
        <div className="absolute inset-0 bg-neon-magenta/20 rounded-full blur-2xl group-hover:bg-neon-magenta/30 transition-all" />

        <svg
          viewBox="0 0 160 200"
          className="w-full h-full drop-shadow-[0_10px_20px_rgba(0,0,0,0.5)] z-10"
          fill="none"
          xmlns="http://www.w3.org/2000/svg"
        >
          {/* Jar Lid */}
          <rect
            x="45"
            y="10"
            width="70"
            height="14"
            rx="4"
            fill="#334155"
            stroke="#64748B"
            strokeWidth="2"
          />
          <rect
            x="40"
            y="20"
            width="80"
            height="8"
            rx="3"
            fill="#475569"
            stroke="#94A3B8"
            strokeWidth="1.5"
          />

          {/* Jar Body Outline with Glass Gloss */}
          <path
            d="M 35 28 
               Q 25 35 20 60 
               L 18 165 
               Q 18 185 40 190 
               L 120 190 
               Q 142 185 142 165 
               L 140 60 
               Q 135 35 125 28 
               Z"
            fill="url(#glassGradient)"
            stroke="rgba(255, 255, 255, 0.25)"
            strokeWidth="3"
          />

          {/* Liquid / Coin Level Background */}
          <defs>
            <linearGradient id="glassGradient" x1="0%" y1="0%" x2="100%" y2="100%">
              <stop offset="0%" stopColor="rgba(255, 255, 255, 0.15)" />
              <stop offset="50%" stopColor="rgba(28, 38, 64, 0.5)" />
              <stop offset="100%" stopColor="rgba(19, 27, 46, 0.85)" />
            </linearGradient>

            <linearGradient id="coinFillGradient" x1="0%" y1="0%" x2="0%" y2="100%">
              <stop offset="0%" stopColor="#F59E0B" />
              <stop offset="50%" stopColor="#D97706" />
              <stop offset="100%" stopColor="#B45309" />
            </linearGradient>

            <clipPath id="jarClip">
              <path
                d="M 35 28 
                   Q 25 35 20 60 
                   L 18 165 
                   Q 18 185 40 190 
                   L 120 190 
                   Q 142 185 142 165 
                   L 140 60 
                   Q 135 35 125 28 
                   Z"
              />
            </clipPath>
          </defs>

          {/* Coin Fill Block (Clipped inside Jar) */}
          <g clipPath="url(#jarClip)">
            {/* Liquid / Gold Coins Base Level */}
            <rect
              x="10"
              y={190 - clampedFill * 1.5}
              width="140"
              height={clampedFill * 1.5 + 20}
              fill="url(#coinFillGradient)"
              opacity="0.85"
            />

            {/* Render Decorative Coins inside */}
            <circle cx="50" cy="165" r="14" fill="#FBBF24" stroke="#D97706" strokeWidth="2" />
            <text x="50" y="170" fill="#78350F" fontSize="12" fontWeight="bold" textAnchor="middle">₱</text>

            <circle cx="95" cy="168" r="15" fill="#FDE68A" stroke="#F59E0B" strokeWidth="2" />
            <text x="95" y="173" fill="#78350F" fontSize="13" fontWeight="bold" textAnchor="middle">₱</text>

            <circle cx="75" cy="145" r="13" fill="#FBBF24" stroke="#D97706" strokeWidth="2" />
            <text x="75" y="150" fill="#78350F" fontSize="11" fontWeight="bold" textAnchor="middle">₱</text>

            {clampedFill > 40 && (
              <>
                <circle cx="45" cy="130" r="12" fill="#FDE68A" stroke="#F59E0B" strokeWidth="1.5" />
                <text x="45" y="134" fill="#78350F" fontSize="10" fontWeight="bold" textAnchor="middle">₱</text>

                <circle cx="105" cy="135" r="14" fill="#FBBF24" stroke="#D97706" strokeWidth="2" />
                <text x="105" y="140" fill="#78350F" fontSize="12" fontWeight="bold" textAnchor="middle">₱</text>
              </>
            )}

            {clampedFill > 60 && (
              <>
                <circle cx="70" cy="110" r="14" fill="#FDE68A" stroke="#F59E0B" strokeWidth="2" />
                <text x="70" y="115" fill="#78350F" fontSize="12" fontWeight="bold" textAnchor="middle">₱</text>
              </>
            )}
          </g>

          {/* Glass Highlight Reflection Stroke */}
          <path
            d="M 32 65 Q 30 110 32 160"
            stroke="rgba(255, 255, 255, 0.45)"
            strokeWidth="4"
            strokeLinecap="round"
          />
          <path
            d="M 40 60 Q 38 90 40 120"
            stroke="rgba(255, 255, 255, 0.2)"
            strokeWidth="2"
            strokeLinecap="round"
          />

          {/* Jar Label Banner */}
          <rect
            x="32"
            y="85"
            width="96"
            height="32"
            rx="6"
            fill="#131B2E"
            stroke="#FF007F"
            strokeWidth="1.5"
            className="shadow-sm"
          />
          <text
            x="80"
            y="105"
            fill="#FF007F"
            fontSize="10"
            fontWeight="bold"
            letterSpacing="1.5"
            textAnchor="middle"
            className="select-none font-display font-extrabold"
          >
            SWEAR JAR
          </text>
        </svg>
      </div>

      {totalSwears !== undefined && (
        <div className="mt-2 text-center">
          <span className="text-xs font-semibold text-slate-400 bg-midnight-elevated/80 px-3 py-1 rounded-full border border-white/10">
            {totalSwears} {totalSwears === 1 ? "Swear" : "Swears"} Tracked
          </span>
        </div>
      )}
    </div>
  );
};
