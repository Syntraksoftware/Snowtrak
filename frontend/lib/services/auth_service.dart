import 'package:dio/dio.dart';
import 'package:syntrak/core/config/app_config.dart';
import 'package:syntrak/core/config/app_environment.dart';
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

  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    String? firstName,
    String? lastName,
  }) async {
    try {
      return _authRepository.register(
        email: email,
        password: password,
        firstName: firstName,
        lastName: lastName,
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 409) {
        throw Exception(
          'An account with this email already exists. Please login instead.',
        );
      }
      if (e.response?.statusCode == 422) {
        throw Exception(
          'Invalid registration data. Please check that your email is valid and password is at least 8 characters.',
        );
      }
      throw Exception('Registration failed: ${e.message ?? "Unknown error"}');
    }
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      return _authRepository.login(email: email, password: password);
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw Exception('Invalid email or password. Please try again.');
      }
      if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw Exception(
          'Cannot connect to auth server at ${_appConfig.mainApiBaseUrl}.',
        );
      }
      throw Exception('Login failed: ${e.message}');
    }
  }

  Future<Map<String, dynamic>> refreshToken(String refreshToken) {
    return _authRepository.refreshToken(refreshToken);
  }
}
