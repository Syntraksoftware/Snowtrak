import 'package:snowtrak/models/duel.dart';

/// How a metric's value is written, and in what unit.
///
/// The server ranks in metres and km/h; the app is imperial elsewhere
/// (`Imperial.mphFromPace` in home_stats), so the conversion happens once,
/// here, rather than in each screen that shows a number.
String formatMetricValue(DuelMetric metric, double value) {
  return switch (metric) {
    DuelMetric.vertical => '${_thousands((value * 3.28084).round())} ft',
    DuelMetric.distance => '${(value / 1000 * 0.621371).toStringAsFixed(1)} mi',
    DuelMetric.speed => '${(value * 0.621371).toStringAsFixed(1)} mph',
  };
}

/// Short unit for a column header.
String metricUnit(DuelMetric metric) => switch (metric) {
      DuelMetric.vertical => 'ft',
      DuelMetric.distance => 'mi',
      DuelMetric.speed => 'mph',
    };

/// A countdown, coarsest useful unit first.
///
/// Deliberately not seconds: a duel runs for days, and a ticking second hand
/// is a rebuild per second for information nobody acts on.
String formatRemaining(Duration remaining) {
  if (remaining <= Duration.zero) return 'Ended';
  if (remaining.inDays >= 1) {
    final hours = remaining.inHours % 24;
    return '${remaining.inDays}d ${hours}h left';
  }
  if (remaining.inHours >= 1) {
    final minutes = remaining.inMinutes % 60;
    return '${remaining.inHours}h ${minutes}m left';
  }
  return '${remaining.inMinutes}m left';
}

String _thousands(int value) {
  final digits = value.abs().toString();
  final buffer = StringBuffer(value < 0 ? '-' : '');
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(',');
    buffer.write(digits[i]);
  }
  return buffer.toString();
}
