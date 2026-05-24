import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:syntrak/core/errors/app_result.dart';
import 'package:syntrak/core/logging/app_logger.dart';
import 'package:syntrak/helpers/mock_activities.dart';
import 'package:syntrak/models/activity.dart';
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
  static const int _pageSize = 20;

  List<Activity> get activities => _activities;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasMore => _hasMore;
  String? get error => _error;

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
            userMessage:
                'Activity service unavailable. Showing demo data.',
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
        final created = value;
        _activities.insert(0, created);
        _isLoading = false;
        notifyListeners();
        await _feedCache.writePage(1, _activities.take(_pageSize).toList());
        return created;

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
    notifyListeners();
  }
}
