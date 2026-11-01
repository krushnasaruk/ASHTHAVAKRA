/// Design tokens for H10 theme, ensuring color-blind accessibility and consistency.
class H10Tokens {
  // Brand Palette
  static const int colorBackground = 0xFFF7F7F2;
  static const int colorPrimary = 0xFF173C35;
  static const int colorSecondary = 0xFFA7B9A3;
  static const int colorSurfaceTint = 0xFFD8E8E2;
  static const int colorText = 0xFF252A28;
  static const int colorSecondaryText = 0xFF747B76;
  static const int colorCard = 0xFFFFFFFF;
  static const int colorBorder = 0xFFE0E5E2;

  // Status Colors (Never rely on color alone)
  static const int colorSuccess = 0xFF2E7D32;
  static const int colorWarning = 0xFFED6C02;
  static const int colorError = 0xFFD32F2F;
  static const int colorInfo = 0xFF0288D1;

  // Okabe-Ito Color-Blind Safe Palette for 5 Fingers
  static const List<int> fingerColors = [
    0xFFE69F00, // Thumb: Orange / Vermilion
    0xFF56B4E9, // Index: Sky Blue
    0xFF009E73, // Middle: Bluish Green
    0xFFE4C41B, // Ring: High-contrast Gold
    0xFF0072B2, // Pinky: Blue
  ];

  static const List<String> fingerNames = [
    'Thumb',
    'Index',
    'Middle',
    'Ring',
    'Pinky',
  ];

  // Spacing Grid (4-point system)
  static const double space4 = 4.0;
  static const double space8 = 8.0;
  static const double space12 = 12.0;
  static const double space16 = 16.0;
  static const double space20 = 20.0;
  static const double space24 = 24.0;
  static const double space32 = 32.0;

  // Radii
  static const double radiusInput = 8.0;
  static const double radiusCard = 12.0;
  static const double radiusChip = 999.0;

  // Touch Target Minimum
  static const double minTouchTargetDp = 48.0;
}
