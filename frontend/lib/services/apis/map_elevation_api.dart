import 'package:dio/dio.dart';

/// Thin HTTP client for map-backend DEM elevation correction.
class MapElevationApi {
  MapElevationApi({required Dio dio}) : _dio = dio;

  final Dio _dio;

  Future<Map<String, dynamic>> correctElevations(
    List<Map<String, dynamic>> points,
  ) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/elevation/correct',
      data: {'points': points},
    );
    return Map<String, dynamic>.from(response.data ?? const {});
  }
}
