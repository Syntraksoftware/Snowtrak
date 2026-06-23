import 'dart:convert';
import 'package:flutter/services.dart';

enum MapVisualStyle {
  clean2d,
  terrain,
}

class MapConfig {
  // Runtime key — populated by init() below.
  static String _mapTilerKey = '';

  // ponytail: --dart-define takes precedence so CI/CD never needs the asset file.
  static const String _compiledKey = String.fromEnvironment('MAPTILER_API_KEY');
  static const String _compiledStyleUrl = String.fromEnvironment('MAP_STYLE_URL');

  /// Call once during app bootstrap (before runApp).
  /// Loads keys from .env.local.json; --dart-define values override the file.
  static Future<void> init() async {
    if (_compiledKey.isNotEmpty) {
      _mapTilerKey = _compiledKey;
      return;
    }
    try {
      final raw = await rootBundle.loadString('.env.local.json');
      final map = jsonDecode(raw) as Map<String, dynamic>;
      _mapTilerKey = (map['MAPTILER_API_KEY'] as String? ?? '').trim();
    } catch (_) {
      // File missing or malformed — tiles fall back to open sources.
    }
  }

  static const String _mapTilerStreetsStyleUrl =
      'https://api.maptiler.com/maps/streets-v2/style.json';
  static const String _mapTilerOutdoorStyleUrl =
      'https://api.maptiler.com/maps/outdoor-v2/style.json';

  static const String _clean2dRasterStyleJson = '''
{
  "version": 8,
  "name": "Syntrak Clean 2D",
  "glyphs": "https://demotiles.maplibre.org/font/{fontstack}/{range}.pbf",
  "sources": {
    "carto_light": {
      "type": "raster",
      "tiles": [
        "https://a.basemaps.cartocdn.com/light_nolabels/{z}/{x}/{y}.png",
        "https://b.basemaps.cartocdn.com/light_nolabels/{z}/{x}/{y}.png",
        "https://c.basemaps.cartocdn.com/light_nolabels/{z}/{x}/{y}.png"
      ],
      "tileSize": 256,
      "attribution": "© OpenStreetMap contributors © CARTO"
    }
  },
  "layers": [
    {
      "id": "carto_light",
      "type": "raster",
      "source": "carto_light"
    }
  ]
}
''';

  static const String _terrainRasterStyleJson = '''
{
  "version": 8,
  "name": "Syntrak Terrain",
  "glyphs": "https://demotiles.maplibre.org/font/{fontstack}/{range}.pbf",
  "sources": {
    "opentopo": {
      "type": "raster",
      "tiles": [
        "https://a.tile.opentopomap.org/{z}/{x}/{y}.png",
        "https://b.tile.opentopomap.org/{z}/{x}/{y}.png",
        "https://c.tile.opentopomap.org/{z}/{x}/{y}.png"
      ],
      "tileSize": 256,
      "attribution": "© OpenStreetMap contributors, SRTM | OpenTopoMap"
    }
  },
  "layers": [
    {
      "id": "opentopo",
      "type": "raster",
      "source": "opentopo"
    }
  ]
}
''';

  static String styleForMode(MapVisualStyle style) {
    final styleUrl = _compiledStyleUrl.trim();
    if (style == MapVisualStyle.clean2d && styleUrl.isNotEmpty) {
      return styleUrl;
    }

    if (_mapTilerKey.isNotEmpty) {
      switch (style) {
        case MapVisualStyle.clean2d:
          return '$_mapTilerStreetsStyleUrl?key=$_mapTilerKey';
        case MapVisualStyle.terrain:
          return '$_mapTilerOutdoorStyleUrl?key=$_mapTilerKey';
      }
    }

    switch (style) {
      case MapVisualStyle.clean2d:
        return _clean2dRasterStyleJson;
      case MapVisualStyle.terrain:
        return _terrainRasterStyleJson;
    }
  }

  static String get defaultStyleString => styleForMode(MapVisualStyle.clean2d);

  static bool get hasMapTilerApiKey => _mapTilerKey.isNotEmpty;

  static bool isUsingMapTiler(MapVisualStyle style) {
    return styleForMode(style).contains('api.maptiler.com/maps/');
  }

  static String resolvedSourceLabel(MapVisualStyle style) {
    final resolved = styleForMode(style);
    if (resolved.contains('api.maptiler.com/maps/outdoor')) return 'MapTiler Outdoor';
    if (resolved.contains('api.maptiler.com/maps/streets')) return 'MapTiler Streets';
    if (resolved.contains('tile.opentopomap.org')) return 'OpenTopoMap fallback';
    if (resolved.contains('basemaps.cartocdn.com')) return 'CARTO fallback';
    if (resolved.contains('tiles.openfreemap.org')) return 'OpenFreeMap fallback';
    return 'Custom style';
  }

  static String get emergencyFallbackStyleJson =>
      'https://demotiles.maplibre.org/style.json';

  static bool get isConfigured => true;
}
