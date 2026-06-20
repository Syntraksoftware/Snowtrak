import 'package:shared_preferences/shared_preferences.dart';

import 'app_environment.dart';

class AppConfig {
  AppConfig({
    required this.environment,
    required this.mainApiBaseUrl,
    required this.activityApiBaseUrl,
    required this.communityApiBaseUrl,
    required this.mapApiBaseUrl,
    required this.nivusApiBaseUrl,
    required this.useNivusPipeline,
  });

  final AppEnvironment environment;
  final String mainApiBaseUrl;
  final String activityApiBaseUrl;
  final String communityApiBaseUrl;

  /// map-backend — DEM elevation, map_trail persistence, resort GeoJSON.
  final String mapApiBaseUrl;

  /// Nivus — track math + PostGIS trail matching (compute plane).
  final String nivusApiBaseUrl;

  /// When true, live saves run through Nivus + map-backend instead of local engines.
  final bool useNivusPipeline;

  static const _mainOverrideKey = 'override_main_api_base_url';
  static const _activityOverrideKey = 'override_activity_api_base_url';
  static const _communityOverrideKey = 'override_community_api_base_url';
  static const _mapOverrideKey = 'override_map_api_base_url';
  static const _nivusOverrideKey = 'override_nivus_api_base_url';

  static Future<AppConfig> bootstrap() async {
    return bootstrapWithOverride();
  }

  static Future<AppConfig> bootstrapWithOverride({
    AppEnvironment? environmentOverride,
  }) async {
    final env = environmentOverride ??
        AppEnvironmentX.fromString(
          const String.fromEnvironment('APP_ENV', defaultValue: 'dev'),
        );

    final defaults = _defaultsFor(env);
    final prefs = await SharedPreferences.getInstance();

    final runtimeMain = prefs.getString(_mainOverrideKey);
    final runtimeActivity = prefs.getString(_activityOverrideKey);
    final runtimeCommunity = prefs.getString(_communityOverrideKey);
    final runtimeMap = prefs.getString(_mapOverrideKey);
    final runtimeNivus = prefs.getString(_nivusOverrideKey);

    const defineMain = String.fromEnvironment('MAIN_API_BASE_URL');
    const defineActivity = String.fromEnvironment('ACTIVITY_API_BASE_URL');
    const defineCommunity = String.fromEnvironment('COMMUNITY_API_BASE_URL');
    const defineMap = String.fromEnvironment('MAP_API_BASE_URL');
    const defineNivus = String.fromEnvironment('NIVUS_API_BASE_URL');
    const defineUseNivusPipeline = String.fromEnvironment('USE_NIVUS_PIPELINE');

    return AppConfig(
      environment: env,
      mainApiBaseUrl: _firstNonEmpty(runtimeMain, defineMain, defaults.mainApiBaseUrl),
      activityApiBaseUrl: _firstNonEmpty(
        runtimeActivity,
        defineActivity,
        defaults.activityApiBaseUrl,
      ),
      communityApiBaseUrl: _firstNonEmpty(
        runtimeCommunity,
        defineCommunity,
        defaults.communityApiBaseUrl,
      ),
      mapApiBaseUrl: _firstNonEmpty(runtimeMap, defineMap, defaults.mapApiBaseUrl),
      nivusApiBaseUrl: _firstNonEmpty(runtimeNivus, defineNivus, defaults.nivusApiBaseUrl),
      useNivusPipeline: _resolveUseNivusPipeline(defineUseNivusPipeline, env),
    );
  }

  static Future<void> setRuntimeOverrides({
    String? mainApiBaseUrl,
    String? activityApiBaseUrl,
    String? communityApiBaseUrl,
    String? mapApiBaseUrl,
    String? nivusApiBaseUrl,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    if (mainApiBaseUrl != null) {
      await prefs.setString(_mainOverrideKey, mainApiBaseUrl);
    }
    if (activityApiBaseUrl != null) {
      await prefs.setString(_activityOverrideKey, activityApiBaseUrl);
    }
    if (communityApiBaseUrl != null) {
      await prefs.setString(_communityOverrideKey, communityApiBaseUrl);
    }
    if (mapApiBaseUrl != null) {
      await prefs.setString(_mapOverrideKey, mapApiBaseUrl);
    }
    if (nivusApiBaseUrl != null) {
      await prefs.setString(_nivusOverrideKey, nivusApiBaseUrl);
    }
  }

  static Future<void> clearRuntimeOverrides() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_mainOverrideKey);
    await prefs.remove(_activityOverrideKey);
    await prefs.remove(_communityOverrideKey);
    await prefs.remove(_mapOverrideKey);
    await prefs.remove(_nivusOverrideKey);
  }

  static AppConfig _defaultsFor(AppEnvironment environment) {
    switch (environment) {
      case AppEnvironment.dev:
        return AppConfig(
          environment: environment,
          mainApiBaseUrl: 'http://localhost:8080/api/v1',
          activityApiBaseUrl: 'http://localhost:5100/api/v1',
          communityApiBaseUrl: 'http://localhost:5001/api/v1',
          mapApiBaseUrl: 'http://localhost:5200',
          nivusApiBaseUrl: 'http://localhost:5201',
          useNivusPipeline: true,
        );
      case AppEnvironment.staging:
        return AppConfig(
          environment: environment,
          mainApiBaseUrl: 'https://staging-main.syntrak.app/api/v1',
          activityApiBaseUrl: 'https://staging-activity.syntrak.app/api/v1',
          communityApiBaseUrl: 'https://staging-community.syntrak.app/api/v1',
          mapApiBaseUrl: 'https://staging-map.syntrak.app',
          nivusApiBaseUrl: 'https://staging-nivus.syntrak.app',
          useNivusPipeline: false,
        );
      case AppEnvironment.prod:
        return AppConfig(
          environment: environment,
          mainApiBaseUrl: 'https://main.syntrak.app/api/v1',
          activityApiBaseUrl: 'https://activity.syntrak.app/api/v1',
          communityApiBaseUrl: 'https://community.syntrak.app/api/v1',
          mapApiBaseUrl: 'https://map.syntrak.app',
          nivusApiBaseUrl: 'https://nivus.syntrak.app',
          useNivusPipeline: false,
        );
    }
  }

  static bool _resolveUseNivusPipeline(String defineValue, AppEnvironment env) {
    final normalized = defineValue.trim().toLowerCase();
    if (normalized == 'true' || normalized == '1') return true;
    if (normalized == 'false' || normalized == '0') return false;
    return env == AppEnvironment.dev;
  }

  static String _firstNonEmpty(String? v1, String? v2, String fallback) {
    if (v1 != null && v1.trim().isNotEmpty) return v1.trim();
    if (v2 != null && v2.trim().isNotEmpty) return v2.trim();
    return fallback;
  }
}
