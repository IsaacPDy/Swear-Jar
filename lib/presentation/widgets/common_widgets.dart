import 'dart:math' as math;
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
  final double borderRadius;

  const NeonCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
    this.hasGlow = false,
    this.borderColor,
    this.backgroundColor,
    this.borderRadius = 16,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(borderRadius);
    final effectiveBorderColor = borderColor ??
        (hasGlow
            ? AppColors.accentPrimary.withValues(alpha: 0.45)
            : AppColors.borderDefault);

    Widget content = Container(
      margin: margin,
      padding: padding ?? const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.bgSurface,
        borderRadius: radius,
        border: Border.all(
          color: effectiveBorderColor,
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.28),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
          if (hasGlow)
            BoxShadow(
              color: AppColors.accentGlow,
              blurRadius: 20,
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
  final EdgeInsetsGeometry? padding;

  const NeonButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.isLoading = false,
    this.type = NeonButtonType.primary,
    this.width,
    this.padding,
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
        fg = AppColors.onAccentPrimary;
        border = AppColors.accentPrimary;
        shadows = [
          BoxShadow(
            color: AppColors.accentPrimary.withValues(alpha: 0.18),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ];
        break;
      case NeonButtonType.mint:
        bg = AppColors.accentMint;
        fg = const Color(0xFF072116);
        border = null;
        shadows = [
          BoxShadow(
            color: AppColors.accentMint.withValues(alpha: 0.20),
            blurRadius: 10,
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
              style: GoogleFonts.plusJakartaSans(
                color: fg,
                fontWeight: FontWeight.w700,
                fontSize: 14,
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
        color: onPressed == null ? bg.withValues(alpha: 0.45) : bg,
        borderRadius: radius,
        child: InkWell(
          onTap: isLoading ? null : onPressed,
          borderRadius: radius,
          child: Container(
            padding: padding ??
                const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
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

class StepNumberBadge extends StatelessWidget {
  final int number;
  final double size;

  const StepNumberBadge({
    super.key,
    required this.number,
    this.size = 28,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: AppColors.accentPrimary,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        '$number',
        style: GoogleFonts.plusJakartaSans(
          color: AppColors.onAccentPrimary,
          fontSize: size * 0.5,
          fontWeight: FontWeight.w800,
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
          color: AppColors.accentMint,
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
          color: AppColors.accentPrimary,
          icon: Icons.schedule_outlined,
        );
    }
  }

  factory StatusPill.fromDebt(
    DebtStatus status, {
    bool isTransferred = false,
    bool isPartiallyPaid = false,
  }) {
    if (isTransferred && status == DebtStatus.active) {
      return StatusPill(
        label: isPartiallyPaid ? 'Partial Bounty' : 'Transferred',
        color: AppColors.accentInfo,
        icon: Icons.swap_horiz,
      );
    }
    if (isPartiallyPaid && status == DebtStatus.active) {
      return const StatusPill(
        label: 'Partial Paid',
        color: AppColors.accentWarning,
        icon: Icons.pie_chart_outline_rounded,
      );
    }
    switch (status) {
      case DebtStatus.paid:
        return const StatusPill(
          label: 'Settled',
          color: AppColors.accentMint,
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
          label: 'To Be Received',
          color: AppColors.accentPrimary,
          icon: Icons.pending_actions,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.32), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                color: color,
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.1,
              ),
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
      style: GoogleFonts.plusJakartaSans(
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
    this.size = 42,
    this.showBadge = false,
  });

  static String initialsFor(String displayName) {
    final cleaned = displayName.split('(').first.trim();
    if (cleaned.isEmpty) return 'U';
    final parts =
        cleaned.split(RegExp(r'\s+')).where((s) => s.isNotEmpty).toList();
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    final word = parts.first;
    if (word.length >= 2) {
      return word.substring(0, 2).toUpperCase();
    }
    return word[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final initials = initialsFor(user.displayName);
    final bgColor = AppColors.avatarColorFor(
      user.displayName.isNotEmpty ? user.displayName : user.id,
    );

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: bgColor,
          ),
          alignment: Alignment.center,
          child: Text(
            initials,
            style: GoogleFonts.plusJakartaSans(
              color: AppColors.onAccentPrimary,
              fontWeight: FontWeight.w800,
              fontSize: size * 0.35,
              letterSpacing: -0.3,
            ),
          ),
        ),
        if (showBadge && user.isKeeper)
          Positioned(
            right: -2,
            bottom: -2,
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
                color: AppColors.onAccentPrimary,
              ),
            ),
          ),
      ],
    );
  }
}

/// Custom-painted Mason Jar icon with gold coins inside (used in the top-left sidebar logo).
class SwearJarBrandIcon extends StatelessWidget {
  final double size;

  const SwearJarBrandIcon({super.key, this.size = 30});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _SwearJarBrandPainter(),
      ),
    );
  }
}

class _SwearJarBrandPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final strokePaint = Paint()
      ..color = AppColors.accentPrimary
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.065
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fillPaint = Paint()
      ..color = const Color(0xFF1A222B)
      ..style = PaintingStyle.fill;

    // Jar body
    final bodyRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.16, h * 0.24, w * 0.68, h * 0.68),
      Radius.circular(w * 0.15),
    );
    canvas.drawRRect(bodyRect, fillPaint);
    canvas.drawRRect(bodyRect, strokePaint);

    // Jar neck / lid
    final lidRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.24, h * 0.10, w * 0.52, h * 0.12),
      Radius.circular(w * 0.04),
    );
    canvas.drawRRect(lidRect, fillPaint);
    canvas.drawRRect(lidRect, strokePaint);

    // Lid ridges
    canvas.drawLine(
      Offset(w * 0.24, h * 0.16),
      Offset(w * 0.76, h * 0.16),
      strokePaint..strokeWidth = w * 0.045,
    );

    // Coins inside jar
    final coinPaint = Paint()
      ..color = const Color(0xFFF5B851)
      ..style = PaintingStyle.fill;
    final coinHighlight = Paint()
      ..color = AppColors.accentPrimary
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(w * 0.38, h * 0.70), w * 0.10, coinPaint);
    canvas.drawCircle(Offset(w * 0.58, h * 0.72), w * 0.11, coinHighlight);
    canvas.drawCircle(Offset(w * 0.48, h * 0.56), w * 0.095, coinPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Custom-painted tilted glass Swear Jar with golden coins and mint sparkle lines
/// matching the top-right header illustration in the reference design.
class SwearJarHeroIllustration extends StatelessWidget {
  final double width;
  final double height;

  const SwearJarHeroIllustration({
    super.key,
    this.width = 136,
    this.height = 104,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: CustomPaint(
        painter: _SwearJarHeroPainter(),
      ),
    );
  }
}

class _SwearJarHeroPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 1. Mint-green sparkle lines on the left side
    final sparklePaint = Paint()
      ..color = AppColors.accentMint
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    // Top-left diagonal ray
    canvas.drawLine(
      Offset(w * 0.22, h * 0.16),
      Offset(w * 0.13, h * 0.06),
      sparklePaint,
    );
    // Middle-left horizontal/slightly angled ray
    canvas.drawLine(
      Offset(w * 0.17, h * 0.36),
      Offset(w * 0.05, h * 0.31),
      sparklePaint,
    );
    // Bottom-left angled ray
    canvas.drawLine(
      Offset(w * 0.20, h * 0.54),
      Offset(w * 0.09, h * 0.60),
      sparklePaint,
    );

    // 2. Tilted Glass Mason Jar on the right
    canvas.save();
    canvas.translate(w * 0.62, h * 0.58);
    canvas.rotate(14 * math.pi / 180);

    final jarW = w * 0.50;
    final jarH = h * 0.76;

    final glassFill = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          const Color(0xFF283747).withValues(alpha: 0.65),
          const Color(0xFF16202B).withValues(alpha: 0.85),
        ],
      ).createShader(
        Rect.fromCenter(center: Offset.zero, width: jarW, height: jarH),
      );

    final glassBorder = Paint()
      ..color = const Color(0xFF3A4D63)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final bodyRRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(0, jarH * 0.08),
        width: jarW,
        height: jarH * 0.82,
      ),
      const Radius.circular(14),
    );
    canvas.drawRRect(bodyRRect, glassFill);
    canvas.drawRRect(bodyRRect, glassBorder);

    // Glass shine streak on left of jar
    final shinePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.10)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(-jarW * 0.34, -jarH * 0.18),
      Offset(-jarW * 0.34, jarH * 0.28),
      shinePaint,
    );

    // Golden coins inside the jar
    final coinDark = Paint()
      ..color = const Color(0xFFD99B38)
      ..style = PaintingStyle.fill;
    final coinBright = Paint()
      ..color = const Color(0xFFF5BA54)
      ..style = PaintingStyle.fill;
    final coinSoft = Paint()
      ..color = AppColors.accentPrimary
      ..style = PaintingStyle.fill;

    final coinPositions = [
      (Offset(-jarW * 0.18, jarH * 0.32), jarW * 0.13, coinDark),
      (Offset(jarW * 0.06, jarH * 0.35), jarW * 0.14, coinBright),
      (Offset(jarW * 0.22, jarH * 0.26), jarW * 0.12, coinDark),
      (Offset(-jarW * 0.05, jarH * 0.18), jarW * 0.13, coinSoft),
      (Offset(jarW * 0.16, jarH * 0.08), jarW * 0.125, coinBright),
      (Offset(-jarW * 0.16, -jarH * 0.02), jarW * 0.115, coinBright),
    ];

    for (final (offset, radius, paint) in coinPositions) {
      canvas.drawCircle(offset, radius, paint);
    }

    // Jar Neck / Rim
    final neckRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(0, -jarH * 0.36),
        width: jarW * 0.82,
        height: jarH * 0.14,
      ),
      const Radius.circular(5),
    );
    final neckFill = Paint()
      ..color = const Color(0xFF243342)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(neckRect, neckFill);
    canvas.drawRRect(neckRect, glassBorder);

    // Top Lip
    final lipRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(0, -jarH * 0.43),
        width: jarW * 0.90,
        height: jarH * 0.07,
      ),
      const Radius.circular(4),
    );
    canvas.drawRRect(lipRect, neckFill);
    canvas.drawRRect(lipRect, glassBorder);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
