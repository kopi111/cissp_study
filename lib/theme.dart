import 'package:flutter/material.dart';

/// The app's colours, in one place.
class AppColors {
  static const evergreen = Color(0xFF12473F);
  static const evergreenSoft = Color(0xFFDCE9E3);
  static const amber = Color(0xFFB9650F);
  static const amberSoft = Color(0xFFFBEBD3);
  static const page = Color(0xFFF2F5F1);
  static const ink = Color(0xFF1B2623);
  static const inkSoft = Color(0xFF55635E);
  static const good = Color(0xFF1F7A4D);
  static const warning = Color(0xFFB9650F);
  static const bad = Color(0xFFB3302A);
  static const line = Color(0xFFD5DDD8);
}

/// Builds a calm theme with large, easy-to-read text.
ThemeData buildTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: AppColors.evergreen,
    primary: AppColors.evergreen,
    secondary: AppColors.amber,
    surface: Colors.white,
  );
  return ThemeData(
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.page,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.page,
      foregroundColor: AppColors.ink,
      elevation: 0,
      scrolledUnderElevation: 0,
    ),
    textTheme: const TextTheme(
      headlineMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: AppColors.ink),
      titleLarge: TextStyle(fontSize: 21, fontWeight: FontWeight.w700, color: AppColors.ink),
      titleMedium: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.ink),
      bodyLarge: TextStyle(fontSize: 18, height: 1.5, color: AppColors.ink),
      bodyMedium: TextStyle(fontSize: 17, height: 1.45, color: AppColors.ink),
      bodySmall: TextStyle(fontSize: 15, height: 1.35, color: AppColors.inkSoft),
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppColors.line),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(64, 54),
        textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(64, 54),
        textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
      ),
    ),
  );
}
