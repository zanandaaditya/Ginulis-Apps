import 'package:flutter/material.dart';

/// Identitas visual Ginulis.id, terinspirasi desain mobile soft modern.
abstract final class AppColors {
  static const primary = Color(0xFF625BF6);
  static const primaryDark = Color(0xFF4A44DB);
  static const navy = Color(0xFF182440);
  static const background = Color(0xFFF6F8FD);
  static const muted = Color(0xFF7C879B);
  static const stroke = Color(0xFFEAEDF5);
  static const lavender = Color(0xFFEDEBFF);
  static const cyan = Color(0xFF40B7E8);
  static const green = Color(0xFF15A976);
  static const orange = Color(0xFFEF9B37);
  static const red = Color(0xFFF16D7D);
  static const yellow = Color(0xFFFFD661);
}

ThemeData buildGinulisTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: AppColors.primary,
    brightness: Brightness.light,
  ).copyWith(
    primary: AppColors.primary,
    surface: Colors.white,
    onSurface: AppColors.navy,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.background,
    splashColor: AppColors.primary.withValues(alpha: 0.06),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.background,
      foregroundColor: AppColors.navy,
      elevation: 0,
      centerTitle: false,
      scrolledUnderElevation: 0,
    ),
    textTheme: const TextTheme(
      headlineMedium: TextStyle(fontSize: 27, fontWeight: FontWeight.w800, color: AppColors.navy, letterSpacing: -0.7),
      headlineSmall: TextStyle(fontSize: 23, fontWeight: FontWeight.w800, color: AppColors.navy, letterSpacing: -0.5),
      titleLarge: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: AppColors.navy),
      titleMedium: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.navy),
      bodyMedium: TextStyle(fontSize: 13.5, color: AppColors.navy, height: 1.45),
      bodySmall: TextStyle(fontSize: 12, color: AppColors.muted, height: 1.4),
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
      hintStyle: const TextStyle(fontSize: 13, color: AppColors.muted),
      labelStyle: const TextStyle(color: AppColors.muted),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.stroke)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.stroke)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        minimumSize: const Size(0, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        minimumSize: const Size(0, 50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        side: const BorderSide(color: AppColors.stroke),
        textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      shape: CircleBorder(),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.navy,
      contentTextStyle: const TextStyle(color: Colors.white),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
  );
}
