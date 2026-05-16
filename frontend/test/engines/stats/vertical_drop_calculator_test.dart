import 'package:flutter_test/flutter_test.dart';
import 'package:syntrak/engines/stats/vertical_drop_calculator.dart';
import 'package:syntrak/models/segment.dart';
import 'package:syntrak/models/track_point.dart';

void main() {
  test('totalDropM sums negative deltas only and ignores flat traverses', () {
    final segments = <Segment>[
      _descent([1000, 995, 996, 992]),
      _lift([992, 1000]),
      _pause([1000, 995]),
    ];

    expect(totalDropM(segments), closeTo(9.0, 1e-9));
  });

  test('totalDropM ignores non-descent segments', () {
    final segments = <Segment>[
      _lift([1000, 990, 980]),
      _flat([980, 979, 981]),
    ];

    expect(totalDropM(segments), 0.0);
  });
}

Segment _descent(List<num> elevations) => _segment(SegmentType.descent, elevations);
Segment _lift(List<num> elevations) => _segment(SegmentType.lift, elevations);
Segment _pause(List<num> elevations) => _segment(SegmentType.pause, elevations);
Segment _flat(List<num> elevations) => _segment(SegmentType.flat, elevations);

Segment _segment(SegmentType type, List<num> elevations) {
  final start = DateTime.utc(2026, 1, 1, 10, 0, 0);
  final points = <TrackPoint>[
    for (var i = 0; i < elevations.length; i++)
      TrackPoint(
        lat: 46.0 + i * 0.00001,
        lon: 8.0 + i * 0.00001,
        elevationM: elevations[i].toDouble(),
        timestamp: start.add(Duration(seconds: i)),
        speedKmh: 20,
      ),
  ];

  return Segment(
    type: type,
    points: points,
    startIndex: 0,
    endIndex: points.length - 1,
  );
}