import 'package:flutter/material.dart';
import 'package:syntrak/core/theme.dart';

class ProgressStreaksBanner extends StatelessWidget {
  const ProgressStreaksBanner({
    super.key,
    required this.currentStreak,
    required this.longestStreak,
  });

  final int currentStreak;
  final int longestStreak;

  @override
  Widget build(BuildContext context) {
    final hasStreak = currentStreak > 0;
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
            color: hasStreak ? SyntrakColors.accent : SyntrakColors.textTertiary,
            size: 24,
          ),
          const SizedBox(width: SyntrakSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasStreak
                      ? '$currentStreak-week streak'
                      : 'No active streak',
                  style: SyntrakTypography.labelLarge.copyWith(
                    color: SyntrakColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: SyntrakSpacing.xs),
                Text(
                  longestStreak > 0
                      ? 'Best: $longestStreak ${longestStreak == 1 ? 'week' : 'weeks'} — log one activity a week to keep it alive'
                      : 'Log one activity a week to build your streak',
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
