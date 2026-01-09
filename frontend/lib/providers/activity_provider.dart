import 'package:flutter/foundation.dart';
import 'package:syntrak/models/activity.dart';
import 'package:syntrak/services/api_service.dart';
import 'package:syntrak/helpers/mock_activities.dart';

class ActivityProvider extends ChangeNotifier {
  final ApiService _apiService;
  List<Activity> _activities = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _currentPage = 1;
  String? _error;
  static const int _pageSize = 20;

  ActivityProvider(this._apiService);

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

      final newActivities = await _apiService.getActivities(
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
      // If API fails and we have no activities, load mock data for demonstration
      if (_activities.isEmpty) {
        loadMockActivities();
      } else {
        _error = e.toString();
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  Future<void> loadMore() async {
    if (_isLoadingMore || !_hasMore) return;

    try {
      _isLoadingMore = true;
      notifyListeners();

      final newActivities = await _apiService.getActivities(
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
      notifyListeners();
    }
  }

  Future<Activity?> createActivity(Activity activity) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final created = await _apiService.createActivity(activity);
      _activities.insert(0, created);
      _isLoading = false;
      notifyListeners();
      return created;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  Future<void> deleteActivity(String id) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _apiService.deleteActivity(id);
      _activities.removeWhere((a) => a.id == id);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Activity?> getActivity(String id) async {
    try {
      return await _apiService.getActivity(id);
    } catch (e) {
      _error = e.toString();
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

