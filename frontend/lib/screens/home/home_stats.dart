import 'package:snowtrak/models/activity.dart';

/// The two windows the Home statistics card can show.
enum StatsPeriod { week, month }

/// Imperial conversion + formatting. The design (`12 layout now`) is imperial
/// throughout: feet, miles, mph, °F.
class Imperial {
  static const double _metresPerMile = 1609.344;
  static const double _feetPerMetre = 3.280839895;
  static const double _mphPerKmh = 0.621371;

  static double miles(double metres) => metres / _metresPerMile;
  static double feet(double metres) => metres * _feetPerMetre;
  static double fahrenheit(double celsius) => celsius * 9 / 5 + 32;

  /// Pace is stored as seconds per km; 0 or negative means "no reading".
  static double mphFromPace(double secondsPerKm) {
    if (secondsPerKm <= 0) return 0;
    return (3600 / secondsPerKm) * _mphPerKmh;
  }

  static String distance(double metres) =>
      '${miles(metres).toStringAsFixed(1)} mi';

  static String vertical(double metres) => '${_grouped(feet(metres).round())} ft';

  static String speed(double mph) => '${mph.toStringAsFixed(1)} mph';

  static String duration(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    if (hours == 0) return '${minutes}m';
    return '${hours}h ${minutes.toString().padLeft(2, '0')}m';
  }

  static String _grouped(int value) {
    final digits = value.abs().toString();
    final buffer = StringBuffer(value < 0 ? '-' : '');
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(',');
      buffer.write(digits[i]);
    }
    return buffer.toString();
  }
}

/// Everything the statistics card shows for one period, derived from the
/// activities already in memory — no extra endpoint needed.
class PeriodStats {
  const PeriodStats({
    required this.period,
    required this.start,
    required this.end,
    required this.sessions,
    required this.runs,
    required this.distanceMetres,
    required this.verticalMetres,
    required this.durationSeconds,
    required this.topSpeedMph,
    required this.avgSpeedMph,
  });

  final StatsPeriod period;
  final DateTime start;
  final DateTime end;
  final int sessions;
  final int runs;
  final double distanceMetres;
  final double verticalMetres;
  final int durationSeconds;
  final double topSpeedMph;
  final double avgSpeedMph;

  bool get isEmpty => sessions == 0;

  /// [now] is injectable so the aggregation is testable without a clock.
  factory PeriodStats.from(
    List<Activity> activities,
    StatsPeriod period, {
    DateTime? now,
  }) {
    final today = now ?? DateTime.now();
    final midnight = DateTime(today.year, today.month, today.day);
    final DateTime start;
    final DateTime end;
    if (period == StatsPeriod.week) {
      start = midnight.subtract(Duration(days: midnight.weekday - 1));
      end = start.add(const Duration(days: 7));
    } else {
      start = DateTime(today.year, today.month);
      end = DateTime(today.year, today.month + 1);
    }

    final inPeriod = activities
        .where((a) => !a.startTime.isBefore(start) && a.startTime.isBefore(end))
        .toList();

    var distance = 0.0;
    var vertical = 0.0;
    var duration = 0;
    var topSpeed = 0.0;
    for (final activity in inPeriod) {
      distance += activity.distance;
      vertical += activity.elevationGain;
      duration += activity.duration;
      final speed = Imperial.mphFromPace(activity.maxPace);
      if (speed > topSpeed) topSpeed = speed;
    }

    final avgSpeed = duration == 0
        ? 0.0
        : Imperial.miles(distance) / (duration / 3600);

    return PeriodStats(
      period: period,
      start: start,
      // Display wants an inclusive end date ("Dec 16 – Dec 22").
      end: end.subtract(const Duration(days: 1)),
      sessions: inPeriod.length,
      // ponytail: one activity == one recorded session; a per-run breakdown
      // lands when the pipeline starts emitting runs separately.
      runs: inPeriod.length,
      distanceMetres: distance,
      verticalMetres: vertical,
      durationSeconds: duration,
      topSpeedMph: topSpeed,
      avgSpeedMph: avgSpeed,
    );
  }
}
