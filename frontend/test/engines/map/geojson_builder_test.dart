import 'package:flutter_test/flutter_test.dart';
import 'package:syntrak/engines/map/geojson_builder.dart';
import 'package:syntrak/models/segment.dart';
import 'package:syntrak/models/track_point.dart';

void main() {
  test('buildRouteFeatureCollection emits one feature per pair of points', () {
    final builder = GeoJsonBuilder();
    final segment = Segment(
      type: SegmentType.descent,
      points: <TrackPoint>[
        _point(46.0, 8.0, 1000, 30),
        _point(46.0001, 8.0001, 995, 32),
        _point(46.0002, 8.0002, 990, 34),
      ],
      startIndex: 12,
      endIndex: 14,
      trailName: 'Blue Fox',
      difficulty: 'blue',
    );

    final collection = builder.buildRouteFeatureCollection(<Segment>[segment]);
    final features = collection['features'] as List<dynamic>;

    expect(collection['type'], 'FeatureCollection');
    expect(features, hasLength(2));

    final first = Map<String, dynamic>.from(features.first as Map);
    expect(first['geometry']['type'], 'LineString');
    expect(first['geometry']['coordinates'], [
      [8.0, 46.0],
      [8.0001, 46.0001],
    ]);
    expect(first['properties']['segmentType'], 'descent');
    expect(first['properties']['trailName'], 'Blue Fox');
    expect(first['properties']['difficulty'], 'blue');
    expect(first['properties']['startIndex'], 12);
    expect(first['properties']['endIndex'], 13);
    expect(first['properties']['speedKmh'], closeTo(31, 1e-9));
    expect(first['properties']['elevationM'], closeTo(997.5, 1e-9));
  });

  test('buildHoverPointFeatureCollection emits a single point feature', () {
    final builder = GeoJsonBuilder();
    final collection = builder.buildHoverPointFeatureCollection(
      _point(47.1, 10.2, 1830, 24),
    );

    final features = collection['features'] as List<dynamic>;
    expect(features, hasLength(1));

    final first = Map<String, dynamic>.from(features.first as Map);
    expect(first['geometry']['type'], 'Point');
    expect(first['geometry']['coordinates'], [10.2, 47.1]);
  });
}

TrackPoint _point(double lat, double lon, double elevationM, double speedKmh) {
  return TrackPoint(
    lat: lat,
    lon: lon,
    elevationM: elevationM,
    timestamp: DateTime.utc(2026, 1, 1, 10, 0, 0),
    speedKmh: speedKmh,
  );
}