import 'package:flutter/foundation.dart';
import 'package:syntrak/core/logging/app_logger.dart';
import 'package:syntrak/features/auth/data/auth_session_store.dart';
import 'package:syntrak/models/user.dart';
import 'package:syntrak/models/auth_session.dart';
import 'package:syntrak/services/api_service.dart';
import 'package:syntrak/services/storage_service.dart';

class AuthProvider extends ChangeNotifier {
  final ApiService _apiService;
  final AuthSessionStore? _sessionStore;
  AuthSession? _session;
  bool _isAuthenticated = false;
  bool _isLoading = true;
  String? _error;

  AuthProvider(
    this._apiService, [
    StorageService? storageService,
    AuthSessionStore? sessionStore,
  ]) : _sessionStore = sessionStore ??
            (storageService != null ? AuthSessionStore(storageService) : null);

  // Public method to check auth (called after storage is initialized)
  Future<void> checkAuth() => _checkAuth();

  User? get user => _session?.user;
  AuthSession? get session => _session;
  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> _checkAuth() async {
    AppLogger.instance.debug('🔍 [AuthProvider] Starting _checkAuth');
    try {
      _isLoading = true;
      notifyListeners();
      AppLogger.instance.debug('🔍 [AuthProvider] isLoading set to true');

      if (_sessionStore != null) {
        AppLogger.instance.debug('🔍 [AuthProvider] Initializing storage...');
        await _sessionStore!.initialize();
        AppLogger.instance.debug(
            '🔍 [AuthProvider] Storage initialized. Token: ${_sessionStore!.rawSession}');
      } else {
        AppLogger.instance
            .debug('🔍 [AuthProvider] No storage service available');
      }

      // Try to restore session from storage
      final restoredSession = await _sessionStore?.restore();
      if (restoredSession != null) {
        AppLogger.instance
            .debug('🔍 [AuthProvider] Session restored from storage');

        // Check if token is expired
        if (restoredSession.isExpired) {
          AppLogger.instance.debug(
              '🔍 [AuthProvider] Access token expired, attempting refresh...');
          try {
            _session = await _refreshSession(restoredSession);
            await _sessionStore?.save(_session!);
            _apiService.setToken(_session!.accessToken);
            _isAuthenticated = true;
            AppLogger.instance
                .debug('🔍 [AuthProvider] Session refreshed successfully');
          } catch (error) {
            AppLogger.instance
                .debug('🔍 [AuthProvider] Token refresh failed: $error');
            await _sessionStore?.clear();
            _isAuthenticated = false;
          }
        } else {
          AppLogger.instance.debug(
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
            AppLogger.instance
                .debug('🔍 [AuthProvider] User authenticated: ${user.email}');
          } catch (e) {
            AppLogger.instance
                .debug('🔍 [AuthProvider] Token validation failed: $e');
            await _sessionStore?.clear();
            _isAuthenticated = false;
          }
        }
      } else {
        AppLogger.instance
            .debug('🔍 [AuthProvider] No session found, showing login');
        _isAuthenticated = false;
      }
    } catch (e) {
      AppLogger.instance.debug('🔍 [AuthProvider] Error in _checkAuth: $e');
      _isAuthenticated = false;
    } finally {
      AppLogger.instance.debug('🔍 [AuthProvider] Setting isLoading to false');
      _isLoading = false;
      notifyListeners();
      AppLogger.instance.debug(
          '🔍 [AuthProvider] Auth check complete. isAuthenticated: $_isAuthenticated');
    }
  }

  Future<bool> login(String email, String password) async {
    try {
      AppLogger.instance.debug('🔍 [AuthProvider] Starting login for: $email');
      _isLoading = true;
      _error = null;
      notifyListeners();

      final response =
          await _apiService.login(email: email, password: password);
      AppLogger.instance.debug('🔍 [AuthProvider] Login API response received');

      // Parse session from response
      _session = AuthSession.fromJson(response);
      AppLogger.instance.debug(
          '🔍 [AuthProvider] Session parsed, user: ${_session!.user.email}');
      _apiService.setToken(_session!.accessToken);
      _isAuthenticated = true;
      _error = null;

      // Save session to storage
      await _sessionStore?.save(_session!);
      AppLogger.instance.debug(
          '🔍 [AuthProvider] Session saved, isAuthenticated: $_isAuthenticated');

      _isLoading = false;
      AppLogger.instance.debug(
          '🔍 [AuthProvider] Calling notifyListeners() after successful login');
      notifyListeners();

      // Force another notify after a brief delay to ensure Consumer rebuilds
      Future.delayed(const Duration(milliseconds: 50), () {
        AppLogger.instance.debug(
            '🔍 [AuthProvider] Second notifyListeners() call to ensure rebuild');
        notifyListeners();
      });

      AppLogger.instance
          .debug('🔍 [AuthProvider] notifyListeners() called, returning true');
      return true;
    } catch (error) {
      AppLogger.instance.debug('🔍 [AuthProvider] Login error: $error');
      _error = error.toString();
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
      await _sessionStore?.save(_session!);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (error) {
      // Extract clean error message
      String errorMessage = 'Registration failed';
      if (error is Exception) {
        errorMessage = error.toString().replaceFirst('Exception: ', '');
      } else {
        errorMessage = error.toString();
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
    await _sessionStore?.clear();

    notifyListeners();
  }

  /// Refresh user data from the backend, do not assume the data is constant
  /// setup the reload logic to detect changes in the supabase side rather than user side
  Future<void> refreshUserData() async {
    if (!_isAuthenticated || _session == null) {
      return;
    }

    try {
      AppLogger.instance.debug('🔍 [AuthProvider] Refreshing user data...');
      final user = await _apiService.getCurrentUser();
      _session = AuthSession(
        accessToken: _session!.accessToken,
        refreshToken: _session!.refreshToken,
        expiresAt: _session!.expiresAt,
        user: user,
      );
      await _sessionStore?.save(_session!);
      AppLogger.instance
          .debug('🔍 [AuthProvider] User data refreshed: ${user.firstName}');
      notifyListeners();
    } catch (e) {
      AppLogger.instance
          .debug('🔍 [AuthProvider] Error refreshing user data: $e');
    }
  }

  /// Refresh the access token using the refresh token
  /// Returns true if refresh was successful, false otherwise
  Future<bool> refreshTokenIfNeeded() async {
    if (_session == null) {
      AppLogger.instance.debug('🔍 [AuthProvider] No session to refresh');
      return false;
    }

    // Check if token is expired
    if (!_session!.isExpired) {
      AppLogger.instance.debug('🔍 [AuthProvider] Token is still valid');
      return true;
    }

    if (_session!.refreshToken == null) {
      AppLogger.instance.debug('🔍 [AuthProvider] No refresh token available');
      return false;
    }

    try {
      AppLogger.instance
          .debug('🔍 [AuthProvider] Token expired, refreshing...');
      final newSession = await _refreshSession(_session!);
      _session = newSession;
      _apiService.setToken(newSession.accessToken);
      await _sessionStore?.save(newSession);
      _isAuthenticated = true;
      notifyListeners();
      AppLogger.instance
          .debug('🔍 [AuthProvider] Token refreshed successfully');
      return true;
    } catch (e) {
      AppLogger.instance.debug('🔍 [AuthProvider] Token refresh failed: $e');
      // Clear session on refresh failure
      _session = null;
      _isAuthenticated = false;
      _apiService.setToken(null);
      await _sessionStore?.clear();
      notifyListeners();
      return false;
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
      AppLogger.instance.debug('🔍 [AuthProvider] Token refresh failed: $e');
      rethrow;
    }
  }
}
