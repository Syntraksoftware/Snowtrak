import 'package:flutter/material.dart';
import 'package:syntrak/core/theme.dart';

/// Standard titled card shell used across the progress tab.
class ProgressSectionCard extends StatelessWidget {
  const ProgressSectionCard({
    super.key,
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: SyntrakSpacing.md),
      decoration: BoxDecoration(
        color: SyntrakColors.surface,
        borderRadius: BorderRadius.circular(SyntrakRadius.lg),
        border: Border.all(color: SyntrakColors.divider),
        boxShadow: SyntrakElevation.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              SyntrakSpacing.md,
              SyntrakSpacing.md,
              SyntrakSpacing.md,
              SyntrakSpacing.sm,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: SyntrakTypography.headlineSmall.copyWith(
                    color: SyntrakColors.textPrimary,
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: SyntrakColors.textTertiary,
                  size: 20,
                ),
              ],
            ),
          ),
          child,
          const SizedBox(height: SyntrakSpacing.sm),
        ],
      ),
    );
  }
}
