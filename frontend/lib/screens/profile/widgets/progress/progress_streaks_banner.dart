import 'package:flutter/material.dart';
import 'package:syntrak/core/theme.dart';

class ProgressStreaksBanner extends StatelessWidget {
  const ProgressStreaksBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(SyntrakSpacing.md),
      padding: const EdgeInsets.all(SyntrakSpacing.md),
      decoration: BoxDecoration(
        color: SyntrakColors.surfaceVariant,
        borderRadius: BorderRadius.circular(SyntrakRadius.lg),
      ),
      child: Row(
        children: [
          Icon(
            Icons.local_fire_department,
            color: SyntrakColors.accent,
            size: 24,
          ),
          const SizedBox(width: SyntrakSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Scroll down for streaks',
                  style: SyntrakTypography.labelLarge.copyWith(
                    color: SyntrakColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: SyntrakSpacing.xs),
                Text(
                  'Build habits with streaks - log one activity a week to keep it alive',
                  style: SyntrakTypography.bodySmall.copyWith(
                    color: SyntrakColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
