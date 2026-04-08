import 'dart:convert';

import 'package:syntrak/models/segment.dart';
import 'package:syntrak/models/track_point.dart';

class GeoJsonBuilder {
  const GeoJsonBuilder();

  Map<String, dynamic> buildRouteFeatureCollection(List<Segment> segments) {
    final features = <Map<String, dynamic>>[];

    for (final segment in segments) {
      features.addAll(buildSegmentFeatures(segment));
    }

    return <String, dynamic>{
      'type': 'FeatureCollection',
      'features': features,
    };
  }

  Map<String, dynamic> buildSegmentFeatureCollection(Segment segment) {
    return <String, dynamic>{
      'type': 'FeatureCollection',
      'features': buildSegmentFeatures(segment),
    };
  }

  List<Map<String, dynamic>> buildSegmentFeatures(Segment segment) {
    if (segment.points.length < 2) {
      return const <Map<String, dynamic>>[];
    }

    final features = <Map<String, dynamic>>[];
    for (var i = 0; i < segment.points.length - 1; i++) {
      final start = segment.points[i];
      final end = segment.points[i + 1];
      final durationSeconds = end.timestamp.difference(start.timestamp).inMilliseconds / 1000.0;
      final speedKmh = _average(start.speedKmh, end.speedKmh);
      final elevationM = _average(start.elevationM, end.elevationM);

      features.add(
        <String, dynamic>{
          'type': 'Feature',
          'id': '${segment.type.name}-$i',
          'properties': <String, dynamic>{
            'segmentType': segment.type.name,
            'speedKmh': speedKmh,
            'elevationM': elevationM,
            'elevationDeltaM': end.elevationM - start.elevationM,
            'durationSeconds': durationSeconds,
            'trailName': segment.trailName,
            'difficulty': segment.difficulty,
            'startIndex': segment.startIndex + i,
            'endIndex': segment.startIndex + i + 1,
          },
          'geometry': <String, dynamic>{
            'type': 'LineString',
            'coordinates': <List<double>>[
              <double>[start.lon, start.lat],
              <double>[end.lon, end.lat],
            ],
          },
        },
      );
    }

    return features;
  }

  Map<String, dynamic> buildHoverPointFeatureCollection(TrackPoint point) {
    return <String, dynamic>{
      'type': 'FeatureCollection',
      'features': <Map<String, dynamic>>[
        <String, dynamic>{
          'type': 'Feature',
          'properties': <String, dynamic>{
            'speedKmh': point.speedKmh,
            'elevationM': point.elevationM,
            'segmentType': point.segmentType?.name,
          },
          'geometry': <String, dynamic>{
            'type': 'Point',
            'coordinates': <double>[point.lon, point.lat],
          },
        },
      ],
    };
  }

  Map<String, dynamic> buildEmptyFeatureCollection() {
    return <String, dynamic>{
      'type': 'FeatureCollection',
      'features': <Map<String, dynamic>>[],
    };
  }

  String encode(Map<String, dynamic> featureCollection) {
    return jsonEncode(featureCollection);
  }

  double _average(double a, double b) => (a + b) / 2.0;
}