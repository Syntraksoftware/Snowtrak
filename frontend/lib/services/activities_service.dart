import 'package:syntrak/core/config/app_config.dart';
import 'package:syntrak/core/config/app_environment.dart';
import 'package:syntrak/features/activities/data/activities_repository.dart';
import 'package:syntrak/models/activity.dart';

class ActivitiesService {
  ActivitiesService({
    required ActivitiesRepository activitiesRepository,
    required AppConfig appConfig,
  })  : _activitiesRepository = activitiesRepository,
        _appConfig = appConfig;

  final ActivitiesRepository _activitiesRepository;
  final AppConfig _appConfig;

  bool get isDevEnvironment => _appConfig.environment == AppEnvironment.dev;

  Future<Activity> createActivity(Activity activity) {
    return _activitiesRepository.createActivity(activity);
  }

  Future<List<Activity>> getActivities({int page = 1, int limit = 20}) {
    return _activitiesRepository.getActivities(page: page, limit: limit);
  }

  Future<Activity> getActivity(String id) {
    return _activitiesRepository.getActivity(id);
  }

  Future<Activity> updateActivity(
    String id, {
    String? name,
    String? description,
    bool? isPublic,
  }) {
    return _activitiesRepository.updateActivity(
      id,
      name: name,
      description: description,
      isPublic: isPublic,
    );
  }

  Future<void> deleteActivity(String id) {
    return _activitiesRepository.deleteActivity(id);
  }
}
