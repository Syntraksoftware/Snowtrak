import 'dart:convert';

import 'package:syntrak/core/logging/app_logger.dart';
import 'package:syntrak/models/auth_session.dart';
import 'package:syntrak/services/storage_service.dart';

class AuthSessionStore {
  final StorageService _storageService;

  AuthSessionStore(this._storageService);

  Future<void> initialize() async {
    await _storageService.init();
  }

  String? get rawSession => _storageService.token;

  Future<AuthSession?> restore() async {
    try {
      await _storageService.init();
      final sessionJson = _storageService.token;
      if (sessionJson == null || sessionJson.isEmpty) {
        return null;
      }

      final decoded = jsonDecode(sessionJson) as Map<String, dynamic>;
      return AuthSession.fromJson(decoded);
    } catch (e) {
      AppLogger.instance
          .debug('🔍 [AuthSessionStore] Error restoring session: $e');
      return null;
    }
  }

  Future<void> save(AuthSession session) async {
    try {
      final sessionJson = jsonEncode(session.toJson());
      await _storageService.saveToken(sessionJson, session.user.id);
      AppLogger.instance
          .debug('🔍 [AuthSessionStore] Session saved to storage');
    } catch (e) {
      AppLogger.instance
          .debug('🔍 [AuthSessionStore] Error saving session: $e');
    }
  }

  Future<void> clear() async {
    try {
      await _storageService.clearToken();
      AppLogger.instance
          .debug('🔍 [AuthSessionStore] Session cleared from storage');
    } catch (e) {
      AppLogger.instance
          .debug('🔍 [AuthSessionStore] Error clearing session: $e');
    }
  }
}
