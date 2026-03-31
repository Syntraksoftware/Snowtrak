import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syntrak/core/logging/app_logger.dart';

class StorageService extends ChangeNotifier {
  static const String _secureTokenKey = 'auth_token';
  static const String _secureUserIdKey = 'user_id';
  static const String _legacyTokenKey = 'auth_token';
  static const String _legacyUserIdKey = 'user_id';
  static const String _locationPermissionAskedKey = 'location_permission_asked';
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();

  String? _token;
  String? _userId;
  bool _locationPermissionAsked = false;

  String? get token => _token;
  String? get userId => _userId;
  bool get locationPermissionAsked => _locationPermissionAsked;

  Future<void> init() async {
    AppLogger.instance.debug('🔍 [StorageService] Starting init');
    try {
      // When SharedPreferences.setMockInitialValues is called (in tests),
      // getInstance() returns immediately. We use a race between the actual
      // future and a very short delay to detect if it's mocked without creating
      // a long-lived timer.
      final prefsFuture = SharedPreferences.getInstance();

      SharedPreferences prefs;
      try {
        // Fast path (typically tests with setMockInitialValues)
        prefs = await prefsFuture.timeout(const Duration(milliseconds: 10));
      } on TimeoutException {
        // Normal path (don't treat as failure; just wasn't immediate)
        prefs = await prefsFuture.timeout(
          const Duration(seconds: 5),
          onTimeout: () => throw TimeoutException('SharedPreferences timeout'),
        );
      }

      _token = await _secureStorage.read(key: _secureTokenKey);
      _userId = await _secureStorage.read(key: _secureUserIdKey);

      // One-time migration from legacy SharedPreferences token storage.
      if (_token == null || _userId == null) {
        final legacyToken = prefs.getString(_legacyTokenKey);
        final legacyUserId = prefs.getString(_legacyUserIdKey);
        if (legacyToken != null && legacyToken.isNotEmpty) {
          await _secureStorage.write(key: _secureTokenKey, value: legacyToken);
          _token = legacyToken;
        }
        if (legacyUserId != null && legacyUserId.isNotEmpty) {
          await _secureStorage.write(key: _secureUserIdKey, value: legacyUserId);
          _userId = legacyUserId;
        }
        if (legacyToken != null || legacyUserId != null) {
          await prefs.remove(_legacyTokenKey);
          await prefs.remove(_legacyUserIdKey);
        }
      }

      _locationPermissionAsked = prefs.getBool(_locationPermissionAskedKey) ?? false;
      AppLogger.instance.debug(
        '🔍 [StorageService] Init complete. Session present: ${_token != null}',
      );
      notifyListeners();
    } on TimeoutException {
      // Handle timeout - in production this shouldn't happen, in tests it means not mocked
      AppLogger.instance.debug('🔍 [StorageService] Init error: Timeout');
      _token = null;
      _userId = null;
      _locationPermissionAsked = false;
      notifyListeners();
    } catch (e) {
      AppLogger.instance.debug('🔍 [StorageService] Init error: $e');
      // If SharedPreferences fails, just continue with null values
      _token = null;
      _userId = null;
      _locationPermissionAsked = false;
      notifyListeners();
    }
  }

  Future<void> setLocationPermissionAsked(bool asked) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_locationPermissionAskedKey, asked);
      _locationPermissionAsked = asked;
      notifyListeners();
    } catch (e) {
      // Ignore errors
    }
  }

  Future<void> saveToken(String token, String userId) async {
    await _secureStorage.write(key: _secureTokenKey, value: token);
    await _secureStorage.write(key: _secureUserIdKey, value: userId);

    // Keep legacy storage clean if an older build wrote these values.
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_legacyTokenKey);
    await prefs.remove(_legacyUserIdKey);

    _token = token;
    _userId = userId;
    notifyListeners();
  }

  Future<void> clearToken() async {
    await _secureStorage.delete(key: _secureTokenKey);
    await _secureStorage.delete(key: _secureUserIdKey);

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_legacyTokenKey);
    await prefs.remove(_legacyUserIdKey);

    _token = null;
    _userId = null;
    notifyListeners();
  }
}

