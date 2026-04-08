import 'package:maplibre_gl/maplibre_gl.dart';

import '../../models/track_point.dart';
import 'color_mode_styler.dart';
import 'geojson_builder.dart';

class HoverMarkerController {
  HoverMarkerController({
    GeoJsonBuilder geoJsonBuilder = const GeoJsonBuilder(),
    MapColorModeStyler styleBuilder = const MapColorModeStyler(),
    this.sourceId = 'ski-hover-marker-source',
  })  : _geoJsonBuilder = geoJsonBuilder,
        _styleBuilder = styleBuilder;

  final GeoJsonBuilder _geoJsonBuilder;
  final MapColorModeStyler _styleBuilder;
  final String sourceId;

  bool _attached = false;

  Future<void> attach(MapLibreMapController controller) async {
    if (_attached) {
      return;
    }

    await controller.addGeoJsonSource(
      sourceId,
      GeojsonSourceProperties(
        data: _geoJsonBuilder.buildEmptyFeatureCollection(),
        generateId: true,
      ),
    );
    await controller.addCircleLayer(
      sourceId,
      MapColorModeStyler.hoverLayerId,
      _styleBuilder.hoverMarkerProperties(),
    );
    _attached = true;
  }

  Future<void> update(MapLibreMapController controller, TrackPoint? point) async {
    if (!_attached || point == null) {
      await clear(controller);
      return;
    }

    await controller.setGeoJsonSource(sourceId, _geoJsonBuilder.buildHoverPointFeatureCollection(point));
  }

  Future<void> clear(MapLibreMapController controller) async {
    if (!_attached) {
      return;
    }

    await controller.setGeoJsonSource(sourceId, _geoJsonBuilder.buildEmptyFeatureCollection());
  }
}