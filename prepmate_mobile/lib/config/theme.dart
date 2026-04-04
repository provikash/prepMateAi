import 'package:flutter/material.dart';

class AppTheme {
  /* ---------------- LIGHT COLORS ---------------- */

  static const Color lightBackground = Color(0xFFEEF1F5);
  static const Color lightSurface = Color(0xFFF3F6FA);

  static const Color primary = Color(0xFF4A89F3);

  static const Color textPrimary = Color(0xFF1F1F1F);
  static const Color textSecondary = Color(0xFF8A8A8A);

  /* ---------------- DARK COLORS ---------------- */

  static const Color darkBackground = Color(0xFF1E2228);
  static const Color darkSurface = Color(0xFF2A2F36);

  static const Color darkTextPrimary = Color(0xFFFFFFFF);
  static const Color darkTextSecondary = Color(0xFFB0B3B8);

  /* ---------------- BUTTON GRADIENT ---------------- */

  static const LinearGradient buttonGradient = LinearGradient(
    colors: [
      Color(0xFF8FB8FF),
      Color(0xFF4A89F3),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /* ---------------- NEUMORPHIC SHADOWS ---------------- */

  static const List<BoxShadow> lightShadow = [
    BoxShadow(
      color: Colors.white,
      offset: Offset(-6, -6),
      blurRadius: 12,
    ),
    BoxShadow(
      color: Color(0xFFD1D9E6),
      offset: Offset(6, 6),
      blurRadius: 12,
    ),
  ];

  static const List<BoxShadow> darkShadow = [
    BoxShadow(
      color: Color(0xFF2A2F36),
      offset: Offset(-6, -6),
      blurRadius: 12,
    ),
    BoxShadow(
      color: Colors.black54,
      offset: Offset(6, 6),
      blurRadius: 12,
    ),
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
      bodyMedium: TextStyle(
        fontSize: 14,
        color: textSecondary,
      ),
    ),

    inputDecorationTheme: InputDecorationTheme(
      hintStyle: const TextStyle(color: textSecondary),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      filled: true,
      fillColor: lightSurface,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 14,
      ),
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
      bodyMedium: TextStyle(
        fontSize: 14,
        color: darkTextSecondary,
      ),
    ),

    inputDecorationTheme: InputDecorationTheme(
      hintStyle: const TextStyle(color: darkTextSecondary),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      filled: true,
      fillColor: darkSurface,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 14,
      ),
    ),
  );
}