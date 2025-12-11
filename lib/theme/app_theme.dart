import 'package:flutter/material.dart';

class AppTheme {
  static const Color primaryBrand = Color(0xFF6750A4);

  static const Color bgLight = Color(0xFFF5F5FA);
  static const Color surfaceLight = Colors.white;

  static const Color bgDark = Color(0xFF050509);
  static const Color surfaceDark = Color(0xFF15151C);
  static const Color inputDark = Color(0xFF20202A);

  static ThemeData light() {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryBrand,
        brightness: Brightness.light,
        surface: surfaceLight,
        primary: primaryBrand,
      ),
      scaffoldBackgroundColor: bgLight,
    );

    return base.copyWith(
      appBarTheme: base.appBarTheme.copyWith(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: const TextStyle(
          color: Colors.black87,
          fontSize: 24,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.5,
        ),
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      cardTheme: base.cardTheme.copyWith(
        color: surfaceLight,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: BorderSide(color: Colors.grey.withValues(alpha: 0.12)),
        ),
      ),
      inputDecorationTheme: base.inputDecorationTheme.copyWith(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: primaryBrand, width: 2),
        ),
        labelStyle: TextStyle(
          color: Colors.grey.shade700,
          fontWeight: FontWeight.w600,
        ),
        hintStyle: TextStyle(color: Colors.grey.shade400),
      ),
      textTheme: base.textTheme.apply(
        bodyColor: Colors.black87,
        displayColor: Colors.black87,
      ),
      snackBarTheme: base.snackBarTheme.copyWith(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  static ThemeData dark() {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryBrand,
        brightness: Brightness.dark,
        primary: primaryBrand,
        surface: surfaceDark,
        onSurface: Colors.white,
      ),
      scaffoldBackgroundColor: bgDark,
    );

    return base.copyWith(
      appBarTheme: base.appBarTheme.copyWith(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 24,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.5,
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      cardTheme: base.cardTheme.copyWith(
        color: surfaceDark,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
        ),
      ),
      inputDecorationTheme: base.inputDecorationTheme.copyWith(
        filled: true,
        fillColor: inputDark,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: primaryBrand, width: 2),
        ),
        labelStyle: const TextStyle(
          color: Colors.white70,
          fontWeight: FontWeight.w500,
        ),
        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.25)),
      ),
      textTheme: base.textTheme.apply(
        bodyColor: Colors.white,
        displayColor: Colors.white,
      ),
    );
  }
}
