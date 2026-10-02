import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppBreakpoints {
  static const double desktop = 900.0;

  static bool isDesktop(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= desktop;
}

class AppColors {
  // Refined professional dark slate surfaces
  static const bgBase = Color(0xFF090D16);
  static const bgSurface = Color(0xFF111827);
  static const bgSurfaceElevated = Color(0xFF1E293B);

  // High-contrast crisp typography
  static const textPrimary = Color(0xFFF8FAFC);
  static const textSecondary = Color(0xFF94A3B8);
  static const textMuted = Color(0xFF64748B);

  // Subtle architectural borders
  static const borderDefault = Color(0x1AFFFFFF); // 10% white
  static const borderFocus = Color(0x806366F1); // 50% indigo
  static const borderSubtle = Color(0x0DFFFFFF); // 5% white

  // Executive Indigo primary accent & semantic tokens
  static const accentPrimary = Color(0xFF6366F1); // Indigo 500
  static const accentGlow = Color(0x336366F1); // Subtle 20% indigo shadow

  static const accentSuccess = Color(0xFF10B981); // Emerald 500
  static const accentWarning = Color(0xFFF59E0B); // Amber 500
  static const accentError = Color(0xFFEF4444); // Rose/Red 500
  static const accentInfo = Color(0xFF38BDF8); // Sky 400
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
        secondary: AppColors.accentInfo,
        surface: AppColors.bgSurface,
        error: AppColors.accentError,
        onPrimary: Colors.white,
        onSurface: AppColors.textPrimary,
      ),
      textTheme: TextTheme(
        displayLarge: GoogleFonts.outfit(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w700,
          fontSize: 32,
          letterSpacing: -0.5,
        ),
        displayMedium: GoogleFonts.outfit(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w700,
          fontSize: 24,
          letterSpacing: -0.4,
        ),
        titleLarge: GoogleFonts.outfit(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w600,
          fontSize: 19,
          letterSpacing: -0.3,
        ),
        titleMedium: GoogleFonts.inter(
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
          letterSpacing: 0.6,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.bgSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        shape: const Border(
          bottom: BorderSide(color: AppColors.borderDefault, width: 1),
        ),
        titleTextStyle: GoogleFonts.outfit(
          color: AppColors.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.2,
        ),
        iconTheme: const IconThemeData(color: AppColors.textPrimary, size: 20),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.bgSurface,
        selectedItemColor: AppColors.accentPrimary,
        unselectedItemColor: AppColors.textMuted,
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        contentTextStyle: GoogleFonts.inter(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

