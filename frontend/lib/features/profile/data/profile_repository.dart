import 'dart:io';

import 'package:snowtrak/models/profile.dart';
import 'package:snowtrak/models/user.dart';
import 'package:snowtrak/services/apis/users_api.dart';

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
    String? bio,
    String? avatarUrl,
    String? pushToken,
    String? skiLevel,
    String? home,
  }) {
    return _api.updateProfile(
      bio: bio,
      avatarUrl: avatarUrl,
      pushToken: pushToken,
      skiLevel: skiLevel,
      home: home,
    );
  }

  Future<String?> setUsername(String? username) {
    return _api.setUsername(username);
  }

  Future<Profile> getProfileById(String userId) {
    return _api.getProfileById(userId);
  }

  Future<Profile> uploadAvatar(File imageFile) {
    return _api.uploadAvatar(imageFile);
  }
}
