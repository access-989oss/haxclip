import 'package:flutter/material.dart';

class HaxTheme {
  // Brand Palette
  static const Color bgDark = Color(0xFF080811);
  static const Color bgSurface = Color(0xFF0F0F23);
  static const Color bgCard = Color(0xFF151530);
  static const Color bgGlass = Color(0xCC181838);

  static const Color neonCyan = Color(0xFF00F0FF);
  static const Color neonViolet = Color(0xFFA855F7);
  static const Color neonPurple = Color(0xFF8B5CF6);
  static const Color neonGreen = Color(0xFF10B981);
  static const Color neonAmber = Color(0xFFF59E0B);
  static const Color neonRose = Color(0xFFF43F5E);

  // Modern Minimalist Aliases
  static const Color bgPrimary = bgDark;
  static const Color bgSurfaceElevated = Color(0xFF16162E);
  static const Color cyanAccent = neonCyan;
  static const Color emeraldAccent = neonGreen;

  static const Color textPrimary = Color(0xFFF8FAFC);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color textMuted = Color(0xFF64748B);

  static const Color borderGlow = Color(0x3300F0FF);
  static const Color borderCard = Color(0x22FFFFFF);

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bgDark,
      primaryColor: neonCyan,
      canvasColor: bgSurface,
      cardColor: bgCard,
      colorScheme: const ColorScheme.dark(
        primary: neonCyan,
        secondary: neonViolet,
        surface: bgSurface,
        error: neonRose,
        onPrimary: Colors.black,
        onSecondary: Colors.white,
        onSurface: textPrimary,
      ),
      fontFamily: 'Roboto',
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.5,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF101026),
        hintStyle: const TextStyle(color: textMuted, fontSize: 14),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0x3300F0FF), width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: neonCyan, width: 2.0),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: neonRose, width: 1.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: neonCyan,
          foregroundColor: Colors.black,
          elevation: 8,
          shadowColor: neonCyan.withOpacity(0.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.0,
          ),
        ),
      ),
    );
  }

  // 3D Box Shadow Generator
  static List<BoxShadow> get3dShadow({
    Color color = neonCyan,
    double spread = 0,
    double blur = 16,
    Offset offset = const Offset(0, 8),
    double opacity = 0.35,
  }) {
    return [
      BoxShadow(
        color: color.withOpacity(opacity),
        blurRadius: blur,
        spreadRadius: spread,
        offset: offset,
      ),
      BoxShadow(
        color: Colors.black.withOpacity(0.6),
        blurRadius: 10,
        offset: const Offset(0, 4),
      ),
    ];
  }
}
