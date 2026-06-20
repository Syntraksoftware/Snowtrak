import 'package:syntrak/models/activity_stats.dart';
import 'package:syntrak/models/processed_track.dart';
import 'package:syntrak/models/run_summary.dart';
import 'package:syntrak/models/segment.dart';

/// Domain result of a full server-side track pipeline run.
///
/// Produced by [TrackPipelineCoordinator] after Nivus compute + optional
/// map-backend persistence. Keeps pipeline types out of API clients.
class ProcessedPipelineResult {
  const ProcessedPipelineResult({
    required this.processedTrack,
    required this.segments,
    this.stats,
    this.runSummaries = const [],
    this.mapActivityId,
  });

  final ProcessedTrack processedTrack;
  final List<Segment> segments;
  final ActivityStats? stats;
  final List<RunSummary> runSummaries;

  /// Set when the coordinator persisted to `map_trail.activities`.
  final String? mapActivityId;
}
