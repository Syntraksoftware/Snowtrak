// Shared map UI configuration.
//
// Defaults to a clean 2D basemap so all map screens stay readable and avoid
// heavy 3D visual clutter.

enum MapVisualStyle {
  clean2d,
  terrain,
}

class MapConfig {
  static const String _styleUrl = String.fromEnvironment(
    'MAP_STYLE_URL',
    defaultValue: '',
  );

  static const String _mapTilerKey = String.fromEnvironment(
    'MAPTILER_API_KEY',
    defaultValue: '',
  );

      static const String _mapTilerStreetsStyleUrl =
        'https://api.maptiler.com/maps/streets-v2/style.json';
      static const String _mapTilerOutdoorStyleUrl =
        'https://api.maptiler.com/maps/outdoor-v2/style.json';

  // Very quiet 2D raster style for a Strava-like clean base map.
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

  // Terrain style fallback (topographic tiles), useful for slope readability.
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
    final hasStyleOverride = _styleUrl.trim().isNotEmpty;

    // Respect explicit MAP_STYLE_URL override for clean mode, while still
    // allowing terrain toggle to switch maps.
    if (style == MapVisualStyle.clean2d && hasStyleOverride) {
      return _styleUrl;
    }

    if (_mapTilerKey.trim().isNotEmpty) {
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

  static String get defaultStyleString {
    return styleForMode(MapVisualStyle.clean2d);
  }

  static bool get hasMapTilerApiKey => _mapTilerKey.trim().isNotEmpty;

  static bool isUsingMapTiler(MapVisualStyle style) {
    return styleForMode(style).contains('api.maptiler.com/maps/');
  }

  static String resolvedSourceLabel(MapVisualStyle style) {
    final resolved = styleForMode(style);
    if (resolved.contains('api.maptiler.com/maps/outdoor')) {
      return 'MapTiler Outdoor';
    }
    if (resolved.contains('api.maptiler.com/maps/streets')) {
      return 'MapTiler Streets';
    }
    if (resolved.contains('tile.opentopomap.org')) {
      return 'OpenTopoMap fallback';
    }
    if (resolved.contains('basemaps.cartocdn.com')) {
      return 'CARTO fallback';
    }
    if (resolved.contains('tiles.openfreemap.org')) {
      return 'OpenFreeMap fallback';
    }
    return 'Custom style';
  }

  static String get emergencyFallbackStyleJson {
    return 'https://demotiles.maplibre.org/style.json';
  }

  static bool get isConfigured => true;
}
