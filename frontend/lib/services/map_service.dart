import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:syntrak/models/location.dart';
import 'package:syntrak/services/route_calculation_service.dart';

/// Service for map-related utilities and helpers
/// 
/// Provides methods for:
/// - Camera positioning
/// - Bounds calculation
/// - Route fitting
/// - Marker creation
/// - Polyline utilities
class MapService {
  /// Calculate camera position to fit a list of locations
  /// 
  /// Returns a CameraPosition that shows all locations with appropriate padding.
  /// [zoom] - Optional zoom level (if null, will be calculated automatically)
  static CameraPosition calculateCameraPosition(
    List<Location> locations, {
    double? zoom,
    double padding = 50.0,
  }) {
    if (locations.isEmpty) {
      // Default position if no locations
      return const CameraPosition(
        target: LatLng(0, 0),
        zoom: 15,
      );
    }

    if (locations.length == 1) {
      // Single location - center on it
      return CameraPosition(
        target: LatLng(locations.first.latitude, locations.first.longitude),
        zoom: zoom ?? 15,
      );
    }

    // Calculate bounds
    final bounds = calculateBounds(locations);
    
    // Calculate center
    final center = LatLng(
      (bounds.northeast.latitude + bounds.southwest.latitude) / 2,
      (bounds.northeast.longitude + bounds.southwest.longitude) / 2,
    );

    // Calculate zoom level if not provided
    double calculatedZoom = zoom ?? _calculateZoomFromBounds(bounds, padding);

    return CameraPosition(
      target: center,
      zoom: calculatedZoom,
    );
  }

  /// Calculate bounds (bounding box) for a list of locations
  static LatLngBounds calculateBounds(List<Location> locations) {
    if (locations.isEmpty) {
      return LatLngBounds(
        southwest: const LatLng(-90, -180),
        northeast: const LatLng(90, 180),
      );
    }

    double minLat = locations.first.latitude;
    double maxLat = locations.first.latitude;
    double minLng = locations.first.longitude;
    double maxLng = locations.first.longitude;

    for (final location in locations) {
      if (location.latitude < minLat) minLat = location.latitude;
      if (location.latitude > maxLat) maxLat = location.latitude;
      if (location.longitude < minLng) minLng = location.longitude;
      if (location.longitude > maxLng) maxLng = location.longitude;
    }

    return LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
  }

  /// Calculate zoom level from bounds
  /// 
  /// Uses a simple approximation based on the span of the bounds.
  static double _calculateZoomFromBounds(
    LatLngBounds bounds,
    double padding,
  ) {
    final latSpan = bounds.northeast.latitude - bounds.southwest.latitude;
    final lngSpan = bounds.northeast.longitude - bounds.southwest.longitude;
    final maxSpan = latSpan > lngSpan ? latSpan : lngSpan;

    // Simple zoom calculation
    // This is an approximation - Google Maps API has more sophisticated methods
    if (maxSpan > 180) return 1;
    if (maxSpan > 90) return 2;
    if (maxSpan > 45) return 3;
    if (maxSpan > 22.5) return 4;
    if (maxSpan > 11.25) return 5;
    if (maxSpan > 5.625) return 6;
    if (maxSpan > 2.813) return 7;
    if (maxSpan > 1.406) return 8;
    if (maxSpan > 0.703) return 9;
    if (maxSpan > 0.352) return 10;
    if (maxSpan > 0.176) return 11;
    if (maxSpan > 0.088) return 12;
    if (maxSpan > 0.044) return 13;
    if (maxSpan > 0.022) return 14;
    if (maxSpan > 0.011) return 15;
    if (maxSpan > 0.0055) return 16;
    if (maxSpan > 0.0028) return 17;
    if (maxSpan > 0.0014) return 18;
    return 19;
  }

  /// Convert list of Location to list of LatLng
  static List<LatLng> locationsToLatLng(List<Location> locations) {
    return locations
        .map((loc) => LatLng(loc.latitude, loc.longitude))
        .toList();
  }

  /// Create a camera update to fit bounds
  static CameraUpdate fitBounds(
    List<Location> locations, {
    double padding = 50.0,
  }) {
    if (locations.isEmpty) {
      return CameraUpdate.newLatLngZoom(const LatLng(0, 0), 15);
    }

    final bounds = calculateBounds(locations);
    return CameraUpdate.newLatLngBounds(bounds, padding);
  }

  /// Create a camera update to center on a location
  static CameraUpdate centerOnLocation(
    Location location, {
    double zoom = 15,
  }) {
    return CameraUpdate.newLatLngZoom(
      LatLng(location.latitude, location.longitude),
      zoom,
    );
  }

  /// Create a camera update to center on current position
  static CameraUpdate centerOnCurrentPosition(
    double latitude,
    double longitude, {
    double zoom = 15,
  }) {
    return CameraUpdate.newLatLngZoom(
      LatLng(latitude, longitude),
      zoom,
    );
  }

  /// Create start marker
  static Marker createStartMarker(Location location) {
    return Marker(
      markerId: const MarkerId('start'),
      position: LatLng(location.latitude, location.longitude),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      infoWindow: const InfoWindow(title: 'Start'),
    );
  }

  /// Create end marker
  static Marker createEndMarker(Location location) {
    return Marker(
      markerId: const MarkerId('end'),
      position: LatLng(location.latitude, location.longitude),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      infoWindow: const InfoWindow(title: 'End'),
    );
  }

  /// Create current position marker
  static Marker createCurrentPositionMarker(
    double latitude,
    double longitude,
  ) {
    return Marker(
      markerId: const MarkerId('current'),
      position: LatLng(latitude, longitude),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
      infoWindow: const InfoWindow(title: 'Current Position'),
    );
  }

  /// Create route polyline
  /// 
  /// [color] - Polyline color (default: orange)
  /// [width] - Polyline width (default: 4)
  static Polyline createRoutePolyline(
    List<Location> locations, {
    Color color = const Color(0xFFFF4500),
    int width = 4,
    String polylineId = 'route',
  }) {
    return Polyline(
      polylineId: PolylineId(polylineId),
      points: locationsToLatLng(locations),
      color: color,
      width: width,
      geodesic: true, // Follows the curvature of the Earth
    );
  }

  /// Create planned route polyline (for navigation)
  /// 
  /// Uses a different style to distinguish from actual route.
  static Polyline createPlannedRoutePolyline(
    List<LatLng> points, {
    Color color = const Color(0xFF4285F4), // Google Blue
    int width = 3,
    String polylineId = 'planned_route',
  }) {
    return Polyline(
      polylineId: PolylineId(polylineId),
      points: points,
      color: color,
      width: width,
      patterns: [PatternItem.dash(20), PatternItem.gap(10)],
      geodesic: true,
    );
  }

  /// Calculate distance along a route
  /// 
  /// Returns total distance in meters.
  static double calculateRouteDistance(List<Location> locations) {
    return RouteCalculationService.calculateDistance(locations);
  }

  /// Get center point of a route
  static LatLng? getRouteCenter(List<Location> locations) {
    if (locations.isEmpty) return null;

    if (locations.length == 1) {
      return LatLng(locations.first.latitude, locations.first.longitude);
    }

    final bounds = calculateBounds(locations);
    return LatLng(
      (bounds.northeast.latitude + bounds.southwest.latitude) / 2,
      (bounds.northeast.longitude + bounds.southwest.longitude) / 2,
    );
  }

  /// Check if a location is within bounds
  static bool isLocationInBounds(Location location, LatLngBounds bounds) {
    return bounds.contains(LatLng(location.latitude, location.longitude));
  }

  /// Calculate distance between two locations
  static double distanceBetween(Location loc1, Location loc2) {
    return Geolocator.distanceBetween(
      loc1.latitude,
      loc1.longitude,
      loc2.latitude,
      loc2.longitude,
    );
  }
}

