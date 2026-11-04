import 'package:flutter/material.dart';

class AdminTheme {
  // Primary Palette - Reference Dashboard Aesthetic
  static const Color sidebarBg = Color(0xFF1B1E2B);
  static const Color sidebarNavHover = Color(0xFF25293A);
  static const Color sidebarTextMuted = Color(0xFF8C93A4);
  static const Color sidebarBadge = Color(0xFFFF6B4A);

  static const Color canvasBg = Color(0xFFF5F6FA);
  static const Color cardBg = Color(0xFFFFFFFF);
  static const Color cardBorder = Color(0xFFECEFF5);
  static const Color heroCardBg = Color(0xFF1A1D26);

  // Vibrant Lime Accent
  static const Color lime = Color(0xFFC8F05F);
  static const Color limeLight = Color(0xFFD8F86E);
  static const Color limeDark = Color(0xFF14181B);

  // Pastel Squircle Tints
  static const Color pastelPeach = Color(0xFFFFEEDB);
  static const Color pastelPeachIcon = Color(0xFFF97316);
  static const Color pastelMint = Color(0xFFE3F8EB);
  static const Color pastelMintIcon = Color(0xFF10B981);
  static const Color pastelLavender = Color(0xFFEBE8FC);
  static const Color pastelLavenderIcon = Color(0xFF8B5CF6);
  static const Color pastelSky = Color(0xFFE0F2FE);
  static const Color pastelSkyIcon = Color(0xFF0284C7);
  static const Color pastelYellow = Color(0xFFFEF9C3);
  static const Color pastelYellowIcon = Color(0xFFCA8A04);

  // Status & Utility Colors
  static const Color cyan = Color(0xFF56B4E9);
  static const Color amber = Color(0xFFF5A623);
  static const Color amberMuted = Color(0xFF1E170C);
  static const Color red = Color(0xFFE05D5D);
  static const Color crimson = Color(0xFFEF4444);
  static const Color green = Color(0xFF10B981);

  // Typography Colors
  static const Color textPrimary = Color(0xFF1A1D26);
  static const Color textSecondary = Color(0xFF7D8597);
  static const Color textTertiary = Color(0xFFA0A7B8);

  // Dark Theme Equivalents (for 3D Hand HUD Stage & Dark Cards)
  static const Color background = Color(0xFFF5F6FA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceElevated = Color(0xFF1A1D26);
  static const Color border = Color(0xFFECEFF5);
  static const Color borderSubtle = Color(0xFFE2E6EF);

  // Okabe-Ito Color-Blind Safe Channel Palette (5 Finger channels)
  static const Color colorThumb = Color(0xFFE69F00);   // Orange
  static const Color colorIndex = Color(0xFF56B4E9);   // Sky Blue
  static const Color colorMiddle = Color(0xFF009E73);  // Bluish Green
  static const Color colorRing = Color(0xFFF0E442);    // Yellow
  static const Color colorPinky = Color(0xFFCC79A7);   // Reddish Purple

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: canvasBg,
      colorScheme: const ColorScheme.light(
        surface: cardBg,
        primary: lime,
        secondary: cyan,
        error: crimson,
        onSurface: textPrimary,
        onPrimary: limeDark,
      ),
      fontFamily: 'Roboto',
      appBarTheme: const AppBarTheme(
        backgroundColor: cardBg,
        foregroundColor: textPrimary,
        elevation: 0,
      ),
      cardTheme: CardTheme(
        color: cardBg,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: cardBorder, width: 1.0),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: cardBorder,
        thickness: 1,
        space: 1,
      ),
    );
  }

  // Keep darkTheme alias for compatibility
  static ThemeData get darkTheme => lightTheme;
}
