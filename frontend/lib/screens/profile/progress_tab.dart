import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:snowtrak/core/theme.dart';
import 'package:snowtrak/providers/activity_provider.dart';
import 'package:snowtrak/screens/profile/widgets/progress/progress_activity_calendar.dart';
import 'package:snowtrak/screens/profile/widgets/progress/progress_insight_cards.dart';
import 'package:snowtrak/screens/profile/widgets/progress/progress_streaks_banner.dart';
import 'package:snowtrak/screens/profile/widgets/progress/progress_weekly_overview.dart';
import 'package:snowtrak/widgets/skeleton.dart';

class ProgressTab extends StatelessWidget {
  const ProgressTab({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ActivityProvider>();
    final stats = provider.stats;

    return RefreshIndicator(
      onRefresh: () => provider.loadActivities(refresh: true, forceNetwork: true),
      color: SnowtrakColors.primary,
      child: ColoredBox(
        color: SnowtrakColors.surface,
        child: provider.isLoading && stats == null
          ? const SkeletonFeedList()
          : stats == null
            ? const _EmptyProgressState()
            : SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ProgressStreaksBanner(
                    currentStreak: stats.currentStreak,
                    longestStreak: stats.longestStreak,
                  ),
                  ProgressWeeklyOverview(
                    weeklyStats: {
                      'distance': stats.weeklyDistanceKm,
                      'time': stats.weeklyTimeMin,
                      'elevGain': stats.weeklyElevGain,
                    },
                    activities: provider.activities,
                  ),
                  const SizedBox(height: SnowtrakSpacing.lg),
                  ProgressInsightCards(
                    bestEfforts: stats.bestEfforts,
                    goals: {
                      'weeklyRuns': {
                        'current': stats.weeklySessionCount,
                        'target': 4,
                      },
                      'description': 'Weekly Skiing Goal',
                    },
                    relativeEffort: {
                      'current': stats.weeklySessionCount,
                      'previous': stats.lastWeekSessionCount,
                      // ponytail: session counts stand in for training load — replace when CTL/ATL lands
                      'currentRange': _weekRange(stats.weekStart),
                      'lastRange': _weekRange(stats.weekStart.subtract(const Duration(days: 7))),
                    },
                    trainingLog: {
                      'distance': stats.weeklyDistanceKm.toStringAsFixed(1),
                      'dateRange': _weekRange(stats.weekStart),
                      'activeDays': stats.activityDays
                          .where((d) => !d.isBefore(stats.weekStart))
                          .map((d) => d.weekday) // 1=Mon … 7=Sun
                          .toSet(),
                    },
                  ),
                  ProgressActivityCalendar(activityDays: stats.activityDays),
                  const SizedBox(height: SnowtrakSpacing.xl),
                ],
              ),
          ),
        ),
    );
  }

  String _weekRange(DateTime monday) {
    final sunday = monday.add(const Duration(days: 6));
    final fmt = DateFormat('MMM d');
    return '${fmt.format(monday)} – ${fmt.format(sunday)}';
  }
}

class _EmptyProgressState extends StatelessWidget {
  const _EmptyProgressState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.downhill_skiing,
            size: 56,
            color: SnowtrakColors.textTertiary,
          ),
          const SizedBox(height: SnowtrakSpacing.md),
          Text(
            'No activities yet',
            style: SnowtrakTypography.headlineSmall.copyWith(
              color: SnowtrakColors.textPrimary,
            ),
          ),
          const SizedBox(height: SnowtrakSpacing.xs),
          Text(
            'Record your first run to see your progress here.',
            style: SnowtrakTypography.bodyMedium.copyWith(
              color: SnowtrakColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
