import 'package:flutter/material.dart';
import 'package:snowtrak/core/theme.dart';

/// Snowtrak auth screens — dark blue accent on a clean white canvas.
abstract final class SnowtrakAuthTheme {
  static const brand = Color(0xFF0D47A1);
  static const brandMuted = Color(0xFF5C7FA8);
  static const fieldBorder = Color(0xFFE0E0E0);
  static const socialBorder = Color(0xFFD9D9D9);

  static const fieldRadius = 14.0;
  static const buttonRadius = 999.0;

  static TextStyle get pageTitle => SnowtrakTypography.displaySmall.copyWith(
        fontSize: 26,
        fontWeight: FontWeight.w700,
        color: SnowtrakColors.textPrimary,
        height: 1.2,
      );

  static TextStyle get fieldLabel => SnowtrakTypography.labelLarge.copyWith(
        fontWeight: FontWeight.w600,
        color: SnowtrakColors.textPrimary,
      );

  static TextStyle get legalText => SnowtrakTypography.bodySmall.copyWith(
        color: SnowtrakColors.textSecondary,
        height: 1.45,
      );
}
