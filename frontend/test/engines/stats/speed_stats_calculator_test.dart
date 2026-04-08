import 'package:flutter_test/flutter_test.dart';
import 'package:syntrak/engines/stats/speed_stats_calculator.dart';
import 'package:syntrak/models/segment.dart';
import 'package:syntrak/models/track_point.dart';

void main() {
  test('topSpeedKmh uses descent points only', () {
    final segments = <Segment>[
      _segment(SegmentType.descent, [20, 45, 38]),
      _segment(SegmentType.flat, [80, 90]),
      _segment(SegmentType.lift, [110, 120]),
      _segment(SegmentType.pause, [200, 250]),
    ];

    expect(topSpeedKmh(segments), 45.0);
  });

  test('avgSpeedKmh excludes lift and pause segments', () {
    final segments = <Segment>[
      _segment(SegmentType.descent, [20, 40]),
      _segment(SegmentType.flat, [10, 30]),
      _segment(SegmentType.lift, [200, 220]),
      _segment(SegmentType.pause, [0, 0]),
    ];

    expect(avgSpeedKmh(segments), closeTo(25.0, 1e-9));
  });
}

Segment _segment(SegmentType type, List<double> speeds) {
  final start = DateTime.utc(2026, 1, 1, 10, 0, 0);
  final points = <TrackPoint>[
    for (var i = 0; i < speeds.length; i++)
      TrackPoint(
        lat: 46.0 + i * 0.00001,
        lon: 8.0 + i * 0.00001,
        elevationM: 1000 - i * 5,
        timestamp: start.add(Duration(seconds: i)),
        speedKmh: speeds[i],
      ),
  ];

  return Segment(
    type: type,
    points: points,
    startIndex: 0,
    endIndex: points.length - 1,
  );
}