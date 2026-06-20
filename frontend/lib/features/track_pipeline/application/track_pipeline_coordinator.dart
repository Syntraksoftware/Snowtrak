import 'package:syntrak/engines/ingestion/parsers/gpx_parser.dart';
import 'package:syntrak/features/track_pipeline/data/repositories/map_elevation_repository.dart';
import 'package:syntrak/features/track_pipeline/data/repositories/map_track_persistence_repository.dart';
import 'package:syntrak/features/track_pipeline/data/repositories/nivus_pipeline_repository.dart';
import 'package:syntrak/features/track_pipeline/domain/processed_pipeline_result.dart';
import 'package:syntrak/models/location.dart';
import 'package:syntrak/models/processed_track.dart';
import 'package:syntrak/features/track_pipeline/data/mappers/pipeline_json_mapper.dart';

/// Application-layer orchestrator for the sync pipeline bridge.
///
/// Coordinates three independent microservices without coupling them:
/// 1. map-backend — DEM elevation
/// 2. Nivus — track math + trail matching
/// 3. map-backend — `map_trail` persistence
///
/// Replaced later by an event queue; the mobile client will only upload files.
class TrackPipelineCoordinator {
  TrackPipelineCoordinator({
    required MapElevationRepository elevationRepository,
    required NivusPipelineRepository nivusRepository,
    required MapTrackPersistenceRepository mapPersistenceRepository,
    PipelineJsonMapper? mapper,
  })  : _elevationRepository = elevationRepository,
        _nivusRepository = nivusRepository,
        _mapPersistenceRepository = mapPersistenceRepository,
        _mapper = mapper ?? const PipelineJsonMapper();

  final MapElevationRepository _elevationRepository;
  final NivusPipelineRepository _nivusRepository;
  final MapTrackPersistenceRepository _mapPersistenceRepository;
  final PipelineJsonMapper _mapper;

  Future<ProcessedPipelineResult> processLiveLocations({
    required String userId,
    required List<Location> locations,
    bool matchTrails = true,
    bool persistToMapTrail = true,
  }) async {
    if (locations.isEmpty) {
      throw ArgumentError.value(locations, 'locations', 'must not be empty');
    }

    final rawPoints = _mapper.locationsToRawPoints(locations);
    return processRawPoints(
      userId: userId,
      rawPoints: rawPoints,
      recordedAt: locations.first.timestamp,
      sourceType: SourceType.live,
      matchTrails: matchTrails,
      persistToMapTrail: persistToMapTrail,
    );
  }

  Future<ProcessedPipelineResult> processRawPoints({
    required String userId,
    required List<RawPoint> rawPoints,
    required DateTime recordedAt,
    required SourceType sourceType,
    bool matchTrails = true,
    bool persistToMapTrail = true,
  }) async {
    final elevated = await _elevationRepository.correctElevations(rawPoints);

    var pipeline = await _nivusRepository.processRawTrack(
      rawPoints: elevated,
      recordedAt: recordedAt,
      sourceType: sourceType,
      matchTrails: matchTrails,
    );

    if (!persistToMapTrail) {
      return pipeline;
    }

    final mapActivityId = await _mapPersistenceRepository.persistPipeline(
      userId: userId,
      pipeline: pipeline,
    );

    return ProcessedPipelineResult(
      processedTrack: pipeline.processedTrack,
      segments: pipeline.segments,
      stats: pipeline.stats,
      runSummaries: pipeline.runSummaries,
      mapActivityId: mapActivityId,
    );
  }
}
