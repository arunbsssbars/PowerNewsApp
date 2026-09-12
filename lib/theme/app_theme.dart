import 'package:flutter/material.dart';

class AppTheme {
  // --- Professional Eye-Easing Palette (Light Mode) ---
  static const Color lightBg = Color(0xFFF8FAFC); // Clean Slate 50
  static const Color lightSurface = Color(0xFFFFFFFF); // Pure White Cards
  static const Color lightBorder = Color(0xFFE2E8F0); // Subtle Slate 200 border
  static const Color lightTextPrimary = Color(0xFF0F172A); // Slate 900
  static const Color lightTextSecondary = Color(0xFF475569); // Slate 600
  static const Color lightTextMuted = Color(0xFF94A3B8); // Slate 400
  static const Color lightPrimary = Color(0xFF2563EB); // Electric Royal Blue
  static const Color lightAccent = Color(0xFFD97706); // Warm Amber

  // --- Ultra-Modern Professional Reader Dark Palette (Eye-Easing Obsidian) ---
  static const Color darkBg = Color(0xFF0D1117); // Obsidian Charcoal Canvas (No halation / eye strain)
  static const Color darkSurface = Color(0xFF161B22); // Deep Slate Card Surface
  static const Color darkSurfaceElevated = Color(0xFF1F2937); // Elevated Modal & Highlights
  static const Color darkBorder = Color(0xFF263040); // Subtle Refined Slate Border
  static const Color darkBorderLuminous = Color(0xFF384964); // Focused Luminous Border
  static const Color darkTextPrimary = Color(0xFFE6EDF3); // Soft Off-White (Eliminates glare fatigue)
  static const Color darkTextSecondary = Color(0xFF9DA7B3); // Warm Slate 400 (High-Legibility)
  static const Color darkTextMuted = Color(0xFF6E7781); // Slate 500
  static const Color darkPrimary = Color(0xFF38BDF8); // Electric Sky Cyan
  static const Color darkAccent = Color(0xFFFBBF24); // Warm Amber Energy Glow

  // --- Sector Specific Accents ---
  static const Color sectorTransmission = Color(0xFF0284C7); // High Voltage Blue
  static const Color sectorRenewables = Color(0xFF10B981); // Clean Emerald
  static const Color sectorGeneration = Color(0xFFF59E0B); // Thermal/Power Amber
  static const Color sectorDistribution = Color(0xFF8B5CF6); // DISCOM Violet
  static const Color sectorPolicy = Color(0xFFEC4899); // Regulatory Rose
  static const Color sectorTenders = Color(0xFF06B6D4); // Cyan Procurement

  static ThemeData get lightTheme {
    final base = ThemeData.light(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: lightBg,
      colorScheme: ColorScheme.fromSeed(
        seedColor: lightPrimary,
        brightness: Brightness.light,
        primary: lightPrimary,
        secondary: lightAccent,
        surface: lightSurface,
      ),
      textTheme: base.textTheme.copyWith(
        titleLarge: const TextStyle(fontWeight: FontWeight.w800, letterSpacing: -0.3),
        titleMedium: const TextStyle(fontWeight: FontWeight.w700, letterSpacing: -0.2),
        bodyLarge: const TextStyle(fontWeight: FontWeight.w400, letterSpacing: 0),
        bodyMedium: const TextStyle(fontWeight: FontWeight.w400, letterSpacing: 0),
      ).apply(
        bodyColor: lightTextPrimary,
        displayColor: lightTextPrimary,
        fontFamily: 'sans-serif',
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: false,
        iconTheme: IconThemeData(color: lightTextPrimary),
        titleTextStyle: TextStyle(
          color: lightTextPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.4,
        ),
      ),
      cardTheme: CardTheme(
        color: lightSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: lightBorder, width: 1),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        elevation: 3,
        height: 65,
        indicatorColor: lightPrimary.withOpacity(0.12),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: lightPrimary,
            );
          }
          return const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: lightTextSecondary,
          );
        }),
      ),
    );
  }

  static ThemeData get darkTheme {
    final base = ThemeData.dark(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: darkBg,
      colorScheme: ColorScheme.fromSeed(
        seedColor: darkPrimary,
        brightness: Brightness.dark,
        primary: darkPrimary,
        secondary: darkAccent,
        surface: darkSurface,
        surfaceContainerHighest: darkSurfaceElevated,
      ),
      textTheme: base.textTheme.copyWith(
        titleLarge: const TextStyle(fontWeight: FontWeight.w800, letterSpacing: -0.3),
        titleMedium: const TextStyle(fontWeight: FontWeight.w700, letterSpacing: -0.2),
        bodyLarge: const TextStyle(fontWeight: FontWeight.w400, letterSpacing: 0),
        bodyMedium: const TextStyle(fontWeight: FontWeight.w400, letterSpacing: 0),
      ).apply(
        bodyColor: darkTextPrimary,
        displayColor: darkTextPrimary,
        fontFamily: 'sans-serif',
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: darkBg,
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: false,
        iconTheme: IconThemeData(color: darkTextPrimary),
        titleTextStyle: TextStyle(
          color: darkTextPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.4,
        ),
      ),
      cardTheme: CardTheme(
        color: darkSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: darkBorder, width: 1),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: const Color(0xFF10151E),
        elevation: 0,
        height: 65,
        indicatorColor: darkPrimary.withOpacity(0.22),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: darkPrimary,
            );
          }
          return const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: darkTextSecondary,
          );
        }),
      ),
    );
  }
}
