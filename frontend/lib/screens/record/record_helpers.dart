import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

String formatRecordDuration(Duration duration) {
  final hours = duration.inHours;
  final minutes = duration.inMinutes.remainder(60);
  final seconds = duration.inSeconds.remainder(60);

  if (hours > 0) {
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
  return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
}

/// Instantaneous speed from last two route samples (~1s apart).
String formatSpeedFromRouteTail(List<LatLng> routePoints) {
  if (routePoints.length < 2) return '-- km/h';
  final lastPoint = routePoints.last;
  final secondLast = routePoints[routePoints.length - 2];
  final distance = Geolocator.distanceBetween(
    secondLast.latitude,
    secondLast.longitude,
    lastPoint.latitude,
    lastPoint.longitude,
  );
  final speedMs = distance / 1.0;
  final speedKmh = speedMs * 3.6;
  return '${speedKmh.toStringAsFixed(1)} km/h';
}
