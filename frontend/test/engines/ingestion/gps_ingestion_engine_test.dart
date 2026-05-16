import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:syntrak/engines/ingestion/gps_ingestion_engine.dart';
import 'package:syntrak/engines/ingestion/parsers/gpx_parser.dart';
import 'package:syntrak/engines/ingestion/processors/elevation_corrector.dart';
import 'package:syntrak/models/processed_track.dart';

void main() {
  test('processGpxFile runs full pipeline and returns ProcessedTrack', () async {
    final apiClient = _FakeApiClient();
    final engine = GpsIngestionEngine(
      elevationCorrector: ElevationCorrector(apiClient: apiClient),
      idFactory: () => 'test-track-id',
    );

    final file = File('test/engines/ingestion/parsers/fixtures/sample_track.gpx');
    final result = await engine.processGpxFile(file);

    expect(result.id, 'test-track-id');
    expect(result.sourceType, SourceType.gpx);
    expect(result.points, isNotEmpty);
    expect(result.points.every((p) => p.elevationM >= 1000.0), isTrue);
    expect(apiClient.callCount, greaterThan(0));
  });

  test('processLiveSession uses live source type', () async {
    final apiClient = _FakeApiClient();
    final engine = GpsIngestionEngine(
      elevationCorrector: ElevationCorrector(apiClient: apiClient),
      idFactory: () => 'live-id',
    );

    final start = DateTime.utc(2026, 1, 1, 10, 0, 0);
    final livePoints = <RawPoint>[
      RawPoint(lat: 46.8, lon: 8.2, ele: 2200, time: start),
      RawPoint(lat: 46.8001, lon: 8.2001, ele: 2198, time: start.add(const Duration(seconds: 1))),
      RawPoint(lat: 46.8002, lon: 8.2002, ele: 2195, time: start.add(const Duration(seconds: 2))),
    ];

    final result = await engine.processLiveSession(livePoints);

    expect(result.id, 'live-id');
    expect(result.sourceType, SourceType.live);
    expect(result.points.length, greaterThanOrEqualTo(2));
  });

  test('processLiveSession preserves shape on tracks with missing timestamps', () async {
    final apiClient = _FakeApiClient();
    final engine = GpsIngestionEngine(
      elevationCorrector: ElevationCorrector(apiClient: apiClient),
      idFactory: () => 'no-time-id',
    );

    final points = List<RawPoint>.generate(
      120,
      (i) => RawPoint(
        lat: 59.0 + i * 0.0002,
        lon: 11.0 + (i % 17) * 0.00015,
        ele: 150 + (i % 9) * 0.8,
        time: null,
      ),
    );

    final result = await engine.processLiveSession(points);

    expect(result.sourceType, SourceType.live);
    expect(result.points.length, greaterThan(2));
    expect(result.points.length, lessThan(120));
  });
}

class _FakeApiClient implements ApiClient {
  int callCount = 0;

  @override
  Future<Map<String, dynamic>> post(String path, {Map<String, dynamic>? data}) async {
    callCount += 1;
    final points = (data?['points'] as List<dynamic>? ?? <dynamic>[])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();

    return <String, dynamic>{
      'points': points
          .map(
            (p) => <String, dynamic>{
              'lat': p['lat'],
              'lon': p['lon'],
              'elevation_m': 1500.0,
              'timestamp': p['timestamp'],
              'speed_kmh': 0.0,
              'segment_type': p['segment_type'],
            },
          )
          .toList(),
    };
  }
}
