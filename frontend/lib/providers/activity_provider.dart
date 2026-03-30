import 'package:flutter/foundation.dart';
import 'package:syntrak/core/logging/app_logger.dart';
import 'package:syntrak/models/activity.dart';
import 'package:syntrak/services/activities_service.dart';
import 'package:syntrak/helpers/mock_activities.dart';

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
    try {
      if (refresh) {
        _currentPage = 1;
        _hasMore = true;
        _activities.clear();
      }
      
      _isLoading = true;
      _error = null;
      notifyListeners();

      final newActivities = await _activitiesService.getActivities(
        page: _currentPage,
        limit: _pageSize,
      );
      
      if (refresh) {
        _activities = newActivities;
      } else {
        _activities.addAll(newActivities);
      }
      
      _hasMore = newActivities.length == _pageSize;
      _currentPage++;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;

      if (_activities.isEmpty && _activitiesService.isDevEnvironment) {
        AppLogger.instance.warning(
          '[ActivityProvider] Activity API unavailable in dev, loading demo data',
          error: e,
          notifyUser: true,
          userMessage: 'Activity service unavailable. Showing demo data.',
        );
        _error = 'Activity service unavailable. Showing demo data.';
        loadMockActivities();
      } else {
        AppLogger.instance.error(
          '[ActivityProvider] Failed to load activities',
          error: e,
          notifyUser: true,
          userMessage: 'Unable to load activities. Please try again.',
        );
        notifyListeners();
      }
    }
  }

  Future<void> loadMore() async {
    if (_isLoadingMore || !_hasMore) return;

    try {
      _isLoadingMore = true;
      notifyListeners();

      final newActivities = await _activitiesService.getActivities(
        page: _currentPage,
        limit: _pageSize,
      );
      
      _activities.addAll(newActivities);
      _hasMore = newActivities.length == _pageSize;
      _currentPage++;
      _isLoadingMore = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoadingMore = false;
      AppLogger.instance.warning(
        '[ActivityProvider] Failed to load more activities',
        error: e,
        notifyUser: true,
        userMessage: 'Unable to load more activities right now.',
      );
      notifyListeners();
    }
  }

  Future<Activity?> createActivity(Activity activity) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final created = await _activitiesService.createActivity(activity);
      _activities.insert(0, created);
      _isLoading = false;
      notifyListeners();
      return created;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      AppLogger.instance.error(
        '[ActivityProvider] Failed to create activity',
        error: e,
        notifyUser: true,
        userMessage: 'Failed to create activity. Please try again.',
      );
      notifyListeners();
      return null;
    }
  }

  Future<void> deleteActivity(String id) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _activitiesService.deleteActivity(id);
      _activities.removeWhere((a) => a.id == id);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      AppLogger.instance.error(
        '[ActivityProvider] Failed to delete activity',
        error: e,
        notifyUser: true,
        userMessage: 'Failed to delete activity. Please try again.',
      );
      notifyListeners();
    }
  }

  Future<Activity?> getActivity(String id) async {
    try {
      return await _activitiesService.getActivity(id);
    } catch (e) {
      _error = e.toString();
      AppLogger.instance.warning(
        '[ActivityProvider] Failed to get activity details',
        error: e,
      );
      notifyListeners();
      return null;
    }
  }

  /// Load mock activities for demonstration purposes
  void loadMockActivities() {
    _activities = MockActivities.generateMockActivities();
    _hasMore = false; // No more mock data to load
    _isLoading = false;
    notifyListeners();
  }
}

