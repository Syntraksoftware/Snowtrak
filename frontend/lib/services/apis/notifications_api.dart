import 'package:dio/dio.dart';
import 'package:syntrak/models/notification.dart';

class NotificationsApi {
  NotificationsApi({required Dio dio}) : _dio = dio;

  final Dio _dio;

  static final Options _fastPollingOptions = Options(
    sendTimeout: const Duration(seconds: 5),
    receiveTimeout: const Duration(seconds: 5),
  );

  Future<List<AppNotification>> getPending() async {
    final response = await _dio.get(
      '/notifications/pending',
      options: _fastPollingOptions,
    );
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
      options: _fastPollingOptions,
    );
    if (response.data is! List) {
      return [];
    }

    return (response.data as List)
        .map((json) => AppNotification.fromJson(json as Map<String, dynamic>))
        .toList();
  }
}
