import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';

import 'package:snowtrak/core/config/app_config.dart';
import 'package:snowtrak/core/config/app_environment.dart';
import 'package:snowtrak/core/logging/app_logger.dart';
import 'package:snowtrak/core/network/auth_token_store.dart';
import 'package:snowtrak/core/network/dio_factory.dart';
import 'package:snowtrak/features/activities/data/activities_context_repository.dart';
import 'package:snowtrak/features/activities/data/activities_repository.dart';
import 'package:snowtrak/features/auth/data/auth_repository.dart';
import 'package:snowtrak/features/auth/data/auth_session_store.dart';
import 'package:snowtrak/features/community/data/community_repository.dart';
import 'package:snowtrak/features/profile/data/profile_repository.dart';
import 'package:snowtrak/providers/activity_provider.dart';
import 'package:snowtrak/providers/auth_provider.dart';
import 'package:snowtrak/services/activities_service.dart';
import 'package:snowtrak/services/auth_service.dart';
import 'package:snowtrak/services/community_service.dart';
import 'package:snowtrak/services/duel_service.dart';
import 'package:snowtrak/services/follow_service.dart';
import 'package:snowtrak/services/leaderboard_service.dart';
import 'package:snowtrak/services/profile_service.dart';
import 'package:snowtrak/features/track_pipeline/application/activity_upload_coordinator.dart';
import 'package:snowtrak/services/apis/activities_api.dart';
import 'package:snowtrak/services/apis/activity_upload_api.dart';
import 'package:snowtrak/services/apis/auth_api.dart';
import 'package:snowtrak/services/apis/community_api.dart';
import 'package:snowtrak/services/apis/duel_api.dart';
import 'package:snowtrak/services/apis/follow_api.dart';
import 'package:snowtrak/services/apis/leaderboard_api.dart';
import 'package:snowtrak/services/apis/map_activities_api.dart';
import 'package:snowtrak/services/apis/privacy_api.dart';
import 'package:snowtrak/services/apis/users_api.dart';
import 'package:snowtrak/services/location_service.dart';
import 'package:snowtrak/services/map_config.dart';
import 'package:snowtrak/services/feed/activities_feed_cache.dart';
import 'package:snowtrak/services/feed/community_feed_cache.dart';
import 'package:snowtrak/services/weather_cache.dart';
import 'package:snowtrak/services/weather_service.dart';

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
  sl.registerLazySingleton<FollowApi>(
    () => FollowApi(dio: sl<Dio>(instanceName: 'community')),
  );
  // activity-backend, not community: the board and a duel both aggregate
  // `activities`, so they live with the activities. See
  // docs/service-ownership.md.
  sl.registerLazySingleton<LeaderboardApi>(
    () => LeaderboardApi(dio: sl<Dio>(instanceName: 'activity')),
  );
  sl.registerLazySingleton<DuelApi>(
    () => DuelApi(dio: sl<Dio>(instanceName: 'activity')),
  );
  // main-backend, not community: `/users/me/privacy` lives next to
  // `/users/me/profile` (see users_profile_routes.py), not next to follows.
  sl.registerLazySingleton<PrivacyApi>(
    () => PrivacyApi(dio: sl<Dio>(instanceName: 'main')),
  );
  sl.registerLazySingleton<CommunityApi>(
    () => CommunityApi(dio: sl<Dio>(instanceName: 'community')),
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
  sl.registerLazySingleton<FollowService>(
    () => FollowService(followApi: sl<FollowApi>()),
  );
  sl.registerLazySingleton<LeaderboardService>(
    () => LeaderboardService(leaderboardApi: sl<LeaderboardApi>()),
  );
  sl.registerLazySingleton<DuelService>(
    () => DuelService(duelApi: sl<DuelApi>()),
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
