import 'package:syntrak/engines/ingestion/parsers/gpx_parser.dart';
import 'package:syntrak/features/track_pipeline/domain/processed_pipeline_result.dart';
import 'package:syntrak/models/activity_stats.dart';
import 'package:syntrak/models/location.dart';
import 'package:syntrak/models/processed_track.dart';
import 'package:syntrak/models/run_summary.dart';
import 'package:syntrak/models/segment.dart';
import 'package:syntrak/models/track_point.dart';
import 'dart:math';

/// JSON codec aligned with `backend/shared/track_pipeline_schemas.py` (snake_case).
class PipelineJsonMapper {
  const PipelineJsonMapper();

  static final _random = Random();

  Map<String, dynamic> buildNivusRequest({
    required List<RawPoint> rawPoints,
    required DateTime recordedAt,
    required SourceType sourceType,
    String? trackId,
    bool matchTrails = true,
  }) {
    return {
      'id': trackId ?? _newTrackId(),
      'recorded_at': recordedAt.toUtc().toIso8601String(),
      'source_type': sourceType.name,
      'match_trails': matchTrails,
      'points': rawPoints.map(_rawPointToApi).toList(growable: false),
    };
  }

  Map<String, dynamic> buildMapPersistRequest({
    required String userId,
    required ProcessedPipelineResult pipeline,
  }) {
    final track = pipeline.processedTrack;
    return {
      'user_id': userId,
      'processed_track': {
        'id': track.id,
        'recorded_at': track.recordedAt.toUtc().toIso8601String(),
        'source_type': track.sourceType.name,
        'points': track.points.map(_trackPointToApi).toList(growable: false),
      },
      'segments': pipeline.segments.map(_segmentToApi).toList(growable: false),
      if (pipeline.stats != null) 'stats': _statsToApi(pipeline.stats!),
    };
  }

  List<Map<String, dynamic>> rawPointsToElevationRequest(
      List<RawPoint> points) {
    return points
        .map(
          (p) => {
            'lat': p.lat,
            'lon': p.lon,
            if (p.ele != null) 'elevation_m': p.ele,
            if (p.time != null) 'timestamp': p.time!.toUtc().toIso8601String(),
            'speed_kmh': 0.0,
          },
        )
        .toList(growable: false);
  }

  List<RawPoint> elevationResponseToRawPoints(
    List<RawPoint> original,
    Map<String, dynamic> response,
  ) {
    final corrected = (response['points'] as List<dynamic>? ?? const [])
        .cast<Map<String, dynamic>>();
    final out = <RawPoint>[];
    for (var i = 0; i < original.length; i++) {
      final source = original[i];
      final row = i < corrected.length ? corrected[i] : null;
      final elevation = row?['elevation_m'];
      out.add(
        RawPoint(
          lat: source.lat,
          lon: source.lon,
          ele: elevation is num ? elevation.toDouble() : source.ele,
          time: source.time,
        ),
      );
    }
    return out;
  }

  ProcessedPipelineResult parseNivusResponse(Map<String, dynamic> json) {
    final trackJson = Map<String, dynamic>.from(json['processed_track'] as Map);
    final processedTrack = _parseProcessedTrack(trackJson);
    final segments = (json['segments'] as List<dynamic>? ?? const [])
        .map((e) => _parseSegment(Map<String, dynamic>.from(e as Map)))
        .toList(growable: false);

    ActivityStats? stats;
    final statsJson = json['stats'];
    if (statsJson is Map<String, dynamic>) {
      stats = _parseActivityStats(statsJson);
    }

    final runSummaries = (json['run_summaries'] as List<dynamic>? ?? const [])
        .map((e) => _parseRunSummary(Map<String, dynamic>.from(e as Map)))
        .toList(growable: false);

    return ProcessedPipelineResult(
      processedTrack: processedTrack,
      segments: segments,
      stats: stats,
      runSummaries: runSummaries,
    );
  }

  List<RawPoint> locationsToRawPoints(List<Location> locations) {
    return locations
        .map(
          (l) => RawPoint(
            lat: l.latitude,
            lon: l.longitude,
            ele: l.altitude,
            time: l.timestamp,
          ),
        )
        .toList(growable: false);
  }

  Map<String, dynamic> _rawPointToApi(RawPoint point) {
    return {
      'lat': point.lat,
      'lon': point.lon,
      if (point.ele != null) 'elevation_m': point.ele,
      'timestamp':
          (point.time ?? DateTime.now().toUtc()).toUtc().toIso8601String(),
      'speed_kmh': 0.0,
    };
  }

  Map<String, dynamic> _trackPointToApi(TrackPoint point) {
    return {
      'lat': point.lat,
      'lon': point.lon,
      'elevation_m': point.elevationM,
      'timestamp': point.timestamp.toUtc().toIso8601String(),
      'speed_kmh': point.speedKmh,
      if (point.segmentType != null) 'segment_type': point.segmentType!.name,
    };
  }

  Map<String, dynamic> _segmentToApi(Segment segment) {
    return {
      'type': segment.type.name,
      'points': segment.points.map(_trackPointToApi).toList(growable: false),
      'start_index': segment.startIndex,
      'end_index': segment.endIndex,
      if (segment.trailName != null) 'trail_name': segment.trailName,
      if (segment.difficulty != null) 'difficulty': segment.difficulty,
    };
  }

  Map<String, dynamic> _statsToApi(ActivityStats stats) {
    return {
      'total_distance_km': stats.totalDistanceKm,
      'total_vertical_drop_m': stats.totalVerticalDropM,
      'top_speed_kmh': stats.topSpeedKmh,
      'avg_speed_kmh': stats.avgSpeedKmh,
      'moving_time_s': stats.movingTime.inMilliseconds / 1000.0,
      'trail_count': stats.trailCount,
    };
  }

  ProcessedTrack _parseProcessedTrack(Map<String, dynamic> json) {
    final points = (json['points'] as List<dynamic>? ?? const [])
        .map((e) => _parseTrackPoint(Map<String, dynamic>.from(e as Map)))
        .toList(growable: false);

    return ProcessedTrack(
      id: json['id'] as String,
      points: points,
      recordedAt: DateTime.parse(json['recorded_at'] as String),
      sourceType: SourceType.values.byName(json['source_type'] as String),
    );
  }

  TrackPoint _parseTrackPoint(Map<String, dynamic> json) {
    PointSegmentType? segmentType;
    final rawSegmentType = json['segment_type'];
    if (rawSegmentType is String && rawSegmentType.isNotEmpty) {
      segmentType = PointSegmentType.values.byName(rawSegmentType);
    }

    return TrackPoint(
      lat: (json['lat'] as num).toDouble(),
      lon: (json['lon'] as num).toDouble(),
      elevationM: (json['elevation_m'] as num).toDouble(),
      timestamp: DateTime.parse(json['timestamp'] as String),
      speedKmh: (json['speed_kmh'] as num).toDouble(),
      segmentType: segmentType,
    );
  }

  Segment _parseSegment(Map<String, dynamic> json) {
    final points = (json['points'] as List<dynamic>? ?? const [])
        .map((e) => _parseTrackPoint(Map<String, dynamic>.from(e as Map)))
        .toList(growable: false);

    return Segment(
      type: SegmentType.values.byName(json['type'] as String),
      points: points,
      startIndex: json['start_index'] as int,
      endIndex: json['end_index'] as int,
      trailName: json['trail_name'] as String?,
      difficulty: json['difficulty'] as String?,
    );
  }

  ActivityStats _parseActivityStats(Map<String, dynamic> json) {
    final movingSeconds = (json['moving_time_s'] as num).toDouble();
    return ActivityStats(
      totalDistanceKm: (json['total_distance_km'] as num).toDouble(),
      totalVerticalDropM: (json['total_vertical_drop_m'] as num).toDouble(),
      topSpeedKmh: (json['top_speed_kmh'] as num).toDouble(),
      avgSpeedKmh: (json['avg_speed_kmh'] as num).toDouble(),
      movingTime: Duration(milliseconds: (movingSeconds * 1000).round()),
      trailCount: json['trail_count'] as int,
    );
  }

  static String _newTrackId() {
    return '${DateTime.now().toUtc().microsecondsSinceEpoch}-${_random.nextInt(0x7fffffff)}';
  }

  RunSummary _parseRunSummary(Map<String, dynamic> json) {
    final movingSeconds = (json['moving_time_s'] as num).toDouble();
    return RunSummary(
      runNumber: '1',
      distanceKm: (json['distance_km'] as num).toDouble(),
      verticalDropM: (json['vertical_drop_m'] as num).toDouble(),
      topSpeedKmh: (json['top_speed_kmh'] as num).toDouble(),
      avgSpeedKmh: (json['avg_speed_kmh'] as num).toDouble(),
      movingTime: Duration(milliseconds: (movingSeconds * 1000).round()),
      startElevM: 0,
      endElevM: 0,
      trailName: json['trail_name'] as String?,
      difficulty: json['difficulty'] as String?,
    );
  }
}
