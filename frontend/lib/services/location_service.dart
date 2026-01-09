import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:syntrak/models/location.dart' as app_location;
import 'package:syntrak/services/gps_filter_service.dart';

class LocationService {
  bool _isTracking = false;
  Position? _currentPosition;
  List<app_location.Location> _locations = [];
  StreamSubscription<Position>? _positionSubscription;
  Position? _lastAcceptedPosition;

  bool get isTracking => _isTracking;
  Position? get currentPosition => _currentPosition;
  List<app_location.Location> get locations => List.unmodifiable(_locations);

  Future<bool> checkPermissions() async {
    // Check permission_handler status
    final permissionStatus = await Permission.location.status;
    print('🔍 [LocationService] Permission status: $permissionStatus');

    // Also check Geolocator permission status for better compatibility
    final geolocatorPermission = await Geolocator.checkPermission();
    print('🔍 [LocationService] Geolocator permission: $geolocatorPermission');

    // Check if location services are enabled
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    print('🔍 [LocationService] Location services enabled: $serviceEnabled');

    // If permission is granted by either system, return true
    if (permissionStatus.isGranted ||
        geolocatorPermission == LocationPermission.always ||
        geolocatorPermission == LocationPermission.whileInUse) {
      if (!serviceEnabled) {
        print(
            '🔍 [LocationService] Permission granted but location services disabled');
        return false;
      }
      print('🔍 [LocationService] Permission granted');
      return true;
    }

    // If denied, try to request
    if (permissionStatus.isDenied ||
        geolocatorPermission == LocationPermission.denied) {
      print('🔍 [LocationService] Permission denied, requesting...');
      final result = await Permission.location.request();
      print('🔍 [LocationService] Permission request result: $result');

      // Also check Geolocator after request
      final newGeolocatorPermission = await Geolocator.checkPermission();
      print(
          '🔍 [LocationService] Geolocator permission after request: $newGeolocatorPermission');

      return result.isGranted ||
          newGeolocatorPermission == LocationPermission.always ||
          newGeolocatorPermission == LocationPermission.whileInUse;
    }

    // If permanently denied, open settings
    if (permissionStatus.isPermanentlyDenied ||
        geolocatorPermission == LocationPermission.deniedForever) {
      print('🔍 [LocationService] Permission permanently denied');
      // Open app settings
      await openAppSettings();
      return false;
    }

    print('🔍 [LocationService] Permission check failed');
    return false;
  }

  Future<bool> requestPermissions() async {
    final hasPermission = await checkPermissions();
    if (!hasPermission) {
      return false;
    }

    // Check if location services are enabled
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are disabled
      return false;
    }

    return true;
  }

  Future<Position?> getCurrentPosition() async {
    try {
      final hasPermission = await requestPermissions();
      if (!hasPermission) {
        print('🔍 [LocationService] No permission for location');
        return null;
      }

      print('🔍 [LocationService] Getting current position...');
      try {
        _currentPosition = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.best,
          timeLimit: const Duration(seconds: 30), // Increased timeout for emulator/slow GPS
        );
        print(
            '🔍 [LocationService] Position obtained: ${_currentPosition?.latitude}, ${_currentPosition?.longitude}');
        return _currentPosition;
      } on TimeoutException catch (e) {
        print('🔍 [LocationService] Timeout getting position: $e');
        // Try with lower accuracy as fallback
        print('🔍 [LocationService] Retrying with lower accuracy...');
        try {
          _currentPosition = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.medium,
            timeLimit: const Duration(seconds: 15),
          );
          print(
              '🔍 [LocationService] Position obtained with medium accuracy: ${_currentPosition?.latitude}, ${_currentPosition?.longitude}');
          return _currentPosition;
        } catch (e2) {
          print('🔍 [LocationService] Failed to get position even with lower accuracy: $e2');
          return null;
        }
      } catch (e, stackTrace) {
        print('🔍 [LocationService] Error getting position: $e');
        print('🔍 [LocationService] Stack trace: $stackTrace');
        return null;
      }
    } catch (e, stackTrace) {
      print('🔍 [LocationService] Outer error getting position: $e');
      print('🔍 [LocationService] Stack trace: $stackTrace');
      return null;
    }
  }

  /// Get a stream of GPS positions with optional filtering and smoothing
  ///
  /// [interval] - Sampling interval (default: 5 seconds)
  /// [distanceFilter] - Minimum distance in meters before emitting new position (default: 5m)
  /// [accuracyThreshold] - Maximum accuracy in meters to accept (default: 50m)
  /// [maxSpeed] - Maximum speed in km/h to accept (default: 200 km/h)
  /// [maxDistanceJump] - Maximum distance jump in meters (default: 500m)
  /// [enableFiltering] - Whether to filter bad GPS points (default: true)
  /// [enableSmoothing] - Whether to smooth GPS points (default: false)
  Stream<Position> getPositionStream({
    Duration interval = const Duration(seconds: 5),
    double distanceFilter = 5.0,
    double accuracyThreshold = GpsFilterService.defaultAccuracyThreshold,
    double maxSpeed = GpsFilterService.defaultMaxSpeed,
    double maxDistanceJump = GpsFilterService.defaultMaxDistanceJump,
    bool enableFiltering = true,
    bool enableSmoothing = false,
  }) {
    final rawStream = Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: distanceFilter.toInt(),
        timeLimit: interval,
      ),
    );

    if (enableFiltering) {
      return GpsFilterService.filterPositionStream(
        rawStream,
        accuracyThreshold: accuracyThreshold,
        maxSpeed: maxSpeed,
        maxDistanceJump: maxDistanceJump,
        enableSmoothing: enableSmoothing,
      );
    }

    return rawStream;
  }

  /// Get a simple position stream (backward compatibility)
  Stream<Position> getPositionStreamSimple() {
    return getPositionStream(
      enableFiltering: false,
      enableSmoothing: false,
    );
  }

  void startTracking() {
    _isTracking = true;
    _locations.clear();
    _lastAcceptedPosition = null;
  }

  void stopTracking() {
    _isTracking = false;
    _positionSubscription?.cancel();
    _positionSubscription = null;
  }

  /// Add a location with optional filtering
  ///
  /// Returns true if the location was added, false if it was filtered out.
  bool addLocation(
    Position position, {
    bool enableFiltering = true,
    double accuracyThreshold = GpsFilterService.defaultAccuracyThreshold,
    double maxSpeed = GpsFilterService.defaultMaxSpeed,
    double maxDistanceJump = GpsFilterService.defaultMaxDistanceJump,
  }) {
    if (!_isTracking) return false;

    // Apply filtering if enabled
    if (enableFiltering) {
      if (!GpsFilterService.shouldAcceptPoint(
        position,
        lastPoint: _lastAcceptedPosition,
        accuracyThreshold: accuracyThreshold,
        maxSpeed: maxSpeed,
        maxDistanceJump: maxDistanceJump,
      )) {
        return false; // Point was filtered out
      }
    }

    final location = app_location.Location(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      activityId: '', // Will be set when activity is created
      latitude: position.latitude,
      longitude: position.longitude,
      altitude: position.altitude,
      accuracy: position.accuracy,
      speed: position.speed,
      timestamp: position.timestamp,
    );

    _locations.add(location);
    _lastAcceptedPosition = position;
    _currentPosition = position;
    return true;
  }

  void clearLocations() {
    _locations.clear();
    _lastAcceptedPosition = null;
    _currentPosition = null;
  }

  /// Dispose resources
  void dispose() {
    _positionSubscription?.cancel();
    _positionSubscription = null;
    _locations.clear();
    _lastAcceptedPosition = null;
    _currentPosition = null;
  }

  double calculateDistance() {
    if (_locations.length < 2) return 0.0;

    double totalDistance = 0.0;
    for (int i = 1; i < _locations.length; i++) {
      final prev = _locations[i - 1];
      final curr = _locations[i];
      totalDistance += Geolocator.distanceBetween(
        prev.latitude,
        prev.longitude,
        curr.latitude,
        curr.longitude,
      );
    }

    return totalDistance;
  }

  double calculateElevationGain() {
    if (_locations.length < 2) return 0.0;

    double elevationGain = 0.0;
    for (int i = 1; i < _locations.length; i++) {
      final prev = _locations[i - 1];
      final curr = _locations[i];
      if (curr.altitude != null && prev.altitude != null) {
        final diff = curr.altitude! - prev.altitude!;
        if (diff > 0) {
          elevationGain += diff;
        }
      }
    }

    return elevationGain;
  }
}
