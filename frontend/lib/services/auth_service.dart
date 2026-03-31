import 'package:dio/dio.dart';
import 'package:syntrak/core/config/app_config.dart';
import 'package:syntrak/core/config/app_environment.dart';
import 'package:syntrak/core/errors/app_error.dart';
import 'package:syntrak/core/errors/app_result.dart';
import 'package:syntrak/core/network/auth_token_store.dart';
import 'package:syntrak/features/auth/data/auth_repository.dart';

class AuthService {
  AuthService({
    required AuthRepository authRepository,
    required AuthTokenStore tokenStore,
    required AppConfig appConfig,
  })  : _authRepository = authRepository,
        _tokenStore = tokenStore,
        _appConfig = appConfig;

  final AuthRepository _authRepository;
  final AuthTokenStore _tokenStore;
  final AppConfig _appConfig;

  bool get isDevEnvironment => _appConfig.environment == AppEnvironment.dev;

  void setToken(String? token) {
    _tokenStore.setToken(token);
  }

  Future<AppResult<Map<String, dynamic>>> register({
    required String email,
    required String password,
    String? firstName,
    String? lastName,
  }) async {
    try {
      final data = await _authRepository.register(
        email: email,
        password: password,
        firstName: firstName,
        lastName: lastName,
      );
      return AppSuccess(data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 409) {
        return AppFailure(
          AppError(
            userMessage:
                'An account with this email already exists. Please login instead.',
            cause: e,
          ),
        );
      }
      if (e.response?.statusCode == 422) {
        return AppFailure(
          AppError(
            userMessage:
                'Invalid registration data. Please check that your email is valid and password is at least 8 characters.',
            cause: e,
          ),
        );
      }
      return AppFailure(AppError.from(e));
    } catch (e, st) {
      return AppFailure(AppError.from(e, st));
    }
  }

  Future<AppResult<Map<String, dynamic>>> login({
    required String email,
    required String password,
  }) async {
    try {
      final data = await _authRepository.login(email: email, password: password);
      return AppSuccess(data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        return AppFailure(
          AppError(
            userMessage: 'Invalid email or password. Please try again.',
            cause: e,
          ),
        );
      }
      if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        return AppFailure(
          AppError(
            userMessage:
                'Cannot connect to auth server at ${_appConfig.mainApiBaseUrl}.',
            cause: e,
          ),
        );
      }
      return AppFailure(AppError.from(e));
    } catch (e, st) {
      return AppFailure(AppError.from(e, st));
    }
  }

  Future<AppResult<Map<String, dynamic>>> refreshToken(String refreshToken) async {
    try {
      final data = await _authRepository.refreshToken(refreshToken);
      return AppSuccess(data);
    } catch (e, st) {
      return AppFailure(AppError.from(e, st));
    }
  }
}
