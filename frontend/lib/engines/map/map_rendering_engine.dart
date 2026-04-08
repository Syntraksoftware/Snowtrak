import 'package:maplibre_gl/maplibre_gl.dart';

import '../../models/processed_track.dart';
import '../../models/segment.dart';
import '../../models/track_point.dart';
import 'camera_controller.dart';
import 'color_mode_styler.dart';
import 'geojson_builder.dart';
import 'hover_marker_controller.dart';
import 'ski_map_layer_loader.dart';

class MapRenderingEngine {
  MapRenderingEngine({
    GeoJsonBuilder geoJsonBuilder = const GeoJsonBuilder(),
    MapColorModeStyler styleBuilder = const MapColorModeStyler(),
    MapCameraController cameraController = const MapCameraController(),
    HoverMarkerController? hoverMarkerController,
    SkiMapLayerLoader? skiTrailLoader,
  })  : _geoJsonBuilder = geoJsonBuilder,
        _styleBuilder = styleBuilder,
        _cameraController = cameraController,
        _hoverMarkerController = hoverMarkerController ?? HoverMarkerController(),
        _skiTrailLoader = skiTrailLoader;

  final GeoJsonBuilder _geoJsonBuilder;
  final MapColorModeStyler _styleBuilder;
  final MapCameraController _cameraController;
  final HoverMarkerController _hoverMarkerController;
  final SkiMapLayerLoader? _skiTrailLoader;

  MapLibreMapController? _controller;
  List<Segment> _segments = const <Segment>[];
  MapColorMode _colorMode = MapColorMode.segment;
  String _routeSourceId = 'ski-route-source';
  String _highlightSourceId = 'ski-route-highlight-source';

  Future<void> initialise(
    MapLibreMapController controller, {
    required ProcessedTrack track,
    required List<Segment> segments,
    MapColorMode initialColorMode = MapColorMode.segment,
    String routeSourceId = 'ski-route-source',
    String highlightSourceId = 'ski-route-highlight-source',
  }) async {
    _controller = controller;
    _segments = List<Segment>.unmodifiable(segments);
    _colorMode = initialColorMode;
    _routeSourceId = routeSourceId;
    _highlightSourceId = highlightSourceId;

    final routeCollection = _geoJsonBuilder.buildRouteFeatureCollection(segments);
    await controller.addGeoJsonSource(
      _routeSourceId,
      GeojsonSourceProperties(
        data: routeCollection,
        lineMetrics: true,
        generateId: true,
      ),
    );
    await controller.addLineLayer(
      _routeSourceId,
      MapColorModeStyler.routeLayerId,
      _styleBuilder.routeLayerProperties(initialColorMode),
    );

    await controller.addGeoJsonSource(
      _highlightSourceId,
      GeojsonSourceProperties(
        data: _geoJsonBuilder.buildEmptyFeatureCollection(),
        lineMetrics: true,
        generateId: true,
      ),
    );
    await controller.addLineLayer(
      _highlightSourceId,
      MapColorModeStyler.highlightLayerId,
      _styleBuilder.highlightLayerProperties(),
    );

    await _hoverMarkerController.attach(controller);

    if (_skiTrailLoader != null) {
      await _skiTrailLoader.loadForSegments(
        controller,
        track.points.map((point) => LatLng(point.lat, point.lon)).toList(growable: false),
      );
    }
  }

  Future<void> setColorMode(MapColorMode mode) async {
    final controller = _controller;
    if (controller == null || mode == _colorMode) {
      return;
    }

    _colorMode = mode;
    await controller.setLayerProperties(
      MapColorModeStyler.routeLayerId,
      _styleBuilder.routeLayerProperties(mode),
    );
  }

  Future<void> highlightSegment(Segment segment) async {
    final controller = _controller;
    if (controller == null) {
      return;
    }

    await controller.setGeoJsonSource(
      _highlightSourceId,
      _geoJsonBuilder.buildSegmentFeatureCollection(segment),
    );
  }

  Future<void> resetHighlight() async {
    final controller = _controller;
    if (controller == null) {
      return;
    }

    await controller.setGeoJsonSource(
      _highlightSourceId,
      _geoJsonBuilder.buildEmptyFeatureCollection(),
    );
  }

  Future<void> updateHoverPoint(TrackPoint? point) async {
    final controller = _controller;
    if (controller == null) {
      return;
    }

    await _hoverMarkerController.update(controller, point);
  }

  Future<void> clearHoverPoint() async {
    final controller = _controller;
    if (controller == null) {
      return;
    }

    await _hoverMarkerController.clear(controller);
  }

  Future<void> fitToTrack(ProcessedTrack track) async {
    final controller = _controller;
    if (controller == null) {
      return;
    }

    await _cameraController.fitToTrack(controller, track.points);
  }

  Future<void> zoomToSegment(Segment segment) async {
    final controller = _controller;
    if (controller == null) {
      return;
    }

    await _cameraController.zoomToSegment(controller, segment);
  }

  Future<void> zoomToPoint(LatLng point, double zoom) async {
    final controller = _controller;
    if (controller == null) {
      return;
    }

    await _cameraController.animateTo(controller, point, zoom);
  }

  Map<String, dynamic> buildRouteGeoJson(List<Segment> segments) {
    return _geoJsonBuilder.buildRouteFeatureCollection(segments);
  }

  List<Segment> get segments => _segments;

  MapColorMode get colorMode => _colorMode;
}