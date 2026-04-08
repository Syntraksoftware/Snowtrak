import 'package:flutter_test/flutter_test.dart';
import 'package:syntrak/engines/segmentation/gap_merger.dart';
import 'package:syntrak/models/segment.dart';
import 'package:syntrak/models/track_point.dart';

void main() {
  test('mergeShortBridges merges pause bridge between descents at 30s boundary', () {
    final segments = <Segment>[
      _segment(type: SegmentType.descent, start: 0, end: 2, secondOffsets: <int>[0, 2]),
      _segment(type: SegmentType.pause, start: 3, end: 4, secondOffsets: <int>[10, 40]),
      _segment(type: SegmentType.descent, start: 5, end: 8, secondOffsets: <int>[41, 48]),
    ];

    final merged = mergeShortBridges(segments);

    expect(merged, hasLength(1));
    expect(merged.first.type, SegmentType.descent);
    expect(merged.first.startIndex, 0);
    expect(merged.first.endIndex, 8);
    expect(merged.first.points.length, 6);
  });

  test('mergeShortBridges does not merge flat bridge longer than 15s', () {
    final segments = <Segment>[
      _segment(type: SegmentType.descent, start: 0, end: 1, secondOffsets: <int>[0, 2]),
      _segment(type: SegmentType.flat, start: 2, end: 3, secondOffsets: <int>[10, 26]),
      _segment(type: SegmentType.descent, start: 4, end: 5, secondOffsets: <int>[27, 31]),
    ];

    final merged = mergeShortBridges(segments);

    expect(merged, hasLength(3));
    expect(merged[0].type, SegmentType.descent);
    expect(merged[1].type, SegmentType.flat);
    expect(merged[2].type, SegmentType.descent);
  });

  test('mergeShortBridges does not merge bridge when not sandwiched by descents', () {
    final segments = <Segment>[
      _segment(type: SegmentType.descent, start: 0, end: 1, secondOffsets: <int>[0, 2]),
      _segment(type: SegmentType.pause, start: 2, end: 3, secondOffsets: <int>[5, 12]),
      _segment(type: SegmentType.lift, start: 4, end: 6, secondOffsets: <int>[13, 20]),
    ];

    final merged = mergeShortBridges(segments);

    expect(merged, hasLength(3));
    expect(merged[0].type, SegmentType.descent);
    expect(merged[1].type, SegmentType.pause);
    expect(merged[2].type, SegmentType.lift);
  });

  test('mergeShortBridges can merge consecutive bridges after first merge', () {
    final segments = <Segment>[
      _segment(type: SegmentType.descent, start: 0, end: 1, secondOffsets: <int>[0, 2]),
      _segment(type: SegmentType.pause, start: 2, end: 3, secondOffsets: <int>[3, 10]),
      _segment(type: SegmentType.descent, start: 4, end: 5, secondOffsets: <int>[11, 14]),
      _segment(type: SegmentType.flat, start: 6, end: 7, secondOffsets: <int>[15, 20]),
      _segment(type: SegmentType.descent, start: 8, end: 9, secondOffsets: <int>[21, 26]),
    ];

    final merged = mergeShortBridges(segments);

    expect(merged, hasLength(1));
    expect(merged.first.type, SegmentType.descent);
    expect(merged.first.startIndex, 0);
    expect(merged.first.endIndex, 9);
    expect(merged.first.points.length, 10);
  });
}

Segment _segment({
  required SegmentType type,
  required int start,
  required int end,
  required List<int> secondOffsets,
}) {
  final points = secondOffsets
      .map((s) => TrackPoint(
            lat: 46.0 + s * 0.00001,
            lon: 8.0 + s * 0.00001,
            elevationM: 1000 - s * 0.5,
            timestamp: DateTime.utc(2026, 1, 1, 10, 0, 0).add(Duration(seconds: s)),
            speedKmh: 20,
          ))
      .toList();

  return Segment(
    type: type,
    startIndex: start,
    endIndex: end,
    points: points,
  );
}
