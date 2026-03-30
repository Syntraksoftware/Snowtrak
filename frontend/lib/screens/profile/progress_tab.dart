import 'package:flutter/material.dart';
import 'package:syntrak/core/theme.dart';
import 'package:syntrak/models/activity.dart';
import 'package:syntrak/screens/profile/widgets/progress/progress_activity_calendar.dart';
import 'package:syntrak/screens/profile/widgets/progress/progress_insight_cards.dart';
import 'package:syntrak/screens/profile/widgets/progress/progress_streaks_banner.dart';
import 'package:syntrak/screens/profile/widgets/progress/progress_weekly_overview.dart';

class ProgressTab extends StatefulWidget {
  const ProgressTab({
    super.key,
    required this.activities,
  });

  final List<Activity> activities;

  @override
  State<ProgressTab> createState() => _ProgressTabState();
}

class _ProgressTabState extends State<ProgressTab> {
  final Map<String, dynamic> _weeklyStats = {
    'distance': 0.0,
    'time': 0,
    'elevGain': 0.0,
  };

  final List<Map<String, dynamic>> _bestEfforts = [];
  final Map<String, dynamic> _goals = {
    'weeklyRuns': {'current': 1, 'target': 4},
    'description': 'Weekly Skiing Goal',
  };
  final Map<String, dynamic> _relativeEffort = {
    'current': 89,
    'previous': 22,
  };
  final Map<String, dynamic> _trainingLog = {
    'distance': 10.9,
    'dateRange': 'Jan 5 - Jan 11, 2026',
  };

  final Set<DateTime> _activityDays = {};

  @override
  void initState() {
    super.initState();
    _calculateStats();
  }

  void _calculateStats() {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));

    double weeklyDistance = 0;
    int weeklyTime = 0;
    double weeklyElevGain = 0;

    _bestEfforts.clear();
    _activityDays.clear();

    for (final activity in widget.activities) {
      if (activity.startTime.isAfter(weekStart)) {
        weeklyDistance += activity.distance / 1000;
        weeklyTime += activity.duration ~/ 60;
        weeklyElevGain += activity.elevationGain;
        _activityDays.add(DateTime(
          activity.startTime.year,
          activity.startTime.month,
          activity.startTime.day,
        ));
      }
    }

    if (widget.activities.isNotEmpty) {
      final sortedByDistance = List<Activity>.from(widget.activities)
        ..sort((a, b) => b.distance.compareTo(a.distance));

      if (sortedByDistance.isNotEmpty) {
        _bestEfforts.add({
          'type': '5K',
          'time': '26:54',
          'date': sortedByDistance.first.startTime,
          'isPR': true,
        });
      }
    }

    setState(() {
      _weeklyStats['distance'] = weeklyDistance;
      _weeklyStats['time'] = weeklyTime;
      _weeklyStats['elevGain'] = weeklyElevGain;
    });
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        await Future.delayed(const Duration(seconds: 1));
      },
      color: SyntrakColors.primary,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const ProgressStreaksBanner(),
            ProgressWeeklyOverview(
              weeklyStats: _weeklyStats,
              activities: widget.activities,
            ),
            const SizedBox(height: SyntrakSpacing.lg),
            ProgressInsightCards(
              bestEfforts: _bestEfforts,
              goals: _goals,
              relativeEffort: _relativeEffort,
              trainingLog: _trainingLog,
            ),
            ProgressActivityCalendar(activityDays: _activityDays),
            const SizedBox(height: SyntrakSpacing.xl),
          ],
        ),
      ),
    );
  }
}
