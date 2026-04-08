import 'package:syntrak/core/constants/trail_detection_thresholds.dart';
import 'package:syntrak/engines/segmentation/gap_merger.dart';
import 'package:syntrak/engines/segmentation/point_classifier.dart';
import 'package:syntrak/engines/segmentation/segment_grouper.dart' as grouper;
import 'package:syntrak/engines/segmentation/trail_matcher.dart';
import 'package:syntrak/engines/segmentation/vertical_velocity_computer.dart' as vv;
import 'package:syntrak/models/processed_track.dart';
import 'package:syntrak/models/segment.dart';

/// Engine 2 facade: vertical velocity -> point states -> grouped segments ->
/// bridge-merge -> trail matching.
class SegmentDetectionEngine {
  SegmentDetectionEngine({required TrailMatcher trailMatcher}) : _trailMatcher = trailMatcher;

  final TrailMatcher _trailMatcher;

  Future<List<Segment>> detect(ProcessedTrack track) async {
    final points = track.points;
    if (points.isEmpty) {
      return <Segment>[];
    }

    final vvs = vv.compute(points);
    final states = <PointState>[];

    var lowSpeedDuration = 0.0;
    for (var i = 0; i < points.length; i++) {
      if (i > 0 && points[i].speedKmh < pauseSpeedKmh) {
        final delta = points[i].timestamp.difference(points[i - 1].timestamp);
        lowSpeedDuration += delta.inMilliseconds / 1000.0;
      } else if (i > 0) {
        lowSpeedDuration = 0.0;
      }

      states.add(classify(points[i], vvs[i], lowSpeedDurationSeconds: lowSpeedDuration));
    }

    final rawSegments = grouper.group(points, states);
    final initial = rawSegments
        .map(
          (s) => Segment(
            type: _toSegmentType(s.type),
            points: s.points,
            startIndex: s.startIndex,
            endIndex: s.endIndex,
          ),
        )
        .toList();

    final merged = mergeShortBridges(initial);
    return _trailMatcher.matchDescents(merged);
  }

  SegmentType _toSegmentType(PointState state) {
    switch (state) {
      case PointState.descent:
        return SegmentType.descent;
      case PointState.lift:
        return SegmentType.lift;
      case PointState.flat:
        return SegmentType.flat;
      case PointState.pause:
        return SegmentType.pause;
    }
  }
}
