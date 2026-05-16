import 'package:flutter_test/flutter_test.dart';
import 'package:syntrak/engines/stats/time_calculator.dart';
import 'package:syntrak/models/segment.dart';
import 'package:syntrak/models/track_point.dart';

void main() {
  test('movingTime sums all non-pause segments', () {
    final segments = <Segment>[
      _segment(SegmentType.descent, 0, 10),
      _segment(SegmentType.lift, 20, 35),
      _segment(SegmentType.pause, 40, 70),
      _segment(SegmentType.flat, 80, 95),
    ];

    expect(movingTime(segments), const Duration(seconds: 10 + 15 + 15));
  });

  test('totalTime spans first to last point timestamp', () {
    final segments = <Segment>[
      _segment(SegmentType.descent, 0, 10),
      _segment(SegmentType.pause, 40, 70),
      _segment(SegmentType.lift, 80, 95),
    ];

    expect(totalTime(segments), const Duration(seconds: 95));
  });

  test('timeOnLifts uses lift segments only', () {
    final segments = <Segment>[
      _segment(SegmentType.descent, 0, 10),
      _segment(SegmentType.lift, 20, 35),
      _segment(SegmentType.pause, 40, 70),
      _segment(SegmentType.lift, 80, 100),
    ];

    expect(timeOnLifts(segments), const Duration(seconds: 35));
  });
}

Segment _segment(SegmentType type, int startSecond, int endSecond) {
  final points = <TrackPoint>[
    TrackPoint(
      lat: 46.0,
      lon: 8.0,
      elevationM: 1000,
      timestamp: DateTime.utc(2026, 1, 1, 10, 0, 0).add(Duration(seconds: startSecond)),
      speedKmh: 20,
    ),
    TrackPoint(
      lat: 46.0001,
      lon: 8.0001,
      elevationM: 999,
      timestamp: DateTime.utc(2026, 1, 1, 10, 0, 0).add(Duration(seconds: endSecond)),
      speedKmh: 22,
    ),
  ];

  return Segment(
    type: type,
    points: points,
    startIndex: 0,
    endIndex: 1,
  );
}