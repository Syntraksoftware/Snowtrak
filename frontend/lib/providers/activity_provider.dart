import 'package:flutter/foundation.dart';
import 'package:syntrak/core/errors/app_result.dart';
import 'package:syntrak/core/logging/app_logger.dart';
import 'package:syntrak/helpers/mock_activities.dart';
import 'package:syntrak/models/activity.dart';
import 'package:syntrak/services/activities_service.dart';

class ActivityProvider extends ChangeNotifier {
  final ActivitiesService _activitiesService;
  List<Activity> _activities = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _currentPage = 1;
  String? _error;
  static const int _pageSize = 20;

  ActivityProvider(this._activitiesService);

  List<Activity> get activities => _activities;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasMore => _hasMore;
  String? get error => _error;

  Future<void> loadActivities({bool refresh = false}) async {
    if (refresh) {
      _currentPage = 1;
      _hasMore = true;
      _activities.clear();
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await _activitiesService.getActivities(
      page: _currentPage,
      limit: _pageSize,
    );

    switch (result) {
      case AppSuccess(:final value):
        final newActivities = value;
        if (refresh) {
          _activities = newActivities;
        } else {
          _activities.addAll(newActivities);
        }
        _hasMore = newActivities.length == _pageSize;
        _currentPage++;
        _isLoading = false;
        notifyListeners();

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

    _isLoadingMore = true;
    notifyListeners();

    final result = await _activitiesService.getActivities(
      page: _currentPage,
      limit: _pageSize,
    );

    switch (result) {
      case AppSuccess(:final value):
        final newActivities = value;
        _activities.addAll(newActivities);
        _hasMore = newActivities.length == _pageSize;
        _currentPage++;
        _isLoadingMore = false;
        notifyListeners();

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

  /// Load mock activities for demonstration purposes
  void loadMockActivities() {
    _activities = MockActivities.generateMockActivities();
    _hasMore = false;
    _isLoading = false;
    notifyListeners();
  }
}
