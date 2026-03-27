import 'dart:io';

import 'package:syntrak/models/profile.dart';
import 'package:syntrak/models/user.dart';
import 'package:syntrak/services/apis/users_api.dart';

class ProfileRepository {
  ProfileRepository(this._api);

  final UsersApi _api;

  Future<User> getCurrentUser() {
    return _api.getCurrentUser();
  }

  Future<User> updateUserProfile({String? firstName, String? lastName}) {
    return _api.updateUserProfile(firstName: firstName, lastName: lastName);
  }

  Future<Profile> getCurrentUserProfile() {
    return _api.getCurrentUserProfile();
  }

  Future<Profile> updateProfile({
    String? fullName,
    String? username,
    String? bio,
    String? avatarUrl,
    String? pushToken,
    String? skiLevel,
    String? home,
  }) {
    return _api.updateProfile(
      fullName: fullName,
      username: username,
      bio: bio,
      avatarUrl: avatarUrl,
      pushToken: pushToken,
      skiLevel: skiLevel,
      home: home,
    );
  }

  Future<Profile> getProfileById(String userId) {
    return _api.getProfileById(userId);
  }

  Future<Profile> uploadAvatar(File imageFile) {
    return _api.uploadAvatar(imageFile);
  }
}
