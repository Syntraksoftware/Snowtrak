import 'package:dio/dio.dart';

class ServiceRegistry {
  ServiceRegistry._();

  static final ServiceRegistry instance = ServiceRegistry._();

  static const String mainBaseUrl = 'http://127.0.0.1:8080/api/v1';
  static const String activityBaseUrl = 'http://127.0.0.1:5100/api/v1';
  static const String communityBaseUrl = 'http://127.0.0.1:5001/api/v1';

  String? _token;

  late final Dio _main = _buildDio(mainBaseUrl);
  late final Dio _activity = _buildDio(activityBaseUrl);
  late final Dio _community = _buildDio(communityBaseUrl);

  Dio get main => _main;
  Dio get activity => _activity;
  Dio get community => _community;

  void setToken(String? token) {
    _token = token;
  }

  Dio _buildDio(String baseUrl) {
    final dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          if (_token != null && _token!.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $_token';
          }
          handler.next(options);
        },
      ),
    );

    return dio;
  }
}
