"use client";

import React, { useState, useEffect } from "react";
import { useApp } from "../../context/AppContext";
import { useRouter } from "next/navigation";
import { Loader2 } from "lucide-react";

export default function LoginPage() {
  const { loginWithGoogle, currentUser } = useApp();
  const router = useRouter();
  const [loading, setLoading] = useState(false);

  // If already authenticated, redirect to home
  useEffect(() => {
    if (currentUser) {
      router.push("/");
    }
  }, [currentUser, router]);

  const handleConnect = async () => {
    try {
      setLoading(true);
      await loginWithGoogle();
      router.push("/");
    } catch (err) {
      console.error(err);
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="w-full flex items-center justify-center p-4">
      {/* Auth Card */}
      <div className="w-full max-w-sm bg-midnight-surface/85 backdrop-blur-xl border border-white/10 rounded-3xl p-8 shadow-[0_20px_60px_rgba(0,0,0,0.6)] flex flex-col items-center text-center space-y-6 relative overflow-hidden">
        {/* Ambient Top Glow */}
        <div className="absolute -top-16 inset-x-0 mx-auto w-36 h-36 bg-neon-magenta/20 rounded-full blur-2xl pointer-events-none" />

        {/* Jar Logo */}
        <div className="relative flex items-center justify-center">
          <div className="w-24 h-24 sm:w-28 sm:h-28 relative flex items-center justify-center">
            {/* Soft backdrop neon halo */}
            <div className="absolute inset-0 bg-gradient-to-b from-neon-magenta/30 to-neon-cyan/20 rounded-full blur-xl animate-pulse" />

            <svg
              viewBox="0 0 160 200"
              className="w-full h-full drop-shadow-[0_8px_24px_rgba(255,0,127,0.35)] relative z-10"
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

              {/* Jar Glass Body */}
              <path
                d="M 35 28 Q 25 35 20 60 L 18 165 Q 18 185 40 190 L 120 190 Q 142 185 142 165 L 140 60 Q 135 35 125 28 Z"
                fill="url(#authJarGlassGradient)"
                stroke="rgba(255, 255, 255, 0.35)"
                strokeWidth="2.5"
              />

              {/* Liquid / Coins Fill */}
              <path
                d="M 20 115 Q 45 105 80 115 T 140 115 L 142 165 Q 142 185 120 190 L 40 190 Q 18 185 18 165 Z"
                fill="url(#authJarLiquidGradient)"
                opacity="0.85"
              />

              {/* Coin Shapes inside Jar */}
              <circle cx="65" cy="148" r="14" fill="#F59E0B" stroke="#FDE68A" strokeWidth="1.5" />
              <text x="65" y="153" textAnchor="middle" fill="#78350F" fontSize="12" fontWeight="bold">₱</text>

              <circle cx="95" cy="142" r="15" fill="#FBBF24" stroke="#FEF3C7" strokeWidth="1.5" />
              <text x="95" y="147" textAnchor="middle" fill="#78350F" fontSize="13" fontWeight="bold">₱</text>

              <circle cx="80" cy="165" r="13" fill="#D97706" stroke="#FDE68A" strokeWidth="1.5" />
              <text x="80" y="170" textAnchor="middle" fill="#451A03" fontSize="11" fontWeight="bold">₱</text>

              {/* Glass Glare Highlights */}
              <path
                d="M 28 50 L 26 150"
                stroke="white"
                strokeWidth="4"
                strokeLinecap="round"
                opacity="0.4"
              />
              <path
                d="M 36 55 L 35 120"
                stroke="white"
                strokeWidth="2"
                strokeLinecap="round"
                opacity="0.2"
              />

              {/* Gradients */}
              <defs>
                <linearGradient id="authJarGlassGradient" x1="0" y1="0" x2="1" y2="1">
                  <stop offset="0%" stopColor="rgba(56, 189, 248, 0.15)" />
                  <stop offset="50%" stopColor="rgba(255, 0, 127, 0.08)" />
                  <stop offset="100%" stopColor="rgba(15, 23, 42, 0.6)" />
                </linearGradient>
                <linearGradient id="authJarLiquidGradient" x1="0" y1="0" x2="1" y2="1">
                  <stop offset="0%" stopColor="#FF007F" />
                  <stop offset="100%" stopColor="#7928CA" />
                </linearGradient>
              </defs>
            </svg>
          </div>
        </div>

        {/* Title */}
        <div className="space-y-1">
          <h1 className="text-2xl sm:text-3xl font-extrabold font-display tracking-tight text-white">
            SWEAR JAR
          </h1>
        </div>

        {/* Connect to Google Button */}
        <button
          onClick={handleConnect}
          disabled={loading}
          className="w-full py-3.5 px-5 rounded-2xl bg-white text-slate-900 font-bold text-sm flex items-center justify-center gap-3 shadow-lg hover:bg-slate-100 active:scale-[0.98] transition-all duration-200 disabled:opacity-70 disabled:cursor-not-allowed hover:shadow-[0_0_25px_rgba(255,255,255,0.35)]"
        >
          {loading ? (
            <Loader2 className="w-5 h-5 animate-spin text-slate-700" />
          ) : (
            <svg className="w-5 h-5 shrink-0" viewBox="0 0 24 24">
              <path
                fill="#4285F4"
                d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92c-.26 1.37-1.04 2.53-2.21 3.31v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.09z"
              />
              <path
                fill="#34A853"
                d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z"
              />
              <path
                fill="#FBBC05"
                d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.06H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.94l2.85-2.22.81-.63z"
              />
              <path
                fill="#EA4335"
                d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.06l3.66 2.84c.87-2.6 3.3-4.52 6.16-4.52z"
              />
            </svg>
          )}
          <span>{loading ? "Connecting..." : "Connect to Google"}</span>
        </button>
      </div>
    </div>
  );
}
