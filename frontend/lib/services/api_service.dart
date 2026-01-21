import 'dart:io';
import 'package:dio/dio.dart';
import 'package:syntrak/models/activity.dart';
import 'package:syntrak/models/user.dart';
import 'package:syntrak/models/profile.dart';

class ApiService {
  final Dio _dio = Dio();
  String? _token;

  // Use 127.0.0.1 instead of localhost for iOS simulator compatibility

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
      // Build request data, only including non-null optional fields
      final data = <String, dynamic>{
        'email': email,
        'password': password,
      };

      // Only add optional fields if they are not null and not empty
      if (firstName != null && firstName.isNotEmpty) {
        data['first_name'] = firstName;
      }
      if (lastName != null && lastName.isNotEmpty) {
        data['last_name'] = lastName;
      }

      final response = await _dio.post('/auth/register', data: data);
      return response.data;
    } on DioException catch (e) {
      // Log the full error for debugging
      print('🔴 Registration error: ${e.response?.statusCode}');
      print('🔴 Response data: ${e.response?.data}');

      // Extract error message from response
      if (e.response != null && e.response!.data != null) {
        final errorData = e.response!.data;

        // Try to extract error message
        if (errorData is Map) {
          // Try different error message fields
          String? errorMessage;
          if (errorData['error'] != null) {
            errorMessage = errorData['error'].toString();
          } else if (errorData['detail'] != null) {
            if (errorData['detail'] is String) {
              errorMessage = errorData['detail'];
            } else if (errorData['detail'] is List) {
              // Pydantic validation errors
              final errors = (errorData['detail'] as List).map((e) {
                if (e is Map) {
                  final loc = e['loc']?.join('.') ?? '';
                  final msg = e['msg'] ?? e.toString();
                  return '$loc: $msg';
                }
                return e.toString();
              }).join(', ');
              errorMessage = 'Validation error: $errors';
            }
          } else if (errorData['message'] != null) {
            errorMessage = errorData['message'].toString();
          }

          if (errorMessage != null) {
            throw Exception(errorMessage);
          }
        }
      }

      // Default error messages based on status code
      if (e.response?.statusCode == 409) {
        throw Exception(
            'An account with this email already exists. Please login instead.');
      } else if (e.response?.statusCode == 400) {
        throw Exception('Invalid registration data. Please check your input.');
      } else if (e.response?.statusCode == 422) {
        throw Exception(
            'Invalid registration data. Please check that your email is valid and password is at least 8 characters.');
      } else if (e.response?.statusCode == 500) {
        throw Exception('Server error. Please try again later.');
      }

      throw Exception('Registration failed: ${e.message ?? "Unknown error"}');
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

  Future<User> updateUserProfile({
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

  Future<Activity> updateActivity(
    String id, {
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

  // Profile endpoints
  Future<Profile> getCurrentUserProfile() async {
    final response = await _dio.get('/users/me/profile');
    return Profile.fromJson(response.data);
  }

  Future<Profile> updateProfile({
    String? fullName,
    String? username,
    String? bio,
    String? avatarUrl,
    String? pushToken,
    String? skiLevel,
    String? home,
  }) async {
    final response = await _dio.put('/users/me/profile', data: {
      if (fullName != null) 'full_name': fullName,
      if (username != null) 'username': username,
      if (bio != null) 'bio': bio,
      if (avatarUrl != null) 'avatar_url': avatarUrl,
      if (pushToken != null) 'push_token': pushToken,
      if (skiLevel != null) 'ski_level': skiLevel,
      if (home != null) 'home': home,
    });
    return Profile.fromJson(response.data);
  }

  Future<Profile> getProfileById(String userId) async {
    try {
      print('🔍 [ApiService] Getting profile for userId: $userId');
      //try to get profile by user id
      final response = await _dio
          .get(
        '/users/$userId/profile',
        options: Options(
          receiveTimeout: const Duration(seconds: 10),
        ),
      )
          .timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Request timeout. Please check your connection.');
        },
      );
      print(
          '🔍 [ApiService] Profile response received: ${response.statusCode}');
      return Profile.fromJson(response.data);
    } on DioException catch (e) {
      print('🔍 [ApiService] DioException: ${e.type} - ${e.message}');
      print(
          '🔍 [ApiService] Response: ${e.response?.statusCode} - ${e.response?.data}');
      // Extract error message from response
      if (e.response != null && e.response!.data != null) {
        final errorData = e.response!.data;
        if (errorData is Map && errorData['detail'] != null) {
          throw Exception(errorData['detail']);
        }
      }
      // Default error messages
      if (e.response?.statusCode == 401) {
        throw Exception('Authentication failed. Please login again.');
      } else if (e.response?.statusCode == 404) {
        throw Exception('Profile not found');
      } else if (e.response?.statusCode == 503) {
        throw Exception('Database not configured');
      } else if (e.response?.statusCode == 500) {
        throw Exception('Server error. Please try again later.');
      } else if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw Exception(
            'Connection timeout. Please check your internet connection.');
      } else if (e.type == DioExceptionType.connectionError) {
        throw Exception('Cannot connect to server. Is the backend running?');
      }
      throw Exception('Failed to get profile: ${e.message ?? "Unknown error"}');
    } catch (e) {
      print('🔍 [ApiService] General exception: $e');
      rethrow;
    }
  }

  // Posts endpoints (community backend)
  Future<List<Map<String, dynamic>>> getPostsByUserId(
    String userId, {
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      print('🔍 [ApiService] Getting posts for userId: $userId');
      // Note: This calls the community backend, not main backend
      // You may need to adjust the base URL or create a separate service
      final communityBaseUrl = 'http://127.0.0.1:5001/api';
      final dio = Dio(BaseOptions(
        baseUrl: communityBaseUrl,
        receiveTimeout: const Duration(seconds: 10),
      ));

      // Copy auth token if available
      if (_token != null) {
        dio.options.headers['Authorization'] = 'Bearer $_token';
        print('🔍 [ApiService] Token set for posts request');
      } else {
        print('🔍 [ApiService] No token available for posts request');
      }

      final response = await dio.get(
        '/posts/user/$userId',
        queryParameters: {
          'limit': limit,
          'offset': offset,
        },
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Request timeout. Please check your connection.');
        },
      );

      print('🔍 [ApiService] Posts response received: ${response.statusCode}');
      if (response.data is Map && response.data['posts'] != null) {
        final posts = List<Map<String, dynamic>>.from(response.data['posts']);
        print('🔍 [ApiService] Returning ${posts.length} posts');
        return posts;
      }
      print('🔍 [ApiService] No posts in response, returning empty list');
      return [];
    } on DioException catch (e) {
      print(
          '🔍 [ApiService] DioException getting posts: ${e.type} - ${e.message}');
      print(
          '🔍 [ApiService] Response: ${e.response?.statusCode} - ${e.response?.data}');
      // Return empty list on error instead of throwing
      return [];
    } catch (e) {
      print('🔍 [ApiService] General exception getting posts: $e');
      return [];
    }
  }

  // Avatar upload endpoint
  Future<Profile> uploadAvatar(File imageFile) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(
        imageFile.path,
        filename: imageFile.path.split('/').last,
      ),
    });

    final response = await _dio.post(
      '/users/me/profile/avatar',
      data: formData,
      options: Options(
        contentType: 'multipart/form-data',
      ),
    );

    return Profile.fromJson(response.data);
  }
}
