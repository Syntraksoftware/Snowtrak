import 'dart:math' as math;

import 'package:syntrak/models/track_point.dart';

import '../parsers/gpx_parser.dart';

const double _earthRadiusM = 6371000.0;
const int _rollingWindow = 5;

/// Converts [RawPoint] samples into [TrackPoint] with smoothed speed.
///
/// - Instantaneous speed = haversine distance / delta-time.
/// - Applies trailing 5-point rolling average to reduce spikes.
List<TrackPoint> compute(List<RawPoint> rawPoints) {
  if (rawPoints.isEmpty) {
    return <TrackPoint>[];
  }

  final instantaneous = <double>[];

  for (var i = 0; i < rawPoints.length; i++) {
    if (i == 0) {
      instantaneous.add(0.0);
      continue;
    }

    final prev = rawPoints[i - 1];
    final curr = rawPoints[i];

    final dtSeconds = _deltaTimeSeconds(prev.time, curr.time);
    if (dtSeconds <= 0) {
      instantaneous.add(0.0);
      continue;
    }

    final distanceM = _haversineMeters(prev.lat, prev.lon, curr.lat, curr.lon);
    final speedKmh = (distanceM / dtSeconds) * 3.6;
    instantaneous.add(speedKmh);
  }

  final smoothed = _rollingAverage(instantaneous, _rollingWindow);

  final out = <TrackPoint>[];
  DateTime? prevTimestamp;
  double prevElevation = rawPoints.first.ele ?? 0.0;

  for (var i = 0; i < rawPoints.length; i++) {
    final p = rawPoints[i];

    final timestamp = p.time?.toUtc() ??
        (prevTimestamp != null
            ? prevTimestamp.add(const Duration(seconds: 1))
            : DateTime.fromMillisecondsSinceEpoch(0, isUtc: true));

    final elevation = p.ele ?? prevElevation;

    out.add(
      TrackPoint(
        lat: p.lat,
        lon: p.lon,
        elevationM: elevation,
        timestamp: timestamp,
        speedKmh: smoothed[i],
      ),
    );

    prevTimestamp = timestamp;
    prevElevation = elevation;
  }

  return out;
}

List<double> _rollingAverage(List<double> values, int windowSize) {
  final out = <double>[];

  for (var i = 0; i < values.length; i++) {
    final start = math.max(0, i - windowSize + 1);
    var sum = 0.0;
    for (var j = start; j <= i; j++) {
      sum += values[j];
    }
    out.add(sum / (i - start + 1));
  }

  return out;
}

double _deltaTimeSeconds(DateTime? a, DateTime? b) {
  if (a == null || b == null) {
    return 1.0;
  }

  final ms = b.toUtc().difference(a.toUtc()).inMilliseconds;
  if (ms <= 0) {
    return 0.0;
  }
  return ms / 1000.0;
}

double _haversineMeters(double lat1, double lon1, double lat2, double lon2) {
  final phi1 = _degToRad(lat1);
  final phi2 = _degToRad(lat2);
  final dPhi = _degToRad(lat2 - lat1);
  final dLambda = _degToRad(lon2 - lon1);

  final a = math.sin(dPhi / 2) * math.sin(dPhi / 2) +
      math.cos(phi1) * math.cos(phi2) * math.sin(dLambda / 2) * math.sin(dLambda / 2);
  final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  return _earthRadiusM * c;
}

double _degToRad(double deg) => deg * math.pi / 180.0;
