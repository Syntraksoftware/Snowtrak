import 'package:dio/dio.dart';
import 'package:syntrak/models/notification.dart';
import 'package:syntrak/services/service_registry.dart';

class NotificationsApi {
  NotificationsApi({Dio? dio}) : _dio = dio ?? ServiceRegistry.instance.main;

  final Dio _dio;

  Future<List<AppNotification>> getPending() async {
    final response = await _dio.get('/notifications/pending');
    if (response.data is! List) {
      return [];
    }

    return (response.data as List)
        .map((json) => AppNotification.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<List<AppNotification>> getHistory({int limit = 50}) async {
    final response = await _dio.get(
      '/notifications/history',
      queryParameters: {'limit': limit},
    );
    if (response.data is! List) {
      return [];
    }

    return (response.data as List)
        .map((json) => AppNotification.fromJson(json as Map<String, dynamic>))
        .toList();
  }
}
