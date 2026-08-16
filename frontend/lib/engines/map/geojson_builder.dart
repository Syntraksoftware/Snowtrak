import 'dart:convert';

import 'package:snowtrak/models/segment.dart';
import 'package:snowtrak/models/track_point.dart';

class GeoJsonBuilder {
  const GeoJsonBuilder();

  Map<String, dynamic> buildRouteFeatureCollectionForMode(
    List<Segment> segments,
    String modeName,
  ) {
    final features = <Map<String, dynamic>>[];
    final elevationRange = _computeElevationRange(segments);

    for (final segment in segments) {
      features.addAll(
        buildSegmentFeaturesForMode(
          segment,
          modeName,
          minElevation: elevationRange.$1,
          maxElevation: elevationRange.$2,
        ),
      );
    }

    return <String, dynamic>{
      'type': 'FeatureCollection',
      'features': features,
    };
  }

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

  List<Map<String, dynamic>> buildSegmentFeaturesForMode(
    Segment segment,
    String modeName, {
    required double minElevation,
    required double maxElevation,
  }) {
    if (segment.points.length < 2) {
      return const <Map<String, dynamic>>[];
    }

    final features = <Map<String, dynamic>>[];
    for (var i = 0; i < segment.points.length - 1; i++) {
      final start = segment.points[i];
      final end = segment.points[i + 1];
      final speedKmh = _average(start.speedKmh, end.speedKmh);
      final elevationM = _average(start.elevationM, end.elevationM);

      features.add(
        <String, dynamic>{
          'type': 'Feature',
          'id': '$modeName-${segment.type.name}-$i',
          'properties': <String, dynamic>{
            'segmentType': segment.type.name,
            'speedKmh': speedKmh,
            'elevationM': elevationM,
            'trailName': segment.trailName,
            'difficulty': segment.difficulty,
            'color': _colorForMode(
              modeName,
              speedKmh: speedKmh,
              elevationM: elevationM,
              minElevation: minElevation,
              maxElevation: maxElevation,
              segmentType: segment.type.name,
            ),
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

  (double, double) _computeElevationRange(List<Segment> segments) {
    double? minElevation;
    double? maxElevation;

    for (final segment in segments) {
      for (final point in segment.points) {
        final elevation = point.elevationM;
        if (minElevation == null || elevation < minElevation) {
          minElevation = elevation;
        }
        if (maxElevation == null || elevation > maxElevation) {
          maxElevation = elevation;
        }
      }
    }

    return (minElevation ?? 0, maxElevation ?? 0);
  }

  String _colorForMode(
    String modeName, {
    required double speedKmh,
    required double elevationM,
    required double minElevation,
    required double maxElevation,
    required String segmentType,
  }) {
    switch (modeName) {
      case 'speed':
        if (speedKmh < 20) return '#378ADD';
        if (speedKmh < 40) return '#1D9E75';
        if (speedKmh < 60) return '#EF9F27';
        return '#E24B4A';
      case 'elevation':
        final range = maxElevation - minElevation;
        if (range <= 0) {
          return '#2E7DFF';
        }
        final t = ((elevationM - minElevation) / range).clamp(0.0, 1.0);
        if (t < 0.33) return '#1A237E';
        if (t < 0.66) return '#0277BD';
        return '#E65100';
      case 'segment':
      default:
        switch (segmentType) {
          case 'descent':
            return '#1E88E5';
          case 'lift':
            return '#8E24AA';
          case 'flat':
            return '#546E7A';
          case 'pause':
            return '#B0BEC5';
          default:
            return '#1E88E5';
        }
    }
  }

  double _average(double a, double b) => (a + b) / 2.0;
}