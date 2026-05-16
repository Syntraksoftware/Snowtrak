import 'package:syntrak/engines/stats/distance_calculator.dart';
import 'package:syntrak/engines/stats/run_summary_builder.dart' as run_summary_builder;
import 'package:syntrak/engines/stats/speed_stats_calculator.dart';
import 'package:syntrak/engines/stats/time_calculator.dart';
import 'package:syntrak/engines/stats/vertical_drop_calculator.dart';
import 'package:syntrak/models/activity_stats.dart';
import 'package:syntrak/models/run_summary.dart';
import 'package:syntrak/models/segment.dart';

/// Engine 3 facade for activity-level and per-run statistics.
class StatsEngine {
  const StatsEngine();

  ActivityStats compute(List<Segment> segments) {
    final trailNames = <String>{};
    for (final segment in segments) {
      final trailName = segment.trailName?.trim();
      if (trailName != null && trailName.isNotEmpty) {
        trailNames.add(trailName);
      }
    }

    return ActivityStats(
      totalDistanceKm: _totalDistanceKm(segments),
      totalVerticalDropM: totalDropM(segments),
      topSpeedKmh: topSpeedKmh(segments),
      avgSpeedKmh: avgSpeedKmh(segments),
      movingTime: movingTime(segments),
      trailCount: trailNames.length,
    );
  }

  List<RunSummary> buildRunSummaries(List<Segment> segments) {
    return run_summary_builder.build(segments);
  }
}

double _totalDistanceKm(List<Segment> segments) {
  var total = 0.0;
  for (final segment in segments) {
    if (segment.type == SegmentType.pause || segment.points.length < 2) {
      continue;
    }
    total += totalKm(segment.points);
  }
  return total;
}