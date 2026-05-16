import 'package:syntrak/models/activity.dart';

class ActivityCalendarEntry {
  final DateTime date;
  final int activityCount;
  final double totalDistance; // meters
  final int totalDuration; // kept in seconds, conversion to be done in frontend
  final String? lastActivityId;
  final List<Activity> activities;

  ActivityCalendarEntry({
    required this.date,
    required this.activityCount,
    required this.totalDistance,
    required this.totalDuration,
    this.lastActivityId,
    this.activities = const [],
  });

  double get totalDistanceKm => totalDistance / 1000;

  factory ActivityCalendarEntry.fromJson(Map<String, dynamic> json) {
    return ActivityCalendarEntry(
      date: DateTime.parse(json['date']),
      activityCount: json['activity_count'] ?? (json['activities'] as List<dynamic>?)?.length ?? 0,
      totalDistance: (json['total_distance'] as num?)?.toDouble() ?? 0.0,
      totalDuration: json['total_duration'] ?? 0,
      lastActivityId: json['last_activity_id'],
      activities: (json['activities'] as List<dynamic>?) // maping list of activity jsons to list of Activity objects
              ?.map((activityJson) => Activity.fromJson(activityJson))
              .toList() ??
          const [], // fallback to empty list to prevent null entries in container (ActivityCalendar)
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'activity_count': activityCount,
      'total_distance': totalDistance,
      'total_duration': totalDuration,
      'last_activity_id': lastActivityId,
      'activities': activities.map((activity) => activity.toJson()).toList(),
    };
  }
}
