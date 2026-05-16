import 'package:syntrak/models/activity.dart';

/// Local/mock activity list for the profile Activities tab until backend wiring is complete.
class ProfileActivitiesService {
  Future<List<Activity>> getUserActivities({
    String? searchQuery,
    ActivityType? typeFilter,
    DateTime? dateFrom,
    DateTime? dateTo,
  }) async {
    return _mockActivities();
  }

  Future<void> toggleKudos(String activityId) async {}

  Future<void> shareActivity(String activityId) async {}

  Future<void> addComment(String activityId, String comment) async {}

  List<Activity> _mockActivities() {
    final activityDate = DateTime(2025, 1, 27, 21, 30);
    final now = DateTime.now();

    return [
      Activity(
        id: '1',
        userId: 'user1',
        type: ActivityType.alpine,
        name: 'Night Hike',
        distance: 1390,
        duration: 773,
        elevationGain: 10,
        startTime: activityDate,
        endTime: activityDate.add(const Duration(minutes: 12, seconds: 53)),
        averagePace: 556,
        maxPace: 500,
        isPublic: true,
        createdAt: activityDate,
        locations: [],
      ),
      Activity(
        id: '2',
        userId: 'user1',
        type: ActivityType.alpine,
        name: 'Morning Alpine Run',
        distance: 12500,
        duration: 3600,
        elevationGain: 850,
        startTime: now.subtract(const Duration(days: 2, hours: 2)),
        endTime: now.subtract(const Duration(days: 2, hours: 1)),
        averagePace: 288,
        maxPace: 240,
        isPublic: true,
        createdAt: now.subtract(const Duration(days: 2)),
        locations: [],
      ),
      Activity(
        id: '3',
        userId: 'user1',
        type: ActivityType.backcountry,
        name: 'Backcountry Adventure',
        distance: 18500,
        duration: 7200,
        elevationGain: 1200,
        startTime: now.subtract(const Duration(days: 5, hours: 3)),
        endTime: now.subtract(const Duration(days: 5, hours: 1)),
        averagePace: 389,
        maxPace: 320,
        isPublic: true,
        createdAt: now.subtract(const Duration(days: 5)),
        locations: [],
      ),
    ];
  }
}
