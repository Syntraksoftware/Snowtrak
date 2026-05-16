import 'package:flutter_test/flutter_test.dart';
import 'package:syntrak/engines/segmentation/segment_detection_engine.dart';
import 'package:syntrak/engines/segmentation/trail_matcher.dart';
import 'package:syntrak/models/processed_track.dart';
import 'package:syntrak/models/segment.dart';
import 'package:syntrak/models/track_point.dart';

void main() {
  test('detect merges short bridge and enriches descent segments with trail metadata', () async {
    final apiClient = _FakeTrailMatchApiClient();
    final matcher = TrailMatcher(apiClient: apiClient);
    final engine = SegmentDetectionEngine(trailMatcher: matcher);

    final track = ProcessedTrack(
      id: 'track-1',
      sourceType: SourceType.gpx,
      recordedAt: DateTime.utc(2026, 1, 1, 10, 0, 0),
      points: <TrackPoint>[
        _pt(0, 1000, 35),
        _pt(1, 999, 35),
        _pt(2, 998, 35),
        _pt(3, 997, 35),
        _pt(4, 997, 15),
        _pt(5, 997, 15),
        _pt(6, 996, 35),
        _pt(7, 995, 35),
        _pt(8, 994, 35),
        _pt(9, 1006, 10),
        _pt(10, 1018, 10),
        _pt(11, 1030, 10),
      ],
    );

    final segments = await engine.detect(track);

    expect(segments, hasLength(3));
    expect(segments[0].type, SegmentType.flat);
    expect(segments[0].trailName, isNull);

    expect(segments[1].type, SegmentType.descent);
    expect(segments[1].startIndex, 2);
    expect(segments[1].endIndex, 8);
    expect(segments[1].trailName, 'Blue Fox');
    expect(segments[1].difficulty, 'blue');

    expect(segments[2].type, SegmentType.lift);
    expect(segments[2].trailName, isNull);
    expect(segments[2].difficulty, isNull);

    expect(apiClient.calls, 1);
  });

  test('done-when: descent count matches expected runs and at least one descent is trail-matched', () async {
    final apiClient = _FakeTrailMatchApiClient(
      responses: <Map<String, dynamic>>[
        <String, dynamic>{'trail_name': 'Blue Fox', 'difficulty': 'blue'},
        <String, dynamic>{'trail_name': null, 'difficulty': null},
      ],
    );
    final matcher = TrailMatcher(apiClient: apiClient);
    final engine = SegmentDetectionEngine(trailMatcher: matcher);

    const expectedRunCountAtResort = 2;

    final track = ProcessedTrack(
      id: 'track-2',
      sourceType: SourceType.gpx,
      recordedAt: DateTime.utc(2026, 1, 1, 10, 0, 0),
      points: <TrackPoint>[
        _pt(0, 1000, 35),
        _pt(1, 997, 35),
        _pt(2, 994, 35),
        _pt(3, 991, 35),
        _pt(4, 1010, 10),
        _pt(5, 1020, 10),
        _pt(6, 1030, 10),
        _pt(7, 1028, 35),
        _pt(8, 1025, 35),
        _pt(9, 1022, 35),
        _pt(10, 1019, 35),
      ],
    );

    final segments = await engine.detect(track);
    final descentSegments =
        segments.where((s) => s.type == SegmentType.descent).toList();

    expect(descentSegments.length, expectedRunCountAtResort);
    expect(descentSegments.any((s) => s.trailName != null), isTrue);
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

class _FakeTrailMatchApiClient implements TrailMatchApiClient {
  _FakeTrailMatchApiClient({List<Map<String, dynamic>>? responses})
      : _responses =
            responses ?? <Map<String, dynamic>>[<String, dynamic>{'trail_name': 'Blue Fox', 'difficulty': 'blue'}];

  int calls = 0;
  final List<Map<String, dynamic>> _responses;

  @override
  Future<Map<String, dynamic>> post(String path, {Map<String, dynamic>? data}) async {
    calls += 1;
    expect(path, '/trails/match');

    final idx = (calls - 1).clamp(0, _responses.length - 1);

    return <String, dynamic>{
      'segments': <Map<String, dynamic>>[
        _responses[idx],
      ],
    };
  }
}
