import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:syntrak/core/config/app_environment.dart';

enum AppLogLevel { debug, info, warning, error }

class AppLogger {
  AppLogger._();

  static final AppLogger instance = AppLogger._();

  AppEnvironment _environment = AppEnvironment.dev;
  bool _fileExportEnabled = false;
  File? _logFile;
  GlobalKey<ScaffoldMessengerState>? _scaffoldMessengerKey;

  bool get isDev => _environment == AppEnvironment.dev;

  void configure({
    required AppEnvironment environment,
    bool fileExportEnabled = false,
  }) {
    _environment = environment;
    _fileExportEnabled = fileExportEnabled;

    if (_fileExportEnabled && !kIsWeb) {
      final ts = DateTime.now().toIso8601String().replaceAll(':', '-');
      final path =
          '${Directory.systemTemp.path}/syntrak-$ts.log.jsonl';
      _logFile = File(path);
      if (!_logFile!.existsSync()) {
        _logFile!.createSync(recursive: true);
      }
    }
  }

  void attachScaffoldMessenger(
    GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey,
  ) {
    _scaffoldMessengerKey = scaffoldMessengerKey;
  }

  void debug(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, dynamic>? context,
  }) {
    _log(
      level: AppLogLevel.debug,
      message: message,
      error: error,
      stackTrace: stackTrace,
      context: context,
    );
  }

  void info(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, dynamic>? context,
  }) {
    _log(
      level: AppLogLevel.info,
      message: message,
      error: error,
      stackTrace: stackTrace,
      context: context,
    );
  }

  void warning(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    bool notifyUser = false,
    String? userMessage,
    Map<String, dynamic>? context,
  }) {
    _log(
      level: AppLogLevel.warning,
      message: message,
      error: error,
      stackTrace: stackTrace,
      notifyUser: notifyUser,
      userMessage: userMessage,
      context: context,
    );
  }

  void error(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    bool notifyUser = false,
    String? userMessage,
    Map<String, dynamic>? context,
  }) {
    _log(
      level: AppLogLevel.error,
      message: message,
      error: error,
      stackTrace: stackTrace,
      notifyUser: notifyUser,
      userMessage: userMessage,
      context: context,
    );
  }

  void _log({
    required AppLogLevel level,
    required String message,
    Object? error,
    StackTrace? stackTrace,
    bool notifyUser = false,
    String? userMessage,
    Map<String, dynamic>? context,
  }) {
    if (!_shouldLog(level)) {
      return;
    }

    final entry = <String, dynamic>{
      'timestamp': DateTime.now().toIso8601String(),
      'environment': _environment.name,
      'level': level.name,
      'message': message,
      if (error != null) 'error': error.toString(),
      if (stackTrace != null) 'stack_trace': stackTrace.toString(),
      if (context != null && context.isNotEmpty) 'context': context,
    };

    debugPrint('[${level.name.toUpperCase()}] $message');
    if (error != null) {
      debugPrint('[${level.name.toUpperCase()}][error] $error');
    }

    if (_fileExportEnabled && _logFile != null) {
      unawaited(_appendToFile(entry));
    }

    if (notifyUser) {
      _showUserNotification(
        level: level,
        message: userMessage ?? message,
      );
    }
  }

  bool _shouldLog(AppLogLevel level) {
    if (isDev) {
      return true;
    }
    return level == AppLogLevel.warning || level == AppLogLevel.error;
  }

  Future<void> _appendToFile(Map<String, dynamic> entry) async {
    if (_logFile == null) {
      return;
    }
    try {
      await _logFile!.writeAsString('${jsonEncode(entry)}\n', mode: FileMode.append);
    } catch (_) {
      // Avoid recursive logging if filesystem write fails.
    }
  }

  void _showUserNotification({
    required AppLogLevel level,
    required String message,
  }) {
    final messengerState = _scaffoldMessengerKey?.currentState;
    if (messengerState == null || message.trim().isEmpty) {
      return;
    }

    Color backgroundColor;
    switch (level) {
      case AppLogLevel.debug:
      case AppLogLevel.info:
        backgroundColor = const Color(0xFF1D4ED8);
        break;
      case AppLogLevel.warning:
        backgroundColor = const Color(0xFFD97706);
        break;
      case AppLogLevel.error:
        backgroundColor = const Color(0xFFB91C1C);
        break;
    }

    messengerState
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: backgroundColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
  }
}