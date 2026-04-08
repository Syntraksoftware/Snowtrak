import 'package:flutter_test/flutter_test.dart';
import 'package:syntrak/engines/ingestion/parsers/gpx_parser.dart';
import 'package:syntrak/engines/ingestion/processors/elevation_corrector.dart';
import 'package:syntrak/engines/ingestion/processors/kalman_filter.dart' as kalman;
import 'package:syntrak/engines/ingestion/processors/outlier_remover.dart' as outliers;
import 'package:syntrak/engines/ingestion/processors/rdp_downsampler.dart' as rdp;

void main() {
  test('ingestion pipeline: parser -> outlier -> kalman -> rdp -> elevation', () async {
    final gpxXml = _buildSyntheticGpx();

    final parsed = parseGpxString(gpxXml);
    expect(parsed.length, 122);

    final cleaned = outliers.remove(parsed);
    expect(cleaned.length, lessThan(parsed.length));

    final smoothed = kalman.apply(cleaned);
    expect(smoothed.length, cleaned.length);

    final simplified = rdp.simplify(smoothed, rdp.defaultEpsilon);
    expect(simplified.length, lessThan(smoothed.length));
    expect(simplified.first.time, smoothed.first.time);
    expect(simplified.last.time, smoothed.last.time);

    final fakeApi = _PipelineFakeApiClient();
    final elevationCorrector = ElevationCorrector(apiClient: fakeApi);
    final elevated = await elevationCorrector.correctElevations(simplified);

    expect(elevated.length, simplified.length);
    expect(fakeApi.callCount, greaterThan(0));
    expect(fakeApi.callCount, lessThanOrEqualTo((simplified.length / 500).ceil()));
    expect(elevated.every((p) => p.ele != null), isTrue);

    for (var i = 0; i < elevated.length; i++) {
      expect(elevated[i].lat, closeTo(simplified[i].lat, 1e-12));
      expect(elevated[i].lon, closeTo(simplified[i].lon, 1e-12));
      expect(elevated[i].time, simplified[i].time);
    }
  });
}

class _PipelineFakeApiClient implements ApiClient {
  int callCount = 0;

  @override
  Future<Map<String, dynamic>> post(String path, {Map<String, dynamic>? data}) async {
    if (path != '/elevation/correct') {
      throw ArgumentError('Unexpected path: $path');
    }

    callCount += 1;

    final points = (data?['points'] as List<dynamic>? ?? <dynamic>[])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();

    final corrected = points.map((p) {
      final lat = (p['lat'] as num).toDouble();
      final lon = (p['lon'] as num).toDouble();
      return <String, dynamic>{
        'lat': lat,
        'lon': lon,
        'elevation_m': 1000.0 + (lat * 0.5) + (lon * 0.25),
        'timestamp': p['timestamp'],
        'speed_kmh': p['speed_kmh'] ?? 0.0,
        'segment_type': p['segment_type'],
      };
    }).toList();

    return <String, dynamic>{'points': corrected};
  }
}

String _buildSyntheticGpx() {
  final sb = StringBuffer();
  sb.writeln('<?xml version="1.0" encoding="UTF-8"?>');
  sb.writeln('<gpx version="1.1" creator="pipeline-test" xmlns="http://www.topografix.com/GPX/1/1">');
  sb.writeln('  <trk>');
  sb.writeln('    <name>Pipeline synthetic track</name>');
  sb.writeln('    <trkseg>');

  final start = DateTime.utc(2026, 1, 1, 10, 0, 0);

  for (var i = 0; i < 120; i++) {
    final t = i / 119.0;
    var lat = 46.800000 + 0.020 * t;
    var lon = 8.200000 + 0.025 * t;
    var ele = 2400.0 - (600.0 * t);

    // Mild GPS jitter.
    lat += (i.isEven ? 1 : -1) * 0.00002;
    lon += (i % 3 == 0 ? 1 : -1) * 0.000015;

    // Physically impossible position jump (speed outlier).
    if (i == 40) {
      lat += 0.05;
      lon += 0.05;
    }

    // Elevation spike outlier within 1 second.
    if (i == 70) {
      ele += 250.0;
    }

    final ts = start.add(Duration(seconds: i)).toIso8601String();
    sb.writeln('      <trkpt lat="$lat" lon="$lon">');
    sb.writeln('        <ele>$ele</ele>');
    sb.writeln('        <time>$ts</time>');
    sb.writeln('      </trkpt>');
  }

  // Extra points that share same rounded cache key with neighbors.
  sb.writeln('      <trkpt lat="46.8200012" lon="8.2250012"><ele>1800.0</ele><time>${start.add(const Duration(seconds: 121)).toIso8601String()}</time></trkpt>');
  sb.writeln('      <trkpt lat="46.8200014" lon="8.2250014"><ele>1799.5</ele><time>${start.add(const Duration(seconds: 122)).toIso8601String()}</time></trkpt>');

  sb.writeln('    </trkseg>');
  sb.writeln('  </trk>');
  sb.writeln('</gpx>');

  return sb.toString();
}
