import 'package:dio/dio.dart';
import 'package:syntrak/core/config/app_config.dart';
import 'package:syntrak/core/network/auth_token_store.dart';
import 'package:syntrak/core/network/dio_factory.dart';

class ServiceRegistry {
  ServiceRegistry._internal({
    required this.config,
    required AuthTokenStore tokenStore,
  }) : _tokenStore = tokenStore {
    final factory = DioFactory(config: config, tokenStore: _tokenStore);
    _main = factory.buildMainClient();
    _activity = factory.buildActivityClient();
    _community = factory.buildCommunityClient();
  }

  static late final ServiceRegistry instance;

  final AppConfig config;
  final AuthTokenStore _tokenStore;

  static void initialize({
    required AppConfig config,
    required AuthTokenStore tokenStore,
  }) {
    instance = ServiceRegistry._internal(config: config, tokenStore: tokenStore);
  }

  late final Dio _main;
  late final Dio _activity;
  late final Dio _community;

  Dio get main => _main;
  Dio get activity => _activity;
  Dio get community => _community;

  void setToken(String? token) {
    _tokenStore.setToken(token);
  }
}
