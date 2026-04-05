import 'package:flutter/foundation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'track_point.freezed.dart';

/// Atomic GPS sample used across recording, map, and analytics pipelines.
@immutable
@freezed
class TrackPoint with _$TrackPoint {
  const TrackPoint._();

  const factory TrackPoint({
    required double lat,
    required double lon,
    required double elevationM,
    required DateTime timestamp,
    required double speedKmh,
    int? heartRate,
    SegmentType? segmentType, // Optional classification for a point along a ski activity (lift vs descent, etc.).
  }) = _TrackPoint;
}

/// Optional classification for a point along a ski activity (lift vs descent, etc.).
enum SegmentType {
  //todo: add more segment types 
  
  lift,
  run,
  transition,
}
