import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Design tokens extracted from Stitch HTML `head` config.
///
/// Primary: #13ec5b | Background Dark: #102216 | Background Light: #f6f8f6
/// Font: Manrope | Border Radius: sm=4, lg=8, xl=12, full=9999
class AppTheme {
  AppTheme._();

  // ── Colour tokens ──────────────────────────────────────────────────
  static const Color _primary = Color(0xFF13EC5B);
  static const Color _backgroundLight = Color(0xFFF6F8F6);
  static const Color _backgroundDark = Color(0xFF102216);
  static const Color _surfaceLight = Color(0xFFFFFFFF);
  static const Color _surfaceDark = Color(0xFF1A2E1F);

  // Accent palette
  static const Color accentOrange = Color(0xFFF59E0B);
  static const Color accentRose = Color(0xFFF43F5E);
  static const Color accentBlue = Color(0xFF3B82F6);
  static const Color accentPurple = Color(0xFF8B5CF6);
  static const Color accentYellow = Color(0xFFEAB308);
  static const Color accentRed = Color(0xFFEF4444);

  // ── Spacing ────────────────────────────────────────────────────────
  static const double spacingXs = 4;
  static const double spacingSm = 8;
  static const double spacingMd = 16;
  static const double spacingLg = 24;
  static const double spacingXl = 32;

  // ── Border Radius ──────────────────────────────────────────────────
  static const double radiusSm = 4;
  static const double radiusMd = 8;
  static const double radiusLg = 12;
  static const double radiusXl = 16;
  static const double radiusXxl = 24;

  // ── Text Theme ─────────────────────────────────────────────────────
  static TextTheme _buildTextTheme(Color bodyColor) {
    return GoogleFonts.manropeTextTheme().copyWith(
      displayLarge: GoogleFonts.manrope(
        fontSize: 57,
        fontWeight: FontWeight.w800,
        color: bodyColor,
      ),
      headlineLarge: GoogleFonts.manrope(
        fontSize: 32,
        fontWeight: FontWeight.w800,
        color: bodyColor,
      ),
      headlineMedium: GoogleFonts.manrope(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: bodyColor,
      ),
      titleLarge: GoogleFonts.manrope(
        fontSize: 22,
        fontWeight: FontWeight.w800,
        color: bodyColor,
      ),
      titleMedium: GoogleFonts.manrope(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: bodyColor,
      ),
      titleSmall: GoogleFonts.manrope(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: bodyColor,
      ),
      bodyLarge: GoogleFonts.manrope(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: bodyColor,
      ),
      bodyMedium: GoogleFonts.manrope(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: bodyColor,
      ),
      bodySmall: GoogleFonts.manrope(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: bodyColor,
      ),
      labelLarge: GoogleFonts.manrope(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: bodyColor,
      ),
      labelMedium: GoogleFonts.manrope(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: bodyColor,
      ),
      labelSmall: GoogleFonts.manrope(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        color: bodyColor,
      ),
    );
  }

  // ── Light Theme ────────────────────────────────────────────────────
  static ThemeData get light {
    final colorScheme = ColorScheme.light(
      primary: _primary,
      onPrimary: _backgroundDark,
      secondary: accentBlue,
      onSecondary: Colors.white,
      surface: _surfaceLight,
      onSurface: const Color(0xFF0F172A), // slate-900
      onSurfaceVariant: const Color(0xFF64748B), // slate-500
      error: accentRed,
      outline: const Color(0xFFE2E8F0), // slate-200
      shadow: Colors.black,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: _backgroundLight,
      textTheme: _buildTextTheme(const Color(0xFF0F172A)),
      appBarTheme: AppBarTheme(
        backgroundColor: _backgroundLight,
        foregroundColor: const Color(0xFF0F172A),
        elevation: 0,
      ),
      iconTheme: const IconThemeData(color: Color(0xFF0F172A)),
    );
  }

  // ── Dark Theme ─────────────────────────────────────────────────────
  static ThemeData get dark {
    final colorScheme = ColorScheme.dark(
      primary: _primary,
      onPrimary: _backgroundDark,
      secondary: accentBlue,
      onSecondary: Colors.white,
      surface: _surfaceDark,
      onSurface: const Color(0xFFF1F5F9), // slate-100
      onSurfaceVariant: const Color(0xFF94A3B8), // slate-400
      error: accentRed,
      outline: const Color(0xFF1E293B), // slate-800
      shadow: Colors.black,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: _backgroundDark,
      textTheme: _buildTextTheme(const Color(0xFFF1F5F9)),
      appBarTheme: AppBarTheme(
        backgroundColor: _backgroundDark,
        foregroundColor: const Color(0xFFF1F5F9),
        elevation: 0,
      ),
      iconTheme: const IconThemeData(color: Color(0xFFF1F5F9)),
    );
  }
}
