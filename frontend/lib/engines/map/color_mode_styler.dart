import 'package:maplibre_gl/maplibre_gl.dart';

enum MapColorMode {
  speed,
  elevation,
  segment,
}

class MapColorModeStyler {
  const MapColorModeStyler();

  static const String highlightLayerId = 'ski-route-highlight-layer';
  static const String resortLayerId = 'ski-resort-trails-layer';
  static const String hoverLayerId = 'ski-hover-marker-layer';

  String routeLayerIdForMode(MapColorMode mode) {
    return switch (mode) {
      MapColorMode.speed => 'ski-route-layer-speed',
      MapColorMode.elevation => 'ski-route-layer-elevation',
      MapColorMode.segment => 'ski-route-layer-segment',
    };
  }

  String routeSourceIdForMode(String sourceBaseId, MapColorMode mode) {
    return '$sourceBaseId-${mode.name}';
  }

  LineLayerProperties routeLayerProperties({required bool visible}) {
    return LineLayerProperties(
      lineColor: <dynamic>['get', 'color'],
      lineWidth: 5,
      lineOpacity: 1,
      lineCap: 'round',
      lineJoin: 'round',
      visibility: visible ? 'visible' : 'none',
    );
  }

  LineLayerProperties highlightLayerProperties() {
    return const LineLayerProperties(
      lineColor: '#F9D65C',
      lineWidth: 8,
      lineOpacity: 0.95,
      lineCap: 'round',
      lineJoin: 'round',
      visibility: 'visible',
    );
  }

  LineLayerProperties resortLayerProperties() {
    return const LineLayerProperties(
      lineColor: <dynamic>[
        'match',
        ['get', 'difficulty'],
        'green',
        '#4CAF50',
        'blue',
        '#2196F3',
        'red',
        '#E53935',
        'black',
        '#212121',
        'doubleblack',
        '#212121',
        'double_black',
        '#212121',
        '#90A4AE',
      ],
      lineWidth: 3,
      lineOpacity: 0.35,
      lineCap: 'round',
      lineJoin: 'round',
      visibility: 'visible',
    );
  }

  CircleLayerProperties hoverMarkerProperties() {
    return const CircleLayerProperties(
      circleRadius: 7,
      circleColor: '#FFFFFF',
      circleOpacity: 1,
      circleStrokeColor: '#111111',
      circleStrokeWidth: 2,
      circlePitchScale: 'viewport',
      visibility: 'visible',
    );
  }

}