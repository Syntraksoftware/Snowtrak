import 'package:syntrak/models/activity.dart';
import 'package:syntrak/services/apis/activities_api.dart';

class ActivitiesRepository {
  ActivitiesRepository(this._api);

  final ActivitiesApi _api;

  Future<Activity> createActivity(Activity activity) {
    return _api.createActivity(activity);
  }

  Future<List<Activity>> getActivities({int page = 1, int limit = 20}) {
    return _api.getActivities(page: page, limit: limit);
  }

  Future<Activity> getActivity(String id) {
    return _api.getActivity(id);
  }

  Future<Activity> updateActivity(
    String id, {
    String? name,
    String? description,
    bool? isPublic,
  }) {
    return _api.updateActivity(
      id,
      name: name,
      description: description,
      isPublic: isPublic,
    );
  }

  Future<void> deleteActivity(String id) {
    return _api.deleteActivity(id);
  }

  Future<List<Activity>> getMyActivities({
    String? search,
    String? activityType,
    String? startDate,
    String? endDate,
    int limit = 100,
    int offset = 0,
  }) {
    return _api.getMyActivities(
      search: search,
      activityType: activityType,
      startDate: startDate,
      endDate: endDate,
      limit: limit,
      offset: offset,
    );
  }
}
