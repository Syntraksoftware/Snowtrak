import 'package:maplibre_gl/maplibre_gl.dart';

enum MapColorMode {
  speed,
  elevation,
  segment,
}

class MapColorModeStyler {
  const MapColorModeStyler();

  static const String routeLayerId = 'ski-route-layer';
  static const String highlightLayerId = 'ski-route-highlight-layer';
  static const String resortLayerId = 'ski-resort-trails-layer';
  static const String hoverLayerId = 'ski-hover-marker-layer';

  LineLayerProperties routeLayerProperties(MapColorMode mode) {
    return LineLayerProperties(
      lineColor: routeColorExpression(mode),
      lineWidth: 5,
      lineOpacity: 1,
      lineCap: 'round',
      lineJoin: 'round',
      visibility: 'visible',
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
    return LineLayerProperties(
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

  dynamic routeColorExpression(MapColorMode mode) {
    switch (mode) {
      case MapColorMode.speed:
        return <dynamic>[
          'interpolate',
          ['linear'],
          ['get', 'speedKmh'],
          0,
          '#2C7BB6',
          20,
          '#00A6CA',
          35,
          '#F9D057',
          50,
          '#D7191C',
        ];
      case MapColorMode.elevation:
        return <dynamic>[
          'interpolate',
          ['linear'],
          ['get', 'elevationM'],
          0,
          '#1A237E',
          1000,
          '#0277BD',
          2000,
          '#26A69A',
          3000,
          '#E65100',
        ];
      case MapColorMode.segment:
        return <dynamic>[
          'match',
          ['get', 'segmentType'],
          'descent',
          '#1E88E5',
          'lift',
          '#8E24AA',
          'flat',
          '#546E7A',
          'pause',
          '#B0BEC5',
          '#1E88E5',
        ];
    }
  }
}