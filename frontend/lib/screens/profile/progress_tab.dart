import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:syntrak/core/theme.dart';
import 'package:syntrak/providers/activity_provider.dart';
import 'package:syntrak/screens/profile/widgets/progress/progress_activity_calendar.dart';
import 'package:syntrak/screens/profile/widgets/progress/progress_insight_cards.dart';
import 'package:syntrak/screens/profile/widgets/progress/progress_streaks_banner.dart';
import 'package:syntrak/screens/profile/widgets/progress/progress_weekly_overview.dart';
import 'package:syntrak/widgets/skeleton.dart';

class ProgressTab extends StatelessWidget {
  const ProgressTab({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ActivityProvider>();
    final stats = provider.stats;

    return RefreshIndicator(
      onRefresh: () => provider.loadActivities(refresh: true, forceNetwork: true),
      color: SyntrakColors.primary,
      child: ColoredBox(
        color: SyntrakColors.surface,
        child: stats == null
          ? const SkeletonFeedList()
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
                  const SizedBox(height: SyntrakSpacing.lg),
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
                  const SizedBox(height: SyntrakSpacing.xl),
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
