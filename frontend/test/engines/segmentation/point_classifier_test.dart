import 'package:flutter_test/flutter_test.dart';
import 'package:syntrak/core/constants/trail_detection_thresholds.dart';
import 'package:syntrak/engines/segmentation/point_classifier.dart';
import 'package:syntrak/models/track_point.dart';

void main() {
  final basePoint = TrackPoint(
    lat: 46.0,
    lon: 8.0,
    elevationM: 1000,
    timestamp: DateTime.utc(2026, 1, 1, 10, 0, 0),
    speedKmh: 20,
  );

  test('classify prefers pause when speed is low for long enough', () {
    final state = classify(
      basePoint.copyWith(speedKmh: pauseSpeedKmh - 0.1),
      0.0,
      lowSpeedDurationSeconds: pauseMinSeconds + 1,
    );

    expect(state, PointState.pause);
  });

  test('classify returns descent when vv is below threshold', () {
    final state = classify(basePoint, descentVvThreshold - 0.1);
    expect(state, PointState.descent);
  });

  test('classify returns lift when vv is above threshold', () {
    final state = classify(basePoint, liftVvThreshold + 0.1);
    expect(state, PointState.lift);
  });

  test('classify returns flat when vv is between thresholds', () {
    final state = classify(basePoint, 0.0);
    expect(state, PointState.flat);
  });
}
