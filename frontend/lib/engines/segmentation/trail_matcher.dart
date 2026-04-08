import 'package:syntrak/models/segment.dart';
import 'package:syntrak/models/track_point.dart';

abstract class TrailMatchApiClient {
  Future<Map<String, dynamic>> post(String path, {Map<String, dynamic>? data});
}

/// Calls map-backend `/trails/match` for each descent segment and enriches
/// matched `trailName` and `difficulty` when returned.
class TrailMatcher {
  TrailMatcher({required TrailMatchApiClient apiClient}) : _apiClient = apiClient;

  final TrailMatchApiClient _apiClient;

  Future<List<Segment>> matchDescents(List<Segment> segments) async {
    final enriched = <Segment>[];

    for (final segment in segments) {
      if (segment.type != SegmentType.descent || segment.points.isEmpty) {
        enriched.add(segment);
        continue;
      }

      final midpoint = segment.points[segment.points.length ~/ 2];
      final payload = <String, dynamic>{
        'points': <Map<String, dynamic>>[_toRequestPoint(midpoint)],
      };

      final response = await _apiClient.post('/trails/match', data: payload);
      final responseSegments = (response['segments'] as List<dynamic>?) ?? <dynamic>[];

      if (responseSegments.isEmpty) {
        enriched.add(segment);
        continue;
      }

      final first = Map<String, dynamic>.from(responseSegments.first as Map);
      enriched.add(
        segment.copyWith(
          trailName: first['trail_name'] as String?,
          difficulty: first['difficulty'] as String?,
        ),
      );
    }

    return enriched;
  }

  Map<String, dynamic> _toRequestPoint(TrackPoint p) {
    return <String, dynamic>{
      'lat': p.lat,
      'lon': p.lon,
      'elevation_m': p.elevationM,
      'timestamp': p.timestamp.toUtc().toIso8601String(),
      'speed_kmh': p.speedKmh,
      'segment_type': p.segmentType?.name,
    };
  }
}
