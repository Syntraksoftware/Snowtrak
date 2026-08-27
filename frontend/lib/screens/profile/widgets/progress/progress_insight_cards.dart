import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:snowtrak/core/theme.dart';
import 'package:snowtrak/screens/profile/widgets/progress/progress_section_card.dart';

/// Best efforts, goals, relative effort, training log, and trial CTA.
class ProgressInsightCards extends StatelessWidget {
  const ProgressInsightCards({
    super.key,
    required this.bestEfforts,
    required this.goals,
    required this.relativeEffort,
    required this.trainingLog,
  });

  final List<Map<String, dynamic>> bestEfforts;
  final Map<String, dynamic> goals;
  final Map<String, dynamic> relativeEffort;
  final Map<String, dynamic> trainingLog;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _BestEffortsCard(efforts: bestEfforts),
        const SizedBox(height: SnowtrakSpacing.md),
        _GoalsCard(goals: goals),
        const SizedBox(height: SnowtrakSpacing.md),
        _RelativeEffortCard(relativeEffort: relativeEffort),
        const SizedBox(height: SnowtrakSpacing.md),
        _TrainingLogCard(trainingLog: trainingLog),
        const SizedBox(height: SnowtrakSpacing.xl),
      ],
    );
  }
}

class _BestEffortsCard extends StatelessWidget {
  const _BestEffortsCard({required this.efforts});

  final List<Map<String, dynamic>> efforts;

  @override
  Widget build(BuildContext context) {
    return ProgressSectionCard(
      title: 'Best Efforts',
      child: efforts.isEmpty
          ? Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: SnowtrakSpacing.md,
                vertical: SnowtrakSpacing.lg,
              ),
              child: Text(
                'No best efforts yet. Complete activities to see your records!',
                style: SnowtrakTypography.bodyMedium.copyWith(
                  color: SnowtrakColors.textTertiary,
                ),
                textAlign: TextAlign.center,
              ),
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: efforts.map((effort) {
                return _BestEffortRow(
                  isPR: effort['is_pr'] ?? effort['isPR'] ?? false,
                  type: effort['type'] ?? '',
                  value: effort['value'] ?? effort['time'] ?? '',
                  date: effort['date'] is DateTime
                      ? effort['date'] as DateTime
                      : DateTime.tryParse(effort['date'] as String? ?? '') ?? DateTime.now(),
                );
              }).toList(),
            ),
    );
  }
}

class _BestEffortRow extends StatelessWidget {
  const _BestEffortRow({
    required this.isPR,
    required this.type,
    required this.value,
    required this.date,
  });

  final bool isPR;
  final String type;
  final String value;
  final DateTime date;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: SnowtrakSpacing.md,
        vertical: SnowtrakSpacing.sm,
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isPR
                  ? SnowtrakColors.accent.withOpacity(0.2)
                  : SnowtrakColors.textTertiary.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isPR ? Icons.emoji_events : Icons.military_tech,
              color: isPR ? SnowtrakColors.accent : SnowtrakColors.textTertiary,
              size: 20,
            ),
          ),
          const SizedBox(width: SnowtrakSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      isPR ? 'PR' : '2nd-fastest',
                      style: SnowtrakTypography.labelMedium.copyWith(
                        color: SnowtrakColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: SnowtrakSpacing.xs),
                    Flexible(
                      child: Text(
                        type,
                        style: SnowtrakTypography.bodyMedium.copyWith(
                          color: SnowtrakColors.textSecondary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: SnowtrakSpacing.xs / 2),
                Text(
                  DateFormat('d MMM yyyy').format(date),
                  style: SnowtrakTypography.bodySmall.copyWith(
                    color: SnowtrakColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            value,
            style: SnowtrakTypography.bodyLarge.copyWith(
              color: SnowtrakColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _GoalsCard extends StatelessWidget {
  const _GoalsCard({required this.goals});

  final Map<String, dynamic> goals;

  @override
  Widget build(BuildContext context) {
    final weekly = goals['weeklyRuns'] as Map<String, dynamic>;
    return ProgressSectionCard(
      title: 'Goals',
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: SnowtrakSpacing.md,
          vertical: SnowtrakSpacing.md,
        ),
        child: Row(
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 60,
                  height: 60,
                  child: CircularProgressIndicator(
                    value: weekly['current'] / weekly['target'],
                    strokeWidth: 4,
                    backgroundColor: SnowtrakColors.surfaceVariant,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      SnowtrakColors.primary,
                    ),
                  ),
                ),
                const Icon(
                  Icons.downhill_skiing,
                  color: SnowtrakColors.primary,
                  size: 24,
                ),
              ],
            ),
            const SizedBox(width: SnowtrakSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    goals['description'] as String,
                    style: SnowtrakTypography.bodyMedium.copyWith(
                      color: SnowtrakColors.textPrimary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: SnowtrakSpacing.xs),
                  Text(
                    '${weekly['current']}/${weekly['target']} activities',
                    style: SnowtrakTypography.bodySmall.copyWith(
                      color: SnowtrakColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: SnowtrakColors.textTertiary,
            ),
          ],
        ),
      ),
    );
  }
}

class _RelativeEffortCard extends StatelessWidget {
  const _RelativeEffortCard({required this.relativeEffort});

  final Map<String, dynamic> relativeEffort;

  @override
  Widget build(BuildContext context) {
    return ProgressSectionCard(
      title: 'Relative Effort',
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: SnowtrakSpacing.sm),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _RelativeEffortRow(
              relativeEffort['current'] as int,
              relativeEffort['currentRange'] as String? ?? '',
              SnowtrakColors.primary,
            ),
            const Divider(
              height: 1,
              color: SnowtrakColors.divider,
            ),
            _RelativeEffortRow(
              relativeEffort['previous'] as int,
              relativeEffort['lastRange'] as String? ?? '',
              SnowtrakColors.textTertiary,
            ),
          ],
        ),
      ),
    );
  }
}

class _RelativeEffortRow extends StatelessWidget {
  const _RelativeEffortRow(this.value, this.dateRange, this.color);

  final int value;
  final String dateRange;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: SnowtrakSpacing.md,
        vertical: SnowtrakSpacing.sm,
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(SnowtrakRadius.md),
            ),
            child: Center(
              child: Text(
                value.toString(),
                style: SnowtrakTypography.headlineSmall.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: SnowtrakSpacing.md),
          Expanded(
            child: Text(
              dateRange,
              style: SnowtrakTypography.bodyMedium.copyWith(
                color: SnowtrakColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TrainingLogCard extends StatelessWidget {
  const _TrainingLogCard({required this.trainingLog});

  final Map<String, dynamic> trainingLog;

  @override
  Widget build(BuildContext context) {
    return ProgressSectionCard(
      title: 'Training Log',
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: SnowtrakSpacing.md,
          vertical: SnowtrakSpacing.md,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    trainingLog['dateRange'] as String,
                    style: SnowtrakTypography.bodyMedium.copyWith(
                      color: SnowtrakColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  '${trainingLog['distance']} km',
                  style: SnowtrakTypography.headlineSmall.copyWith(
                    color: SnowtrakColors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: SnowtrakSpacing.md),
            Builder(builder: (context) {
              final activeDays = (trainingLog['activeDays'] as Set<int>?) ?? <int>{};
              const labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: List.generate(7, (i) {
                  final isActive = activeDays.contains(i + 1);
                  return Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: isActive
                          ? SnowtrakColors.primary.withValues(alpha: 0.15)
                          : Colors.transparent,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        labels[i],
                        style: SnowtrakTypography.labelSmall.copyWith(
                          color: isActive ? SnowtrakColors.primary : SnowtrakColors.textTertiary,
                          fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ),
                  );
                }),
              );
            }),
          ],
        ),
      ),
    );
  }
}
