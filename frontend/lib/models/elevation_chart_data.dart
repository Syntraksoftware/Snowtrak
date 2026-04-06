import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/foundation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'elevation_chart_data.freezed.dart';

typedef LiftBandRange = ({double start, double end});

/// Series and metadata for an elevation profile chart (`fl_chart`). Output of Engine 5.
///
/// [spots]: x = distance along route, y = elevation (meters), per `FlSpot` conventions.
@immutable
@freezed
class ElevationChartData with _$ElevationChartData {
  const ElevationChartData._();

  const factory ElevationChartData({
    required List<FlSpot> spots, // x = distance along route, y = elevation (routes are horizontal, elevation is vertical, consider this in 2D plane)
    required List<LiftBandRange> liftBandRanges, 
    required double minElevM, // minimum elevation in meters
    required double maxElevM, // maximum elevation in meters
  }) = _ElevationChartData;
}
