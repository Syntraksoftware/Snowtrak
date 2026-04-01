/// Mock classes for testing.
import 'package:syntrak/services/storage_service.dart';
import 'package:syntrak/services/location_service.dart';

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

