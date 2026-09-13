import 'package:flutter/material.dart';

class AppColors {
  final Color screenBackground;
  final Color cardBackground;
  final Color primary;
  final Color primarySoft;
  final Color textPrimary;
  final Color textSecondary;
  final Color border;
  final Color iconSoftBackground;
  final Color mutedBackground;

  const AppColors({
    required this.screenBackground,
    required this.cardBackground,
    required this.primary,
    required this.primarySoft,
    required this.textPrimary,
    required this.textSecondary,
    required this.border,
    required this.iconSoftBackground,
    required this.mutedBackground,
  });

  static const light = AppColors(
    screenBackground: Color(0xFFF8F9FB),
    cardBackground: Colors.white,
    primary: Color(0xFF246BFD),
    primarySoft: Color(0xFFEAF2FF),
    textPrimary: Color(0xFF1D2939),
    textSecondary: Color(0xFF667085),
    border: Color(0xFFD8DEE8),
    iconSoftBackground: Color(0xFFEFF3F7),
    mutedBackground: Color(0xFFF2F5F9),
  );

  static const dark = AppColors(
    screenBackground: Color(0xFF1E2228),
    cardBackground: Color(0xFF2A2F36),
    primary: Color(0xFF8FB8FF),
    primarySoft: Color(0xFF233246),
    textPrimary: Color(0xFFFFFFFF),
    textSecondary: Color(0xFFB0B3B8),
    border: Color(0xFF3A4350),
    iconSoftBackground: Color(0xFF313943),
    mutedBackground: Color(0xFF252C34),
  );

  static AppColors of(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? dark : light;
  }
}

class AppTheme {
  /* ---------------- LIGHT COLORS ---------------- */

  static const Color lightBackgrounds = Color(0xFFEEF1F5);
  static const Color lightBackground = Color(0xFFF2F4F8);
  static const Color lightSurface = Color(0xFFF3F6FA);

  static const Color primary = Color(0xFF4A89F3);

  static const Color textPrimary = Color(0xFF1F1F1F);
  static const Color headingPrimary = Color(0xFF2C6CE0);
  static const Color textSecondary = Color(0xFF8A8A8A);

  /* ---------------- DARK COLORS ---------------- */

  static const Color darkBackground = Color(0xFF1E2228);
  static const Color darkSurface = Color(0xFF2A2F36);

  static const Color darkTextPrimary = Color(0xFFFFFFFF);
  static const Color darkTextSecondary = Color(0xFFB0B3B8);

  /* ---------------- BUTTON GRADIENT ---------------- */

  static const LinearGradient buttonGradient = LinearGradient(
    colors: [Color(0xFF8FB8FF), Color(0xFF4A89F3)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /* ---------------- NEUMORPHIC SHADOWS ---------------- */

  static const List<BoxShadow> lightShadow = [
    BoxShadow(
      color: Colors.white,
      offset: Offset(-6, -6),
      blurRadius: 12,
      spreadRadius: 1,
    ),
    BoxShadow(color: Color(0xFFD1D9E6), offset: Offset(6, 6), blurRadius: 12),
  ];

  static const List<BoxShadow> darkShadow = [
    BoxShadow(color: Color(0xFF2A2F36), offset: Offset(-6, -6), blurRadius: 12),
    BoxShadow(color: Colors.black54, offset: Offset(6, 6), blurRadius: 12),
  ];

  /* ---------------- LIGHT THEME ---------------- */

  static ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: lightBackground,
    primaryColor: primary,
    fontFamily: "Poppins",

    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.w600,
        color: textPrimary,
      ),
      titleLarge: TextStyle(
        fontSize: 26,
        fontWeight: FontWeight.w600,
        color: Color(0xFF2F4D8C),
      ),
      labelMedium: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: textPrimary,
      ),

      bodyMedium: TextStyle(fontSize: 14, color: textSecondary),
    ),

    inputDecorationTheme: InputDecorationTheme(
      hintStyle: const TextStyle(color: textSecondary),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      filled: true,
      fillColor: lightSurface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
  );

  /* ---------------- DARK THEME ---------------- */

  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: darkBackground,
    primaryColor: primary,
    fontFamily: "Poppins",

    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.w600,
        color: darkTextPrimary,
      ),
      titleLarge: TextStyle(
        fontSize: 26,
        fontWeight: FontWeight.w600,
        color: Color(0xFF8FB8FF),
      ),
      labelMedium: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: darkTextPrimary,
      ),

      bodyMedium: TextStyle(fontSize: 14, color: darkTextSecondary),
    ),

    inputDecorationTheme: InputDecorationTheme(
      hintStyle: const TextStyle(color: darkTextSecondary),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      filled: true,
      fillColor: darkSurface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
  );
}
