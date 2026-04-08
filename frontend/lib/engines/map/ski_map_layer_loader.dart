import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

import 'color_mode_styler.dart';
import 'geojson_builder.dart';

abstract class SkiMapApiClient {
  Future<Map<String, dynamic>> get(String path, {Map<String, dynamic>? queryParameters});
}

class DioSkiMapApiClient implements SkiMapApiClient {
  DioSkiMapApiClient(this._dio);

  final Dio _dio;

  @override
  Future<Map<String, dynamic>> get(String path, {Map<String, dynamic>? queryParameters}) async {
    final response = await _dio.get(path, queryParameters: queryParameters);
    return Map<String, dynamic>.from(response.data as Map);
  }
}

class SkiMapLayerLoader {
  SkiMapLayerLoader({
    required SkiMapApiClient apiClient,
    GeoJsonBuilder geoJsonBuilder = const GeoJsonBuilder(),
    MapColorModeStyler styleBuilder = const MapColorModeStyler(),
    this.sourceId = 'ski-resort-trails-source',
  })  : _apiClient = apiClient,
        _geoJsonBuilder = geoJsonBuilder,
        _styleBuilder = styleBuilder;

  final SkiMapApiClient _apiClient;
  final GeoJsonBuilder _geoJsonBuilder;
  final MapColorModeStyler _styleBuilder;
  final String sourceId;

  bool _attached = false;

  Future<void> loadForBounds(MapLibreMapController controller, LatLngBounds bounds) async {
    final bbox = _bboxForBounds(bounds);
    final response = await _apiClient.get('/trails/resort', queryParameters: <String, dynamic>{'bbox': bbox});
    final featureCollection = jsonDecode(jsonEncode(response)) as Map<String, dynamic>;

    await _attachIfNeeded(controller, featureCollection);
    await controller.setGeoJsonSource(sourceId, featureCollection);
  }

  Future<void> loadForSegments(
    MapLibreMapController controller,
    List<LatLng> coordinates,
  ) async {
    if (coordinates.isEmpty) {
      return;
    }

    final bbox = _bboxForCoordinates(coordinates);
    final response = await _apiClient.get('/trails/resort', queryParameters: <String, dynamic>{'bbox': bbox});
    final featureCollection = jsonDecode(jsonEncode(response)) as Map<String, dynamic>;

    await _attachIfNeeded(controller, featureCollection);
    await controller.setGeoJsonSource(sourceId, featureCollection);
  }

  Map<String, dynamic> buildFallbackCollection() {
    return _geoJsonBuilder.buildEmptyFeatureCollection();
  }

  Future<void> _attachIfNeeded(MapLibreMapController controller, Map<String, dynamic> featureCollection) async {
    if (_attached) {
      return;
    }

    await controller.addGeoJsonSource(
      sourceId,
      GeojsonSourceProperties(
        data: featureCollection,
        lineMetrics: true,
        generateId: true,
      ),
    );
    await controller.addLineLayer(
      sourceId,
      MapColorModeStyler.resortLayerId,
      _styleBuilder.resortLayerProperties(),
    );
    _attached = true;
  }

  String _bboxForBounds(LatLngBounds bounds) {
    return '${bounds.southwest.longitude},${bounds.southwest.latitude},${bounds.northeast.longitude},${bounds.northeast.latitude}';
  }

  String _bboxForCoordinates(List<LatLng> coordinates) {
    var minLon = coordinates.first.longitude;
    var maxLon = coordinates.first.longitude;
    var minLat = coordinates.first.latitude;
    var maxLat = coordinates.first.latitude;

    for (final coordinate in coordinates.skip(1)) {
      if (coordinate.longitude < minLon) minLon = coordinate.longitude;
      if (coordinate.longitude > maxLon) maxLon = coordinate.longitude;
      if (coordinate.latitude < minLat) minLat = coordinate.latitude;
      if (coordinate.latitude > maxLat) maxLat = coordinate.latitude;
    }

    return '$minLon,$minLat,$maxLon,$maxLat';
  }
}