import 'package:syntrak/engines/stats/distance_calculator.dart';
import 'package:syntrak/engines/stats/speed_stats_calculator.dart';
import 'package:syntrak/engines/stats/time_calculator.dart';
import 'package:syntrak/engines/stats/vertical_drop_calculator.dart';
import 'package:syntrak/models/run_summary.dart';
import 'package:syntrak/models/segment.dart';

/// Builds per-descent run summaries for display.
List<RunSummary> build(List<Segment> segments) {
  final descentSegments = segments
      .where((segment) => segment.type == SegmentType.descent && segment.points.isNotEmpty)
      .toList(growable: false);

  final summaries = <RunSummary>[];
  for (var i = 0; i < descentSegments.length; i++) {
    final segment = descentSegments[i];
    final distanceKm = totalKm(segment.points);
    final dropM = totalDropM(<Segment>[segment]);
    final duration = movingTime(<Segment>[segment]);
    final avgSpeed = avgSpeedKmh(<Segment>[segment]);
    final peakSpeed = topSpeedKmh(<Segment>[segment]);
    final startElevM = segment.points.first.elevationM;
    final endElevM = segment.points.last.elevationM;

    summaries.add(
      RunSummary(
        runNumber: 'Run ${i + 1}',
        distanceKm: distanceKm,
        verticalDropM: dropM,
        topSpeedKmh: peakSpeed,
        avgSpeedKmh: avgSpeed,
        movingTime: duration,
        startElevM: startElevM,
        endElevM: endElevM,
        trailName: segment.trailName,
        difficulty: segment.difficulty,
      ),
    );
  }

  return summaries;
}