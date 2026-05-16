import 'package:flutter/foundation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'activity_stats.freezed.dart';

/// Activity-level aggregates. Output of Engine 3.
@immutable
@freezed
class ActivityStats with _$ActivityStats {
  const ActivityStats._();

  const factory ActivityStats({
    required double totalDistanceKm,
    required double totalVerticalDropM,
    required double topSpeedKmh,
    required double avgSpeedKmh,
    required Duration movingTime,
    /// Distinct named trails touched during the activity (Engine 3).
    required int trailCount,
  }) = _ActivityStats;
}
