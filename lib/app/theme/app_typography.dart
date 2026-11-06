import 'package:flutter/material.dart';

import 'app_colors.dart';

abstract final class AppTypography {
  static const fontFamily = 'Inter';

  static const _tabular = [FontFeature.tabularFigures()];

  static TextStyle numeric(
    TextStyle base, {
    FontWeight? weight,
    double? size,
    Color? color,
    double? letterSpacing,
  }) {
    return base.copyWith(
      fontFeatures: _tabular,
      fontWeight: weight,
      fontSize: size,
      color: color,
      letterSpacing: letterSpacing,
    );
  }

  static TextTheme textTheme(PulsePalette palette) {
    final primary = palette.textPrimary;
    final secondary = palette.textSecondary;
    final muted = palette.textMuted;

    return TextTheme(
      displayLarge: TextStyle(
        fontFamily: fontFamily,
        fontSize: 44,
        height: 1.02,
        fontWeight: FontWeight.w700,
        letterSpacing: -1.8,
        color: primary,
        fontFeatures: _tabular,
      ),
      displayMedium: TextStyle(
        fontFamily: fontFamily,
        fontSize: 34,
        height: 1.06,
        fontWeight: FontWeight.w700,
        letterSpacing: -1.2,
        color: primary,
        fontFeatures: _tabular,
      ),
      displaySmall: TextStyle(
        fontFamily: fontFamily,
        fontSize: 28,
        height: 1.1,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.8,
        color: primary,
        fontFeatures: _tabular,
      ),
      headlineLarge: TextStyle(
        fontFamily: fontFamily,
        fontSize: 26,
        height: 1.12,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.6,
        color: primary,
      ),
      headlineMedium: TextStyle(
        fontFamily: fontFamily,
        fontSize: 22,
        height: 1.18,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.35,
        color: primary,
      ),
      headlineSmall: TextStyle(
        fontFamily: fontFamily,
        fontSize: 19,
        height: 1.22,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
        color: primary,
      ),
      titleLarge: TextStyle(
        fontFamily: fontFamily,
        fontSize: 17,
        height: 1.28,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.1,
        color: primary,
      ),
      titleMedium: TextStyle(
        fontFamily: fontFamily,
        fontSize: 15,
        height: 1.3,
        fontWeight: FontWeight.w600,
        color: primary,
      ),
      titleSmall: TextStyle(
        fontFamily: fontFamily,
        fontSize: 13.5,
        height: 1.3,
        fontWeight: FontWeight.w600,
        color: primary,
      ),
      bodyLarge: TextStyle(
        fontFamily: fontFamily,
        fontSize: 15,
        height: 1.5,
        fontWeight: FontWeight.w400,
        color: secondary,
      ),
      bodyMedium: TextStyle(
        fontFamily: fontFamily,
        fontSize: 13.5,
        height: 1.48,
        fontWeight: FontWeight.w400,
        color: secondary,
      ),
      bodySmall: TextStyle(
        fontFamily: fontFamily,
        fontSize: 12,
        height: 1.45,
        fontWeight: FontWeight.w400,
        color: muted,
      ),
      labelLarge: TextStyle(
        fontFamily: fontFamily,
        fontSize: 13,
        height: 1.2,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
        color: primary,
      ),
      labelMedium: TextStyle(
        fontFamily: fontFamily,
        fontSize: 11.5,
        height: 1.2,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.3,
        color: secondary,
      ),
      labelSmall: TextStyle(
        fontFamily: fontFamily,
        fontSize: 10,
        height: 1.2,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.1,
        color: muted,
      ),
    );
  }
}
