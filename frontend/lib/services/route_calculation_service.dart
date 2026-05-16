import 'package:geolocator/geolocator.dart';
import 'package:syntrak/models/location.dart';

/// Service for calculating route metrics from GPS locations
/// 
/// Provides methods to calculate:
/// - Distance (using haversine formula)
/// - Elevation gain/loss
/// - Average and max speed
/// - Pace calculations
/// - Route statistics
class RouteCalculationService {
  /// Calculate total distance in meters from a list of locations
  /// 
  /// Uses haversine formula to calculate distance between consecutive points.
  static double calculateDistance(List<Location> locations) {
    if (locations.length < 2) return 0.0;

    double totalDistance = 0.0;
    for (int i = 1; i < locations.length; i++) {
      final prev = locations[i - 1];
      final curr = locations[i];
      totalDistance += Geolocator.distanceBetween(
        prev.latitude,
        prev.longitude,
        curr.latitude,
        curr.longitude,
      );
    }

    return totalDistance;
  }

  /// Calculate elevation gain in meters
  /// 
  /// Only counts positive elevation changes (going uphill).
  static double calculateElevationGain(List<Location> locations) {
    if (locations.length < 2) return 0.0;

    double elevationGain = 0.0;
    for (int i = 1; i < locations.length; i++) {
      final prev = locations[i - 1];
      final curr = locations[i];
      
      if (curr.altitude != null && prev.altitude != null) {
        final diff = curr.altitude! - prev.altitude!;
        if (diff > 0) {
          elevationGain += diff;
        }
      }
    }

    return elevationGain;
  }

  /// Calculate elevation loss in meters
  /// 
  /// Only counts negative elevation changes (going downhill).
  static double calculateElevationLoss(List<Location> locations) {
    if (locations.length < 2) return 0.0;

    double elevationLoss = 0.0;
    for (int i = 1; i < locations.length; i++) {
      final prev = locations[i - 1];
      final curr = locations[i];
      
      if (curr.altitude != null && prev.altitude != null) {
        final diff = curr.altitude! - prev.altitude!;
        if (diff < 0) {
          elevationLoss += diff.abs();
        }
      }
    }

    return elevationLoss;
  }

  /// Calculate average speed in km/h
  /// 
  /// [duration] - Total duration of the activity
  static double calculateAverageSpeed(
    List<Location> locations,
    Duration duration,
  ) {
    if (duration.inSeconds == 0) return 0.0;
    
    final distance = calculateDistance(locations);
    final distanceKm = distance / 1000.0;
    final hours = duration.inSeconds / 3600.0;
    
    if (hours == 0) return 0.0;
    
    return distanceKm / hours;
  }

  /// Calculate average pace in seconds per kilometer
  /// 
  /// [duration] - Total duration of the activity
  static double calculateAveragePace(
    List<Location> locations,
    Duration duration,
  ) {
    final distance = calculateDistance(locations);
    if (distance == 0) return 0.0;
    
    final distanceKm = distance / 1000.0;
    if (distanceKm == 0) return 0.0;
    
    return duration.inSeconds / distanceKm;
  }

  /// Calculate maximum speed in km/h from GPS speed data
  static double calculateMaxSpeed(List<Location> locations) {
    if (locations.isEmpty) return 0.0;

    double maxSpeed = 0.0;
    for (final location in locations) {
      if (location.speed != null && location.speed! > 0) {
        // Convert m/s to km/h
        final speedKmh = location.speed! * 3.6;
        if (speedKmh > maxSpeed) {
          maxSpeed = speedKmh;
        }
      }
    }

    return maxSpeed;
  }

  /// Calculate current speed in km/h from the last two points
  /// 
  /// Returns 0.0 if there are less than 2 points or if calculation fails.
  static double calculateCurrentSpeed(List<Location> locations) {
    if (locations.length < 2) return 0.0;

    final last = locations[locations.length - 1];
    final secondLast = locations[locations.length - 2];

    // Calculate distance between last two points
    final distance = Geolocator.distanceBetween(
      secondLast.latitude,
      secondLast.longitude,
      last.latitude,
      last.longitude,
    );

    // Calculate time difference
    final timeDiff = last.timestamp.difference(secondLast.timestamp);
    if (timeDiff.inSeconds == 0) return 0.0;

    // Calculate speed in m/s, then convert to km/h
    final speedMs = distance / timeDiff.inSeconds;
    return speedMs * 3.6;
  }

  /// Calculate minimum elevation in meters
  static double? calculateMinElevation(List<Location> locations) {
    if (locations.isEmpty) return null;

    double? minElevation;
    for (final location in locations) {
      if (location.altitude != null) {
        if (minElevation == null || location.altitude! < minElevation) {
          minElevation = location.altitude;
        }
      }
    }

    return minElevation;
  }

  /// Calculate maximum elevation in meters
  static double? calculateMaxElevation(List<Location> locations) {
    if (locations.isEmpty) return null;

    double? maxElevation;
    for (final location in locations) {
      if (location.altitude != null) {
        if (maxElevation == null || location.altitude! > maxElevation) {
          maxElevation = location.altitude;
        }
      }
    }

    return maxElevation;
  }

  /// Calculate all metrics at once
  /// 
  /// Returns a map with all calculated metrics for efficient computation.
  /// [duration] - Total duration of the activity
  static Map<String, dynamic> calculateAllMetrics(
    List<Location> locations,
    Duration duration,
  ) {
    final distance = calculateDistance(locations);
    final elevationGain = calculateElevationGain(locations);
    final elevationLoss = calculateElevationLoss(locations);
    final averageSpeed = calculateAverageSpeed(locations, duration);
    final averagePace = calculateAveragePace(locations, duration);
    final maxSpeed = calculateMaxSpeed(locations);
    final currentSpeed = calculateCurrentSpeed(locations);
    final minElevation = calculateMinElevation(locations);
    final maxElevation = calculateMaxElevation(locations);

    return {
      'distance': distance, // meters
      'elevationGain': elevationGain, // meters
      'elevationLoss': elevationLoss, // meters
      'averageSpeed': averageSpeed, // km/h
      'averagePace': averagePace, // seconds per km
      'maxSpeed': maxSpeed, // km/h
      'currentSpeed': currentSpeed, // km/h
      'minElevation': minElevation, // meters
      'maxElevation': maxElevation, // meters
      'duration': duration.inSeconds, // seconds
    };
  }

  /// Calculate moving time (time when speed > threshold)
  /// 
  /// [threshold] - Minimum speed in km/h to count as moving (default: 1.0 km/h)
  static Duration calculateMovingTime(
    List<Location> locations, {
    double threshold = 1.0,
  }) {
    if (locations.length < 2) return Duration.zero;

    int movingSeconds = 0;
    for (int i = 1; i < locations.length; i++) {
      final prev = locations[i - 1];
      final curr = locations[i];

      // Calculate speed between these two points
      final distance = Geolocator.distanceBetween(
        prev.latitude,
        prev.longitude,
        curr.latitude,
        curr.longitude,
      );

      final timeDiff = curr.timestamp.difference(prev.timestamp);
      if (timeDiff.inSeconds > 0) {
        final speedMs = distance / timeDiff.inSeconds;
        final speedKmh = speedMs * 3.6;

        if (speedKmh > threshold) {
          movingSeconds += timeDiff.inSeconds;
        }
      }
    }

    return Duration(seconds: movingSeconds);
  }

  /// Calculate average moving speed (excluding stopped time)
  /// 
  /// [threshold] - Minimum speed in km/h to count as moving
  static double calculateAverageMovingSpeed(
    List<Location> locations,
    Duration totalDuration, {
    double threshold = 1.0,
  }) {
    final movingTime = calculateMovingTime(locations, threshold: threshold);
    if (movingTime.inSeconds == 0) return 0.0;

    final distance = calculateDistance(locations);
    final distanceKm = distance / 1000.0;
    final hours = movingTime.inSeconds / 3600.0;

    if (hours == 0) return 0.0;

    return distanceKm / hours;
  }
}

