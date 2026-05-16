import 'dart:math' as math;

import 'package:syntrak/models/track_point.dart';

const double _earthRadiusKm = 6371.0088;

/// Total route distance in kilometres from consecutive track points.
double totalKm(List<TrackPoint> points) {
  if (points.length < 2) {
    return 0.0;
  }

  var total = 0.0;
  for (var i = 1; i < points.length; i++) {
    total += _haversineKm(points[i - 1], points[i]);
  }
  return total;
}

double _haversineKm(TrackPoint a, TrackPoint b) {
  final lat1 = _degToRad(a.lat);
  final lat2 = _degToRad(b.lat);
  final dLat = _degToRad(b.lat - a.lat);
  final dLon = _degToRad(b.lon - a.lon);

  final sinLat = math.sin(dLat / 2);
  final sinLon = math.sin(dLon / 2);
  final h = sinLat * sinLat + math.cos(lat1) * math.cos(lat2) * sinLon * sinLon;
  final c = 2 * math.atan2(math.sqrt(h), math.sqrt(1 - h));
  return _earthRadiusKm * c;
}

double _degToRad(double degrees) => degrees * math.pi / 180.0;