import 'package:flutter/material.dart';
import 'package:snowtrak/core/theme.dart';

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
      margin: const EdgeInsets.all(SnowtrakSpacing.md),
      padding: const EdgeInsets.all(SnowtrakSpacing.md),
      decoration: BoxDecoration(
        color: SnowtrakColors.surfaceVariant,
        borderRadius: BorderRadius.circular(SnowtrakRadius.lg),
      ),
      child: Row(
        children: [
          Icon(
            Icons.local_fire_department,
            color: hasStreak ? SnowtrakColors.accent : SnowtrakColors.textTertiary,
            size: 24,
          ),
          const SizedBox(width: SnowtrakSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasStreak
                      ? '$currentStreak-week streak'
                      : 'No active streak',
                  style: SnowtrakTypography.labelLarge.copyWith(
                    color: SnowtrakColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: SnowtrakSpacing.xs),
                Text(
                  longestStreak > 0
                      ? 'Best: $longestStreak ${longestStreak == 1 ? 'week' : 'weeks'} — log one activity a week to keep it alive'
                      : 'Log one activity a week to build your streak',
                  style: SnowtrakTypography.bodySmall.copyWith(
                    color: SnowtrakColors.textSecondary,
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
