import 'package:flutter/foundation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'track_point.freezed.dart';

/// Atomic GPS sample used across recording, map, and analytics pipelines.
@immutable
@freezed ///create immutable data classes and union types for different types of track points
class TrackPoint with _$TrackPoint {
  const TrackPoint._(); 

  const factory TrackPoint({
    required double lat,
    required double lon,
    required double elevationM,
    required DateTime timestamp,
    required double speedKmh,
    PointSegmentType? segmentType,
  }) = _TrackPoint;
}

/// Per-point hint before Engine 2 produces [Segment]s ([SegmentType]).
enum PointSegmentType {
  lift,
  run,
  transition,
}

