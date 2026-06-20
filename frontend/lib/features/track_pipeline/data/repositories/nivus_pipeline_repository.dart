import 'package:syntrak/engines/ingestion/parsers/gpx_parser.dart';
import 'package:syntrak/features/track_pipeline/data/mappers/pipeline_json_mapper.dart';
import 'package:syntrak/features/track_pipeline/domain/processed_pipeline_result.dart';
import 'package:syntrak/models/processed_track.dart';
import 'package:syntrak/services/apis/nivus_pipeline_api.dart';

/// Repository boundary for the Nivus compute microservice.
abstract class NivusPipelineRepository {
  Future<ProcessedPipelineResult> processRawTrack({
    required List<RawPoint> rawPoints,
    required DateTime recordedAt,
    required SourceType sourceType,
    String? trackId,
    bool matchTrails = true,
  });
}

class NivusPipelineRepositoryImpl implements NivusPipelineRepository {
  NivusPipelineRepositoryImpl({
    required NivusPipelineApi api,
    PipelineJsonMapper? mapper,
  })  : _api = api,
        _mapper = mapper ?? const PipelineJsonMapper();

  final NivusPipelineApi _api;
  final PipelineJsonMapper _mapper;

  @override
  Future<ProcessedPipelineResult> processRawTrack({
    required List<RawPoint> rawPoints,
    required DateTime recordedAt,
    required SourceType sourceType,
    String? trackId,
    bool matchTrails = true,
  }) async {
    final body = _mapper.buildNivusRequest(
      rawPoints: rawPoints,
      recordedAt: recordedAt,
      sourceType: sourceType,
      trackId: trackId,
      matchTrails: matchTrails,
    );
    final response = await _api.processPipeline(body);
    return _mapper.parseNivusResponse(response);
  }
}
