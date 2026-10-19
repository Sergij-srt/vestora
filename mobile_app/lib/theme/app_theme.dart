import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color primary = Color(0xFF121214); // Obsidian Slate
  static const Color secondary = Color(0xFF27272A); // Charcoal Charcoal
  static const Color accent = Color(0xFFD97706); // Champagne Gold
  static const Color background = Color(0xFFF8F9FA); // Warm Ivory
  static const Color surface = Colors.white;
  static const Color muted = Color(0xFF71717A);
  static const Color border = Color(0xFFE4E4E7);
  static const Color success = Color(0xFF16A34A); // Emerald
  static const Color danger = Color(0xFFDC2626); // Ruby Shield

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: background,
      colorScheme: const ColorScheme.light(
        primary: primary,
        secondary: accent,
        surface: surface,
      ),
      fontFamily: GoogleFonts.plusJakartaSans().fontFamily,
      textTheme: const TextTheme(
        headlineMedium: TextStyle(
          fontWeight: FontWeight.w700,
          color: primary,
          letterSpacing: -0.5,
        ),
        titleLarge: TextStyle(
          fontWeight: FontWeight.w600,
          color: primary,
        ),
        titleMedium: TextStyle(
          fontWeight: FontWeight.w600,
          color: primary,
        ),
        bodyMedium: TextStyle(
          color: Color(0xFF27272A),
        ),
        bodySmall: TextStyle(
          color: muted,
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: surface,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        centerTitle: false,
        iconTheme: IconThemeData(color: primary),
        titleTextStyle: TextStyle(
          color: primary,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: border, width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primary, width: 1.5),
        ),
      ),
    );
  }
}
