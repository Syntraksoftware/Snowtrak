/// Test data factories for creating test objects
import 'package:syntrak/models/user.dart';
import 'package:syntrak/models/activity.dart';
import 'package:syntrak/models/auth_session.dart';

class TestData {
  /// Create a test user
  static User createUser({
    String? id,
    String? email,
    String? firstName,
    String? lastName,
  }) {
    return User(
      id: id ?? 'test_user_123',
      email: email ?? 'test@example.com',
      firstName: firstName ?? 'Test',
      lastName: lastName ?? 'User',
    );
  }

  /// Create a test auth session
  static AuthSession createAuthSession({
    String? accessToken,
    String? refreshToken,
    User? user,
  }) {
    return AuthSession(
      accessToken: accessToken ?? 'test_access_token',
      refreshToken: refreshToken ?? 'test_refresh_token',
      expiresAt: DateTime.now().add(const Duration(hours: 1)),
      user: user ?? createUser(),
    );
  }

  /// Create a test auth session JSON (as returned by API)
  static Map<String, dynamic> createAuthSessionJson({
    String? accessToken,
    String? refreshToken,
    User? user,
  }) {
    final testUser = user ?? createUser();
    return {
      'access_token': accessToken ?? 'test_access_token',
      'refresh_token': refreshToken ?? 'test_refresh_token',
      'expires_at': DateTime.now().add(const Duration(hours: 1)).toIso8601String(),
      'user': testUser.toJson(),
    };
  }

  /// Create a test activity
  static Activity createActivity({
    String? id,
    String? userId,
    ActivityType? type,
    DateTime? startTime,
    double? distance,
    int? duration,
  }) {
    final now = DateTime.now();
    final start = startTime ?? now;
    final end = start.add(Duration(seconds: duration ?? 1800));
    return Activity(
      id: id ?? 'activity_123',
      userId: userId ?? 'test_user_123',
      type: type ?? ActivityType.run,
      startTime: start,
      endTime: end,
      distance: distance ?? 5000.0,
      duration: duration ?? 1800,
      elevationGain: 0.0,
      averagePace: 360.0,
      maxPace: 300.0,
      isPublic: true,
      createdAt: now,
    );
  }

  /// Create a list of test activities
  static List<Activity> createActivities({int count = 3}) {
    return List.generate(
      count,
      (index) => createActivity(
        id: 'activity_$index',
        startTime: DateTime.now().subtract(Duration(days: index)),
      ),
    );
  }

  /// Create a test activity JSON (as returned by API)
  static Map<String, dynamic> createActivityJson({
    String? id,
    String? userId,
    String? type,
    DateTime? startTime,
    double? distance,
    int? duration,
  }) {
    final now = DateTime.now();
    final start = startTime ?? now;
    return {
      'id': id ?? 'activity_123',
      'user_id': userId ?? 'test_user_123',
      'type': type ?? 'run',
      'start_time': start.toIso8601String(),
      'end_time': start.add(Duration(seconds: duration ?? 1800)).toIso8601String(),
      'distance': distance ?? 5000.0,
      'duration': duration ?? 1800,
      'elevation_gain': 0.0,
      'average_pace': 360.0,
      'max_pace': 300.0,
      'is_public': true,
      'created_at': now.toIso8601String(),
      'locations': [],
    };
  }

  /// Create a list of test activity JSONs
  static List<Map<String, dynamic>> createActivitiesJson({int count = 3}) {
    return List.generate(
      count,
      (index) => createActivityJson(
        id: 'activity_$index',
        startTime: DateTime.now().subtract(Duration(days: index)),
      ),
    );
  }
}

