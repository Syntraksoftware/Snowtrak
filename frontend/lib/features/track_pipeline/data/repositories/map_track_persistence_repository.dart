import 'package:syntrak/features/track_pipeline/data/mappers/pipeline_json_mapper.dart';
import 'package:syntrak/features/track_pipeline/domain/processed_pipeline_result.dart';
import 'package:syntrak/services/apis/map_activities_api.dart';

/// Repository boundary for map-backend `map_trail` persistence.
abstract class MapTrackPersistenceRepository {
  Future<String> persistPipeline({
    required String userId,
    required ProcessedPipelineResult pipeline,
  });

  Future<void> deleteMapActivity(String mapActivityId);
}

class MapTrackPersistenceRepositoryImpl
    implements MapTrackPersistenceRepository {
  MapTrackPersistenceRepositoryImpl({
    required MapActivitiesApi api,
    PipelineJsonMapper? mapper,
  })  : _api = api,
        _mapper = mapper ?? const PipelineJsonMapper();

  final MapActivitiesApi _api;
  final PipelineJsonMapper _mapper;

  @override
  Future<String> persistPipeline({
    required String userId,
    required ProcessedPipelineResult pipeline,
  }) async {
    final body =
        _mapper.buildMapPersistRequest(userId: userId, pipeline: pipeline);
    final response = await _api.createActivity(body);
    final id = response['id'];
    if (id is! String || id.isEmpty) {
      throw StateError('map-backend /activities response missing id');
    }
    return id;
  }

  @override
  Future<void> deleteMapActivity(String mapActivityId) {
    return _api.deleteActivity(mapActivityId);
  }
}
