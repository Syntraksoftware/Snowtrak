import 'package:syntrak/models/segment.dart';

bool _isEligibleForAverage(SegmentType type) {
  return type != SegmentType.lift && type != SegmentType.pause;
}

/// Maximum observed speed across descent points.
double topSpeedKmh(List<Segment> segments) {
  var maxSpeed = 0.0;

  for (final segment in segments) {
    if (segment.type != SegmentType.descent) {
      continue;
    }

    for (final point in segment.points) {
      if (point.speedKmh > maxSpeed) {
        maxSpeed = point.speedKmh;
      }
    }
  }

  return maxSpeed;
}

/// Mean speed across moving points only, excluding pause and lift segments.
double avgSpeedKmh(List<Segment> segments) {
  var sum = 0.0;
  var count = 0;

  for (final segment in segments) {
    if (!_isEligibleForAverage(segment.type)) {
      continue;
    }

    for (final point in segment.points) {
      sum += point.speedKmh;
      count += 1;
    }
  }

  if (count == 0) {
    return 0.0;
  }

  return sum / count;
}