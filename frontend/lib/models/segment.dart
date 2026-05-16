import 'package:flutter/foundation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import 'track_point.dart';

part 'segment.freezed.dart';

/// Classified slice of a track. Output of Engine 2.
/// freezed because immutable data classes and union types for different type of segments 

@immutable
@freezed
class Segment with _$Segment {
  const Segment._();

  const factory Segment({
    required SegmentType type,
    required List<TrackPoint> points,
    required int startIndex, 
    required int endIndex,
    String? trailName,
    String? difficulty,
  }) = _Segment;
}

enum SegmentType {
  descent,
  lift,
  flat,
  pause,
}
