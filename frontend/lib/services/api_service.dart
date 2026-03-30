import 'dart:io';

import 'package:syntrak/models/activity.dart';
import 'package:syntrak/models/profile.dart';
import 'package:syntrak/models/user.dart';
import 'package:syntrak/services/activities_service.dart';
import 'package:syntrak/services/auth_service.dart';
import 'package:syntrak/services/community_service.dart';
import 'package:syntrak/services/profile_service.dart';

class ApiService {
  final AuthService _authService;
  final ProfileService _profileService;
  final ActivitiesService _activitiesService;
  final CommunityService _communityService;

  ApiService({
    required AuthService authService,
    required ProfileService profileService,
    required ActivitiesService activitiesService,
    required CommunityService communityService,
  })  : _authService = authService,
        _profileService = profileService,
        _activitiesService = activitiesService,
        _communityService = communityService;

  void setToken(String? token) {
    _authService.setToken(token);
  }

  bool get isDevEnvironment => _activitiesService.isDevEnvironment;

  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    String? firstName,
    String? lastName,
  }) async {
    return _authService.register(
      email: email,
      password: password,
      firstName: firstName,
      lastName: lastName,
    );
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    return _authService.login(email: email, password: password);
  }

  Future<Map<String, dynamic>> refreshToken(String refreshToken) async {
    return _authService.refreshToken(refreshToken);
  }

  Future<User> getCurrentUser() async {
    return _profileService.getCurrentUser();
  }

  Future<User> updateUserProfile({
    String? firstName,
    String? lastName,
  }) async {
    return _profileService.updateUserProfile(
      firstName: firstName,
      lastName: lastName,
    );
  }

  Future<Activity> createActivity(Activity activity) async {
    return _activitiesService.createActivity(activity);
  }

  Future<List<Activity>> getActivities({int page = 1, int limit = 20}) async {
    return _activitiesService.getActivities(page: page, limit: limit);
  }

  Future<Activity> getActivity(String id) async {
    return _activitiesService.getActivity(id);
  }

  Future<Activity> updateActivity(
    String id, {
    String? name,
    String? description,
    bool? isPublic,
  }) async {
    return _activitiesService.updateActivity(
      id,
      name: name,
      description: description,
      isPublic: isPublic,
    );
  }

  Future<void> deleteActivity(String id) async {
    await _activitiesService.deleteActivity(id);
  }

  Future<Profile> getCurrentUserProfile() async {
    return _profileService.getCurrentUserProfile();
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
    return _profileService.updateProfile(
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
    return _profileService.getProfileById(userId);
  }

  Future<List<Map<String, dynamic>>> getPostsByUserId(
    String userId, {
    int limit = 20,
    int offset = 0,
  }) async {
    return _communityService.getPostsByUserId(
      userId,
      limit: limit,
      offset: offset,
    );
  }

  Future<List<Map<String, dynamic>>> getCommunitySubthreads({
    int limit = 50,
  }) async {
    return _communityService.getSubthreads(limit: limit);
  }

  Future<List<Map<String, dynamic>>> getCommunityPostsBySubthread(
    String subthreadId, {
    int limit = 20,
    int offset = 0,
  }) async {
    return _communityService.getPostsBySubthread(
      subthreadId,
      limit: limit,
      offset: offset,
    );
  }

  Future<List<Map<String, dynamic>>> getCommunityCommentsByPost(
    String postId,
  ) async {
    return _communityService.getCommentsByPost(postId);
  }

  Future<Map<String, dynamic>> createCommunityPost({
    required String subthreadId,
    required String title,
    required String content,
  }) async {
    return _communityService.createPost(
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
    return _communityService.createComment(
      postId: postId,
      content: content,
      parentId: parentId,
    );
  }

  Future<Map<String, dynamic>> voteCommunityPost({
    required String postId,
    required int voteType,
  }) async {
    return _communityService.votePost(
      postId: postId,
      voteType: voteType,
    );
  }

  Future<Profile> uploadAvatar(File imageFile) async {
    return _profileService.uploadAvatar(imageFile);
  }
}
