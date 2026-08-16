import 'package:flutter/material.dart';
import 'package:snowtrak/core/theme.dart';

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
      margin: const EdgeInsets.symmetric(horizontal: SnowtrakSpacing.md),
      decoration: BoxDecoration(
        color: SnowtrakColors.surface,
        borderRadius: BorderRadius.circular(SnowtrakRadius.lg),
        border: Border.all(color: SnowtrakColors.divider),
        boxShadow: SnowtrakElevation.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              SnowtrakSpacing.md,
              SnowtrakSpacing.md,
              SnowtrakSpacing.md,
              SnowtrakSpacing.sm,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: SnowtrakTypography.headlineSmall.copyWith(
                    color: SnowtrakColors.textPrimary,
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: SnowtrakColors.textTertiary,
                  size: 20,
                ),
              ],
            ),
          ),
          child,
          const SizedBox(height: SnowtrakSpacing.sm),
        ],
      ),
    );
  }
}
