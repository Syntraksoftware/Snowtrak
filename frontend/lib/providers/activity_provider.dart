import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:syntrak/core/errors/app_result.dart';
import 'package:syntrak/core/logging/app_logger.dart';
import 'package:syntrak/helpers/mock_activities.dart';
import 'package:syntrak/models/activity.dart';
import 'package:syntrak/models/user_stats.dart';
import 'package:syntrak/services/activities_service.dart';
import 'package:syntrak/services/feed/activities_feed_cache.dart';
import 'package:syntrak/services/feed/feed_rebase.dart';

class ActivityProvider extends ChangeNotifier {
  ActivityProvider(
    this._activitiesService,
    this._feedCache,
  );

  final ActivitiesService _activitiesService;
  final ActivitiesFeedCache _feedCache;
  List<Activity> _activities = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _currentPage = 1;
  String? _error;
  UserStats? _stats;
  static const int _pageSize = 20;

  List<Activity> get activities => _activities;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasMore => _hasMore;
  String? get error => _error;
  UserStats? get stats => _stats;

  Future<void> hydrateFromCache() async {
    final cached = await _feedCache.readPage(1);
    if (cached == null || cached.isEmpty) return;
    _activities = cached;
    _currentPage = 2;
    _hasMore = cached.length == _pageSize;
    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadActivities({
    bool refresh = false,
    bool forceNetwork = false,
  }) async {
    if (refresh) {
      _currentPage = 1;
      _hasMore = true;
      if (!forceNetwork) {
        final cached = await _feedCache.readPage(1);
        if (cached != null && cached.isNotEmpty) {
          _activities = cached;
          _currentPage = 2;
          _hasMore = cached.length == _pageSize;
        } else {
          _activities.clear();
        }
      } else {
        _activities.clear();
      }
    }

    if (_activities.isEmpty) {
      _isLoading = true;
      _error = null;
      notifyListeners();
    }

    final previousLocal = List<Activity>.from(_activities);
    final result = await _activitiesService.getActivities(
      page: 1,
      limit: _pageSize,
    );

    switch (result) {
      case AppSuccess(:final value):
        final merged = FeedRebase.mergeActivities(
          serverActivities: value,
          localActivities: previousLocal,
        );
        _activities = merged;
        _hasMore = value.length == _pageSize;
        _currentPage = 2;
        _isLoading = false;
        notifyListeners();
        await _feedCache.writePage(1, merged);
        unawaited(_fetchStats());
        unawaited(_prefetchPage(_currentPage));

      case AppFailure(:final error):
        _error = error.userMessage;
        _isLoading = false;

        if (_activities.isEmpty && _activitiesService.isDevEnvironment) {
          AppLogger.instance.warning(
            '[ActivityProvider] Activity API unavailable in dev, loading demo data',
            error: error.cause ?? error,
            stackTrace: error.stackTrace,
            notifyUser: true,
            userMessage: 'Activity service unavailable. Showing demo data.',
          );
          _error = 'Activity service unavailable. Showing demo data.';
          loadMockActivities();
        } else {
          AppLogger.instance.error(
            '[ActivityProvider] Failed to load activities',
            error: error.cause ?? error,
            stackTrace: error.stackTrace,
            notifyUser: true,
            userMessage: error.userMessage,
          );
          notifyListeners();
        }
    }
  }

  Future<void> loadMore() async {
    if (_isLoadingMore || !_hasMore) return;

    final targetPage = _currentPage;
    final cached = await _feedCache.readPage(targetPage);
    if (cached != null && cached.isNotEmpty) {
      _activities.addAll(cached);
      _hasMore = cached.length == _pageSize;
      _currentPage++;
      notifyListeners();
      unawaited(_prefetchPage(_currentPage));
      return;
    }

    _isLoadingMore = true;
    notifyListeners();

    final result = await _activitiesService.getActivities(
      page: targetPage,
      limit: _pageSize,
    );

    switch (result) {
      case AppSuccess(:final value):
        _activities.addAll(value);
        _hasMore = value.length == _pageSize;
        _currentPage++;
        _isLoadingMore = false;
        notifyListeners();
        await _feedCache.writePage(targetPage, value);
        unawaited(_prefetchPage(_currentPage));

      case AppFailure(:final error):
        _error = error.userMessage;
        _isLoadingMore = false;
        AppLogger.instance.warning(
          '[ActivityProvider] Failed to load more activities',
          error: error.cause ?? error,
          stackTrace: error.stackTrace,
          notifyUser: true,
          userMessage: error.userMessage,
        );
        notifyListeners();
    }
  }

  Future<void> _prefetchPage(int page) async {
    if (!_hasMore) return;

    final cached = await _feedCache.readPage(page);
    if (cached != null && cached.isNotEmpty) return;

    final result = await _activitiesService.getActivities(
      page: page,
      limit: _pageSize,
    );
    if (result case AppSuccess(:final value)) {
      if (value.isNotEmpty) {
        await _feedCache.writePage(page, value);
      }
    }
  }

  Future<Activity?> createActivity(Activity activity) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await _activitiesService.createActivity(activity);

    switch (result) {
      case AppSuccess(:final value):
        _activities.insert(0, value);
        _isLoading = false;
        notifyListeners();
        await _feedCache.writePage(1, _activities.take(_pageSize).toList());
        unawaited(_fetchStats());
        return value;

      case AppFailure(:final error):
        _error = error.userMessage;
        _isLoading = false;
        AppLogger.instance.error(
          '[ActivityProvider] Failed to create activity',
          error: error.cause ?? error,
          stackTrace: error.stackTrace,
          notifyUser: true,
          userMessage: error.userMessage,
        );
        notifyListeners();
        return null;
    }
  }

  Future<void> deleteActivity(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await _activitiesService.deleteActivity(id);

    switch (result) {
      case AppSuccess():
        _activities.removeWhere((a) => a.id == id);
        _isLoading = false;
        notifyListeners();
        if (_activities.isNotEmpty) {
          await _feedCache.writePage(1, _activities.take(_pageSize).toList());
        }
        unawaited(_fetchStats());

      case AppFailure(:final error):
        _error = error.userMessage;
        _isLoading = false;
        AppLogger.instance.error(
          '[ActivityProvider] Failed to delete activity',
          error: error.cause ?? error,
          stackTrace: error.stackTrace,
          notifyUser: true,
          userMessage: error.userMessage,
        );
        notifyListeners();
    }
  }

  Future<Activity?> getActivity(String id) async {
    final result = await _activitiesService.getActivity(id);

    switch (result) {
      case AppSuccess(:final value):
        return value;

      case AppFailure(:final error):
        _error = error.userMessage;
        AppLogger.instance.warning(
          '[ActivityProvider] Failed to get activity details',
          error: error.cause ?? error,
          stackTrace: error.stackTrace,
        );
        notifyListeners();
        return null;
    }
  }

  void loadMockActivities() {
    _activities = MockActivities.generateMockActivities();
    _hasMore = false;
    _isLoading = false;
    // ponytail: offline/mock path — no network, fall back to client-side compute
    _computeStatsFromActivities();
    notifyListeners();
  }

  // Fetches server-computed stats (covers all activities, not just page 1).
  Future<void> _fetchStats() async {
    final result = await _activitiesService.getMyStats();
    switch (result) {
      case AppSuccess(:final value):
        _stats = value;
        notifyListeners();
      case AppFailure(:final error):
        AppLogger.instance.warning(
          '[ActivityProvider] Failed to fetch stats — UI may show stale data',
          error: error.cause ?? error,
          stackTrace: error.stackTrace,
        );
    }
  }

  // ponytail: fallback for offline/mock mode only — server stats are authoritative
  void _computeStatsFromActivities() {
    if (_activities.isEmpty) {
      _stats = null;
      return;
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final weekStart = today.subtract(Duration(days: today.weekday - 1));
    final lastWeekStart = weekStart.subtract(const Duration(days: 7));
    final yearStart = DateTime(now.year, 1, 1);

    double weeklyDist = 0, weeklyElev = 0;
    double yearlyDist = 0, yearlyElev = 0;
    double allTimeDist = 0, allTimeElev = 0;
    int weeklyTime = 0, weeklyCount = 0, lastWeekCount = 0;
    int yearlyTime = 0, yearlyCount = 0;
    int allTimeTime = 0, allTimeCount = 0;
    final activityDays = <DateTime>{};

    for (final a in _activities) {
      final day = DateTime(a.startTime.year, a.startTime.month, a.startTime.day);
      activityDays.add(day);

      allTimeDist += a.distance / 1000;
      allTimeElev += a.elevationGain;
      allTimeTime += a.duration ~/ 60;
      allTimeCount++;

      if (!day.isBefore(yearStart)) {
        yearlyDist += a.distance / 1000;
        yearlyElev += a.elevationGain;
        yearlyTime += a.duration ~/ 60;
        yearlyCount++;
      }

      if (!day.isBefore(weekStart)) {
        weeklyDist += a.distance / 1000;
        weeklyElev += a.elevationGain;
        weeklyTime += a.duration ~/ 60;
        weeklyCount++;
      } else if (!day.isBefore(lastWeekStart)) {
        lastWeekCount++;
      }
    }

    final bestEfforts = <Map<String, dynamic>>[];
    final sorted = List.of(_activities);

    sorted.sort((a, b) => b.distance.compareTo(a.distance));
    if (sorted.isNotEmpty) {
      bestEfforts.add({
        'type': 'Longest Activity',
        'value': '${(sorted.first.distance / 1000).toStringAsFixed(1)} km',
        'date': sorted.first.startTime.toIso8601String(),
        'is_pr': true,
      });
    }

    sorted.sort((a, b) => b.elevationGain.compareTo(a.elevationGain));
    if (sorted.isNotEmpty && sorted.first.elevationGain > 0) {
      bestEfforts.add({
        'type': 'Most Elevation',
        'value': '${sorted.first.elevationGain.toStringAsFixed(0)} m',
        'date': sorted.first.startTime.toIso8601String(),
        'is_pr': false,
      });
    }

    final withPace = _activities.where((a) => a.averagePace > 0).toList()
      ..sort((a, b) => a.averagePace.compareTo(b.averagePace));
    if (withPace.isNotEmpty) {
      final p = withPace.first.averagePace.round();
      bestEfforts.add({
        'type': 'Best Pace',
        'value': '${p ~/ 60}:${(p % 60).toString().padLeft(2, '0')} /km',
        'date': withPace.first.startTime.toIso8601String(),
        'is_pr': false,
      });
    }

    final activeMondays = activityDays
        .map((d) => d.subtract(Duration(days: d.weekday - 1)))
        .toSet()
        .toList()
      ..sort();

    int currentStreak = 0;
    DateTime expected = weekStart;
    for (int i = activeMondays.length - 1; i >= 0; i--) {
      if (activeMondays[i] == expected) {
        currentStreak++;
        expected = expected.subtract(const Duration(days: 7));
      } else if (activeMondays[i].isBefore(expected)) {
        break;
      }
    }

    int longest = activeMondays.isEmpty ? 0 : 1, run = longest;
    for (int i = 1; i < activeMondays.length; i++) {
      if (activeMondays[i].difference(activeMondays[i - 1]).inDays == 7) {
        run++;
      } else {
        if (run > longest) longest = run;
        run = 1;
      }
    }
    if (run > longest) longest = run;

    _stats = UserStats(
      weekStart: weekStart,
      weeklyDistanceKm: weeklyDist,
      weeklyTimeMin: weeklyTime,
      weeklyElevGain: weeklyElev,
      weeklySessionCount: weeklyCount,
      lastWeekSessionCount: lastWeekCount,
      yearlyDistanceKm: yearlyDist,
      yearlyTimeMin: yearlyTime,
      yearlyElevGain: yearlyElev,
      yearlySessionCount: yearlyCount,
      allTimeDistanceKm: allTimeDist,
      allTimeTimeMin: allTimeTime,
      allTimeElevGain: allTimeElev,
      allTimeSessionCount: allTimeCount,
      activityDays: activityDays,
      bestEfforts: bestEfforts,
      currentStreak: currentStreak,
      longestStreak: longest,
    );
  }
}
