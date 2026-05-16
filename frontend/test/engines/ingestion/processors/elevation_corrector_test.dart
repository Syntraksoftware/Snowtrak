import 'package:flutter_test/flutter_test.dart';
import 'package:syntrak/engines/ingestion/parsers/gpx_parser.dart';
import 'package:syntrak/engines/ingestion/processors/elevation_corrector.dart';

void main() {
  test('correctElevations batches requests into chunks of 500', () async {
    final api = _FakeApiClient();
    final corrector = ElevationCorrector(apiClient: api);

    final points = List<RawPoint>.generate(
      1201,
      (i) => RawPoint(
        lat: 46.0 + (i * 0.00001),
        lon: 8.0 + (i * 0.00001),
        time: DateTime.utc(2026, 1, 1).add(Duration(seconds: i)),
      ),
    );

    final corrected = await corrector.correctElevations(points);

    expect(corrected.length, points.length);
    expect(api.callCount, 3);
    expect(api.chunkSizes, <int>[500, 500, 201]);
    expect(corrected.first.ele, isNotNull);
    expect(corrected.last.ele, isNotNull);
  });

  test('correctElevations uses 5dp lat/lon cache to avoid redundant calls', () async {
    final api = _FakeApiClient();
    final corrector = ElevationCorrector(apiClient: api);

    final firstBatch = <RawPoint>[
      const RawPoint(lat: 46.123451, lon: 8.543211, time: null),
      const RawPoint(lat: 46.123449, lon: 8.543209, time: null),
    ];

    final secondBatch = <RawPoint>[
      const RawPoint(lat: 46.1234502, lon: 8.5432104, time: null),
    ];

    final corrected1 = await corrector.correctElevations(firstBatch);
    final corrected2 = await corrector.correctElevations(secondBatch);

    expect(corrected1.length, 2);
    expect(corrected2.length, 1);

    // All above points round to the same 5dp key, so only the first call should hit API.
    expect(api.callCount, 1);
    // Cache key collision within firstBatch means last write wins for that rounded key.
    expect(corrected2.first.ele, equals(corrected1.last.ele));
  });
}

class _FakeApiClient implements ApiClient {
  int callCount = 0;
  final List<int> chunkSizes = <int>[];

  @override
  Future<Map<String, dynamic>> post(String path, {Map<String, dynamic>? data}) async {
    callCount += 1;
    if (path != '/elevation/correct') {
      throw ArgumentError('Unexpected path: $path');
    }

    final points = (data?['points'] as List<dynamic>? ?? <dynamic>[])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
    chunkSizes.add(points.length);

    final responsePoints = points
        .map((p) {
          final lat = (p['lat'] as num).toDouble();
          final lon = (p['lon'] as num).toDouble();
          return <String, dynamic>{
            'lat': lat,
            'lon': lon,
            'elevation_m': (lat + lon) * 100.0,
            'timestamp': p['timestamp'],
            'speed_kmh': p['speed_kmh'] ?? 0.0,
            'segment_type': p['segment_type'],
          };
        })
        .toList();

    return <String, dynamic>{'points': responsePoints};
  }
}
