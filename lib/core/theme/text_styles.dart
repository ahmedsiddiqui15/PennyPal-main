import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

class AppTextStyles {
  AppTextStyles._();

  static TextStyle get display => GoogleFonts.poppins(
        fontSize: 34,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
      );

  static TextStyle get heading => GoogleFonts.poppins(
        fontSize: 26,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.4,
      );

  static TextStyle get title => GoogleFonts.poppins(
        fontSize: 19,
        fontWeight: FontWeight.w600,
      );

  static TextStyle get subtitle => GoogleFonts.inter(
        fontSize: 15,
        fontWeight: FontWeight.w600,
      );

  static TextStyle get body => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.45,
      );

  static TextStyle get caption => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.2,
      );

  static TextStyle get button => GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.2,
      );

  static TextStyle get amount => GoogleFonts.poppins(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.6,
      );

  
  static TextTheme textTheme(Color primaryText, Color secondaryText) {
    return TextTheme(
      displayLarge: display.copyWith(color: primaryText),
      displayMedium: heading.copyWith(color: primaryText),
      headlineMedium: heading.copyWith(color: primaryText),
      headlineSmall: title.copyWith(color: primaryText),
      titleLarge: title.copyWith(color: primaryText),
      titleMedium: subtitle.copyWith(color: primaryText),
      bodyLarge: body.copyWith(color: primaryText),
      bodyMedium: body.copyWith(color: secondaryText),
      bodySmall: caption.copyWith(color: secondaryText),
      labelLarge: button.copyWith(color: primaryText),
      labelMedium: caption.copyWith(color: secondaryText),
      labelSmall: caption.copyWith(color: secondaryText),
    );
  }
}

class AppShadows {
  AppShadows._();

  static List<BoxShadow> soft(Color color) => [
        BoxShadow(
          color: color.withValues(alpha: 0.06),
          blurRadius: 24,
          offset: const Offset(0, 10),
        ),
      ];

  static List<BoxShadow> lifted(Color color) => [
        BoxShadow(
          color: color.withValues(alpha: 0.10),
          blurRadius: 32,
          offset: const Offset(0, 16),
        ),
      ];

  static const List<BoxShadow> amber = [
    BoxShadow(
      color: Color(0x33F59E0B),
      blurRadius: 24,
      offset: Offset(0, 12),
    ),
  ];
}

const Color kBrand = AppColors.primary;
