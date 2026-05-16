import 'package:maplibre_gl/maplibre_gl.dart';

import '../../models/segment.dart';
import '../../models/track_point.dart';

class MapCameraController {
  const MapCameraController();

  Future<void> fitToTrack(
    MapLibreMapController controller,
    List<TrackPoint> points, {
    Duration duration = const Duration(milliseconds: 600),
  }) async {
    if (points.isEmpty) {
      return;
    }

    if (points.length == 1) {
      await controller.animateCamera(
        CameraUpdate.newLatLngZoom(LatLng(points.first.lat, points.first.lon), 14),
        duration: duration,
      );
      return;
    }

    final bounds = _boundsFromPoints(points);
    await controller.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, left: 48, top: 48, right: 48, bottom: 48),
      duration: duration,
    );
  }

  Future<void> zoomToSegment(
    MapLibreMapController controller,
    Segment segment, {
    double singlePointZoom = 15,
    Duration duration = const Duration(milliseconds: 450),
  }) async {
    if (segment.points.isEmpty) {
      return;
    }

    if (segment.points.length == 1) {
      final point = segment.points.first;
      await controller.animateCamera(
        CameraUpdate.newLatLngZoom(LatLng(point.lat, point.lon), singlePointZoom),
        duration: duration,
      );
      return;
    }

    final bounds = _boundsFromPoints(segment.points);
    await controller.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, left: 28, top: 28, right: 28, bottom: 28),
      duration: duration,
    );
  }

  Future<void> animateTo(
    MapLibreMapController controller,
    LatLng point,
    double zoom, {
    Duration duration = const Duration(milliseconds: 450),
  }) async {
    await controller.animateCamera(
      CameraUpdate.newLatLngZoom(point, zoom),
      duration: duration,
    );
  }

  LatLngBounds _boundsFromPoints(List<TrackPoint> points) {
    var minLat = points.first.lat;
    var maxLat = points.first.lat;
    var minLon = points.first.lon;
    var maxLon = points.first.lon;

    for (final point in points.skip(1)) {
      if (point.lat < minLat) minLat = point.lat;
      if (point.lat > maxLat) maxLat = point.lat;
      if (point.lon < minLon) minLon = point.lon;
      if (point.lon > maxLon) maxLon = point.lon;
    }

    return LatLngBounds(
      southwest: LatLng(minLat, minLon),
      northeast: LatLng(maxLat, maxLon),
    );
  }
}