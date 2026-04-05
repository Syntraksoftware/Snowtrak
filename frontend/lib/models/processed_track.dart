import 'package:flutter/foundation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import 'track_point.dart';

part 'processed_track.freezed.dart';

/// Output of Engine 1; input to Engines 2, 4, and 5.
@immutable
@freezed
class ProcessedTrack with _$ProcessedTrack {
  const ProcessedTrack._();

  const factory ProcessedTrack({
    required String id, //UUID/ server generated id for the track
    required List<TrackPoint> points,
    required DateTime recordedAt,
    required SourceType sourceType,
  }) = _ProcessedTrack;
}

/// How the raw track was produced before Engine 1 normalization.
enum SourceType {
  gpx,
  fit,
  live,
}
