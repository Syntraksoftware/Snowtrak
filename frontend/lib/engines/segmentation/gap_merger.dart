import 'package:syntrak/models/segment.dart';
import 'package:syntrak/models/track_point.dart';

const double _pauseMergeMaxSeconds = 30.0;
const double _flatMergeMaxSeconds = 15.0;

/// Merges tiny pause/flat bridges between two descents into a single descent.
///
/// Rules:
/// - pause bridge duration <= 30s
/// - flat bridge duration <= 15s
/// - bridge must be sandwiched by descent segments
List<Segment> mergeShortBridges(List<Segment> input) {
  if (input.length < 3) {
    return List<Segment>.from(input);
  }

  final merged = List<Segment>.from(input);
  var i = 1;
  while (i < merged.length - 1) {
    final prev = merged[i - 1];
    final current = merged[i];
    final next = merged[i + 1];

    if (prev.type != SegmentType.descent || next.type != SegmentType.descent) {
      i += 1;
      continue;
    }

    if (!_isMergeableBridge(current)) {
      i += 1;
      continue;
    }

    final combined = Segment(
      type: SegmentType.descent,
      startIndex: prev.startIndex,
      endIndex: next.endIndex,
      points: <TrackPoint>[...prev.points, ...current.points, ...next.points],
      trailName: prev.trailName,
      difficulty: prev.difficulty,
    );

    merged.removeRange(i - 1, i + 2);
    merged.insert(i - 1, combined);

    if (i > 1) {
      i -= 1;
    }
  }

  return merged;
}

bool _isMergeableBridge(Segment segment) {
  if (segment.points.isEmpty) {
    return false;
  }

  final duration = _segmentDurationSeconds(segment);
  if (segment.type == SegmentType.pause) {
    return duration <= _pauseMergeMaxSeconds;
  }

  if (segment.type == SegmentType.flat) {
    return duration <= _flatMergeMaxSeconds;
  }

  return false;
}

double _segmentDurationSeconds(Segment segment) {
  final first = segment.points.first.timestamp.toUtc();
  final last = segment.points.last.timestamp.toUtc();
  return last.difference(first).inMilliseconds / 1000.0;
}
