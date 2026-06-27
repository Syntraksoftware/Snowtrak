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
import 'package:syntrak/features/auth/data/auth_session_store.dart';
import 'package:syntrak/features/community/data/community_repository.dart';
import 'package:syntrak/features/notifications/data/notifications_repository.dart';
import 'package:syntrak/features/profile/data/profile_repository.dart';
import 'package:syntrak/providers/activity_provider.dart';
import 'package:syntrak/providers/auth_provider.dart';
import 'package:syntrak/services/activities_service.dart';
import 'package:syntrak/services/auth_service.dart';
import 'package:syntrak/services/community_service.dart';
import 'package:syntrak/services/profile_service.dart';
import 'package:syntrak/features/track_pipeline/application/activity_upload_coordinator.dart';
import 'package:syntrak/services/apis/activities_api.dart';
import 'package:syntrak/services/apis/activity_upload_api.dart';
import 'package:syntrak/services/apis/auth_api.dart';
import 'package:syntrak/services/apis/community_api.dart';
import 'package:syntrak/services/apis/map_activities_api.dart';
import 'package:syntrak/services/apis/notifications_api.dart';
import 'package:syntrak/services/apis/users_api.dart';
import 'package:syntrak/services/location_service.dart';
import 'package:syntrak/services/map_config.dart';
import 'package:syntrak/services/feed/activities_feed_cache.dart';
import 'package:syntrak/services/feed/community_feed_cache.dart';
import 'package:syntrak/services/weather_cache.dart';
import 'package:syntrak/services/weather_service.dart';

final sl = GetIt.instance;

Future<void> setupServiceLocator() async {
  return setupServiceLocatorWithEnvironment();
}

Future<void> setupServiceLocatorWithEnvironment({
  AppEnvironment? environment,
}) async {
  if (sl.isRegistered<AppConfig>()) {
    return;
  }

  await MapConfig.init();

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
  AppLogger.instance.debug(
    '[Config] env=${appConfig.environment.name} '
    'main=${appConfig.mainApiBaseUrl} '
    'activity=${appConfig.activityApiBaseUrl} '
    'community=${appConfig.communityApiBaseUrl} '
    'map=${appConfig.mapApiBaseUrl}',
  );

  final tokenStore = AuthTokenStore();
  sl.registerSingleton<AuthTokenStore>(tokenStore);
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
  sl.registerSingleton<Dio>(
    dioFactory.buildMapClient(),
    instanceName: 'map',
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
  sl.registerLazySingleton<ActivityUploadApi>(
    () => ActivityUploadApi(dio: sl<Dio>(instanceName: 'activity')),
  );
  sl.registerLazySingleton<CommunityApi>(
    () => CommunityApi(dio: sl<Dio>(instanceName: 'community')),
  );
  sl.registerLazySingleton<NotificationsApi>(
    () => NotificationsApi(dio: sl<Dio>(instanceName: 'main')),
  );
  sl.registerLazySingleton<MapActivitiesApi>(
    () => MapActivitiesApi(dio: sl<Dio>(instanceName: 'map')),
  );

  sl.registerLazySingleton<ActivityUploadCoordinator>(
    () => ActivityUploadCoordinator(uploadApi: sl<ActivityUploadApi>()),
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
  sl.registerLazySingleton<AuthService>(
    () => AuthService(
      authRepository: sl<AuthRepository>(),
      tokenStore: sl<AuthTokenStore>(),
      appConfig: sl<AppConfig>(),
    ),
  );
  sl.registerLazySingleton<ProfileService>(
    () => ProfileService(profileRepository: sl<ProfileRepository>()),
  );
  sl.registerLazySingleton<ActivitiesService>(
    () => ActivitiesService(
      activitiesRepository: sl<ActivitiesRepository>(),
      appConfig: sl<AppConfig>(),
    ),
  );
  sl.registerLazySingleton<CommunityService>(
    () => CommunityService(communityRepository: sl<CommunityRepository>()),
  );

  sl.registerLazySingleton<WeatherService>(() => WeatherService());
  sl.registerLazySingleton<WeatherCache>(() => WeatherCache());
  sl.registerLazySingleton<ActivitiesFeedCache>(() => ActivitiesFeedCache());
  sl.registerLazySingleton<CommunityFeedCache>(() => CommunityFeedCache());
  sl.registerLazySingleton<LocationService>(() => LocationService());
  sl.registerLazySingleton<ActivitiesContextRepository>(
    () => ActivitiesContextRepository(
      weatherService: sl<WeatherService>(),
      locationService: sl<LocationService>(),
      weatherCache: sl<WeatherCache>(),
    ),
  );

  sl.registerFactoryParam<AuthProvider, AuthSessionStore, void>(
    (sessionStore, _) => AuthProvider(
      sl<AuthService>(),
      sl<ProfileService>(),
      sessionStore,
    ),
  );

  sl.registerFactory<ActivityProvider>(
    () => ActivityProvider(
      sl<ActivitiesService>(),
      sl<ActivitiesFeedCache>(),
    ),
  );
}
