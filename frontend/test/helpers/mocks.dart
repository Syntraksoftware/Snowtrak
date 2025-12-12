/// Mock classes for testing
/// Note: For more complex mocks, use mockito with build_runner
import 'package:syntrak/services/api_service.dart';
import 'package:syntrak/services/storage_service.dart';
import 'package:syntrak/services/location_service.dart';
import 'package:syntrak/models/user.dart';
import 'package:syntrak/models/activity.dart';

/// Mock ApiService for testing
class MockApiService extends ApiService {
  bool shouldFail = false;
  String? errorMessage;
  Map<String, dynamic>? mockLoginResponse;
  Map<String, dynamic>? mockRegisterResponse;
  Map<String, dynamic>? mockUserResponse;
  List<Map<String, dynamic>>? mockActivitiesResponse;
  Map<String, dynamic>? mockCreateActivityResponse;
  
  @override
  Future<Map<String, dynamic>> login({required String email, required String password}) async {
    if (shouldFail) {
      throw Exception(errorMessage ?? 'Login failed');
    }
    if (mockLoginResponse != null) {
      return mockLoginResponse!;
    }
    throw UnimplementedError('Set mockLoginResponse in test');
  }
  
  @override
  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    String? firstName,
    String? lastName,
  }) async {
    if (shouldFail) {
      throw Exception(errorMessage ?? 'Registration failed');
    }
    if (mockRegisterResponse != null) {
      return mockRegisterResponse!;
    }
    throw UnimplementedError('Set mockRegisterResponse in test');
  }
  
  User? mockUser;
  List<Activity>? mockActivities;
  Activity? mockCreatedActivity;
  
  @override
  Future<User> getCurrentUser() async {
    if (shouldFail) {
      throw Exception(errorMessage ?? 'Get user failed');
    }
    if (mockUser != null) {
      return mockUser!;
    }
    throw UnimplementedError('Set mockUser in test');
  }
  
  @override
  Future<List<Activity>> getActivities({int page = 1, int limit = 20}) async {
    if (shouldFail) {
      throw Exception(errorMessage ?? 'Get activities failed');
    }
    return mockActivities ?? [];
  }
  
  @override
  Future<Activity> createActivity(Activity activity) async {
    if (shouldFail) {
      throw Exception(errorMessage ?? 'Create activity failed');
    }
    if (mockCreatedActivity != null) {
      return mockCreatedActivity!;
    }
    throw UnimplementedError('Set mockCreatedActivity in test');
  }
}

/// Mock StorageService for testing
class MockStorageService extends StorageService {
  String? _mockToken;
  String? _mockUserId;
  bool _mockLocationPermissionAsked = false;
  bool _shouldFailInit = false;
  
  MockStorageService({
    String? token,
    String? userId,
    bool locationPermissionAsked = false,
    bool shouldFailInit = false,
  })  : _mockToken = token,
        _mockUserId = userId,
        _mockLocationPermissionAsked = locationPermissionAsked,
        _shouldFailInit = shouldFailInit;
  
  @override
  String? get token => _mockToken;
  
  @override
  String? get userId => _mockUserId;
  
  @override
  bool get locationPermissionAsked => _mockLocationPermissionAsked;
  
  @override
  Future<void> init() async {
    if (_shouldFailInit) {
      throw Exception('Storage init failed');
    }
    // Mock successful init
  }
  
  @override
  Future<void> saveToken(String token, String userId) async {
    _mockToken = token;
    _mockUserId = userId;
  }
  
  @override
  Future<void> clearToken() async {
    _mockToken = null;
    _mockUserId = null;
  }
  
  @override
  Future<void> setLocationPermissionAsked(bool asked) async {
    _mockLocationPermissionAsked = asked;
  }
}

/// Mock LocationService for testing
class MockLocationService extends LocationService {
  bool _hasPermission = false;
  bool _shouldFail = false;
  
  MockLocationService({
    bool hasPermission = false,
    bool shouldFail = false,
  })  : _hasPermission = hasPermission,
        _shouldFail = shouldFail;
  
  @override
  Future<bool> requestPermissions() async {
    if (_shouldFail) {
      return false;
    }
    _hasPermission = true;
    return true;
  }
  
  @override
  Future<bool> checkPermissions() async {
    return _hasPermission;
  }
}

