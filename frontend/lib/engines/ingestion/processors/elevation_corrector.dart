import 'package:dio/dio.dart';

import '../parsers/gpx_parser.dart';

const int _elevationChunkSize = 500;

abstract class ApiClient {
  Future<Map<String, dynamic>> post(String path, {Map<String, dynamic>? data});
}

class DioApiClient implements ApiClient {
  DioApiClient(this._dio);

  final Dio _dio;

  @override
  Future<Map<String, dynamic>> post(String path, {Map<String, dynamic>? data}) async {
    final response = await _dio.post(path, data: data);
    return Map<String, dynamic>.from(response.data as Map);
  }
}

/// Corrects elevations via map-backend `/elevation/correct`.
///
/// - Batches input into chunks of 500 points.
/// - Caches corrected elevation by (lat, lon) rounded to 5dp to avoid redundant calls.
class ElevationCorrector {
  ElevationCorrector({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;
  final Map<String, double> _elevationCache = <String, double>{};

  Future<List<RawPoint>> correctElevations(List<RawPoint> points) async {
    if (points.isEmpty) {
      return <RawPoint>[];
    }

    final corrected = List<RawPoint?>.filled(points.length, null);
    final uncachedIndices = <int>[];

    for (var i = 0; i < points.length; i++) {
      final point = points[i];
      final key = _cacheKey(point.lat, point.lon);
      final cachedElevation = _elevationCache[key];
      if (cachedElevation != null) {
        corrected[i] = RawPoint(
          lat: point.lat,
          lon: point.lon,
          ele: cachedElevation,
          time: point.time,
        );
      } else {
        uncachedIndices.add(i);
      }
    }

    for (var start = 0; start < uncachedIndices.length; start += _elevationChunkSize) {
      final end = (start + _elevationChunkSize > uncachedIndices.length)
          ? uncachedIndices.length
          : start + _elevationChunkSize;
      final chunkIndices = uncachedIndices.sublist(start, end);
      final chunkPoints = chunkIndices.map((idx) => points[idx]).toList();

      final payload = <String, dynamic>{
        'points': chunkPoints.map(_toElevationRequestPoint).toList(),
      };

      final response = await _apiClient.post('/elevation/correct', data: payload);
      final responsePoints = (response['points'] as List<dynamic>?) ?? <dynamic>[];

      if (responsePoints.length != chunkPoints.length) {
        throw StateError(
          'Elevation API returned ${responsePoints.length} points for ${chunkPoints.length} request points',
        );
      }

      for (var i = 0; i < responsePoints.length; i++) {
        final requestPoint = chunkPoints[i];
        final originalIndex = chunkIndices[i];
        final responsePoint = Map<String, dynamic>.from(responsePoints[i] as Map);
        final elevation = (responsePoint['elevation_m'] as num).toDouble();

        final key = _cacheKey(requestPoint.lat, requestPoint.lon);
        _elevationCache[key] = elevation;

        corrected[originalIndex] = RawPoint(
          lat: requestPoint.lat,
          lon: requestPoint.lon,
          ele: elevation,
          time: requestPoint.time,
        );
      }
    }

    return corrected.map((p) => p!).toList();
  }

  String _cacheKey(double lat, double lon) {
    final latRounded = lat.toStringAsFixed(5);
    final lonRounded = lon.toStringAsFixed(5);
    return '$latRounded,$lonRounded';
  }

  Map<String, dynamic> _toElevationRequestPoint(RawPoint p) {
    final timestamp = (p.time ?? DateTime.fromMillisecondsSinceEpoch(0, isUtc: true)).toUtc();
    return <String, dynamic>{
      'lat': p.lat,
      'lon': p.lon,
      'elevation_m': p.ele,
      'timestamp': timestamp.toIso8601String(),
      'speed_kmh': 0.0,
      'segment_type': null,
    };
  }
}
