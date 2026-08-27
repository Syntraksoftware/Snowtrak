import 'package:dio/dio.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

/// Thin HTTP client for map-backend: trail overlays and `map_trail` activity persistence.
class MapActivitiesApi {
  MapActivitiesApi({required Dio dio}) : _dio = dio;

  final Dio _dio;

  static const _emptyGeoJson = {'type': 'FeatureCollection', 'features': <dynamic>[]};

  Future<Map<String, dynamic>> getResortTrails(LatLngBounds bbox) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/trails/resort',
      queryParameters: {
        'bbox': '${bbox.southwest.longitude},${bbox.southwest.latitude}'
            ',${bbox.northeast.longitude},${bbox.northeast.latitude}',
      },
    );
    return Map<String, dynamic>.from(response.data ?? _emptyGeoJson);
  }

  Future<Map<String, dynamic>> createActivity(Map<String, dynamic> body) async {
    final response = await _dio.post<Map<String, dynamic>>('/activities', data: body);
    return Map<String, dynamic>.from(response.data ?? const {});
  }

  Future<Map<String, dynamic>> getActivity(String activityId) async {
    final response = await _dio.get<Map<String, dynamic>>('/activities/$activityId');
    return Map<String, dynamic>.from(response.data ?? const {});
  }

  Future<void> deleteActivity(String activityId) async {
    await _dio.delete('/activities/$activityId');
  }
}
