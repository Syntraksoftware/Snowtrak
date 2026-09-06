import 'package:flutter/material.dart';
import 'package:snowtrak/core/theme.dart';

/// Shared styling for the auth screens and the older "liquid" cards.
///
/// Colours are not here. They used to be — `brand`, `brandMuted`,
/// `fieldBorder` and `socialBorder` were `static const` aliases onto
/// `SnowtrakColors`, which made this a second token layer that could never
/// answer a theme change. Call sites read `context.colors` directly now, and
/// the text styles take a context for the same reason.
///
/// What remains is geometry, which is the same in every theme.
abstract final class SnowtrakAuthTheme {
  static const fieldRadius = SnowtrakRadius.md;
  static const buttonRadius = SnowtrakRadius.md;

  static TextStyle pageTitle(BuildContext context) =>
      SnowtrakTypography.displaySmall.copyWith(
        fontSize: 26,
        fontWeight: FontWeight.w700,
        color: context.colors.textPrimary,
        height: 1.2,
      );

  static TextStyle fieldLabel(BuildContext context) =>
      SnowtrakTypography.labelLarge.copyWith(
        fontWeight: FontWeight.w600,
        color: context.colors.textPrimary,
      );

  static TextStyle legalText(BuildContext context) =>
      SnowtrakTypography.bodySmall.copyWith(
        color: context.colors.textSecondary,
        height: 1.45,
      );
}
