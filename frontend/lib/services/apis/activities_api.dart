import 'package:dio/dio.dart';
import 'package:snowtrak/models/activity.dart';
import 'package:snowtrak/models/user_stats.dart';

class ActivitiesApi {
  ActivitiesApi({required Dio dio}) : _dio = dio;

  final Dio _dio;

  Future<Activity> createActivity(Activity activity) async {
    final response = await _dio.post('/activities/', data: activity.toJson());
    return Activity.fromJson(response.data);
  }

  Future<List<Activity>> getActivities({int page = 1, int limit = 20}) async {
    final offset = (page - 1) * limit;
    final response = await _dio.get('/activities/', queryParameters: {
      'limit': limit,
      'offset': offset,
    });
    final data = response.data;
    final List<dynamic> rows;
    if (data is List) {
      rows = data;
    } else if (data is Map<String, dynamic>) {
      rows = data['items'] as List<dynamic>? ?? const [];
    } else {
      rows = const [];
    }
    return rows
        .map((json) => Activity.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<Activity> getActivity(String id) async {
    final response = await _dio.get('/activities/$id');
    return Activity.fromJson(response.data);
  }

  Future<Activity> updateActivity(
    String id, {
    String? name,
    String? description,
    bool? isPublic,
  }) async {
    final response = await _dio.put('/activities/$id', data: {
      if (name != null) 'name': name,
      if (description != null) 'description': description,
      if (isPublic != null) 'is_public': isPublic,
    });
    return Activity.fromJson(response.data);
  }

  Future<void> deleteActivity(String id) async {
    await _dio.delete('/activities/$id');
  }

  Future<UserStats> getMyStats() async {
    final response = await _dio.get('/activities/me/stats');
    return UserStats.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<Activity>> getMyActivities({
    String? search,
    String? activityType,
    String? startDate,
    String? endDate,
    int limit = 100,
    int offset = 0,
  }) async {
    final response = await _dio.get('/activities/me', queryParameters: {
      if (search != null) 'search': search,
      if (activityType != null) 'activity_type': activityType,
      if (startDate != null) 'start_date': startDate,
      if (endDate != null) 'end_date': endDate,
      'limit': limit,
      'offset': offset,
    });
    final data = response.data;
    final List<dynamic> rows = data is Map<String, dynamic>
        ? (data['items'] as List<dynamic>? ?? const [])
        : (data as List<dynamic>? ?? const []);
    return rows
        .map((json) => Activity.fromJson(json as Map<String, dynamic>))
        .toList();
  }
}
