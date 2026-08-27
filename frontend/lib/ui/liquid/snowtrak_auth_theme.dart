import 'package:flutter/material.dart';
import 'package:snowtrak/core/theme.dart';

/// Shared styling for the auth screens and the older "liquid" cards.
///
/// The brand accent is ink (`Core — Colour / action/primary`) — the same one the
/// tabs use, so login and Home no longer show two different blues.
abstract final class SnowtrakAuthTheme {
  static const brand = SnowtrakColors.ink;
  static const brandMuted = SnowtrakColors.neutral500;
  static const fieldBorder = SnowtrakColors.border;
  static const socialBorder = SnowtrakColors.border;

  static const fieldRadius = SnowtrakRadius.md;
  static const buttonRadius = SnowtrakRadius.md;

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
