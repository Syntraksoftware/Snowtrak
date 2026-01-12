import 'package:syntrak/models/location.dart';

enum ActivityType {
  alpine,        // Alpine/Downhill skiing
  crossCountry,  // Cross-country skiing
  freestyle,     // Freestyle skiing
  backcountry,   // Backcountry skiing
  snowboard,     // Snowboarding
  other,         // Other winter activities
}

extension ActivityTypeExtension on ActivityType {
  String get value {
    switch (this) {
      case ActivityType.alpine:
        return 'alpine';
      case ActivityType.crossCountry:
        return 'cross_country';
      case ActivityType.freestyle:
        return 'freestyle';
      case ActivityType.backcountry:
        return 'backcountry';
      case ActivityType.snowboard:
        return 'snowboard';
      case ActivityType.other:
        return 'other';
    }
  }

  String get displayName {
    switch (this) {
      case ActivityType.alpine:
        return 'Alpine';
      case ActivityType.crossCountry:
        return 'Cross-Country';
      case ActivityType.freestyle:
        return 'Freestyle';
      case ActivityType.backcountry:
        return 'Backcountry';
      case ActivityType.snowboard:
        return 'Snowboard';
      case ActivityType.other:
        return 'Other';
    }
  }

  static ActivityType fromString(String value) {
    switch (value) {
      case 'alpine':
        return ActivityType.alpine;
      case 'cross_country':
        return ActivityType.crossCountry;
      case 'freestyle':
        return ActivityType.freestyle;
      case 'backcountry':
        return ActivityType.backcountry;
      case 'snowboard':
        return ActivityType.snowboard;
      default:
        return ActivityType.other;
    }
  }
}

class Activity {
  final String id;
  final String userId;
  final ActivityType type;
  final String? name;
  final String? description;
  final double distance; // in meters
  final int duration; // in seconds
  final double elevationGain; // in meters
  final DateTime startTime;
  final DateTime endTime;
  final double averagePace; // seconds per km
  final double maxPace; // seconds per km
  final int? calories;
  final bool isPublic;
  final DateTime createdAt;
  final List<Location> locations;

  Activity({
    required this.id,
    required this.userId,
    required this.type,
    this.name,
    this.description,
    required this.distance,
    required this.duration,
    required this.elevationGain,
    required this.startTime,
    required this.endTime,
    required this.averagePace,
    required this.maxPace,
    this.calories,
    required this.isPublic,
    required this.createdAt,
    this.locations = const [],
  });

  String get formattedDistance {
    if (distance >= 1000) {
      return '${(distance / 1000).toStringAsFixed(2)} km';
    }
    return '${distance.toStringAsFixed(0)} m';
  }

  String get formattedDuration {
    final hours = duration ~/ 3600;
    final minutes = (duration % 3600) ~/ 60;
    final seconds = duration % 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m ${seconds}s';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    }
    return '${seconds}s';
  }

  String get formattedPace {
    if (averagePace == 0) return '--';
    final minutes = (averagePace ~/ 60).toString().padLeft(2, '0');
    final seconds = (averagePace % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds /km';
  }
  
  // Skiing-specific metrics
  String get formattedVerticalDrop {
    if (elevationGain < 1000) {
      return '${elevationGain.toStringAsFixed(0)} m';
    }
    return '${(elevationGain / 1000).toStringAsFixed(1)} km';
  }
  
  String get formattedSpeed {
    if (averagePace == 0) return '--';
    final speedKmh = 3600 / averagePace;
    return '${speedKmh.toStringAsFixed(1)} km/h';
  }

  factory Activity.fromJson(Map<String, dynamic> json) {
    return Activity(
      id: json['id'],
      userId: json['user_id'],
      type: ActivityTypeExtension.fromString(json['type']),
      name: json['name'],
      description: json['description'],
      distance: (json['distance'] as num).toDouble(),
      duration: json['duration'],
      elevationGain: (json['elevation_gain'] as num?)?.toDouble() ?? 0.0,
      startTime: DateTime.parse(json['start_time']),
      endTime: DateTime.parse(json['end_time']),
      averagePace: (json['average_pace'] as num?)?.toDouble() ?? 0.0,
      maxPace: (json['max_pace'] as num?)?.toDouble() ?? 0.0,
      calories: json['calories'],
      isPublic: json['is_public'] ?? true,
      createdAt: DateTime.parse(json['created_at']),
      locations: (json['locations'] as List<dynamic>?)
              ?.map((loc) => Location.fromJson(loc))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type.value,
      'name': name,
      'description': description,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime.toIso8601String(),
      'locations': locations.map((loc) => loc.toJson()).toList(),
      'is_public': isPublic,
    };
  }
}

