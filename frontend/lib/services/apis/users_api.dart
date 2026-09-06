import 'dart:io';

import 'package:dio/dio.dart';
import 'package:snowtrak/models/profile.dart';
import 'package:snowtrak/models/user.dart';

class UsersApi {
  UsersApi({required Dio dio}) : _dio = dio;

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

  /// Updates the presentation fields `profiles` owns.
  ///
  /// No `full_name`: migration 022 dropped that column, so the field was
  /// accepted, dropped by Pydantic and answered 200 -- a save that did
  /// nothing. The name is written through [updateUserProfile].
  Future<Profile> updateProfile({
    String? bio,
    String? avatarUrl,
    String? pushToken,
    String? skiLevel,
    String? home,
  }) async {
    final response = await _dio.put('/users/me/profile', data: {
      if (bio != null) 'bio': bio,
      if (avatarUrl != null) 'avatar_url': avatarUrl,
      if (pushToken != null) 'push_token': pushToken,
      if (skiLevel != null) 'ski_level': skiLevel,
      if (home != null) 'home': home,
    });
    return Profile.fromJson(response.data);
  }

  /// Sets or clears the caller's chosen handle via its own endpoint --
  /// separate from [updateProfile] because a taken handle (409) is a
  /// different failure mode than the rest of the profile fields.
  Future<String?> setUsername(String? username) async {
    final response = await _dio.put<Map<String, dynamic>>(
      '/users/me/username',
      data: {'username': username},
    );
    return response.data?['username'] as String?;
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
