import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  
  static const Color primary = Color(0xFFF59E0B);
  static const Color primaryDark = Color(0xFFD97706);
  static const Color primarySoft = Color(0xFFFEF3C7);

  
  static const Color background = Color(0xFFFAFAF9);
  static const Color card = Color(0xFFFFFFFF);

  
  static const Color backgroundDark = Color(0xFF111827);
  static const Color cardDark = Color(0xFF1F2937);

  
  static const Color textPrimary = Color(0xFF111827);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textPrimaryDark = Color(0xFFF9FAFB);
  static const Color textSecondaryDark = Color(0xFF9CA3AF);

  
  static const Color success = Color(0xFF16A34A);
  static const Color danger = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);
  static const Color info = Color(0xFF3B82F6);

  
  static const Color border = Color(0xFFE5E7EB);
  static const Color borderDark = Color(0xFF374151);
  static const Color divider = Color(0xFFF3F4F6);

  
  static const LinearGradient amberGradient = LinearGradient(
    colors: [Color(0xFFFBBF24), Color(0xFFF59E0B), Color(0xFFD97706)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient successGradient = LinearGradient(
    colors: [Color(0xFF34D399), Color(0xFF16A34A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient dangerGradient = LinearGradient(
    colors: [Color(0xFFF87171), Color(0xFFDC2626)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

class AppPalette {
  const AppPalette({
    required this.background,
    required this.card,
    required this.textPrimary,
    required this.textSecondary,
    required this.border,
    required this.divider,
    required this.isDark,
  });

  final Color background;
  final Color card;
  final Color textPrimary;
  final Color textSecondary;
  final Color border;
  final Color divider;
  final bool isDark;

  
  Color get surfaceMuted => isDark
      ? const Color(0xFF111827)
      : const Color(0xFFF3F4F6);
}

const AppPalette _lightPalette = AppPalette(
  background: AppColors.background,
  card: AppColors.card,
  textPrimary: AppColors.textPrimary,
  textSecondary: AppColors.textSecondary,
  border: AppColors.border,
  divider: AppColors.divider,
  isDark: false,
);

const AppPalette _darkPalette = AppPalette(
  background: AppColors.backgroundDark,
  card: AppColors.cardDark,
  textPrimary: AppColors.textPrimaryDark,
  textSecondary: AppColors.textSecondaryDark,
  border: AppColors.borderDark,
  divider: Color(0xFF1F2937),
  isDark: true,
);

extension AppThemeX on BuildContext {
  AppPalette get palette => isDark ? _darkPalette : _lightPalette;

  bool get isDark => Theme.of(this).brightness == Brightness.dark;
}
