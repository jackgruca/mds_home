// lib/utils/theme_config.dart
import 'package:flutter/material.dart';

class AppTheme {
  // Core Colors (NFL-Inspired)
  static const Color deepRed = Color(0xFFD50A0A);
  static const Color darkNavy = Color(0xFF002244);
  static const Color brightBlue = Color(0xFF0085CA);
  static const Color silver = Color(0xFFA5ACAF);
  
  // Secondary Colors
  static const Color gold = Color(0xFFFFC72C);
  static const Color green = Color(0xFF008000);
  static const Color orange = Color(0xFFFF8200);
  
  // Light Theme Colors
  static const Color lightBackground = Color(0xFFF4F4F4);
  static const Color lightText = Color(0xFF1E1E1E);
  
  // Dark Theme Colors
  static const Color darkBackground = Color(0xFF121212);
  static const Color darkBackgroundAlt = Color(0xFF1A1A2E);
  static const Color darkText = Color(0xFFFFFFFF);
  static const Color darkTextSecondary = Color(0xFFCFCFCF);

  // Light Theme
  static ThemeData lightTheme = ThemeData(
    primaryColor: deepRed,
    colorScheme: const ColorScheme.light(
      primary: deepRed,
      secondary: brightBlue,
      tertiary: gold,
      surface: Colors.white,
      onSurface: darkNavy,
    ),
    scaffoldBackgroundColor: lightBackground,
    appBarTheme: const AppBarTheme(
      backgroundColor: darkNavy,
      titleTextStyle: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
      iconTheme: IconThemeData(color: Colors.white),
    ),
    cardTheme: CardTheme(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: Colors.white,
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: deepRed,
      foregroundColor: Colors.white,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: deepRed,
        foregroundColor: Colors.white,
        elevation: 2,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: darkNavy,
        side: const BorderSide(color: silver),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: brightBlue,
      ),
    ),
    tabBarTheme: const TabBarTheme(
      labelColor: Colors.black,
      unselectedLabelColor: silver,
      indicator: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: brightBlue, width: 3),
        ),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: silver.withOpacity(0.2),
      selectedColor: brightBlue,
      labelStyle: const TextStyle(color: darkNavy),
      secondaryLabelStyle: const TextStyle(color: Colors.white),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: silver),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: brightBlue, width: 2),
      ),
      filled: true,
      fillColor: Colors.white,
    ),
    dividerTheme: const DividerThemeData(
      color: silver,
      thickness: 1,
    ),
    iconTheme: const IconThemeData(
      color: darkNavy,
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: brightBlue,
    ),
  );

  // Dark Theme
  static ThemeData darkTheme = ThemeData(
    primaryColor: deepRed,
    colorScheme: const ColorScheme.dark(
      primary: deepRed,
      secondary: gold,
      tertiary: brightBlue,
      surface: darkBackgroundAlt,
      onSurface: darkText,
    ),
    scaffoldBackgroundColor: darkBackground,
    appBarTheme: const AppBarTheme(
      backgroundColor: darkBackgroundAlt,
      titleTextStyle: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
      iconTheme: IconThemeData(color: Colors.white),
      elevation: 0,
    ),
    cardTheme: CardTheme(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: darkBackgroundAlt,
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: deepRed,
      foregroundColor: Colors.white,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: deepRed,
        foregroundColor: Colors.white,
        elevation: 4,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: silver,
        side: const BorderSide(color: silver),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: brightBlue,
      ),
    ),
    tabBarTheme: const TabBarTheme(
      labelColor: gold,
      unselectedLabelColor: silver,
      indicator: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: gold, width: 3),
        ),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: darkBackgroundAlt,
      selectedColor: brightBlue,
      labelStyle: const TextStyle(color: darkText),
      secondaryLabelStyle: const TextStyle(color: darkBackgroundAlt),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: silver, width: 1),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: silver),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: brightBlue, width: 2),
      ),
      filled: true,
      fillColor: darkBackgroundAlt,
    ),
    dividerTheme: DividerThemeData(
      color: silver.withOpacity(0.3),
      thickness: 1,
    ),
    iconTheme: const IconThemeData(
      color: silver,
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: brightBlue,
    ),
  );
}