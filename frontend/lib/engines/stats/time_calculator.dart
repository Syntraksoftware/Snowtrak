import 'package:syntrak/models/segment.dart';

Duration _segmentDuration(Segment segment) {
  if (segment.points.length < 2) {
    return Duration.zero;
  }
  final start = segment.points.first.timestamp.toUtc();
  final end = segment.points.last.timestamp.toUtc();
  final duration = end.difference(start);
  return duration.isNegative ? Duration.zero : duration;
}

/// Sum of durations of all non-pause segments.
Duration movingTime(List<Segment> segments) {
  var total = Duration.zero;
  for (final segment in segments) {
    if (segment.type == SegmentType.pause) {
      continue;
    }
    total += _segmentDuration(segment);
  }
  return total;
}

/// First point timestamp to last point timestamp across all segments.
Duration totalTime(List<Segment> segments) {
  final points = segments.expand((segment) => segment.points).toList();
  if (points.length < 2) {
    return Duration.zero;
  }

  var minTime = points.first.timestamp.toUtc();
  var maxTime = points.first.timestamp.toUtc();
  for (final point in points.skip(1)) {
    final timestamp = point.timestamp.toUtc();
    if (timestamp.isBefore(minTime)) {
      minTime = timestamp;
    }
    if (timestamp.isAfter(maxTime)) {
      maxTime = timestamp;
    }
  }

  final duration = maxTime.difference(minTime);
  return duration.isNegative ? Duration.zero : duration;
}

/// Sum of durations of lift segments only.
Duration timeOnLifts(List<Segment> segments) {
  var total = Duration.zero;
  for (final segment in segments) {
    if (segment.type != SegmentType.lift) {
      continue;
    }
    total += _segmentDuration(segment);
  }
  return total;
}