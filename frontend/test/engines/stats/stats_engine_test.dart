import 'package:flutter_test/flutter_test.dart';
import 'package:syntrak/engines/stats/stats_engine.dart';
import 'package:syntrak/models/segment.dart';
import 'package:syntrak/models/track_point.dart';

void main() {
  test('compute returns plausible activity stats and runs within 50ms', () {
    final segments = _realisticTrackSegments();
    final engine = StatsEngine();

    final sw = Stopwatch()..start();
    final stats = engine.compute(segments);
    final summaries = engine.buildRunSummaries(segments);
    sw.stop();

    expect(stats.totalDistanceKm, greaterThan(0));
    expect(stats.totalVerticalDropM, greaterThan(0));
    expect(stats.topSpeedKmh, greaterThan(stats.avgSpeedKmh));
    expect(stats.trailCount, 2);
    expect(summaries, hasLength(2));
    expect(summaries.first.runNumber, 'Run 1');
    expect(sw.elapsedMilliseconds, lessThan(50));
  });
}

List<Segment> _realisticTrackSegments() {
  final start = DateTime.utc(2026, 1, 1, 10, 0, 0);

  List<TrackPoint> buildPoints(
    int count,
    double latStart,
    double lonStart,
    double elevStart,
    double latStep,
    double lonStep,
    double elevStep,
    double speedBase,
  ) {
    return List<TrackPoint>.generate(count, (i) {
      return TrackPoint(
        lat: latStart + latStep * i,
        lon: lonStart + lonStep * i,
        elevationM: elevStart + elevStep * i,
        timestamp: start.add(Duration(seconds: i)),
        speedKmh: speedBase + (i % 7),
      );
    });
  }

  return <Segment>[
    Segment(
      type: SegmentType.descent,
      points: buildPoints(120, 47.25, 10.13, 2050, -0.00005, -0.00006, -4.5, 25),
      startIndex: 0,
      endIndex: 119,
      trailName: 'Karhorn SW face',
      difficulty: 'black',
    ),
    Segment(
      type: SegmentType.lift,
      points: buildPoints(80, 47.23, 10.12, 1500, 0.00002, 0.00003, 6.0, 12),
      startIndex: 120,
      endIndex: 199,
      trailName: null,
      difficulty: null,
    ),
    Segment(
      type: SegmentType.descent,
      points: buildPoints(140, 47.24, 10.14, 2100, -0.00004, -0.00005, -3.5, 28),
      startIndex: 200,
      endIndex: 339,
      trailName: 'Auenfelder Horn',
      difficulty: 'blue',
    ),
    Segment(
      type: SegmentType.pause,
      points: buildPoints(30, 47.245, 10.135, 1800, 0.0, 0.0, 0.0, 0),
      startIndex: 340,
      endIndex: 369,
      trailName: null,
      difficulty: null,
    ),
  ];
}