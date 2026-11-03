import 'package:flutter/material.dart';

/// Dynamic theme color resolution supporting seamless switching
/// between True Obsidian Dark Theme and Neo-Rehab Light Theme.
class AppColors {
  final bool isDark;

  const AppColors(this.isDark);

  static AppColors of(BuildContext context) {
    return AppColors(Theme.of(context).brightness == Brightness.dark);
  }

  Color get background => isDark ? const Color(0xFF0B0F0E) : const Color(0xFFF4F6F0);
  Color get card => isDark ? const Color(0xFF141A17) : Colors.white;
  Color get cardBorder => isDark ? const Color(0xFF222B26) : const Color(0xFFE2E7DE);
  Color get textPrimary => isDark ? Colors.white : const Color(0xFF161C19);
  Color get textSecondary => isDark ? const Color(0xFF8E958E) : const Color(0xFF7A837E);
  Color get iconContainer => isDark ? const Color(0xFF1E2822) : const Color(0xFFF4F6F0);
  Color get iconTint => isDark ? const Color(0xFFC8F05F) : const Color(0xFF121715);
  Color get outerShell => isDark ? const Color(0xFF050706) : const Color(0xFFE5E7EB);
  Color get lime => const Color(0xFFC8F05F);
  Color get obsidian => const Color(0xFF121715);
  Color get divider => isDark ? const Color(0xFF1E2822) : const Color(0xFFF0F4EC);
}

