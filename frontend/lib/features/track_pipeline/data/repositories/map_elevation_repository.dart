import 'package:syntrak/engines/ingestion/parsers/gpx_parser.dart';
import 'package:syntrak/features/track_pipeline/data/mappers/pipeline_json_mapper.dart';
import 'package:syntrak/services/apis/map_elevation_api.dart';

/// Repository boundary for map-backend DEM elevation correction.
abstract class MapElevationRepository {
  Future<List<RawPoint>> correctElevations(List<RawPoint> rawPoints);
}

class MapElevationRepositoryImpl implements MapElevationRepository {
  MapElevationRepositoryImpl({
    required MapElevationApi api,
    PipelineJsonMapper? mapper,
  })  : _api = api,
        _mapper = mapper ?? const PipelineJsonMapper();

  final MapElevationApi _api;
  final PipelineJsonMapper _mapper;

  @override
  Future<List<RawPoint>> correctElevations(List<RawPoint> rawPoints) async {
    if (rawPoints.isEmpty) {
      return const [];
    }

    final corrected = <RawPoint>[];
    const chunkSize = 500;
    for (var start = 0; start < rawPoints.length; start += chunkSize) {
      final end = (start + chunkSize > rawPoints.length) ? rawPoints.length : start + chunkSize;
      final chunk = rawPoints.sublist(start, end);
      final response = await _api.correctElevations(_mapper.rawPointsToElevationRequest(chunk));
      corrected.addAll(_mapper.elevationResponseToRawPoints(chunk, response));
    }
    return corrected;
  }
}
