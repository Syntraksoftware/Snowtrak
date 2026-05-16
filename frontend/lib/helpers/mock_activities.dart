import 'package:syntrak/models/activity.dart';
import 'package:syntrak/models/location.dart';

class MockActivities {
  static List<Activity> generateMockActivities() {
    final now = DateTime.now();
    
    return [
      // Recent activity - Alpine skiing
      Activity(
        id: 'mock-1',
        userId: 'user-1',
        type: ActivityType.alpine,
        name: 'Morning Alpine Run',
        description: 'Perfect conditions on the blue runs',
        distance: 12500, // 12.5 km
        duration: 3600, // 1 hour
        elevationGain: 850,
        startTime: now.subtract(const Duration(hours: 2)),
        endTime: now.subtract(const Duration(hours: 1)),
        averagePace: 288, // 4:48 min/km
        maxPace: 180, // 3:00 min/km
        calories: 450,
        isPublic: true,
        createdAt: now.subtract(const Duration(hours: 2)),
        locations: _generateMockLocations(
          startLat: 46.5197,
          startLng: 9.8380,
          count: 50,
        ),
      ),
      
      // Cross-country skiing
      Activity(
        id: 'mock-2',
        userId: 'user-1',
        type: ActivityType.crossCountry,
        name: 'Cross-Country Trail',
        description: 'Long distance training session',
        distance: 25000, // 25 km
        duration: 7200, // 2 hours
        elevationGain: 320,
        startTime: now.subtract(const Duration(days: 1, hours: 3)),
        endTime: now.subtract(const Duration(days: 1, hours: 1)),
        averagePace: 288, // 4:48 min/km
        maxPace: 240, // 4:00 min/km
        calories: 1200,
        isPublic: true,
        createdAt: now.subtract(const Duration(days: 1, hours: 3)),
        locations: _generateMockLocations(
          startLat: 46.5200,
          startLng: 9.8400,
          count: 100,
        ),
      ),
      
      // Freestyle skiing
      Activity(
        id: 'mock-3',
        userId: 'user-1',
        type: ActivityType.freestyle,
        name: 'Freestyle Park Session',
        description: 'Working on new tricks',
        distance: 3500, // 3.5 km
        duration: 1800, // 30 minutes
        elevationGain: 150,
        startTime: now.subtract(const Duration(days: 2, hours: 5)),
        endTime: now.subtract(const Duration(days: 2, hours: 4, minutes: 30)),
        averagePace: 514, // 8:34 min/km (slower due to tricks)
        maxPace: 300, // 5:00 min/km
        calories: 280,
        isPublic: true,
        createdAt: now.subtract(const Duration(days: 2, hours: 5)),
        locations: _generateMockLocations(
          startLat: 46.5180,
          startLng: 9.8350,
          count: 30,
        ),
      ),
      
      // Backcountry skiing - Long distance
      Activity(
        id: 'mock-4',
        userId: 'user-1',
        type: ActivityType.backcountry,
        name: 'Backcountry Adventure',
        description: 'Explored new terrain off the beaten path',
        distance: 18000, // 18 km
        duration: 14400, // 4 hours
        elevationGain: 1200,
        startTime: now.subtract(const Duration(days: 3)),
        endTime: now.subtract(const Duration(days: 3, hours: -4)),
        averagePace: 480, // 8:00 min/km
        maxPace: 360, // 6:00 min/km
        calories: 1800,
        isPublic: true,
        createdAt: now.subtract(const Duration(days: 3)),
        locations: _generateMockLocations(
          startLat: 46.5150,
          startLng: 9.8300,
          count: 120,
        ),
      ),
      
      // Snowboarding
      Activity(
        id: 'mock-5',
        userId: 'user-1',
        type: ActivityType.snowboard,
        name: 'Snowboard Carving',
        description: 'Perfect powder conditions',
        distance: 8000, // 8 km
        duration: 2700, // 45 minutes
        elevationGain: 600,
        startTime: now.subtract(const Duration(days: 4)),
        endTime: now.subtract(const Duration(days: 4, hours: -1, minutes: -15)),
        averagePace: 338, // 5:38 min/km
        maxPace: 200, // 3:20 min/km
        calories: 520,
        isPublic: true,
        createdAt: now.subtract(const Duration(days: 4)),
        locations: _generateMockLocations(
          startLat: 46.5220,
          startLng: 9.8420,
          count: 60,
        ),
      ),
      
      // Alpine skiing - Short run
      Activity(
        id: 'mock-6',
        userId: 'user-1',
        type: ActivityType.alpine,
        name: 'Quick Slope Run',
        description: 'Fast run down the main slope',
        distance: 4500, // 4.5 km
        duration: 900, // 15 minutes
        elevationGain: 400,
        startTime: now.subtract(const Duration(days: 5)),
        endTime: now.subtract(const Duration(days: 5, hours: -1, minutes: -45)),
        averagePace: 200, // 3:20 min/km (fast!)
        maxPace: 150, // 2:30 min/km
        calories: 180,
        isPublic: true,
        createdAt: now.subtract(const Duration(days: 5)),
        locations: _generateMockLocations(
          startLat: 46.5170,
          startLng: 9.8370,
          count: 25,
        ),
      ),
      
      // Cross-country - Long distance PR
      Activity(
        id: 'mock-7',
        userId: 'user-1',
        type: ActivityType.crossCountry,
        name: 'Personal Best Distance',
        description: 'New personal record for distance!',
        distance: 35000, // 35 km
        duration: 10800, // 3 hours
        elevationGain: 450,
        startTime: now.subtract(const Duration(days: 6)),
        endTime: now.subtract(const Duration(days: 6, hours: -3)),
        averagePace: 309, // 5:09 min/km
        maxPace: 270, // 4:30 min/km
        calories: 2100,
        isPublic: true,
        createdAt: now.subtract(const Duration(days: 6)),
        locations: _generateMockLocations(
          startLat: 46.5210,
          startLng: 9.8410,
          count: 140,
        ),
      ),
    ];
  }

  /// Generate mock GPS locations for a route
  static List<Location> _generateMockLocations({
    required double startLat,
    required double startLng,
    required int count,
  }) {
    final locations = <Location>[];
    final now = DateTime.now();
    
    // Create a winding route
    double lat = startLat;
    double lng = startLng;
    final latStep = 0.001; // ~111 meters per step
    final lngStep = 0.001;
    
    for (int i = 0; i < count; i++) {
      // Create a winding path with variation
      lat += latStep * (0.5 + 0.3 * (i % 3 - 1) / 3);
      lng += lngStep * (0.5 + 0.3 * (i % 5 - 2) / 5);
      
      // Add some altitude variation
      final altitude = 2000.0 + (i * 2.0) + (i % 10) * 5.0;
      
      locations.add(Location(
        id: 'loc-$i',
        activityId: 'mock',
        latitude: lat,
        longitude: lng,
        altitude: altitude,
        accuracy: 10.0,
        speed: 5.0 + (i % 3) * 2.0,
        timestamp: now.subtract(Duration(seconds: (count - i) * 10)),
      ));
    }
    
    return locations;
  }
}

