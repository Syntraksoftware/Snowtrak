import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService extends ChangeNotifier {
  static const String _tokenKey = 'auth_token';
  static const String _userIdKey = 'user_id';
  static const String _locationPermissionAskedKey = 'location_permission_asked';

  String? _token;
  String? _userId;
  bool _locationPermissionAsked = false;

  String? get token => _token;
  String? get userId => _userId;
  bool get locationPermissionAsked => _locationPermissionAsked;

  Future<void> init() async {
    print('🔍 [StorageService] Starting init');
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
      _token = prefs.getString(_tokenKey);
      _userId = prefs.getString(_userIdKey);
      _locationPermissionAsked = prefs.getBool(_locationPermissionAskedKey) ?? false;
      print('🔍 [StorageService] Init complete. Token: ${_token != null ? "exists" : "null"}');
      notifyListeners();
    } on TimeoutException {
      // Handle timeout - in production this shouldn't happen, in tests it means not mocked
      print('🔍 [StorageService] Init error: Timeout');
      _token = null;
      _userId = null;
      _locationPermissionAsked = false;
      notifyListeners();
    } catch (e) {
      print('🔍 [StorageService] Init error: $e');
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
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    await prefs.setString(_userIdKey, userId);
    _token = token;
    _userId = userId;
    notifyListeners();
  }

  Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userIdKey);
    _token = null;
    _userId = null;
    notifyListeners();
  }
}

