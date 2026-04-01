import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:syntrak/core/theme.dart';
import 'package:syntrak/models/activity.dart';
import 'package:syntrak/screens/profile/widgets/progress/progress_weekly_graph_painter.dart';

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
      margin: const EdgeInsets.symmetric(horizontal: SyntrakSpacing.md),
      padding: const EdgeInsets.all(SyntrakSpacing.md),
      decoration: BoxDecoration(
        color: SyntrakColors.surface,
        borderRadius: BorderRadius.circular(SyntrakRadius.lg),
        border: Border.all(color: SyntrakColors.divider),
        boxShadow: SyntrakElevation.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'This week',
            style: SyntrakTypography.headlineMedium.copyWith(
              color: SyntrakColors.textPrimary,
            ),
          ),
          const SizedBox(height: SyntrakSpacing.md),
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
                  '${weeklyStats['time']}m',
                ),
              ),
              Expanded(
                child: _statItem(
                  'Elev Gain',
                  '${(weeklyStats['elevGain'] as num).toStringAsFixed(0)} m',
                ),
              ),
            ],
          ),
          const SizedBox(height: SyntrakSpacing.lg),
          Text(
            'Past 12 weeks',
            style: SyntrakTypography.bodyLarge.copyWith(
              color: SyntrakColors.textPrimary,
            ),
          ),
          const SizedBox(height: SyntrakSpacing.sm),
          SizedBox(
            height: 140,
            child: _TwelveWeekGraph(activities: activities),
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
          style: SyntrakTypography.headlineSmall.copyWith(
            color: SyntrakColors.textPrimary,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: SyntrakSpacing.xs),
        Text(
          label,
          style: SyntrakTypography.labelSmall.copyWith(
            color: SyntrakColors.textTertiary,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

class _TwelveWeekGraph extends StatelessWidget {
  const _TwelveWeekGraph({required this.activities});

  final List<Activity> activities;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final weeks = List.generate(12, (index) {
      final weekStart =
          now.subtract(Duration(days: (11 - index) * 7 + now.weekday - 1));
      final weekEnd = weekStart.add(const Duration(days: 6));

      double weekDistance = 0.0;
      for (final activity in activities) {
        if (activity.startTime
                .isAfter(weekStart.subtract(const Duration(days: 1))) &&
            activity.startTime.isBefore(weekEnd.add(const Duration(days: 1)))) {
          weekDistance += activity.distance / 1000;
        }
      }

      return {
        'date': weekStart,
        'distance': weekDistance,
      };
    });

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 100,
          child: CustomPaint(
            painter: ProgressWeeklyGraphPainter(weeks),
            child: Container(),
          ),
        ),
        const SizedBox(height: SyntrakSpacing.xs),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: SyntrakSpacing.xs),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (weeks.isNotEmpty)
                Text(
                  DateFormat('MMM').format(weeks[0]['date'] as DateTime),
                  style: SyntrakTypography.labelSmall.copyWith(
                    color: SyntrakColors.textTertiary,
                  ),
                ),
              if (weeks.length > 6)
                Text(
                  DateFormat('MMM').format(weeks[6]['date'] as DateTime),
                  style: SyntrakTypography.labelSmall.copyWith(
                    color: SyntrakColors.textTertiary,
                  ),
                ),
              if (weeks.length > 11)
                Text(
                  DateFormat('MMM').format(weeks[11]['date'] as DateTime),
                  style: SyntrakTypography.labelSmall.copyWith(
                    color: SyntrakColors.textTertiary,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
