import 'dart:math' as math;

import '../parsers/gpx_parser.dart';

const double _maxSkiSpeedKmh = 250.0;
const double _maxElevationJumpM = 100.0;
const double _maxElevationJumpWindowS = 2.0;
const double _earthRadiusM = 6371000.0;

/// Removes physically implausible GPS samples for skiing.
///
/// Rules:
/// - Discard point if instantaneous speed from previous kept point > 250 km/h.
/// - Discard point if elevation jump > 100 m within under 2 seconds.
List<RawPoint> remove(List<RawPoint> points) {
  if (points.length <= 1) {
    return List<RawPoint>.from(points);
  }

  final out = <RawPoint>[points.first];

  for (var i = 1; i < points.length; i++) {
    final prev = out.last;
    final curr = points[i];

    final hasTime = prev.time != null && curr.time != null;
    double? dtSeconds;

    if (hasTime) {
      dtSeconds = _deltaTimeSeconds(prev.time!, curr.time!);
      if (dtSeconds <= 0) {
        continue;
      }

      final distanceM = _haversineMeters(prev.lat, prev.lon, curr.lat, curr.lon);
      final speedKmh = (distanceM / dtSeconds) * 3.6;

      if (speedKmh > _maxSkiSpeedKmh) {
        continue;
      }
    }

    final prevEle = prev.ele;
    final currEle = curr.ele;
    if (hasTime && dtSeconds != null && prevEle != null && currEle != null) {
      final elevationDelta = (currEle - prevEle).abs();
      if (dtSeconds < _maxElevationJumpWindowS && elevationDelta > _maxElevationJumpM) {
        continue;
      }
    }

    out.add(curr);
  }

  return out;
}

double _deltaTimeSeconds(DateTime a, DateTime b) {
  return b.difference(a).inMilliseconds / 1000.0;
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
