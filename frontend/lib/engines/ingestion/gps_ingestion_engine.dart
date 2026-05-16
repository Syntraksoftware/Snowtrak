import 'dart:io';

import 'package:syntrak/engines/ingestion/parsers/fit_parser.dart';
import 'package:syntrak/engines/ingestion/parsers/gpx_parser.dart';
import 'package:syntrak/engines/ingestion/processors/elevation_corrector.dart';
import 'package:syntrak/engines/ingestion/processors/kalman_filter.dart' as kalman;
import 'package:syntrak/engines/ingestion/processors/outlier_remover.dart' as outliers;
import 'package:syntrak/engines/ingestion/processors/rdp_downsampler.dart' as rdp;
import 'package:syntrak/engines/ingestion/processors/speed_calculator.dart' as speed;
import 'package:syntrak/models/processed_track.dart';

typedef TrackIdFactory = String Function();

const double _sparseTimeRdpEpsilon = 0.00003;
const double _timeCoverageThreshold = 0.8;

/// Facade for the full GPS ingestion pipeline.
///
/// Public methods in this class are the intended entry points for callers.
class GpsIngestionEngine {
  GpsIngestionEngine({required ElevationCorrector elevationCorrector, TrackIdFactory? idFactory})
      : _elevationCorrector = elevationCorrector,
        _idFactory = idFactory ?? _defaultTrackIdFactory;

  final ElevationCorrector _elevationCorrector;
  final TrackIdFactory _idFactory;

  Future<ProcessedTrack> processGpxFile(File file) async {
    final raw = parseGpxFile(file);
    return _processRaw(raw, SourceType.gpx);
  }

  Future<ProcessedTrack> processFitFile(File file) async {
    final raw = parseFitFile(file);
    return _processRaw(raw, SourceType.fit);
  }

  Future<ProcessedTrack> processLiveSession(List<RawPoint> points) async {
    return _processRaw(points, SourceType.live);
  }

  Future<ProcessedTrack> _processRaw(List<RawPoint> input, SourceType sourceType) async {
    if (input.isEmpty) {
      return ProcessedTrack(
        id: _idFactory(),
        points: const [],
        recordedAt: DateTime.now().toUtc(),
        sourceType: sourceType,
      );
    }

    final noOutliers = outliers.remove(input);
    final hasStrongTime = _hasStrongTimeCoverage(noOutliers);
    final smoothed = hasStrongTime ? kalman.apply(noOutliers) : noOutliers;
    final epsilon = hasStrongTime ? rdp.defaultEpsilon : _sparseTimeRdpEpsilon;
    final simplified = rdp.simplify(smoothed, epsilon);
    final elevationCorrected = await _elevationCorrector.correctElevations(simplified);
    final trackPoints = speed.compute(elevationCorrected);

    final recordedAt = trackPoints.first.timestamp;

    return ProcessedTrack(
      id: _idFactory(),
      points: trackPoints,
      recordedAt: recordedAt,
      sourceType: sourceType,
    );
  }
}

String _defaultTrackIdFactory() => DateTime.now().toUtc().microsecondsSinceEpoch.toString();

bool _hasStrongTimeCoverage(List<RawPoint> points) {
  if (points.isEmpty) {
    return true;
  }
  final withTime = points.where((p) => p.time != null).length;
  final coverage = withTime / points.length;
  return coverage >= _timeCoverageThreshold;
}
