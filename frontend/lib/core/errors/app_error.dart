import 'package:dio/dio.dart';

/// Normalized error for services and providers: always carries a user-safe message.
class AppError {
  const AppError({
    required this.userMessage,
    this.cause,
    this.stackTrace,
    this.retryable = true,
  });

  final String userMessage;
  final Object? cause;
  final StackTrace? stackTrace;

  /// When false, retry is unlikely to help (e.g. auth, not found).
  final bool retryable;

  /// Maps network/API failures to stable user-facing copy.
  factory AppError.from(Object error, [StackTrace? stackTrace]) {
    if (error is AppError) {
      return error;
    }
    if (error is DioException) {
      return _fromDio(error, stackTrace);
    }
    if (error is FormatException) {
      return AppError(
        userMessage:
            'Received unexpected data from the server. Please try again.',
        cause: error,
        stackTrace: stackTrace,
        retryable: true,
      );
    }
    return AppError(
      userMessage: 'Something went wrong. Please try again.',
      cause: error,
      stackTrace: stackTrace,
    );
  }

  static AppError _fromDio(DioException e, StackTrace? stackTrace) {
    final status = e.response?.statusCode;
    final serverMsg = _trimServerMessage(e.response?.data);
    final dioDetail = _nonEmpty(e.message);

    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout) {
      return AppError(
        userMessage: 'Request timed out. Check your connection and try again.',
        cause: e,
        stackTrace: stackTrace,
        retryable: true,
      );
    }
    if (e.type == DioExceptionType.connectionError) {
      return AppError(
        userMessage: 'No internet connection. Try again when you are online.',
        cause: e,
        stackTrace: stackTrace,
        retryable: true,
      );
    }

    final String message;
    bool retryable = true;
    if (status == null) {
      message = serverMsg ??
          dioDetail ??
          'Unable to load data. Please try again.';
    } else if (status == 401) {
      message = 'Please sign in again.';
      retryable = false;
    } else if (status == 403) {
      message = 'You don\'t have permission to do that.';
      retryable = false;
    } else if (status == 404) {
      message = 'We couldn\'t find that resource.';
      retryable = false;
    } else if (status == 429) {
      message = 'Too many requests. Please wait a moment and try again.';
      retryable = true;
    } else if (status >= 500) {
      message = 'Server error. Please try again later.';
      retryable = true;
    } else if (status >= 400) {
      message = serverMsg ?? dioDetail ?? 'Unable to complete that request.';
      retryable = false;
    } else {
      message = serverMsg ??
          dioDetail ??
          'Unable to load data. Please try again.';
    }

    return AppError(
      userMessage: message,
      cause: e,
      stackTrace: stackTrace,
      retryable: retryable,
    );
  }

  static String? _nonEmpty(String? s) {
    if (s == null || s.trim().isEmpty) return null;
    return s.trim();
  }

  static String? _trimServerMessage(dynamic data) {
    if (data is Map<String, dynamic>) {
      final detail = data['detail'];
      if (detail is String && detail.trim().isNotEmpty) {
        return detail.trim();
      }
      if (detail is List && detail.isNotEmpty) {
        final first = detail.first;
        if (first is Map) {
          final msg = first['msg'];
          if (msg is String && msg.trim().isNotEmpty) {
            return msg.trim();
          }
        }
      }
      final err = data['error'];
      if (err is Map) {
        final m = err['message'];
        if (m is String && m.trim().isNotEmpty) {
          return m.trim();
        }
      }
      final message = data['message'];
      if (message is String && message.trim().isNotEmpty) {
        return message.trim();
      }
    }
    if (data is String && data.trim().isNotEmpty) {
      return data.trim();
    }
    return null;
  }
}
