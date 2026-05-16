import 'package:flutter_test/flutter_test.dart';
import 'package:syntrak/engines/segmentation/point_classifier.dart';
import 'package:syntrak/engines/segmentation/segment_grouper.dart' as grouper;
import 'package:syntrak/models/track_point.dart';

void main() {
  test('group emits a new RawSegment whenever state changes', () {
    final points = <TrackPoint>[
      _pt(0, 0),
      _pt(1, 1),
      _pt(2, 2),
      _pt(3, 3),
      _pt(4, 4),
    ];
    final states = <PointState>[
      PointState.descent,
      PointState.descent,
      PointState.flat,
      PointState.flat,
      PointState.lift,
    ];

    final segments = grouper.group(points, states);

    expect(segments, hasLength(3));
    expect(segments[0].type, PointState.descent);
    expect(segments[0].startIndex, 0);
    expect(segments[0].endIndex, 1);
    expect(segments[0].points, hasLength(2));

    expect(segments[1].type, PointState.flat);
    expect(segments[1].startIndex, 2);
    expect(segments[1].endIndex, 3);
    expect(segments[1].points, hasLength(2));

    expect(segments[2].type, PointState.lift);
    expect(segments[2].startIndex, 4);
    expect(segments[2].endIndex, 4);
    expect(segments[2].points, hasLength(1));
  });
}

TrackPoint _pt(int idx, double elevation) {
  return TrackPoint(
    lat: 46.0 + idx * 0.00001,
    lon: 8.0 + idx * 0.00001,
    elevationM: elevation,
    timestamp: DateTime.utc(2026, 1, 1, 10, 0, idx),
    speedKmh: 20,
  );
}
