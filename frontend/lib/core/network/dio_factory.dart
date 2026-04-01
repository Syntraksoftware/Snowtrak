import 'package:dio/dio.dart';

import '../config/app_config.dart';
import 'auth_token_store.dart';

class DioFactory {
  DioFactory({required this.config, required this.tokenStore});

  final AppConfig config;
  final AuthTokenStore tokenStore;

  Dio buildMainClient() => _build(config.mainApiBaseUrl);
  Dio buildActivityClient() => _build(config.activityApiBaseUrl);
  Dio buildCommunityClient() => _build(config.communityApiBaseUrl);

  Dio _build(String baseUrl) {
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
          final token = tokenStore.token;
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
      ),
    );

    return dio;
  }
}
