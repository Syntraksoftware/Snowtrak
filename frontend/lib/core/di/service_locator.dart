// dependency injection setup using get_it package, central place to register and manage all services and repositories, including API clients, token store, and app configuration.

import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';

import 'package:syntrak/core/config/app_config.dart';
import 'package:syntrak/core/config/app_environment.dart';
import 'package:syntrak/core/logging/app_logger.dart';
import 'package:syntrak/core/network/auth_token_store.dart';
import 'package:syntrak/core/network/dio_factory.dart';
import 'package:syntrak/features/activities/data/activities_context_repository.dart';
import 'package:syntrak/features/activities/data/activities_repository.dart';
import 'package:syntrak/features/auth/data/auth_repository.dart';
import 'package:syntrak/features/community/data/community_repository.dart';
import 'package:syntrak/features/notifications/data/notifications_repository.dart';
import 'package:syntrak/features/profile/data/profile_repository.dart';
import 'package:syntrak/services/api_service.dart';
import 'package:syntrak/services/apis/activities_api.dart';
import 'package:syntrak/services/apis/auth_api.dart';
import 'package:syntrak/services/apis/community_api.dart';
import 'package:syntrak/services/apis/notifications_api.dart';
import 'package:syntrak/services/apis/users_api.dart';
import 'package:syntrak/services/location_service.dart';
import 'package:syntrak/services/service_registry.dart';
import 'package:syntrak/services/weather_service.dart';

final sl = GetIt.instance; // Service Locator

Future<void> setupServiceLocator() async {
  return setupServiceLocatorWithEnvironment();
}

Future<void> setupServiceLocatorWithEnvironment({
  AppEnvironment? environment,
}) async {
  if (sl.isRegistered<AppConfig>()) {
    return;
  }

  final appConfig =
      await AppConfig.bootstrapWithOverride(environmentOverride: environment);
  sl.registerSingleton<AppConfig>(appConfig);
  AppLogger.instance.configure(
    environment: appConfig.environment,
    fileExportEnabled: const bool.fromEnvironment(
      'ENABLE_LOG_FILE_EXPORT',
      defaultValue: false,
    ),
  );

  final tokenStore = AuthTokenStore();
  sl.registerSingleton<AuthTokenStore>(tokenStore);
  ServiceRegistry.initialize(config: appConfig, tokenStore: tokenStore);

  //dio: HTTP client for API communication, configured with base URL and interceptors for auth and logging, registered as singleton for app-wide use
  final dioFactory = DioFactory(config: appConfig, tokenStore: tokenStore);
  sl.registerSingleton<Dio>(dioFactory.buildMainClient(), instanceName: 'main');
  sl.registerSingleton<Dio>(
    dioFactory.buildActivityClient(),
    instanceName: 'activity',
  );
  sl.registerSingleton<Dio>(
    dioFactory.buildCommunityClient(),
    instanceName: 'community',
  );

  sl.registerLazySingleton<AuthApi>(
    () => AuthApi(dio: sl<Dio>(instanceName: 'main')),
  );
  sl.registerLazySingleton<UsersApi>(
    () => UsersApi(dio: sl<Dio>(instanceName: 'main')),
  );
  sl.registerLazySingleton<ActivitiesApi>(
    () => ActivitiesApi(dio: sl<Dio>(instanceName: 'activity')),
  );
  sl.registerLazySingleton<CommunityApi>(
    () => CommunityApi(dio: sl<Dio>(instanceName: 'community')),
  );
  sl.registerLazySingleton<NotificationsApi>(
    () => NotificationsApi(dio: sl<Dio>(instanceName: 'main')),
  );

  sl.registerLazySingleton<AuthRepository>(() => AuthRepository(sl<AuthApi>()));
  sl.registerLazySingleton<ProfileRepository>(
    () => ProfileRepository(sl<UsersApi>()),
  );
  sl.registerLazySingleton<ActivitiesRepository>(
    () => ActivitiesRepository(sl<ActivitiesApi>()),
  );
  sl.registerLazySingleton<CommunityRepository>(
    () => CommunityRepository(sl<CommunityApi>()),
  );
  sl.registerLazySingleton<NotificationsRepository>(
    () => NotificationsRepository(sl<NotificationsApi>()),
  );

  sl.registerLazySingleton<WeatherService>(() => WeatherService());
  sl.registerLazySingleton<LocationService>(() => LocationService());
  sl.registerLazySingleton<ActivitiesContextRepository>(
    () => ActivitiesContextRepository(
      weatherService: sl<WeatherService>(),
      locationService: sl<LocationService>(),
    ),
  );

  sl.registerLazySingleton<ApiService>(
    () => ApiService(
      authRepository: sl<AuthRepository>(),
      profileRepository: sl<ProfileRepository>(),
      activitiesRepository: sl<ActivitiesRepository>(),
      communityRepository: sl<CommunityRepository>(),
      tokenStore: sl<AuthTokenStore>(),
      appConfig: sl<AppConfig>(),
    ),
  );
}
