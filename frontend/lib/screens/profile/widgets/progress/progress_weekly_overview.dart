import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:snowtrak/core/theme.dart';
import 'package:snowtrak/models/activity.dart';
import 'package:snowtrak/screens/activities/widgets/activity_feed_formatters.dart';
import 'package:snowtrak/screens/profile/widgets/progress/progress_weekly_graph_painter.dart';

/// This week stats + 12-week distance sparkline.
class ProgressWeeklyOverview extends StatelessWidget {
  const ProgressWeeklyOverview({
    super.key,
    required this.weeklyStats,
    required this.activities,
  });

  final Map<String, dynamic> weeklyStats;
  final List<Activity> activities;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: SnowtrakSpacing.md),
      padding: const EdgeInsets.all(SnowtrakSpacing.md),
      decoration: BoxDecoration(
        color: SnowtrakColors.surface,
        borderRadius: BorderRadius.circular(SnowtrakRadius.lg),
        border: Border.all(color: SnowtrakColors.divider),
        boxShadow: SnowtrakElevation.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'This week',
            style: SnowtrakTypography.headlineMedium.copyWith(
              color: SnowtrakColors.textPrimary,
            ),
          ),
          const SizedBox(height: SnowtrakSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Expanded(
                child: _statItem(
                  'Distance',
                  '${(weeklyStats['distance'] as num).toStringAsFixed(1)} km',
                ),
              ),
              Expanded(
                child: _statItem(
                  'Time',
                  formatDurationMinutes(weeklyStats['time'] as int),
                ),
              ),
              Expanded(
                child: _statItem(
                  'Elev Gain',
                  formatElevation((weeklyStats['elevGain'] as num).toDouble()),
                ),
              ),
            ],
          ),
          const SizedBox(height: SnowtrakSpacing.lg),
          Text(
            'Past 12 weeks',
            style: SnowtrakTypography.bodyLarge.copyWith(
              color: SnowtrakColors.textPrimary,
            ),
          ),
          const SizedBox(height: SnowtrakSpacing.sm),
          SizedBox(
            height: 140,
            child: TwelveWeekSparkline(activities: activities),
          ),
        ],
      ),
    );
  }

  Widget _statItem(String label, String value) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: SnowtrakTypography.headlineSmall.copyWith(
            color: SnowtrakColors.textPrimary,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: SnowtrakSpacing.xs),
        Text(
          label,
          style: SnowtrakTypography.labelSmall.copyWith(
            color: SnowtrakColors.textTertiary,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

class TwelveWeekSparkline extends StatelessWidget {
  const TwelveWeekSparkline({super.key, required this.activities});

  final List<Activity> activities;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final weeks = List.generate(12, (index) {
      final weekStart =
          now.subtract(Duration(days: (11 - index) * 7 + now.weekday - 1));
      final weekEnd = weekStart.add(const Duration(days: 6));

      int weekCount = 0;
      for (final activity in activities) {
        if (activity.startTime
                .isAfter(weekStart.subtract(const Duration(days: 1))) &&
            activity.startTime.isBefore(weekEnd.add(const Duration(days: 1)))) {
          weekCount++;
        }
      }

      return {
        'date': weekStart,
        'count': weekCount.toDouble(),
      };
    });

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 100,
          width: double.infinity,
          child: CustomPaint(
            painter: ProgressWeeklyGraphPainter(weeks),
          ),
        ),
        const SizedBox(height: SnowtrakSpacing.xs),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: SnowtrakSpacing.xs),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (weeks.isNotEmpty)
                Text(
                  DateFormat('MMM').format(weeks[0]['date'] as DateTime),
                  style: SnowtrakTypography.labelSmall.copyWith(
                    color: SnowtrakColors.textTertiary,
                  ),
                ),
              if (weeks.length > 6)
                Text(
                  DateFormat('MMM').format(weeks[6]['date'] as DateTime),
                  style: SnowtrakTypography.labelSmall.copyWith(
                    color: SnowtrakColors.textTertiary,
                  ),
                ),
              if (weeks.length > 11)
                Text(
                  DateFormat('MMM').format(weeks[11]['date'] as DateTime),
                  style: SnowtrakTypography.labelSmall.copyWith(
                    color: SnowtrakColors.textTertiary,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
