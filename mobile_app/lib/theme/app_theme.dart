import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Light Palette
  static const Color primary = Color(0xFF121214); // Obsidian Slate
  static const Color secondary = Color(0xFF27272A); // Charcoal Charcoal
  static const Color accent = Color(0xFFD97706); // Champagne Gold
  static const Color accentLight = Color(0xFFFEF3C7); // Warm Amber Glow
  static const Color background = Color(0xFFF8F9FA); // Warm Ivory
  static const Color surface = Colors.white;
  static const Color muted = Color(0xFF71717A);
  static const Color border = Color(0xFFE4E4E7);
  static const Color glassBorder = Color(0x26000000); // Subtle 15% hairline
  static const Color success = Color(0xFF16A34A); // Emerald
  static const Color danger = Color(0xFFDC2626); // Ruby Shield

  // Dark Palette
  static const Color darkBackground = Color(0xFF0F0F11); // Deep Onyx
  static const Color darkSurface = Color(0xFF18181C); // Obsidian Surface
  static const Color darkCard = Color(0xFF222227); // Elevated Card
  static const Color darkBorder = Color(0xFF2E2E38); // Dark Border
  static const Color darkText = Color(0xFFF4F4F6); // Crisp White/Silver
  static const Color darkMuted = Color(0xFFA1A1AA); // Muted Silver
  static const Color darkAccent = Color(0xFFF59E0B); // Radiant Gold
  static const Color darkAccentLight = Color(0xFF352B18); // Amber Glow Dark

  // Elevation & Shadows
  static const List<BoxShadow> softShadow = [
    BoxShadow(
      color: Color(0x0A000000),
      blurRadius: 16,
      offset: Offset(0, 4),
    ),
  ];

  static const List<BoxShadow> floatingShadow = [
    BoxShadow(
      color: Color(0x14000000),
      blurRadius: 24,
      offset: Offset(0, 8),
    ),
  ];

  static const List<BoxShadow> darkSoftShadow = [
    BoxShadow(
      color: Color(0x40000000),
      blurRadius: 16,
      offset: Offset(0, 4),
    ),
  ];

  // Bento Card decoration helper
  static BoxDecoration bentoCardDecoration({Color? color, Border? border, bool isDark = false}) {
    return BoxDecoration(
      color: color ?? (isDark ? darkCard : surface),
      borderRadius: BorderRadius.circular(20),
      border: border ?? Border.all(color: isDark ? darkBorder : AppTheme.border, width: 1),
      boxShadow: isDark ? darkSoftShadow : softShadow,
    );
  }

  // Glassmorphic decoration helper
  static BoxDecoration glassDecoration({Color? color, double opacity = 0.85, bool isDark = false}) {
    return BoxDecoration(
      color: (color ?? (isDark ? darkSurface : surface)).withValues(alpha: opacity),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(
        color: isDark ? Colors.white.withValues(alpha: 0.12) : Colors.white.withValues(alpha: 0.5),
        width: 1,
      ),
      boxShadow: floatingShadow,
    );
  }

  // --- LIGHT THEME ---
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
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
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: primary,
        unselectedItemColor: muted,
      ),
    );
  }

  // --- DARK THEME ---
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: darkBackground,
      colorScheme: const ColorScheme.dark(
        primary: darkAccent,
        secondary: accent,
        surface: darkSurface,
      ),
      fontFamily: GoogleFonts.plusJakartaSans().fontFamily,
      textTheme: const TextTheme(
        headlineMedium: TextStyle(
          fontWeight: FontWeight.w700,
          color: darkText,
          letterSpacing: -0.5,
        ),
        titleLarge: TextStyle(
          fontWeight: FontWeight.w600,
          color: darkText,
        ),
        titleMedium: TextStyle(
          fontWeight: FontWeight.w600,
          color: darkText,
        ),
        bodyMedium: TextStyle(
          color: Color(0xFFE4E4E7),
        ),
        bodySmall: TextStyle(
          color: darkMuted,
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: darkBackground,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        centerTitle: false,
        iconTheme: IconThemeData(color: darkText),
        titleTextStyle: TextStyle(
          color: darkText,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),
      cardTheme: CardThemeData(
        color: darkCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: darkBorder, width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: darkAccent,
          foregroundColor: Colors.black,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 15,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkCard,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: darkBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: darkBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: darkAccent, width: 1.5),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: darkSurface,
        selectedItemColor: darkAccent,
        unselectedItemColor: darkMuted,
      ),
    );
  }
}
