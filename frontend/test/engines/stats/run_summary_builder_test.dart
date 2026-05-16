import 'package:flutter_test/flutter_test.dart';
import 'package:syntrak/engines/stats/run_summary_builder.dart';
import 'package:syntrak/models/segment.dart';
import 'package:syntrak/models/track_point.dart';

void main() {
  test('build returns one summary per descent with run numbering', () {
    final segments = <Segment>[
      _segment(
        SegmentType.descent,
        [1000, 995, 990],
        speedValues: [20, 35, 40],
        trailName: 'Blue Fox',
        difficulty: 'blue',
      ),
      _segment(
        SegmentType.lift,
        [990, 1005],
        speedValues: [5, 10],
      ),
      _segment(
        SegmentType.descent,
        [1005, 998, 992],
        speedValues: [22, 30, 28],
        trailName: 'Red Line',
        difficulty: 'red',
      ),
    ];

    final summaries = build(segments);

    expect(summaries, hasLength(2));
    expect(summaries[0].runNumber, 'Run 1');
    expect(summaries[0].trailName, 'Blue Fox');
    expect(summaries[0].difficulty, 'blue');
    expect(summaries[0].startElevM, 1000);
    expect(summaries[0].endElevM, 990);
    expect(summaries[0].verticalDropM, closeTo(10.0, 1e-9));
    expect(summaries[1].runNumber, 'Run 2');
    expect(summaries[1].trailName, 'Red Line');
    expect(summaries[1].difficulty, 'red');
  });
}

Segment _segment(
  SegmentType type,
  List<num> elevations, {
  List<num>? speedValues,
  String? trailName,
  String? difficulty,
}) {
  final start = DateTime.utc(2026, 1, 1, 10, 0, 0);
  final points = <TrackPoint>[
    for (var i = 0; i < elevations.length; i++)
      TrackPoint(
        lat: 46.0 + i * 0.00001,
        lon: 8.0 + i * 0.00001,
        elevationM: elevations[i].toDouble(),
        timestamp: start.add(Duration(seconds: i)),
        speedKmh: speedValues?[i].toDouble() ?? 20,
      ),
  ];

  return Segment(
    type: type,
    points: points,
    startIndex: 0,
    endIndex: points.length - 1,
    trailName: trailName,
    difficulty: difficulty,
  );
}