import 'dart:math' as math;

import '../parsers/gpx_parser.dart';

const double defaultEpsilon = 0.0001;

/// Recursive Ramer-Douglas-Peucker simplification for lat/lon tracks.
///
/// Always retains first and last point.
List<RawPoint> simplify(List<RawPoint> points, [double epsilon = defaultEpsilon]) {
  if (points.length <= 2) {
    return List<RawPoint>.from(points);
  }

  final keep = List<bool>.filled(points.length, false);
  keep[0] = true;
  keep[points.length - 1] = true;

  _rdp(points, 0, points.length - 1, epsilon, keep);

  final out = <RawPoint>[];
  for (var i = 0; i < points.length; i++) {
    if (keep[i]) {
      out.add(points[i]);
    }
  }
  return out;
}

void _rdp(List<RawPoint> points, int start, int end, double epsilon, List<bool> keep) {
  if (end <= start + 1) {
    return;
  }

  var maxDistance = -1.0;
  var index = -1;

  final a = points[start];
  final b = points[end];

  for (var i = start + 1; i < end; i++) {
    final d = _perpendicularDistance(points[i], a, b);
    if (d > maxDistance) {
      maxDistance = d;
      index = i;
    }
  }

  if (maxDistance > epsilon && index != -1) {
    keep[index] = true;
    _rdp(points, start, index, epsilon, keep);
    _rdp(points, index, end, epsilon, keep);
  }
}

double _perpendicularDistance(RawPoint p, RawPoint a, RawPoint b) {
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
