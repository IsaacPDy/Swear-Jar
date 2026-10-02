import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppBreakpoints {
  static const double desktop = 900.0;

  static bool isDesktop(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= desktop;
}

class AppColors {
  // Deep Obsidian-Teal & Slate surfaces from reference design
  static const bgBase = Color(0xFF0B1015);
  static const bgSidebar = Color(0xFF0E151B);
  static const bgSurface = Color(0xFF121A22);
  static const bgSurfaceElevated = Color(0xFF17212B);
  static const bgSurfaceSubtle = Color(0xFF141D26);

  // High-contrast crisp typography
  static const textPrimary = Color(0xFFF8FAFC);
  static const textSecondary = Color(0xFF8C9BAE);
  static const textMuted = Color(0xFF64748B);
  static const onAccentPrimary = Color(0xFF111820);

  // Subtle architectural borders
  static const borderDefault = Color(0xFF1F2B37);
  static const borderFocus = Color(0x99F7CE96); // 60% warm cream-gold
  static const borderSubtle = Color(0xFF19232E);
  static const borderMint = Color(0xFF28524A);

  // Warm Cream-Gold primary accent & Mint-Teal secondary accent from reference
  static const accentPrimary = Color(0xFFF7CE96); // Warm cream-peach-gold
  static const accentGoldMuted = Color(0xFFE5B869); // Overline gold
  static const accentNavPill = Color(0xFF2B2820); // Active sidebar tab fill
  static const accentGlow = Color(0x2EF7CE96); // Subtle warm glow

  static const accentMint = Color(0xFF56E39F); // Mint-teal counter & icons
  static const accentSuccess = Color(0xFF56E39F); // Mint-emerald
  static const accentWarning = Color(0xFFF6D067); // Warm amber-gold
  static const accentError = Color(0xFFF47272); // Soft coral-red
  static const accentInfo = Color(0xFF7EB6FF); // Soft sky blue

  // Pastel avatar circle palette from reference (AL, SA, JA, TA, CA)
  static const avatarCoral = Color(0xFFF49D83);
  static const avatarBlue = Color(0xFF7EB6FF);
  static const avatarPink = Color(0xFFF48FB1);
  static const avatarMint = Color(0xFF6EE7B7);
  static const avatarGold = Color(0xFFF6D067);

  static const List<Color> avatarPalette = [
    avatarCoral,
    avatarBlue,
    avatarPink,
    avatarMint,
    avatarGold,
  ];

  static Color avatarColorFor(String seed) {
    final lower = seed.trim().toLowerCase();
    if (lower.startsWith('alex')) return avatarCoral;
    if (lower.startsWith('sam')) return avatarBlue;
    if (lower.startsWith('jamie') || lower.startsWith('fiona')) {
      return avatarPink;
    }
    if (lower.startsWith('taylor')) return avatarMint;
    if (lower.startsWith('casey') || lower.startsWith('leo')) {
      return avatarGold;
    }
    var hash = 0;
    for (var i = 0; i < lower.length; i++) {
      hash = (hash * 31 + lower.codeUnitAt(i)) & 0x7fffffff;
    }
    return avatarPalette[hash % avatarPalette.length];
  }
}

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.bgBase,
      primaryColor: AppColors.accentPrimary,
      cardColor: AppColors.bgSurface,
      dividerColor: AppColors.borderDefault,
      splashColor: AppColors.accentPrimary.withValues(alpha: 0.08),
      highlightColor: AppColors.accentPrimary.withValues(alpha: 0.04),
      colorScheme: const ColorScheme.dark(
        primary: AppColors.accentPrimary,
        secondary: AppColors.accentMint,
        surface: AppColors.bgSurface,
        error: AppColors.accentError,
        onPrimary: AppColors.onAccentPrimary,
        onSurface: AppColors.textPrimary,
      ),
      textTheme: TextTheme(
        displayLarge: GoogleFonts.plusJakartaSans(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w700,
          fontSize: 32,
          letterSpacing: -0.5,
        ),
        displayMedium: GoogleFonts.plusJakartaSans(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w700,
          fontSize: 24,
          letterSpacing: -0.4,
        ),
        titleLarge: GoogleFonts.plusJakartaSans(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w700,
          fontSize: 19,
          letterSpacing: -0.3,
        ),
        titleMedium: GoogleFonts.plusJakartaSans(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w600,
          fontSize: 15,
          letterSpacing: -0.2,
        ),
        bodyLarge: GoogleFonts.inter(
          color: AppColors.textPrimary,
          fontSize: 14,
          height: 1.4,
        ),
        bodyMedium: GoogleFonts.inter(
          color: AppColors.textSecondary,
          fontSize: 13.5,
          height: 1.4,
        ),
        labelSmall: GoogleFonts.inter(
          color: AppColors.textMuted,
          fontSize: 11.5,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.8,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.bgBase,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        shape: const Border(
          bottom: BorderSide(color: AppColors.borderDefault, width: 1),
        ),
        titleTextStyle: GoogleFonts.plusJakartaSans(
          color: AppColors.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2,
        ),
        iconTheme: const IconThemeData(color: AppColors.textPrimary, size: 20),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.bgSidebar,
        selectedItemColor: AppColors.accentPrimary,
        unselectedItemColor: AppColors.textSecondary,
        selectedLabelStyle: GoogleFonts.inter(
          fontSize: 11.5,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: GoogleFonts.inter(
          fontSize: 11.5,
          fontWeight: FontWeight.w500,
        ),
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.bgSurfaceElevated,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        contentTextStyle: GoogleFonts.inter(
          color: AppColors.onAccentPrimary,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
