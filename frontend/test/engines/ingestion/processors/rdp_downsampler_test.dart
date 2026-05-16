import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:syntrak/engines/ingestion/parsers/gpx_parser.dart';
import 'package:syntrak/engines/ingestion/processors/rdp_downsampler.dart';

void main() {
  test('simplify reduces 10,000-point fixture under 1,000 with low shape loss', () {
    final original = _fixtureTrack10000();

    final simplified = simplify(original, defaultEpsilon);

    expect(simplified.length, lessThan(1000));
    expect(simplified.first.lat, closeTo(original.first.lat, 1e-12));
    expect(simplified.first.lon, closeTo(original.first.lon, 1e-12));
    expect(simplified.last.lat, closeTo(original.last.lat, 1e-12));
    expect(simplified.last.lon, closeTo(original.last.lon, 1e-12));

    final maxDeviation = _maxDistanceToPolyline(original, simplified);
    expect(maxDeviation, lessThanOrEqualTo(defaultEpsilon * 1.2));
  });
}

List<RawPoint> _fixtureTrack10000() {
  final out = <RawPoint>[];
  final start = DateTime.utc(2026, 1, 1, 10, 0, 0);

  for (var i = 0; i < 10000; i++) {
    final t = i / 9999.0;

    // Long descent with smooth turns and tiny noise.
    final lat = 46.800000 + 0.08 * t + 0.00025 * math.sin(t * 18 * math.pi);
    final lon = 8.150000 + 0.10 * t + 0.00022 * math.cos(t * 16 * math.pi);

    out.add(
      RawPoint(
        lat: lat,
        lon: lon,
        ele: 2400.0 - (1000.0 * t),
        time: start.add(Duration(milliseconds: i * 500)),
      ),
    );
  }

  return out;
}

double _maxDistanceToPolyline(List<RawPoint> original, List<RawPoint> simplified) {
  if (simplified.length < 2 || original.isEmpty) {
    return 0.0;
  }

  var maxDistance = 0.0;
  for (final p in original) {
    var minDistance = double.infinity;
    for (var i = 0; i < simplified.length - 1; i++) {
      final d = _pointToSegmentDistance(p, simplified[i], simplified[i + 1]);
      if (d < minDistance) {
        minDistance = d;
      }
    }
    if (minDistance > maxDistance) {
      maxDistance = minDistance;
    }
  }

  return maxDistance;
}

double _pointToSegmentDistance(RawPoint p, RawPoint a, RawPoint b) {
  final dx = b.lat - a.lat;
  final dy = b.lon - a.lon;

  if (dx == 0 && dy == 0) {
    return _distance2D(p.lat, p.lon, a.lat, a.lon);
  }

  final t = ((p.lat - a.lat) * dx + (p.lon - a.lon) * dy) / (dx * dx + dy * dy);
  final tClamped = t.clamp(0.0, 1.0);

  final projLat = a.lat + tClamped * dx;
  final projLon = a.lon + tClamped * dy;

  return _distance2D(p.lat, p.lon, projLat, projLon);
}

double _distance2D(double x1, double y1, double x2, double y2) {
  final dx = x2 - x1;
  final dy = y2 - y1;
  return math.sqrt(dx * dx + dy * dy);
}
