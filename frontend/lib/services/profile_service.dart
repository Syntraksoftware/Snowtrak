import 'dart:io';

import 'package:syntrak/features/profile/data/profile_repository.dart';
import 'package:syntrak/models/profile.dart';
import 'package:syntrak/models/user.dart';

class ProfileService {
  ProfileService({required ProfileRepository profileRepository})
      : _profileRepository = profileRepository;

  final ProfileRepository _profileRepository;

  Future<User> getCurrentUser() {
    return _profileRepository.getCurrentUser();
  }

  Future<User> updateUserProfile({
    String? firstName,
    String? lastName,
  }) {
    return _profileRepository.updateUserProfile(
      firstName: firstName,
      lastName: lastName,
    );
  }

  Future<Profile> getCurrentUserProfile() {
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
  }) {
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

  Future<Profile> getProfileById(String userId) {
    return _profileRepository.getProfileById(userId);
  }

  Future<Profile> uploadAvatar(File imageFile) {
    return _profileRepository.uploadAvatar(imageFile);
  }
}
