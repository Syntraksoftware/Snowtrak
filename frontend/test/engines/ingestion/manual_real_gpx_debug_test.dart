import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:syntrak/engines/ingestion/gps_ingestion_engine.dart';
import 'package:syntrak/engines/ingestion/parsers/gpx_parser.dart';
import 'package:syntrak/engines/ingestion/processors/elevation_corrector.dart';

void main() {
  test('real GPX ingestion debug run outputs clean ProcessedTrack + map artifact', () async {
    const envPath = String.fromEnvironment('REAL_GPX_PATH');
    final useRealDem =
        const String.fromEnvironment('INGEST_USE_REAL_DEM', defaultValue: 'false').toLowerCase() ==
            'true';
    const demBaseUrl = String.fromEnvironment('MAP_BACKEND_BASE_URL', defaultValue: '');
    const authToken = String.fromEnvironment('MAP_BACKEND_TOKEN', defaultValue: '');

    final gpxPath = envPath.isNotEmpty
        ? envPath
        : 'test/engines/ingestion/parsers/fixtures/sample_track.gpx';

    final file = File(gpxPath);
    expect(file.existsSync(), isTrue, reason: 'GPX path must exist: $gpxPath');

    final apiClient = useRealDem
        ? _RealDemApiClient(
            baseUrl: demBaseUrl,
            bearerToken: authToken.isEmpty ? null : authToken,
          )
        : _MockDemApiClient();

    final engine = GpsIngestionEngine(
      elevationCorrector: ElevationCorrector(apiClient: apiClient),
      idFactory: () => 'debug-track',
    );

    final raw = parseGpxFile(file);
    final processed = await engine.processGpxFile(file);

    expect(processed.points, isNotEmpty);
    expect(
      processed.points.every((p) => p.elevationM.isFinite),
      isTrue,
      reason: 'every TrackPoint must have non-null elevationM',
    );
    expect(
      processed.points.every((p) => p.speedKmh.isFinite && p.speedKmh >= 0),
      isTrue,
      reason: 'every TrackPoint must have speedKmh',
    );
    expect(
      processed.points.length,
      lessThan(1500),
      reason: 'point count should be under 1,500 after processing',
    );

    final outDir = Directory('docs/debug-ingestion');
    if (!outDir.existsSync()) {
      outDir.createSync(recursive: true);
    }

    final jsonOut = File('${outDir.path}/processed_track_debug.json');
    jsonOut.writeAsStringSync(
      const JsonEncoder.withIndent('  ').convert(
        <String, dynamic>{
          'inputPath': gpxPath,
          'rawPointCount': raw.length,
          'processedPointCount': processed.points.length,
          'allElevationPresent': true,
          'allSpeedPresent': true,
          'under1500': processed.points.length < 1500,
          'demMode': useRealDem ? 'real-backend' : 'mock',
          'demBaseUrl': useRealDem ? demBaseUrl : null,
          'track': <String, dynamic>{
            'id': processed.id,
            'sourceType': processed.sourceType.name,
            'recordedAt': processed.recordedAt.toIso8601String(),
            'points': processed.points
                .map(
                  (p) => <String, dynamic>{
                    'lat': p.lat,
                    'lon': p.lon,
                    'elevationM': p.elevationM,
                    'timestamp': p.timestamp.toIso8601String(),
                    'speedKmh': p.speedKmh,
                  },
                )
                .toList(),
          },
        },
      ),
    );

    final htmlOut = File('${outDir.path}/processed_track_debug_map.html');
    htmlOut.writeAsStringSync(_buildDebugMapHtml(raw, processed.points.map((p) => RawPoint(lat: p.lat, lon: p.lon, ele: p.elevationM, time: p.timestamp)).toList()));

    expect(jsonOut.existsSync(), isTrue);
    expect(htmlOut.existsSync(), isTrue);
  });
}

String _buildDebugMapHtml(List<RawPoint> raw, List<RawPoint> processed) {
  final rawJson = jsonEncode(raw.map((p) => <String, double>{'lat': p.lat, 'lon': p.lon}).toList());
  final processedJson = jsonEncode(processed.map((p) => <String, double>{'lat': p.lat, 'lon': p.lon}).toList());

  return '''<!doctype html>
<html>
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <title>GPS Ingestion Debug Map</title>
  <style>
    body { font-family: -apple-system, BlinkMacSystemFont, sans-serif; margin: 0; background: #0f172a; color: #e2e8f0; }
    .wrap { max-width: 1200px; margin: 16px auto; padding: 0 16px; }
    .card { background: #111827; border: 1px solid #334155; border-radius: 12px; padding: 12px; }
    .legend { display: flex; gap: 16px; margin: 8px 0 12px; }
    .dot { width: 12px; height: 12px; border-radius: 999px; display: inline-block; margin-right: 6px; }
    canvas { width: 100%; height: 75vh; background: #020617; border-radius: 10px; border: 1px solid #1f2937; }
  </style>
</head>
<body>
  <div class="wrap">
    <h2>GPS Ingestion Debug Map</h2>
    <div class="card">
      <p>Raw points: <span id="rawCount"></span></p>
      <p>Processed points: <span id="procCount"></span></p>
      <div class="legend">
        <div><span class="dot" style="background:#ef4444"></span>Raw route</div>
        <div><span class="dot" style="background:#22c55e"></span>Processed route</div>
      </div>
      <canvas id="map" width="1400" height="900"></canvas>
    </div>
  </div>

  <script>
    const raw = $rawJson;
    const processed = $processedJson;
    document.getElementById('rawCount').textContent = raw.length;
    document.getElementById('procCount').textContent = processed.length;

    const canvas = document.getElementById('map');
    const ctx = canvas.getContext('2d');

    const all = raw.concat(processed);
    const lats = all.map(p => p.lat);
    const lons = all.map(p => p.lon);
    const minLat = Math.min(...lats), maxLat = Math.max(...lats);
    const minLon = Math.min(...lons), maxLon = Math.max(...lons);

    const pad = 50;
    const w = canvas.width - pad * 2;
    const h = canvas.height - pad * 2;

    function project(p) {
      const xNorm = (p.lon - minLon) / ((maxLon - minLon) || 1);
      const yNorm = (p.lat - minLat) / ((maxLat - minLat) || 1);
      return { x: pad + xNorm * w, y: canvas.height - (pad + yNorm * h) };
    }

    function draw(points, color, width, alpha) {
      if (!points.length) return;
      ctx.save();
      ctx.globalAlpha = alpha;
      ctx.strokeStyle = color;
      ctx.lineWidth = width;
      ctx.beginPath();
      const s = project(points[0]);
      ctx.moveTo(s.x, s.y);
      for (let i = 1; i < points.length; i++) {
        const p = project(points[i]);
        ctx.lineTo(p.x, p.y);
      }
      ctx.stroke();
      ctx.restore();
    }

    draw(raw, '#ef4444', 2, 0.65);
    draw(processed, '#22c55e', 2.5, 0.95);
  </script>
</body>
</html>
''';
}

class _MockDemApiClient implements ApiClient {
  @override
  Future<Map<String, dynamic>> post(String path, {Map<String, dynamic>? data}) async {
    if (path != '/elevation/correct') {
      throw ArgumentError('Unexpected path: $path');
    }

    final points = (data?['points'] as List<dynamic>? ?? <dynamic>[])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();

    final corrected = points.map((p) {
      final lat = (p['lat'] as num).toDouble();
      final lon = (p['lon'] as num).toDouble();
      return <String, dynamic>{
        'lat': lat,
        'lon': lon,
        'elevation_m': 1200.0 + (lat * 0.35) + (lon * 0.18),
        'timestamp': p['timestamp'],
        'speed_kmh': p['speed_kmh'] ?? 0.0,
        'segment_type': p['segment_type'],
      };
    }).toList();

    return <String, dynamic>{'points': corrected};
  }
}

class _RealDemApiClient implements ApiClient {
  _RealDemApiClient({required String baseUrl, String? bearerToken})
      : _dio = Dio(
          BaseOptions(
            baseUrl: baseUrl,
            connectTimeout: const Duration(seconds: 10),
            receiveTimeout: const Duration(seconds: 60),
            headers: <String, dynamic>{
              if (bearerToken != null && bearerToken.isNotEmpty)
                'Authorization': 'Bearer $bearerToken',
            },
          ),
        ) {
    if (baseUrl.trim().isEmpty) {
      throw ArgumentError(
        'MAP_BACKEND_BASE_URL is required when INGEST_USE_REAL_DEM=true',
      );
    }
  }

  final Dio _dio;

  @override
  Future<Map<String, dynamic>> post(String path, {Map<String, dynamic>? data}) async {
    final response = await _dio.post(path, data: data);
    return Map<String, dynamic>.from(response.data as Map);
  }
}
