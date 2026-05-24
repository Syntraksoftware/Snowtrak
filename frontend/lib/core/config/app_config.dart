import 'package:shared_preferences/shared_preferences.dart';

import 'app_environment.dart';

class AppConfig {
  AppConfig({
    required this.environment,
    required this.mainApiBaseUrl,
    required this.activityApiBaseUrl,
    required this.communityApiBaseUrl,
    required this.mapApiBaseUrl,
    required this.enableMapFeatures,
  });

  final AppEnvironment environment;
  final String mainApiBaseUrl;
  final String activityApiBaseUrl;
  final String communityApiBaseUrl;
  final String mapApiBaseUrl;
  final bool enableMapFeatures;

  static const _mainOverrideKey = 'override_main_api_base_url';
  static const _activityOverrideKey = 'override_activity_api_base_url';
  static const _communityOverrideKey = 'override_community_api_base_url';
  static const _mapOverrideKey = 'override_map_api_base_url';

  static Future<AppConfig> bootstrap() async {
    return bootstrapWithOverride();
  }

  static Future<AppConfig> bootstrapWithOverride({
    AppEnvironment? environmentOverride,
  }) async {
    final env = environmentOverride ??
    // obtain config from env 
        AppEnvironmentX.fromString(
          const String.fromEnvironment('APP_ENV', defaultValue: 'dev'),
        );

    final defaults = _defaultsFor(env);
    final prefs = await SharedPreferences.getInstance();

    final runtimeMain = prefs.getString(_mainOverrideKey);
    final runtimeActivity = prefs.getString(_activityOverrideKey);
    final runtimeCommunity = prefs.getString(_communityOverrideKey);
    final runtimeMap = prefs.getString(_mapOverrideKey);

    const defineMain = String.fromEnvironment('MAIN_API_BASE_URL');
    const defineActivity = String.fromEnvironment('ACTIVITY_API_BASE_URL');
    const defineCommunity = String.fromEnvironment('COMMUNITY_API_BASE_URL');
    const defineMap = String.fromEnvironment('MAP_API_BASE_URL');
    const defineMapFeatures = String.fromEnvironment('ENABLE_MAP_FEATURES');

    return AppConfig(
      environment: env,
      mainApiBaseUrl:
      //first non empty value from runtime override, compile time define, then default, 
      // flexible configuration for different environments and testing scenarios, with the ability to easily switch between different API endpoints without changing the codebase, simply by setting environment variables or using shared preferences for runtime overrides.
          _firstNonEmpty(runtimeMain, defineMain, defaults.mainApiBaseUrl),
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
      enableMapFeatures: _firstNonEmptyBool(
        defineMapFeatures,
        defaults.enableMapFeatures,
      ),
    );
  }

  static Future<void> setRuntimeOverrides({
    String? mainApiBaseUrl,
    String? activityApiBaseUrl,
    String? communityApiBaseUrl,
    String? mapApiBaseUrl,
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
  }

  static Future<void> clearRuntimeOverrides() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_mainOverrideKey);
    await prefs.remove(_activityOverrideKey);
    await prefs.remove(_communityOverrideKey);
    await prefs.remove(_mapOverrideKey);
  }

  static AppConfig _defaultsFor(AppEnvironment environment) {
    switch (environment) {
      case AppEnvironment.dev:
        return AppConfig(
          environment: environment,
          mainApiBaseUrl: 'http://localhost:8080/api/v1',
          activityApiBaseUrl: 'http://localhost:5100/api/v1',
          communityApiBaseUrl: 'http://localhost:5001/api/v1',
          mapApiBaseUrl: 'http://localhost:5200/api/v1/map',
          enableMapFeatures: true,
        );
      case AppEnvironment.staging:
        return AppConfig(
          environment: environment,
          mainApiBaseUrl: 'https://staging-main.syntrak.io/api/v1',
          activityApiBaseUrl: 'https://staging-activity.syntrak.io/api/v1',
          communityApiBaseUrl: 'https://staging-community.syntrak.io/api/v1',
          mapApiBaseUrl: 'https://staging-map.syntrak.io/api/v1/map',
          enableMapFeatures: false,
        );
      case AppEnvironment.prod:
        return AppConfig(
          environment: environment,
          mainApiBaseUrl: 'https://main.syntrak.app/api/v1',
          activityApiBaseUrl: 'https://activity.syntrak.app/api/v1',
          communityApiBaseUrl: 'https://community.syntrak.app/api/v1',
          mapApiBaseUrl: 'https://map.syntrak.app/api/v1/map',
          enableMapFeatures: true,
        );
    }
  }

  static String _firstNonEmpty(String? v1, String? v2, String fallback) {
    if (v1 != null && v1.trim().isNotEmpty) return v1.trim();
    if (v2 != null && v2.trim().isNotEmpty) return v2.trim();
    return fallback;
  }

  static bool _firstNonEmptyBool(String? raw, bool fallback) {
    if (raw == null || raw.trim().isEmpty) {
      return fallback;
    }

    switch (raw.trim().toLowerCase()) {
      case 'true':
      case '1':
      case 'yes':
      case 'on':
        return true;
      case 'false':
      case '0':
      case 'no':
      case 'off':
        return false;
      default:
        return fallback;
    }
  }
}

