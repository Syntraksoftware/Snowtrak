import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:syntrak/models/user.dart';
import 'package:syntrak/models/auth_session.dart';
import 'package:syntrak/services/api_service.dart';
import 'package:syntrak/services/storage_service.dart';

class AuthProvider extends ChangeNotifier {
  final ApiService _apiService;
  final StorageService? _storageService;
  AuthSession? _session;
  bool _isAuthenticated = false;
  bool _isLoading = true;
  String? _error;

  AuthProvider(this._apiService, [this._storageService]);

  // Public method to check auth (called after storage is initialized)
  Future<void> checkAuth() => _checkAuth();

  User? get user => _session?.user;
  AuthSession? get session => _session;
  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> _checkAuth() async {
    print('🔍 [AuthProvider] Starting _checkAuth');
    try {
      _isLoading = true;
      notifyListeners();
      print('🔍 [AuthProvider] isLoading set to true');

      if (_storageService != null) {
        print('🔍 [AuthProvider] Initializing storage...');
        await _storageService!.init();
        print(
            '🔍 [AuthProvider] Storage initialized. Token: ${_storageService!.token}');
      } else {
        print('🔍 [AuthProvider] No storage service available');
      }

      // Try to restore session from storage
      final restoredSession = await _restoreSession();
      if (restoredSession != null) {
        print('🔍 [AuthProvider] Session restored from storage');

        // Check if token is expired
        if (restoredSession.isExpired) {
          print(
              '🔍 [AuthProvider] Access token expired, attempting refresh...');
          try {
            _session = await _refreshSession(restoredSession);
            await _saveSession(_session!);
            _apiService.setToken(_session!.accessToken);
            _isAuthenticated = true;
            print('🔍 [AuthProvider] Session refreshed successfully');
          } catch (e) {
            print('🔍 [AuthProvider] Token refresh failed: $e');
            await _clearSession();
            _isAuthenticated = false;
          }
        } else {
          print(
            '🔍 [AuthProvider] Token still valid, validating with backend...');
          _apiService.setToken(restoredSession.accessToken);
          try {
            // Validate token with backend
            final user = await _apiService
                .getCurrentUser()
                .timeout(const Duration(seconds: 3));
            _session = AuthSession(
              accessToken: restoredSession.accessToken,
              refreshToken: restoredSession.refreshToken,
              expiresAt: restoredSession.expiresAt,
              user: user,
            );
            _isAuthenticated = true;
            print('🔍 [AuthProvider] User authenticated: ${user.email}');
          } catch (e) {
            print('🔍 [AuthProvider] Token validation failed: $e');
            await _clearSession();
            _isAuthenticated = false;
          }
        }
      } else {
        print('🔍 [AuthProvider] No session found, showing login');
        _isAuthenticated = false;
      }
    } catch (e) {
      print('🔍 [AuthProvider] Error in _checkAuth: $e');
      _isAuthenticated = false;
    } finally {
      print('🔍 [AuthProvider] Setting isLoading to false');
      _isLoading = false;
      notifyListeners();
      print(
          '🔍 [AuthProvider] Auth check complete. isAuthenticated: $_isAuthenticated');
    }
  }

  Future<bool> login(String email, String password) async {
    try {
      print('🔍 [AuthProvider] Starting login for: $email');
      _isLoading = true;
      _error = null;
      notifyListeners();

      final response =
          await _apiService.login(email: email, password: password);
      print('🔍 [AuthProvider] Login API response received');

      // Parse session from response
      _session = AuthSession.fromJson(response);
      print('🔍 [AuthProvider] Session parsed, user: ${_session!.user.email}');
      _apiService.setToken(_session!.accessToken);
      _isAuthenticated = true;
      _error = null;

      // Save session to storage
      await _saveSession(_session!);
      print(
          '🔍 [AuthProvider] Session saved, isAuthenticated: $_isAuthenticated');

      _isLoading = false;
      print(
          '🔍 [AuthProvider] Calling notifyListeners() after successful login');
      notifyListeners();

      // Force another notify after a brief delay to ensure Consumer rebuilds
      Future.delayed(const Duration(milliseconds: 50), () {
        print(
            '🔍 [AuthProvider] Second notifyListeners() call to ensure rebuild');
        notifyListeners();
      });

      print('🔍 [AuthProvider] notifyListeners() called, returning true');
      return true;
    } catch (e) {
      print('🔍 [AuthProvider] Login error: $e');
      _error = e.toString();
      _isLoading = false;
      _isAuthenticated = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register(String email, String password,
      {String? firstName, String? lastName}) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final response = await _apiService.register(
        email: email,
        password: password,
        firstName: firstName,
        lastName: lastName,
      );

      // Parse session from response
      _session = AuthSession.fromJson(response);
      _apiService.setToken(_session!.accessToken);
      _isAuthenticated = true;
      _error = null;

      // Save session to storage
      await _saveSession(_session!);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      // Extract clean error message
      String errorMessage = 'Registration failed';
      if (e is Exception) {
        errorMessage = e.toString().replaceFirst('Exception: ', '');
      } else {
        errorMessage = e.toString();
      }
      _error = errorMessage;
      _isLoading = false;
      _isAuthenticated = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    _apiService.setToken(null);
    _session = null;
    _isAuthenticated = false;

    // Clear session from storage
    await _clearSession();

    notifyListeners();
  }

  /// Refresh user data from the backend, do not assume the data is constant
  /// setup the reload logic to detect changes in the supabase side rather than user side 
  Future<void> refreshUserData() async {
    if (!_isAuthenticated || _session == null) {
      return;
    }

    try {
      print('🔍 [AuthProvider] Refreshing user data...');
      final user = await _apiService.getCurrentUser();
      _session = AuthSession(
        accessToken: _session!.accessToken,
        refreshToken: _session!.refreshToken,
        expiresAt: _session!.expiresAt,
        user: user,
      );
      await _saveSession(_session!);
      print('🔍 [AuthProvider] User data refreshed: ${user.firstName}');
      notifyListeners();
    } catch (e) {
      print('🔍 [AuthProvider] Error refreshing user data: $e');
    }
  }

  /// Refresh the access token using the refresh token
  /// Returns true if refresh was successful, false otherwise
  Future<bool> refreshTokenIfNeeded() async {
    if (_session == null) {
      print('🔍 [AuthProvider] No session to refresh');
      return false;
    }

    // Check if token is expired
    if (!_session!.isExpired) {
      print('🔍 [AuthProvider] Token is still valid');
      return true;
    }

    if (_session!.refreshToken == null) {
      print('🔍 [AuthProvider] No refresh token available');
      return false;
    }

    try {
      print('🔍 [AuthProvider] Token expired, refreshing...');
      final newSession = await _refreshSession(_session!);
      _session = newSession;
      _apiService.setToken(newSession.accessToken);
      await _saveSession(newSession);
      _isAuthenticated = true;
      notifyListeners();
      print('🔍 [AuthProvider] Token refreshed successfully');
      return true;
    } catch (e) {
      print('🔍 [AuthProvider] Token refresh failed: $e');
      // Clear session on refresh failure
      _session = null;
      _isAuthenticated = false;
      _apiService.setToken(null);
      await _clearSession();
      notifyListeners();
      return false;
    }
  }

  // Session management helpers

  Future<AuthSession?> _restoreSession() async {
    if (_storageService == null) return null;

    try {
      await _storageService!.init();
      final sessionJson =
          _storageService!.token; // Reuse token field for session JSON

      if (sessionJson == null || sessionJson.isEmpty) return null;

      final decoded = jsonDecode(sessionJson);
      return AuthSession.fromJson(decoded);
    } catch (e) {
      print('🔍 [AuthProvider] Error restoring session: $e');
      return null;
    }
  }

  Future<void> _saveSession(AuthSession session) async {
    if (_storageService == null) return;

    try {
      final sessionJson = jsonEncode(session.toJson());
      await _storageService!.saveToken(sessionJson, session.user.id);
      print('🔍 [AuthProvider] Session saved to storage');
    } catch (e) {
      print('🔍 [AuthProvider] Error saving session: $e');
    }
  }

  Future<void> _clearSession() async {
    if (_storageService == null) return;

    try {
      await _storageService!.clearToken();
      print('🔍 [AuthProvider] Session cleared from storage');
    } catch (e) {
      print('🔍 [AuthProvider] Error clearing session: $e');
    }
  }

  Future<AuthSession> _refreshSession(AuthSession oldSession) async {
    if (oldSession.refreshToken == null) {
      throw Exception('No refresh token available');
    }

    try {
      final response = await _apiService.refreshToken(oldSession.refreshToken!);
      return AuthSession.fromJson(response);
    } catch (e) {
      print('🔍 [AuthProvider] Token refresh failed: $e');
      rethrow;
    }
  }
}
