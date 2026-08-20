import 'package:flutter/material.dart';

class AppTheme {
  // ☀️ LIGHT THEME
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF4CAF50),
      primary: const Color(0xFF4CAF50),
      secondary: const Color(0xFF81C784),
      surface: Colors.white,
      onSurface: Colors.black87,
      onPrimary: Colors.white,
    ),
    scaffoldBackgroundColor: Colors.white,
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF4CAF50),
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
      iconTheme: IconThemeData(color: Colors.white),
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF4CAF50),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
      ),
    ),
    iconTheme: const IconThemeData(
      color: Color(0xFF4CAF50),
    ),
    textTheme: const TextTheme(
      headlineMedium: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: Color(0xFF2E7D32),
      ),
      bodyMedium: TextStyle(
        fontSize: 16,
        color: Colors.black87,
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        color: Colors.black54,
      ),
    ),
  );

  // 🌙 DARK THEME
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF021E16),
      brightness: Brightness.dark,
      primary: const Color(0xFFD4AF37), // Gold as primary in dark mode for better visibility
      secondary: const Color(0xFF0B3D2E),
      surface: const Color(0xFF021E16),
      onSurface: Colors.white,
      surfaceContainerHighest: const Color(0xFF0B3D2E),
      onPrimary: Colors.black,
    ),
    scaffoldBackgroundColor: const Color(0xFF021E16),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF0B3D2E),
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
      iconTheme: IconThemeData(color: Colors.white),
    ),
    cardTheme: CardThemeData(
      color: const Color(0xFF0B3D2E),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFD4AF37),
        foregroundColor: Colors.black,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
      ),
    ),
    iconTheme: const IconThemeData(
      color: Color(0xFFD4AF37),
    ),
    textTheme: const TextTheme(
      headlineMedium: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
      bodyMedium: TextStyle(
        fontSize: 16,
        color: Colors.white70,
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        color: Colors.white60,
      ),
    ),
  );
}
