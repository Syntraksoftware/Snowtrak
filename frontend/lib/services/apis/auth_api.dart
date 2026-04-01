import 'package:dio/dio.dart';

class AuthApi {
  AuthApi({required Dio dio}) : _dio = dio;

  final Dio _dio;

  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    String? firstName,
    String? lastName,
  }) async {
    final data = <String, dynamic>{
      'email': email,
      'password': password,
    };

    if (firstName != null && firstName.isNotEmpty) {
      data['first_name'] = firstName;
    }
    if (lastName != null && lastName.isNotEmpty) {
      data['last_name'] = lastName;
    }

    final response = await _dio.post('/auth/register', data: data);
    return Map<String, dynamic>.from(response.data);
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await _dio.post(
      '/auth/login',
      data: {
        'email': email.trim().toLowerCase(),
        'password': password,
      },
    );
    return Map<String, dynamic>.from(response.data);
  }

  Future<Map<String, dynamic>> refreshToken(String refreshToken) async {
    final response = await _dio.post(
      '/auth/refresh',
      data: {'refresh_token': refreshToken},
    );
    return Map<String, dynamic>.from(response.data);
  }
}
