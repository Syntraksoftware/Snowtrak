import 'dart:io';
import 'package:dio/dio.dart';
import 'package:syntrak/core/config/app_config.dart';
import 'package:syntrak/core/config/app_environment.dart';
import 'package:syntrak/core/network/auth_token_store.dart';
import 'package:syntrak/features/activities/data/activities_repository.dart';
import 'package:syntrak/features/auth/data/auth_repository.dart';
import 'package:syntrak/features/community/data/community_repository.dart';
import 'package:syntrak/features/profile/data/profile_repository.dart';
import 'package:syntrak/models/activity.dart';
import 'package:syntrak/models/profile.dart';
import 'package:syntrak/models/user.dart';

class ApiService {
  final AuthRepository _authRepository;
  final ProfileRepository _profileRepository;
  final ActivitiesRepository _activitiesRepository;
  final CommunityRepository _communityRepository;
  final AuthTokenStore _tokenStore;
  final AppConfig _appConfig;

  ApiService({
    required AuthRepository authRepository,
    required ProfileRepository profileRepository,
    required ActivitiesRepository activitiesRepository,
    required CommunityRepository communityRepository,
    required AuthTokenStore tokenStore,
    required AppConfig appConfig,
  })  : _authRepository = authRepository,
        _profileRepository = profileRepository,
        _activitiesRepository = activitiesRepository,
        _communityRepository = communityRepository,
        _tokenStore = tokenStore,
        _appConfig = appConfig;

  void setToken(String? token) {
    _tokenStore.setToken(token);
  }

  bool get isDevEnvironment => _appConfig.environment == AppEnvironment.dev;

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

  Future<Map<String, dynamic>> refreshToken(String refreshToken) async {
    return _authRepository.refreshToken(refreshToken);
  }

  Future<User> getCurrentUser() async {
    return _profileRepository.getCurrentUser();
  }

  Future<User> updateUserProfile({
    String? firstName,
    String? lastName,
  }) async {
    return _profileRepository.updateUserProfile(
      firstName: firstName,
      lastName: lastName,
    );
  }

  Future<Activity> createActivity(Activity activity) async {
    return _activitiesRepository.createActivity(activity);
  }

  Future<List<Activity>> getActivities({int page = 1, int limit = 20}) async {
    return _activitiesRepository.getActivities(page: page, limit: limit);
  }

  Future<Activity> getActivity(String id) async {
    return _activitiesRepository.getActivity(id);
  }

  Future<Activity> updateActivity(
    String id, {
    String? name,
    String? description,
    bool? isPublic,
  }) async {
    return _activitiesRepository.updateActivity(
      id,
      name: name,
      description: description,
      isPublic: isPublic,
    );
  }

  Future<void> deleteActivity(String id) async {
    await _activitiesRepository.deleteActivity(id);
  }

  Future<Profile> getCurrentUserProfile() async {
    return _profileRepository.getCurrentUserProfile();
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
    return _profileRepository.updateProfile(
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
    return _profileRepository.getProfileById(userId);
  }

  Future<List<Map<String, dynamic>>> getPostsByUserId(
    String userId, {
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      return _communityRepository.getPostsByUserId(
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

  Future<List<Map<String, dynamic>>> getCommunitySubthreads({
    int limit = 50,
  }) async {
    return _communityRepository.getSubthreads(limit: limit);
  }

  Future<List<Map<String, dynamic>>> getCommunityPostsBySubthread(
    String subthreadId, {
    int limit = 20,
    int offset = 0,
  }) async {
    return _communityRepository.getPostsBySubthread(
      subthreadId,
      limit: limit,
      offset: offset,
    );
  }

  Future<List<Map<String, dynamic>>> getCommunityCommentsByPost(
    String postId,
  ) async {
    return _communityRepository.getCommentsByPost(postId);
  }

  Future<Map<String, dynamic>> createCommunityPost({
    required String subthreadId,
    required String title,
    required String content,
  }) async {
    return _communityRepository.createPost(
      subthreadId: subthreadId,
      title: title,
      content: content,
    );
  }

  Future<Map<String, dynamic>> createCommunityComment({
    required String postId,
    required String content,
    String? parentId,
  }) async {
    return _communityRepository.createComment(
      postId: postId,
      content: content,
      parentId: parentId,
    );
  }

  Future<Profile> uploadAvatar(File imageFile) async {
    return _profileRepository.uploadAvatar(imageFile);
  }
}
