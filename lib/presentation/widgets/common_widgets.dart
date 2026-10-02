import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:swear_jar/presentation/theme/app_theme.dart';
import 'package:swear_jar/domain/models/models.dart';

class NeonCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final bool hasGlow;
  final Color? borderColor;
  final Color? backgroundColor;

  const NeonCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
    this.hasGlow = false,
    this.borderColor,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(12);
    final effectiveBorderColor = borderColor ??
        (hasGlow
            ? AppColors.accentPrimary.withValues(alpha: 0.45)
            : AppColors.borderDefault);

    Widget content = Container(
      margin: margin,
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.bgSurface,
        borderRadius: radius,
        border: Border.all(
          color: effectiveBorderColor,
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.22),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
          if (hasGlow)
            BoxShadow(
              color: AppColors.accentGlow.withValues(alpha: 0.18),
              blurRadius: 18,
              spreadRadius: 0,
            ),
        ],
      ),
      child: child,
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: content,
        ),
      );
    }
    return content;
  }
}

enum NeonButtonType { primary, secondary, danger, outline, mint }

class NeonButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool isLoading;
  final NeonButtonType type;
  final double? width;

  const NeonButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.isLoading = false,
    this.type = NeonButtonType.primary,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    Color? border;
    List<BoxShadow>? shadows;

    switch (type) {
      case NeonButtonType.primary:
        bg = AppColors.accentPrimary;
        fg = Colors.white;
        border = AppColors.accentPrimary.withValues(alpha: 0.8);
        shadows = [
          BoxShadow(
            color: AppColors.accentPrimary.withValues(alpha: 0.25),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ];
        break;
      case NeonButtonType.mint:
        bg = AppColors.accentSuccess;
        fg = const Color(0xFF052E16);
        border = null;
        shadows = [
          BoxShadow(
            color: AppColors.accentSuccess.withValues(alpha: 0.22),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ];
        break;
      case NeonButtonType.secondary:
        bg = AppColors.bgSurfaceElevated;
        fg = AppColors.textPrimary;
        border = AppColors.borderDefault;
        shadows = null;
        break;
      case NeonButtonType.danger:
        bg = AppColors.accentError.withValues(alpha: 0.12);
        fg = AppColors.accentError;
        border = AppColors.accentError.withValues(alpha: 0.35);
        shadows = null;
        break;
      case NeonButtonType.outline:
        bg = Colors.transparent;
        fg = AppColors.textPrimary;
        border = AppColors.borderDefault;
        shadows = null;
        break;
    }

    final btnContent = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isLoading)
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(fg),
            ),
          )
        else ...[
          if (icon != null) ...[
            Icon(icon, size: 17, color: fg),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                color: fg,
                fontWeight: FontWeight.w600,
                fontSize: 13.5,
                letterSpacing: -0.1,
              ),
            ),
          ),
        ],
      ],
    );

    final radius = BorderRadius.circular(10);

    return Container(
      width: width,
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: onPressed != null ? shadows : null,
      ),
      child: Material(
        color: onPressed == null ? bg.withValues(alpha: 0.5) : bg,
        borderRadius: radius,
        child: InkWell(
          onTap: isLoading ? null : onPressed,
          borderRadius: radius,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
            decoration: BoxDecoration(
              borderRadius: radius,
              border: border != null ? Border.all(color: border) : null,
            ),
            alignment: Alignment.center,
            child: btnContent,
          ),
        ),
      ),
    );
  }
}

class StatusPill extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;

  const StatusPill({
    super.key,
    required this.label,
    required this.color,
    required this.icon,
  });

  factory StatusPill.fromReport(ReportStatus status) {
    switch (status) {
      case ReportStatus.confirmed:
        return const StatusPill(
          label: 'Confirmed',
          color: AppColors.accentInfo,
          icon: Icons.check_circle_outline,
        );
      case ReportStatus.rejected:
        return const StatusPill(
          label: 'Rejected',
          color: AppColors.accentError,
          icon: Icons.cancel_outlined,
        );
      case ReportStatus.pending:
        return const StatusPill(
          label: 'Pending Review',
          color: AppColors.accentWarning,
          icon: Icons.schedule_outlined,
        );
    }
  }

  factory StatusPill.fromDebt(DebtStatus status, {bool isTransferred = false}) {
    if (isTransferred && status == DebtStatus.active) {
      return const StatusPill(
        label: 'Transferred',
        color: AppColors.accentPrimary,
        icon: Icons.swap_horiz,
      );
    }
    switch (status) {
      case DebtStatus.paid:
        return const StatusPill(
          label: 'Settled',
          color: AppColors.accentSuccess,
          icon: Icons.check_circle,
        );
      case DebtStatus.dismissed:
        return const StatusPill(
          label: 'Dismissed',
          color: AppColors.textMuted,
          icon: Icons.remove_circle_outline,
        );
      case DebtStatus.active:
        return const StatusPill(
          label: 'Active Debt',
          color: AppColors.accentWarning,
          icon: Icons.pending_actions,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.28), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: GoogleFonts.inter(
              color: color,
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.1,
            ),
          ),
        ],
      ),
    );
  }
}

class CurrencyText extends StatelessWidget {
  final double amount;
  final double fontSize;
  final FontWeight fontWeight;
  final Color? color;

  const CurrencyText({
    super.key,
    required this.amount,
    this.fontSize = 24,
    this.fontWeight = FontWeight.bold,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat.currency(
      locale: 'en_PH',
      symbol: '₱',
      decimalDigits: amount % 1 == 0 ? 0 : 2,
    );

    return Text(
      formatter.format(amount),
      style: GoogleFonts.outfit(
        color: color ?? AppColors.textPrimary,
        fontSize: fontSize,
        fontWeight: fontWeight,
        letterSpacing: -0.4,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    );
  }
}

class UserAvatar extends StatelessWidget {
  final AppUser user;
  final double size;
  final bool showBadge;

  const UserAvatar({
    super.key,
    required this.user,
    this.size = 40,
    this.showBadge = true,
  });

  @override
  Widget build(BuildContext context) {
    final initials = user.displayName.isNotEmpty
        ? user.displayName
            .split(' ')
            .map((s) => s.isNotEmpty ? s[0] : '')
            .take(2)
            .join('')
            .toUpperCase()
        : 'U';

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.bgSurfaceElevated,
            border: Border.all(
              color: user.isKeeper
                  ? AppColors.accentPrimary.withValues(alpha: 0.7)
                  : AppColors.borderDefault,
              width: user.isKeeper ? 1.5 : 1,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            initials,
            style: GoogleFonts.inter(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
              fontSize: size * 0.36,
              letterSpacing: -0.3,
            ),
          ),
        ),
        if (showBadge && user.isKeeper)
          Positioned(
            right: -1,
            bottom: -1,
            child: Container(
              padding: const EdgeInsets.all(2.5),
              decoration: BoxDecoration(
                color: AppColors.accentPrimary,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.bgBase, width: 1.5),
              ),
              child: const Icon(
                Icons.shield,
                size: 9,
                color: Colors.white,
              ),
            ),
          ),
      ],
    );
  }
}

