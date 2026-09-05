import 'package:snowtrak/core/config/app_config.dart';
import 'package:snowtrak/core/config/app_environment.dart';
import 'package:snowtrak/core/errors/app_error.dart';
import 'package:snowtrak/core/errors/app_result.dart';
import 'package:snowtrak/features/activities/data/activities_repository.dart';
import 'package:snowtrak/models/activity.dart';
import 'package:snowtrak/models/user_stats.dart';

class ActivitiesService {
  ActivitiesService({
    required ActivitiesRepository activitiesRepository,
    required AppConfig appConfig,
  })  : _activitiesRepository = activitiesRepository,
        _appConfig = appConfig;

  final ActivitiesRepository _activitiesRepository;
  final AppConfig _appConfig;

  bool get isDevEnvironment => _appConfig.environment == AppEnvironment.dev;

  Future<AppResult<Activity>> createActivity(Activity activity) async {
    try {
      final created = await _activitiesRepository.createActivity(activity);
      return AppSuccess(created);
    } catch (e, st) {
      return AppFailure(AppError.from(e, st));
    }
  }

  Future<AppResult<List<Activity>>> getActivities({
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final list = await _activitiesRepository.getActivities(
        page: page,
        limit: limit,
      );
      return AppSuccess(list);
    } catch (e, st) {
      return AppFailure(AppError.from(e, st));
    }
  }

  /// The signed-in user's own activities, newest first.
  ///
  /// Paged the same way as [getActivities] so a caller can hold one or the
  /// other without knowing which; the endpoint underneath takes an offset.
  Future<AppResult<List<Activity>>> getMyActivities({
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final list = await _activitiesRepository.getMyActivities(
        limit: limit,
        offset: (page - 1) * limit,
      );
      return AppSuccess(list);
    } catch (e, st) {
      return AppFailure(AppError.from(e, st));
    }
  }

  Future<AppResult<Activity>> getActivity(String id) async {
    try {
      final activity = await _activitiesRepository.getActivity(id);
      return AppSuccess(activity);
    } catch (e, st) {
      return AppFailure(AppError.from(e, st));
    }
  }

  Future<AppResult<Activity>> updateActivity(
    String id, {
    String? name,
    String? description,
    bool? isPublic,
  }) async {
    try {
      final updated = await _activitiesRepository.updateActivity(
        id,
        name: name,
        description: description,
        isPublic: isPublic,
      );
      return AppSuccess(updated);
    } catch (e, st) {
      return AppFailure(AppError.from(e, st));
    }
  }

  Future<AppResult<UserStats>> getMyStats() async {
    try {
      final stats = await _activitiesRepository.getMyStats();
      return AppSuccess(stats);
    } catch (e, st) {
      return AppFailure(AppError.from(e, st));
    }
  }

  Future<AppResult<Unit>> deleteActivity(String id) async {
    try {
      await _activitiesRepository.deleteActivity(id);
      return const AppSuccess(Unit.unit);
    } catch (e, st) {
      return AppFailure(AppError.from(e, st));
    }
  }
}
