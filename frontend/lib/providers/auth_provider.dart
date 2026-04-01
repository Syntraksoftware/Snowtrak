import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:syntrak/core/errors/app_result.dart';
import 'package:syntrak/core/logging/app_logger.dart';
import 'package:syntrak/features/auth/data/auth_session_store.dart';
import 'package:syntrak/models/user.dart';
import 'package:syntrak/models/auth_session.dart';
import 'package:syntrak/services/auth_service.dart';
import 'package:syntrak/services/profile_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService;
  final ProfileService _profileService;
  final AuthSessionStore _sessionStore;
  AuthSession? _session;
  bool _isAuthenticated = false;
  bool _isLoading = true;
  String? _error;
  Future<void>? _authCheckFuture;

  AuthProvider(
    this._authService,
    this._profileService,
    this._sessionStore,
  );

  // Public method to check auth (called after storage is initialized)
  Future<void> checkAuth() {
    final inFlight = _authCheckFuture;
    if (inFlight != null) {
      return inFlight;
    }

    final next = _checkAuth();
    _authCheckFuture = next;
    return next.whenComplete(() {
      if (identical(_authCheckFuture, next)) {
        _authCheckFuture = null;
      }
    });
  }

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

      AppLogger.instance.debug('🔍 [AuthProvider] Initializing storage...');
      await _sessionStore.initialize();
      AppLogger.instance.debug(
          '🔍 [AuthProvider] Storage initialized');

      // Try to restore session from storage
      final restoredSession = await _sessionStore.restore();
      if (restoredSession != null) {
        AppLogger.instance
            .debug('🔍 [AuthProvider] Session restored from storage');

        // Check if token is expired
        if (restoredSession.isExpired) {
          AppLogger.instance.debug(
              '🔍 [AuthProvider] Access token expired, attempting refresh...');
          try {
            _session = await _refreshSession(restoredSession);
            await _sessionStore.save(_session!);
            _authService.setToken(_session!.accessToken);
            _isAuthenticated = true;
            AppLogger.instance
                .debug('🔍 [AuthProvider] Session refreshed successfully');
          } catch (error) {
            AppLogger.instance
                .debug('🔍 [AuthProvider] Token refresh failed: $error');
            await _sessionStore.clear();
            _isAuthenticated = false;
          }
        } else {
          AppLogger.instance.debug(
              '🔍 [AuthProvider] Token still valid, validating with backend...');
          _authService.setToken(restoredSession.accessToken);
          try {
            final userResult = await _profileService
                .getCurrentUser()
                .timeout(const Duration(seconds: 3));
            switch (userResult) {
              case AppSuccess(:final value):
                final user = value;
                _session = AuthSession(
                  accessToken: restoredSession.accessToken,
                  refreshToken: restoredSession.refreshToken,
                  expiresAt: restoredSession.expiresAt,
                  user: user,
                );
                _isAuthenticated = true;
                AppLogger.instance.debug('🔍 [AuthProvider] User authenticated');
              case AppFailure():
                AppLogger.instance.debug(
                    '🔍 [AuthProvider] Token validation failed');
                await _sessionStore.clear();
                _isAuthenticated = false;
            }
          } on TimeoutException {
            AppLogger.instance.debug(
                '🔍 [AuthProvider] Token validation timed out');
            await _sessionStore.clear();
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
      AppLogger.instance.debug('🔍 [AuthProvider] Starting login');
      _isLoading = true;
      _error = null;
      notifyListeners();

      final result =
          await _authService.login(email: email, password: password);
      switch (result) {
        case AppSuccess(:final value):
          final response = value;
          AppLogger.instance
              .debug('🔍 [AuthProvider] Login API response received');

          _session = AuthSession.fromJson(response);
      AppLogger.instance.debug('🔍 [AuthProvider] Session parsed');
          _authService.setToken(_session!.accessToken);
          _isAuthenticated = true;
          _error = null;

          await _sessionStore.save(_session!);
          AppLogger.instance.debug(
              '🔍 [AuthProvider] Session saved, isAuthenticated: $_isAuthenticated');

          _isLoading = false;
          AppLogger.instance.debug(
              '🔍 [AuthProvider] Calling notifyListeners() after successful login');
          notifyListeners();

          Future.delayed(const Duration(milliseconds: 50), () {
            AppLogger.instance.debug(
                '🔍 [AuthProvider] Second notifyListeners() call to ensure rebuild');
            notifyListeners();
          });

          AppLogger.instance.debug(
              '🔍 [AuthProvider] notifyListeners() called, returning true');
          return true;

        case AppFailure(:final error):
          AppLogger.instance
              .debug('🔍 [AuthProvider] Login error: ${error.userMessage}');
          _error = error.userMessage;
          _isLoading = false;
          _isAuthenticated = false;
          notifyListeners();
          return false;
      }
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

      final result = await _authService.register(
        email: email,
        password: password,
        firstName: firstName,
        lastName: lastName,
      );

      switch (result) {
        case AppSuccess(:final value):
          final response = value;
          _session = AuthSession.fromJson(response);
          _authService.setToken(_session!.accessToken);
          _isAuthenticated = true;
          _error = null;

          await _sessionStore.save(_session!);

          _isLoading = false;
          notifyListeners();
          return true;

        case AppFailure(:final error):
          _error = error.userMessage;
          _isLoading = false;
          _isAuthenticated = false;
          notifyListeners();
          return false;
      }
    } catch (error) {
      _error = error.toString();
      _isLoading = false;
      _isAuthenticated = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    _authService.setToken(null);
    _session = null;
    _isAuthenticated = false;

    await _sessionStore.clear();

    notifyListeners();
  }

  Future<void> refreshUserData() async {
    if (!_isAuthenticated || _session == null) {
      return;
    }

    final result = await _profileService.getCurrentUser();
    switch (result) {
      case AppSuccess(:final value):
        final user = value;
        AppLogger.instance.debug('🔍 [AuthProvider] Refreshing user data...');
        _session = AuthSession(
          accessToken: _session!.accessToken,
          refreshToken: _session!.refreshToken,
          expiresAt: _session!.expiresAt,
          user: user,
        );
        await _sessionStore.save(_session!);
        AppLogger.instance.debug('🔍 [AuthProvider] User data refreshed');
        notifyListeners();
      case AppFailure():
        AppLogger.instance.debug(
            '🔍 [AuthProvider] Error refreshing user data');
    }
  }

  Future<bool> refreshTokenIfNeeded() async {
    if (_session == null) {
      AppLogger.instance.debug('🔍 [AuthProvider] No session to refresh');
      return false;
    }

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
      _authService.setToken(newSession.accessToken);
      await _sessionStore.save(newSession);
      _isAuthenticated = true;
      notifyListeners();
      AppLogger.instance
          .debug('🔍 [AuthProvider] Token refreshed successfully');
      return true;
    } catch (e) {
      AppLogger.instance.debug('🔍 [AuthProvider] Token refresh failed: $e');
      _session = null;
      _isAuthenticated = false;
      _authService.setToken(null);
      await _sessionStore.clear();
      notifyListeners();
      return false;
    }
  }

  Future<AuthSession> _refreshSession(AuthSession oldSession) async {
    if (oldSession.refreshToken == null) {
      throw Exception('No refresh token available');
    }

    final result = await _authService.refreshToken(oldSession.refreshToken!);
    switch (result) {
      case AppSuccess(:final value):
        return AuthSession.fromJson(value);
      case AppFailure(:final error):
        AppLogger.instance.debug('🔍 [AuthProvider] Token refresh failed');
        throw Exception(error.userMessage);
    }
  }
}
