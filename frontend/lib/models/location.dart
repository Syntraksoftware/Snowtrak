class Location {
  final String id;
  final String activityId;
  final double latitude;
  final double longitude;
  final double? altitude;
  final double? accuracy;
  final double? speed;
  final DateTime timestamp;

  Location({
    required this.id,
    required this.activityId,
    required this.latitude,
    required this.longitude,
    this.altitude,
    this.accuracy,
    this.speed,
    required this.timestamp,
  });

  factory Location.fromJson(Map<String, dynamic> json) {
    return Location(
      id: json['id'] ?? '',
      activityId: json['activity_id'] ?? '',
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      altitude: json['altitude'] != null ? (json['altitude'] as num).toDouble() : null,
      accuracy: json['accuracy'] != null ? (json['accuracy'] as num).toDouble() : null,
      speed: json['speed'] != null ? (json['speed'] as num).toDouble() : null,
      timestamp: DateTime.parse(json['timestamp']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'altitude': altitude,
      'accuracy': accuracy,
      'speed': speed,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

