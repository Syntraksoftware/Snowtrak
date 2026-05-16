import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:syntrak/engines/stats/distance_calculator.dart';
import 'package:syntrak/models/track_point.dart';

void main() {
  test('totalKm matches a reference distance calculator', () {
    final points = <TrackPoint>[
      _pt(47.244088, 10.137983),
      _pt(47.243476, 10.13794),
      _pt(47.242806, 10.137168),
      _pt(47.242136, 10.136009),
    ];

    final expected = _referenceTotalKm(points);
    final actual = totalKm(points);

    expect(actual, closeTo(expected, 0.001));
  });

  test('totalKm returns zero for single-point input', () {
    expect(totalKm([_pt(47.244088, 10.137983)]), 0.0);
  });
}

TrackPoint _pt(double lat, double lon) {
  return TrackPoint(
    lat: lat,
    lon: lon,
    elevationM: 2000,
    timestamp: DateTime.utc(2026, 1, 1, 10, 0, 0),
    speedKmh: 20,
  );
}

double _referenceTotalKm(List<TrackPoint> points) {
  var total = 0.0;
  for (var i = 1; i < points.length; i++) {
    total += _haversineKm(points[i - 1], points[i]);
  }
  return total;
}

double _haversineKm(TrackPoint a, TrackPoint b) {
  const earthRadiusKm = 6371.0088;
  final lat1 = _degToRad(a.lat);
  final lat2 = _degToRad(b.lat);
  final dLat = _degToRad(b.lat - a.lat);
  final dLon = _degToRad(b.lon - a.lon);

  final sinLat = math.sin(dLat / 2);
  final sinLon = math.sin(dLon / 2);
  final h = sinLat * sinLat + math.cos(lat1) * math.cos(lat2) * sinLon * sinLon;
  final c = 2 * math.atan2(math.sqrt(h), math.sqrt(1 - h));
  return earthRadiusKm * c;
}

double _degToRad(double degrees) => degrees * math.pi / 180.0;