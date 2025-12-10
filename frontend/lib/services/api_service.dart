import 'package:dio/dio.dart';
import 'package:syntrak/models/activity.dart';
import 'package:syntrak/models/user.dart';

class ApiService {
  final Dio _dio = Dio();
  String? _token;

  // Use 127.0.0.1 instead of localhost for iOS simulator compatibility
  // For physical device, use your Mac's IP address (e.g., http://192.168.1.100:8080)
  static const String baseUrl = 'http://127.0.0.1:8080/api/v1';

  ApiService() {
    _dio.options.baseUrl = baseUrl;
    _dio.options.connectTimeout = const Duration(seconds: 30);
    _dio.options.receiveTimeout = const Duration(seconds: 30);
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        if (_token != null) {
          options.headers['Authorization'] = 'Bearer $_token';
        }
        return handler.next(options);
      },
      onError: (error, handler) {
        return handler.next(error);
      },
    ));
  }

  void setToken(String? token) {
    _token = token;
  }

  // Auth endpoints
  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    String? firstName,
    String? lastName,
  }) async {
    try {
      final response = await _dio.post('/auth/register', data: {
        'email': email,
        'password': password,
        'first_name': firstName,
        'last_name': lastName,
      });
      return response.data;
    } on DioException catch (e) {
      // Extract error message from response
      if (e.response != null && e.response!.data != null) {
        final errorData = e.response!.data;
        if (errorData is Map && errorData['error'] != null) {
          throw Exception(errorData['error']);
        }
      }
      // Default error messages
      if (e.response?.statusCode == 409) {
        throw Exception('An account with this email already exists. Please login instead.');
      } else if (e.response?.statusCode == 400) {
        throw Exception('Invalid registration data. Please check your input.');
      }
      throw Exception('Registration failed: ${e.message}');
    }
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post('/auth/login', data: {
        'email': email,
        'password': password,
      });
      return response.data;
    } on DioException catch (e) {
      // Extract error message from response
      if (e.response != null && e.response!.data != null) {
        final errorData = e.response!.data;
        if (errorData is Map && errorData['error'] != null) {
          throw Exception(errorData['error']);
        }
      }
      // Default error messages
      if (e.response?.statusCode == 401) {
        throw Exception('Invalid email or password. Please try again.');
      } else if (e.response?.statusCode == 400) {
        throw Exception('Invalid login data. Please check your input.');
      }
      throw Exception('Login failed: ${e.message}');
    }
  }

  Future<Map<String, dynamic>> refreshToken(String refreshToken) async {
    try {
      final response = await _dio.post('/auth/refresh', data: {
        'refresh_token': refreshToken,
      });
      return response.data;
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw Exception('Refresh token expired. Please login again.');
      }
      throw Exception('Token refresh failed: ${e.message}');
    }
  }

  // User endpoints
  Future<User> getCurrentUser() async {
    final response = await _dio.get('/users/me');
    return User.fromJson(response.data);
  }

  Future<User> updateProfile({
    String? firstName,
    String? lastName,
  }) async {
    final response = await _dio.put('/users/me', data: {
      if (firstName != null) 'first_name': firstName,
      if (lastName != null) 'last_name': lastName,
    });
    return User.fromJson(response.data);
  }

  // Activity endpoints
  Future<Activity> createActivity(Activity activity) async {
    final response = await _dio.post('/activities', data: activity.toJson());
    return Activity.fromJson(response.data);
  }

  Future<List<Activity>> getActivities({int page = 1, int limit = 20}) async {
    final response = await _dio.get('/activities', queryParameters: {
      'page': page,
      'limit': limit,
    });
    return (response.data as List)
        .map((json) => Activity.fromJson(json))
        .toList();
  }

  Future<Activity> getActivity(String id) async {
    final response = await _dio.get('/activities/$id');
    return Activity.fromJson(response.data);
  }

  Future<Activity> updateActivity(String id, {
    String? name,
    String? description,
    bool? isPublic,
  }) async {
    final response = await _dio.put('/activities/$id', data: {
      if (name != null) 'name': name,
      if (description != null) 'description': description,
      if (isPublic != null) 'is_public': isPublic,
    });
    return Activity.fromJson(response.data);
  }

  Future<void> deleteActivity(String id) async {
    await _dio.delete('/activities/$id');
  }
}

