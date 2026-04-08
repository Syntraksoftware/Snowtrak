import 'package:flutter/foundation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'run_summary.freezed.dart';

/// Per-descent aggregates. Output of Engine 3.
/// by pre-descent: downhill slope data 


@immutable
@freezed
class RunSummary with _$RunSummary {
  const RunSummary._();

  const factory RunSummary({
    required String runNumber,
    required double distanceKm,
    required double verticalDropM,
    required double topSpeedKmh,
    required double avgSpeedKmh,
    required Duration movingTime,
    required double startElevM,
    required double endElevM,
    String? trailName,
    String? difficulty,
  }) = _RunSummary;
}
