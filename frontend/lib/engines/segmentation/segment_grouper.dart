import 'package:syntrak/models/track_point.dart';

import 'point_classifier.dart';

class RawSegment {
  const RawSegment({
    required this.type,
    required this.startIndex,
    required this.endIndex,
    required this.points,
  });

  final PointState type;
  final int startIndex;
  final int endIndex;
  final List<TrackPoint> points;
}

/// Groups consecutive points with the same state into contiguous segments.
List<RawSegment> group(List<TrackPoint> points, List<PointState> states) {
  if (points.length != states.length) {
    throw ArgumentError('points and states must have the same length');
  }
  if (points.isEmpty) {
    return <RawSegment>[];
  }

  final segments = <RawSegment>[];
  var segmentStart = 0;
  var currentState = states.first;

  for (var i = 1; i < states.length; i++) {
    final state = states[i];
    if (state == currentState) {
      continue;
    }

    segments.add(
      RawSegment(
        type: currentState,
        startIndex: segmentStart,
        endIndex: i - 1,
        points: points.sublist(segmentStart, i),
      ),
    );

    segmentStart = i;
    currentState = state;
  }

  segments.add(
    RawSegment(
      type: currentState,
      startIndex: segmentStart,
      endIndex: points.length - 1,
      points: points.sublist(segmentStart),
    ),
  );

  return segments;
}
