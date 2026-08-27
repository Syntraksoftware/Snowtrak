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

  /// map-backend — no auth today; longer receive timeout for DEM batches.
  Dio buildMapClient() => _build(
        config.mapApiBaseUrl,
        receiveTimeout: const Duration(seconds: 45),
      );

  Dio _build(
    String baseUrl, {
    Duration connectTimeout = const Duration(seconds: 8),
    Duration receiveTimeout = const Duration(seconds: 15),
    bool attachAuth = true,
  }) {
    final dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: connectTimeout,
        receiveTimeout: receiveTimeout,
        headers: const {'Content-Type': 'application/json'},
      ),
    );

    if (attachAuth) {
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
    }

    return dio;
  }
}
