import type { Config } from "tailwindcss";

const config: Config = {
  content: [
    "./src/pages/**/*.{js,ts,jsx,tsx,mdx}",
    "./src/components/**/*.{js,ts,jsx,tsx,mdx}",
    "./src/app/**/*.{js,ts,jsx,tsx,mdx}",
  ],
  theme: {
    extend: {
      colors: {
        midnight: {
          base: "#0B0F19",
          surface: "#131B2E",
          elevated: "#1C2640",
          card: "#121829",
          border: "rgba(255, 255, 255, 0.08)",
          "border-focus": "rgba(255, 0, 127, 0.4)",
        },
        neon: {
          magenta: "#FF007F",
          "magenta-hover": "#E60072",
          "magenta-glow": "rgba(255, 0, 127, 0.35)",
          info: "#38BDF8",
          mint: "#10B981",
          amber: "#F59E0B",
          crimson: "#EF4444",
        },
      },
      fontFamily: {
        sans: ["var(--font-inter)", "Inter", "sans-serif"],
        display: ["var(--font-outfit)", "Outfit", "sans-serif"],
        mono: ["var(--font-jetbrains)", "JetBrains Mono", "monospace"],
      },
      boxShadow: {
        "neon-magenta": "0 0 20px rgba(255, 0, 127, 0.35)",
        "neon-magenta-lg": "0 0 35px rgba(255, 0, 127, 0.5)",
        "neon-mint": "0 0 20px rgba(16, 185, 129, 0.35)",
        "neon-amber": "0 0 20px rgba(245, 158, 11, 0.35)",
        "neon-info": "0 0 20px rgba(56, 189, 248, 0.35)",
        "card-subtle": "0 8px 32px 0 rgba(0, 0, 0, 0.37)",
      },
      keyframes: {
        "jar-shake": {
          "0%, 100%": { transform: "rotate(0deg)" },
          "20%": { transform: "rotate(-8deg)" },
          "40%": { transform: "rotate(8deg)" },
          "60%": { transform: "rotate(-5deg)" },
          "80%": { transform: "rotate(5deg)" },
        },
        "coin-drop": {
          "0%": { transform: "translateY(-40px) scale(0.6)", opacity: "0" },
          "50%": { opacity: "1" },
          "100%": { transform: "translateY(0) scale(1)", opacity: "1" },
        },
        "pulse-glow": {
          "0%, 100%": { boxShadow: "0 0 15px rgba(255, 0, 127, 0.3)" },
          "50%": { boxShadow: "0 0 30px rgba(255, 0, 127, 0.6)" },
        },
      },
      animation: {
        "jar-shake": "jar-shake 0.35s ease-in-out",
        "coin-drop": "coin-drop 0.4s cubic-bezier(0.175, 0.885, 0.32, 1.275)",
        "pulse-glow": "pulse-glow 2.5s infinite",
      },
    },
  },
  plugins: [],
};

export default config;
