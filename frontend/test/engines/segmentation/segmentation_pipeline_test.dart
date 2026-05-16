import 'package:flutter_test/flutter_test.dart';
import 'package:syntrak/core/constants/trail_detection_thresholds.dart';
import 'package:syntrak/engines/segmentation/point_classifier.dart';
import 'package:syntrak/engines/segmentation/segment_grouper.dart' as grouper;
import 'package:syntrak/engines/segmentation/vertical_velocity_computer.dart' as vv;
import 'package:syntrak/models/track_point.dart';

void main() {
  test('pipeline computes vv, classifies points, and groups segments', () {
    final points = <TrackPoint>[
      _pt(0, 1000, 30),
      _pt(1, 999, 30),
      _pt(2, 998, 30),
      _pt(3, 1020, 1),
      _pt(4, 1020, 1),
      _pt(5, 1020, 1),
      _pt(6, 1020, 1),
      _pt(7, 1020, 1),
      _pt(8, 1020, 1),
      _pt(9, 1020, 1),
      _pt(10, 1020, 1),
      _pt(11, 1020, 1),
      _pt(12, 1020, 20),
    ];

    final vvs = vv.compute(points);
    final states = <PointState>[];

    var lowSpeedDuration = 0.0;
    for (var i = 0; i < points.length; i++) {
      if (i > 0 && points[i].speedKmh < pauseSpeedKmh) {
        lowSpeedDuration += points[i].timestamp.difference(points[i - 1].timestamp).inSeconds.toDouble();
      } else if (i > 0) {
        lowSpeedDuration = 0.0;
      }
      states.add(classify(points[i], vvs[i], lowSpeedDurationSeconds: lowSpeedDuration));
    }

    final segments = grouper.group(points, states);

    expect(vvs, hasLength(points.length));
    expect(states, hasLength(points.length));
    expect(segments, isNotEmpty);
    expect(segments.any((s) => s.type == PointState.pause), isTrue);
    expect(segments.any((s) => s.type == PointState.descent), isTrue);
    expect(segments.any((s) => s.type == PointState.lift || s.type == PointState.flat), isTrue);
  });
}

TrackPoint _pt(int idx, double elevation, double speedKmh) {
  return TrackPoint(
    lat: 46.0 + idx * 0.00001,
    lon: 8.0 + idx * 0.00001,
    elevationM: elevation,
    timestamp: DateTime.utc(2026, 1, 1, 10, 0, idx),
    speedKmh: speedKmh,
  );
}
