import 'dart:io';
import 'package:dio/dio.dart';
import 'package:syntrak/models/activity.dart';
import 'package:syntrak/models/user.dart';
import 'package:syntrak/models/profile.dart';
import 'package:syntrak/services/apis/activities_api.dart';
import 'package:syntrak/services/apis/auth_api.dart';
import 'package:syntrak/services/apis/community_api.dart';
import 'package:syntrak/services/apis/users_api.dart';
import 'package:syntrak/services/service_registry.dart';

class ApiService {
  final AuthApi _authApi;
  final UsersApi _usersApi;
  final ActivitiesApi _activitiesApi;
  final CommunityApi _communityApi;

  ApiService({
    AuthApi? authApi,
    UsersApi? usersApi,
    ActivitiesApi? activitiesApi,
    CommunityApi? communityApi,
  })  : _authApi = authApi ?? AuthApi(),
        _usersApi = usersApi ?? UsersApi(),
        _activitiesApi = activitiesApi ?? ActivitiesApi(),
        _communityApi = communityApi ?? CommunityApi();

  void setToken(String? token) {
    ServiceRegistry.instance.setToken(token);
  }

  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    String? firstName,
    String? lastName,
  }) async {
    try {
      return _authApi.register(
        email: email,
        password: password,
        firstName: firstName,
        lastName: lastName,
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 409) {
        throw Exception(
            'An account with this email already exists. Please login instead.');
      }
      if (e.response?.statusCode == 422) {
        throw Exception(
            'Invalid registration data. Please check that your email is valid and password is at least 8 characters.');
      }
      throw Exception('Registration failed: ${e.message ?? "Unknown error"}');
    }
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      return _authApi.login(email: email, password: password);
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw Exception('Invalid email or password. Please try again.');
      }
      if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw Exception('Cannot connect to auth server at 127.0.0.1:8080.');
      }
      throw Exception('Login failed: ${e.message}');
    }
  }

  Future<Map<String, dynamic>> refreshToken(String refreshToken) async {
    return _authApi.refreshToken(refreshToken);
  }

  Future<User> getCurrentUser() async {
    return _usersApi.getCurrentUser();
  }

  Future<User> updateUserProfile({
    String? firstName,
    String? lastName,
  }) async {
    return _usersApi.updateUserProfile(firstName: firstName, lastName: lastName);
  }

  Future<Activity> createActivity(Activity activity) async {
    return _activitiesApi.createActivity(activity);
  }

  Future<List<Activity>> getActivities({int page = 1, int limit = 20}) async {
    return _activitiesApi.getActivities(page: page, limit: limit);
  }

  Future<Activity> getActivity(String id) async {
    return _activitiesApi.getActivity(id);
  }

  Future<Activity> updateActivity(
    String id, {
    String? name,
    String? description,
    bool? isPublic,
  }) async {
    return _activitiesApi.updateActivity(
      id,
      name: name,
      description: description,
      isPublic: isPublic,
    );
  }

  Future<void> deleteActivity(String id) async {
    await _activitiesApi.deleteActivity(id);
  }

  Future<Profile> getCurrentUserProfile() async {
    return _usersApi.getCurrentUserProfile();
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
    return _usersApi.updateProfile(
      fullName: fullName,
      username: username,
      bio: bio,
      avatarUrl: avatarUrl,
      pushToken: pushToken,
      skiLevel: skiLevel,
      home: home,
    );
  }

  Future<Profile> getProfileById(String userId) async {
    return _usersApi.getProfileById(userId);
  }

  Future<List<Map<String, dynamic>>> getPostsByUserId(
    String userId, {
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      return _communityApi.getPostsByUserId(
        userId,
        limit: limit,
        offset: offset,
      );
    } on DioException {
      return [];
    } catch (_) {
      return [];
    }
  }

  Future<Profile> uploadAvatar(File imageFile) async {
    return _usersApi.uploadAvatar(imageFile);
  }
}
