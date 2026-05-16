import 'package:syntrak/models/segment.dart';

/// Total vertical drop in metres across descent segments.
double totalDropM(List<Segment> segments) {
  var total = 0.0;

  for (final segment in segments) {
    if (segment.type != SegmentType.descent || segment.points.length < 2) {
      continue;
    }

    for (var i = 1; i < segment.points.length; i++) {
      final delta = segment.points[i].elevationM - segment.points[i - 1].elevationM;
      if (delta < 0) {
        total += -delta;
      }
    }
  }

  return total;
}