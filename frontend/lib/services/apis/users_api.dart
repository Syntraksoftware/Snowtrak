import 'dart:io';

import 'package:dio/dio.dart';
import 'package:syntrak/models/profile.dart';
import 'package:syntrak/models/user.dart';
import 'package:syntrak/services/service_registry.dart';

class UsersApi {
  UsersApi({Dio? dio}) : _dio = dio ?? ServiceRegistry.instance.main;

  final Dio _dio;

  Future<User> getCurrentUser() async {
    final response = await _dio.get('/users/me');
    return User.fromJson(response.data);
  }

  Future<User> updateUserProfile({String? firstName, String? lastName}) async {
    final response = await _dio.put('/users/me', data: {
      if (firstName != null) 'first_name': firstName,
      if (lastName != null) 'last_name': lastName,
    });
    return User.fromJson(response.data);
  }

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
    final response = await _dio.get('/users/$userId/profile');
    return Profile.fromJson(response.data);
  }

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
      options: Options(contentType: 'multipart/form-data'),
    );

    return Profile.fromJson(response.data);
  }
}
