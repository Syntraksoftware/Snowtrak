import 'package:syntrak/models/track_point.dart';

/// Computes vertical velocity (m/s) for each point from elevation change / time.
///
/// Index 0 is always 0.0. Subsequent values are smoothed with a trailing 3-point
/// average to reduce single-point spikes that can create phantom segments.
List<double> compute(List<TrackPoint> points) {
  if (points.isEmpty) {
    return <double>[];
  }

  final raw = List<double>.filled(points.length, 0.0);
  raw[0] = 0.0;

  for (var i = 1; i < points.length; i++) {
    final prev = points[i - 1];
    final curr = points[i];
    final dtSeconds = _deltaTimeSeconds(prev.timestamp, curr.timestamp);
    if (dtSeconds <= 0) {
      raw[i] = raw[i - 1];
      continue;
    }

    raw[i] = (curr.elevationM - prev.elevationM) / dtSeconds;
  }

  final smoothed = List<double>.filled(points.length, 0.0);
  for (var i = 0; i < points.length; i++) {
    final start = i >= 2 ? i - 2 : 0;
    var sum = 0.0;
    for (var j = start; j <= i; j++) {
      sum += raw[j];
    }
    smoothed[i] = sum / (i - start + 1);
  }

  smoothed[0] = 0.0;
  return smoothed;
}

double _deltaTimeSeconds(DateTime prev, DateTime curr) {
  final ms = curr.toUtc().difference(prev.toUtc()).inMilliseconds;
  return ms / 1000.0;
}
