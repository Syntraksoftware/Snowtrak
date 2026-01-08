import 'package:geolocator/geolocator.dart';

/// Service for filtering and smoothing GPS points
///
/// Filters out bad GPS points based on:
/// - Accuracy threshold (discard if > threshold)
/// - Speed sanity check (discard if > max speed)
/// - Distance jump detection (discard if > max distance from last point)
///
/// Also provides optional smoothing using moving average.
class GpsFilterService {
  /// Default accuracy threshold in meters
  static const double defaultAccuracyThreshold = 50.0;

  /// Default maximum speed in km/h (150 km/h for skiing)
  static const double defaultMaxSpeed = 150.0;

  /// Default maximum distance jump in meters
  static const double defaultMaxDistanceJump = 500.0;

  /// Number of recent points to use for smoothing
  static const int smoothingWindowSize = 3;

  /// Check if a GPS point should be accepted
  ///
  /// Returns true if the point passes all filters:
  /// - Accuracy is within threshold
  /// - Speed is within reasonable limits
  /// - Distance from last point is reasonable
  static bool shouldAcceptPoint(
    Position newPoint, {
    Position? lastPoint,
    double accuracyThreshold = defaultAccuracyThreshold,
    double maxSpeed = defaultMaxSpeed,
    double maxDistanceJump = defaultMaxDistanceJump,
  }) {
    // Filter 1: Accuracy check
    if (newPoint.accuracy > accuracyThreshold) {
      return false;
    }

    // Filter 2: Speed sanity check
    // Convert m/s to km/h: speed * 3.6
    final speedKmh = newPoint.speed * 3.6;
    if (speedKmh > maxSpeed) {
      return false;
    }

    // Filter 3: Distance jump detection (only if we have a previous point)
    if (lastPoint != null) {
      final distance = Geolocator.distanceBetween(
        lastPoint.latitude,
        lastPoint.longitude,
        newPoint.latitude,
        newPoint.longitude,
      );

      if (distance > maxDistanceJump) {
        return false;
      }
    }

    return true;
  }

  /// Smooth a GPS point using moving average of recent points
  ///
  /// Uses weighted average where more recent points have higher weight.
  /// This helps reduce GPS noise while maintaining responsiveness.
  static Position smoothPoint(
    Position point,
    List<Position> recentPoints,
  ) {
    if (recentPoints.isEmpty) {
      return point;
    }

    // Calculate weighted average
    double totalWeight = 1.0; // Current point has weight 1
    double weightedLat = point.latitude;
    double weightedLng = point.longitude;
    double? weightedAlt = point.altitude;
    double? weightedSpeed = point.speed >= 0 ? point.speed : null;

    // Add recent points with decreasing weights
    for (int i = 0; i < recentPoints.length; i++) {
      final weight = (recentPoints.length - i) / recentPoints.length;
      totalWeight += weight;

      weightedLat += recentPoints[i].latitude * weight;
      weightedLng += recentPoints[i].longitude * weight;

      final alt = recentPoints[i].altitude;
      if (alt != null) {
        weightedAlt = (weightedAlt ?? point.altitude ?? 0.0) + alt * weight;
      }

      final speed = recentPoints[i].speed;
      if (speed >= 0) {
        weightedSpeed = (weightedSpeed ?? 0.0) + speed * weight;
      }
    }

    // Create smoothed position
    // Note: Position constructor may have limitations, so we calculate smoothed values
    // but may need to return original point if construction fails
    final smoothedLat = weightedLat / totalWeight;
    final smoothedLng = weightedLng / totalWeight;
    final smoothedAlt =
        weightedAlt != null ? weightedAlt / totalWeight : point.altitude;
    double smoothedSpeed;
    if (weightedSpeed != null) {
      smoothedSpeed = weightedSpeed / totalWeight;
    } else {
      smoothedSpeed = point.speed >= 0 ? point.speed : 0.0;
    }

    // Create new Position with smoothed values
    // Using copyWith-like approach if available, otherwise return original
    try {
      return Position(
        latitude: smoothedLat,
        longitude: smoothedLng,
        timestamp: point.timestamp,
        altitude: smoothedAlt,
        accuracy: point.accuracy,
        altitudeAccuracy: point.altitudeAccuracy,
        heading: point.heading,
        headingAccuracy: point.headingAccuracy,
        speed: smoothedSpeed,
        speedAccuracy: point.speedAccuracy,
      );
    } catch (e) {
      // If Position construction fails, return original point
      return point;
    }
  }

  /// Filter a stream of GPS positions
  ///
  /// Returns a stream that only emits positions that pass the filters.
  /// Optionally applies smoothing to the filtered points.
  static Stream<Position> filterPositionStream(
    Stream<Position> positionStream, {
    double accuracyThreshold = defaultAccuracyThreshold,
    double maxSpeed = defaultMaxSpeed,
    double maxDistanceJump = defaultMaxDistanceJump,
    bool enableSmoothing = false,
  }) async* {
    Position? lastAcceptedPoint;
    final recentPoints = <Position>[];

    await for (final position in positionStream) {
      // Check if point should be accepted
      if (shouldAcceptPoint(
        position,
        lastPoint: lastAcceptedPoint,
        accuracyThreshold: accuracyThreshold,
        maxSpeed: maxSpeed,
        maxDistanceJump: maxDistanceJump,
      )) {
        Position processedPoint = position;

        // Apply smoothing if enabled
        if (enableSmoothing && recentPoints.isNotEmpty) {
          processedPoint = smoothPoint(position, recentPoints);
        }

        // Update recent points for smoothing (keep only last N points)
        recentPoints.add(position);
        if (recentPoints.length > smoothingWindowSize) {
          recentPoints.removeAt(0);
        }

        lastAcceptedPoint = processedPoint;
        yield processedPoint;
      }
      // If point is rejected, silently skip it
    }
  }
}
