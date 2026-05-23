import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:syntrak/core/theme.dart';

/// Frosted surface used for auth forms and other elevated content.
class LiquidSurface extends StatelessWidget {
  const LiquidSurface({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(SyntrakSpacing.lg),
    this.maxWidth = 400,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fillColor = isDark
        ? SyntrakColors.darkSurface.withValues(alpha: 0.72)
        : SyntrakColors.surface.withValues(alpha: 0.82);
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.white.withValues(alpha: 0.65);

    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(SyntrakRadius.xl),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: fillColor,
              borderRadius: BorderRadius.circular(SyntrakRadius.xl),
              border: Border.all(color: borderColor),
              boxShadow: SyntrakElevation.md,
            ),
            child: Padding(
              padding: padding,
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
