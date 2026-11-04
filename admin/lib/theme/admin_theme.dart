import 'package:flutter/material.dart';

class AdminTheme {
  static const Color background = Color(0xFF0B0F0E);
  static const Color surface = Color(0xFF121715);
  static const Color surfaceElevated = Color(0xFF18201D);
  static const Color border = Color(0xFF1F2923);
  static const Color borderSubtle = Color(0xFF161E1A);

  static const Color lime = Color(0xFFC8F05F);
  static const Color limeDark = Color(0xFF121715);
  static const Color cyan = Color(0xFF56B4E9);
  static const Color amber = Color(0xFFF5A623);
  static const Color amberMuted = Color(0xFF1E170C);
  static const Color red = Color(0xFFE05D5D);
  static const Color crimson = Color(0xFFEF4444);
  static const Color green = Color(0xFF2E7D32);

  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF8E9893);
  static const Color textTertiary = Color(0xFF5C6561);

  // Okabe-Ito Color-Blind Safe Channel Palette (5 Finger channels)
  static const Color colorThumb = Color(0xFFE69F00);   // Orange
  static const Color colorIndex = Color(0xFF56B4E9);   // Sky Blue
  static const Color colorMiddle = Color(0xFF009E73);  // Bluish Green
  static const Color colorRing = Color(0xFFF0E442);    // Yellow
  static const Color colorPinky = Color(0xFFCC79A7);   // Reddish Purple

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      colorScheme: const ColorScheme.dark(
        surface: surface,
        primary: lime,
        secondary: cyan,
        error: red,
        onSurface: textPrimary,
        onPrimary: limeDark,
      ),
      fontFamily: 'Roboto',
      appBarTheme: const AppBarTheme(
        backgroundColor: background,
        foregroundColor: textPrimary,
        elevation: 0,
      ),
      cardTheme: CardTheme(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: border, width: 1.0),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: border,
        thickness: 1,
        space: 1,
      ),
    );
  }
}

