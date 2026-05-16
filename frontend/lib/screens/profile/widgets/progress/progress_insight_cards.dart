import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:syntrak/core/theme.dart';
import 'package:syntrak/screens/profile/widgets/progress/progress_section_card.dart';

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
        const SizedBox(height: SyntrakSpacing.md),
        _GoalsCard(goals: goals),
        const SizedBox(height: SyntrakSpacing.md),
        _RelativeEffortCard(relativeEffort: relativeEffort),
        const SizedBox(height: SyntrakSpacing.md),
        _TrainingLogCard(trainingLog: trainingLog),
        const SizedBox(height: SyntrakSpacing.lg),
        _FreeTrialButton(),
        const SizedBox(height: SyntrakSpacing.xl),
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
                horizontal: SyntrakSpacing.md,
                vertical: SyntrakSpacing.lg,
              ),
              child: Text(
                'No best efforts yet. Complete activities to see your records!',
                style: SyntrakTypography.bodyMedium.copyWith(
                  color: SyntrakColors.textTertiary,
                ),
                textAlign: TextAlign.center,
              ),
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: efforts.map((effort) {
                return _BestEffortRow(
                  isPR: effort['isPR'] ?? false,
                  type: effort['type'] ?? '',
                  time: effort['time'] ?? '',
                  date: effort['date'] as DateTime? ?? DateTime.now(),
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
    required this.time,
    required this.date,
  });

  final bool isPR;
  final String type;
  final String time;
  final DateTime date;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: SyntrakSpacing.md,
        vertical: SyntrakSpacing.sm,
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isPR
                  ? SyntrakColors.accent.withOpacity(0.2)
                  : SyntrakColors.textTertiary.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isPR ? Icons.emoji_events : Icons.military_tech,
              color: isPR ? SyntrakColors.accent : SyntrakColors.textTertiary,
              size: 20,
            ),
          ),
          const SizedBox(width: SyntrakSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      isPR ? 'PR' : '2nd-fastest',
                      style: SyntrakTypography.labelMedium.copyWith(
                        color: SyntrakColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: SyntrakSpacing.xs),
                    Flexible(
                      child: Text(
                        type,
                        style: SyntrakTypography.bodyMedium.copyWith(
                          color: SyntrakColors.textSecondary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: SyntrakSpacing.xs / 2),
                Text(
                  DateFormat('d MMM yyyy').format(date),
                  style: SyntrakTypography.bodySmall.copyWith(
                    color: SyntrakColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            time,
            style: SyntrakTypography.bodyLarge.copyWith(
              color: SyntrakColors.textPrimary,
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
          horizontal: SyntrakSpacing.md,
          vertical: SyntrakSpacing.md,
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
                    backgroundColor: SyntrakColors.surfaceVariant,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      SyntrakColors.success,
                    ),
                  ),
                ),
                Icon(
                  Icons.downhill_skiing,
                  color: SyntrakColors.primary,
                  size: 24,
                ),
              ],
            ),
            const SizedBox(width: SyntrakSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    goals['description'] as String,
                    style: SyntrakTypography.bodyMedium.copyWith(
                      color: SyntrakColors.textPrimary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: SyntrakSpacing.xs),
                  Text(
                    '${weekly['current']}/${weekly['target']} activities',
                    style: SyntrakTypography.bodySmall.copyWith(
                      color: SyntrakColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: SyntrakColors.textTertiary,
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
        padding: const EdgeInsets.symmetric(vertical: SyntrakSpacing.sm),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _RelativeEffortRow(
              relativeEffort['current'] as int,
              'Jan 6 - Jan 12, 2026',
              SyntrakColors.error,
            ),
            Divider(
              height: 1,
              color: SyntrakColors.divider,
            ),
            _RelativeEffortRow(
              relativeEffort['previous'] as int,
              'Dec 30 - Jan 5, 2026',
              SyntrakColors.snowboard,
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
        horizontal: SyntrakSpacing.md,
        vertical: SyntrakSpacing.sm,
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(SyntrakRadius.md),
            ),
            child: Center(
              child: Text(
                value.toString(),
                style: SyntrakTypography.headlineSmall.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: SyntrakSpacing.md),
          Expanded(
            child: Text(
              dateRange,
              style: SyntrakTypography.bodyMedium.copyWith(
                color: SyntrakColors.textPrimary,
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
          horizontal: SyntrakSpacing.md,
          vertical: SyntrakSpacing.md,
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
                    style: SyntrakTypography.bodyMedium.copyWith(
                      color: SyntrakColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  '${trainingLog['distance']} km',
                  style: SyntrakTypography.headlineSmall.copyWith(
                    color: SyntrakColors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: SyntrakSpacing.md),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: ['M', 'T', 'W', 'T', 'F', 'S', 'S'].map((day) {
                return SizedBox(
                  width: 30,
                  child: Center(
                    child: Text(
                      day,
                      style: SyntrakTypography.labelSmall.copyWith(
                        color: SyntrakColors.textTertiary,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _FreeTrialButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: SyntrakSpacing.md),
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {},
        style: ElevatedButton.styleFrom(
          backgroundColor: SyntrakColors.accent,
          foregroundColor: SyntrakColors.textOnPrimary,
          padding: const EdgeInsets.symmetric(vertical: SyntrakSpacing.md),
        ),
        child: Text(
          'Start a free trial',
          style: SyntrakTypography.labelLarge,
        ),
      ),
    );
  }
}
