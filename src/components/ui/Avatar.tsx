import React from "react";
import { User, Role } from "../../lib/domain/types";
import { getInitials } from "../../lib/utils/formatters";
import { Crown, Zap } from "lucide-react";
import clsx from "clsx";

interface AvatarProps {
  user?: Partial<User> | null;
  name?: string;
  photoURL?: string | null;
  roles?: Role[];
  size?: "sm" | "md" | "lg" | "xl";
  className?: string;
  showBadges?: boolean;
}

export const Avatar: React.FC<AvatarProps> = ({
  user,
  name,
  photoURL,
  roles,
  size = "md",
  className,
  showBadges = true,
}) => {
  const displayName = user?.displayName || name || "Anonymous";
  const avatarUrl = user?.photoURL !== undefined ? user.photoURL : photoURL;
  const userRoles = user?.roles || roles || [];

  const isKeeper = userRoles.includes("keeper");
  const isAdmin = userRoles.includes("admin");

  return (
    <div className={clsx("relative inline-block shrink-0", className)}>
      <div
        className={clsx(
          "rounded-full flex items-center justify-center font-bold font-sans overflow-hidden border-2 transition-all",
          isKeeper ? "border-amber-400/80 shadow-[0_0_12px_rgba(245,158,11,0.4)]" : "border-white/15",
          size === "sm" && "w-8 h-8 text-xs",
          size === "md" && "w-10 h-10 text-sm",
          size === "lg" && "w-14 h-14 text-base",
          size === "xl" && "w-20 h-20 text-xl",
          "bg-midnight-elevated text-white"
        )}
      >
        {avatarUrl ? (
          // eslint-disable-next-line @next/next/no-img-element
          <img
            src={avatarUrl}
            alt={displayName}
            className="w-full h-full object-cover"
          />
        ) : (
          <span>{getInitials(displayName)}</span>
        )}
      </div>

      {showBadges && (
        <div className="absolute -bottom-1 -right-1 flex items-center gap-0.5 pointer-events-none">
          {isKeeper && (
            <span
              className="bg-amber-500 text-slate-950 p-0.5 rounded-full ring-2 ring-midnight-base shadow-sm"
              title="Active Keeper"
            >
              <Crown className={size === "sm" ? "w-2.5 h-2.5" : "w-3.5 h-3.5"} />
            </span>
          )}
          {isAdmin && !isKeeper && (
            <span
              className="bg-neon-magenta text-white p-0.5 rounded-full ring-2 ring-midnight-base shadow-sm"
              title="Admin"
            >
              <Zap className={size === "sm" ? "w-2.5 h-2.5" : "w-3.5 h-3.5"} />
            </span>
          )}
        </div>
      )}
    </div>
  );
};
