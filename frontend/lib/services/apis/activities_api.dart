import 'package:dio/dio.dart';
import 'package:syntrak/models/activity.dart';
import 'package:syntrak/services/service_registry.dart';

class ActivitiesApi {
  ActivitiesApi({Dio? dio}) : _dio = dio ?? ServiceRegistry.instance.activity;

  final Dio _dio;

  Future<Activity> createActivity(Activity activity) async {
    final response = await _dio.post('/activities', data: activity.toJson());
    return Activity.fromJson(response.data);
  }

  Future<List<Activity>> getActivities({int page = 1, int limit = 20}) async {
    final offset = (page - 1) * limit;
    final response = await _dio.get('/activities', queryParameters: {
      'limit': limit,
      'offset': offset,
    });
    return (response.data as List)
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
}
