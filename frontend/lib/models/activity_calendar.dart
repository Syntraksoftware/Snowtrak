import 'package:syntrak/models/activity_calendar_entry.dart';

class ActivityCalendar { // container class for ActivityCalendarEntry
  final String userId;
  final DateTime fromDate;
  final DateTime toDate;
  final List<ActivityCalendarEntry> entries;

  ActivityCalendar({
    required this.userId,
    required this.fromDate,
    required this.toDate,
    required this.entries, // no issue as ActivityCalendarEntry is defaulted to be empty list
  });

  double get totalDistance => entries.fold(0, (sum, e) => sum + e.totalDistance);

  double get totalDistanceKm => totalDistance / 1000;

  int get totalDuration => entries.fold(0, (sum, e) => sum + e.totalDuration);

  int get totalActivities => entries.fold(0, (sum, e) => sum + e.activityCount);

  int get daysWithActivities => entries.where((e) => e.activityCount > 0).length;

  factory ActivityCalendar.fromJson(Map<String, dynamic> json) {
    return ActivityCalendar(
      userId: json['user_id'],
      fromDate: DateTime.parse(json['from_date']),
      toDate: DateTime.parse(json['to_date']),
      entries: (json['entries'] as List<dynamic>?)
              ?.map((entryJson) => ActivityCalendarEntry.fromJson(entryJson))
              .toList() ??
          const [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'from_date': fromDate.toIso8601String(),
      'to_date': toDate.toIso8601String(),
      'entries': entries.map((entry) => entry.toJson()).toList(),
    };
  }
}
