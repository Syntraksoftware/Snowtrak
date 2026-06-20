import 'package:dio/dio.dart';

/// Thin HTTP client for map-backend `map_trail` activity persistence.
class MapActivitiesApi {
  MapActivitiesApi({required Dio dio}) : _dio = dio;

  final Dio _dio;

  Future<Map<String, dynamic>> createActivity(Map<String, dynamic> body) async {
    final response = await _dio.post<Map<String, dynamic>>('/activities', data: body);
    return Map<String, dynamic>.from(response.data ?? const {});
  }

  Future<Map<String, dynamic>> getActivity(String activityId) async {
    final response = await _dio.get<Map<String, dynamic>>('/activities/$activityId');
    return Map<String, dynamic>.from(response.data ?? const {});
  }

  Future<void> deleteActivity(String activityId) async {
    await _dio.delete('/activities/$activityId');
  }
}
