import 'package:flutter_test/flutter_test.dart';
import 'package:snowtrak/models/activity.dart';
import 'package:snowtrak/screens/home/home_stats.dart';

Activity _activity({
  required DateTime start,
  double distance = 1609.344, // 1 mile
  double elevationGain = 304.8, // 1000 ft
  int duration = 3600,
  double maxPace = 60, // 60 s/km -> 60 km/h
}) {
  return Activity(
    id: start.toIso8601String(),
    userId: 'u1',
    type: ActivityType.alpine,
    distance: distance,
    duration: duration,
    elevationGain: elevationGain,
    startTime: start,
    endTime: start.add(Duration(seconds: duration)),
    averagePace: 120,
    maxPace: maxPace,
    isPublic: true,
    createdAt: start,
  );
}

void main() {
  // Wednesday.
  final now = DateTime(2026, 8, 19, 12);

  group('Imperial', () {
    test('converts and formats', () {
      expect(Imperial.distance(1609.344), '1.0 mi');
      expect(Imperial.vertical(3048), '10,000 ft');
      expect(Imperial.duration(52680), '14h 38m');
      expect(Imperial.duration(600), '10m');
      expect(Imperial.fahrenheit(0), 32);
      expect(Imperial.mphFromPace(0), 0, reason: 'no pace reading must not divide by zero');
      expect(Imperial.mphFromPace(60), closeTo(37.28, 0.01));
    });
  });

  group('PeriodStats', () {
    test('week window starts Monday and excludes last week', () {
      final stats = PeriodStats.from(
        [
          _activity(start: DateTime(2026, 8, 17, 9)), // Mon, in
          _activity(start: DateTime(2026, 8, 19, 9)), // Wed, in
          _activity(start: DateTime(2026, 8, 16, 9)), // Sun, previous week
        ],
        StatsPeriod.week,
        now: now,
      );

      expect(stats.sessions, 2);
      expect(stats.start, DateTime(2026, 8, 17));
      expect(stats.end, DateTime(2026, 8, 23));
      expect(Imperial.distance(stats.distanceMetres), '2.0 mi');
      expect(Imperial.vertical(stats.verticalMetres), '2,000 ft');
      expect(stats.durationSeconds, 7200);
    });

    test('month window covers the calendar month', () {
      final stats = PeriodStats.from(
        [
          _activity(start: DateTime(2026, 8, 1)),
          _activity(start: DateTime(2026, 8, 31, 23)),
          _activity(start: DateTime(2026, 7, 31, 23)),
          _activity(start: DateTime(2026, 9, 1)),
        ],
        StatsPeriod.month,
        now: now,
      );

      expect(stats.sessions, 2);
      expect(stats.start, DateTime(2026, 8, 1));
      expect(stats.end, DateTime(2026, 8, 31));
    });

    test('top speed takes the fastest activity, avg speed is distance over time', () {
      final stats = PeriodStats.from(
        [
          _activity(start: DateTime(2026, 8, 18), maxPace: 120), // slower
          _activity(start: DateTime(2026, 8, 19), maxPace: 45), // fastest
        ],
        StatsPeriod.week,
        now: now,
      );

      expect(stats.topSpeedMph, closeTo(49.71, 0.01));
      // 2 miles over 2 hours.
      expect(stats.avgSpeedMph, closeTo(1.0, 0.001));
    });

    test('empty period reports empty, not a crash', () {
      final stats = PeriodStats.from([], StatsPeriod.week, now: now);
      expect(stats.isEmpty, isTrue);
      expect(stats.avgSpeedMph, 0);
      expect(stats.topSpeedMph, 0);
    });
  });
}
