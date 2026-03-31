import 'dart:io';

import 'package:syntrak/core/errors/app_error.dart';
import 'package:syntrak/core/errors/app_result.dart';
import 'package:syntrak/features/profile/data/profile_repository.dart';
import 'package:syntrak/models/profile.dart';
import 'package:syntrak/models/user.dart';

class ProfileService {
  ProfileService({required ProfileRepository profileRepository})
      : _profileRepository = profileRepository;

  final ProfileRepository _profileRepository;

  Future<AppResult<User>> getCurrentUser() {
    return _run(() => _profileRepository.getCurrentUser());
  }

  Future<AppResult<User>> updateUserProfile({
    String? firstName,
    String? lastName,
  }) {
    return _run(() => _profileRepository.updateUserProfile(
          firstName: firstName,
          lastName: lastName,
        ));
  }

  Future<AppResult<Profile>> getCurrentUserProfile() {
    return _run(() => _profileRepository.getCurrentUserProfile());
  }

  Future<AppResult<Profile>> updateProfile({
    String? fullName,
    String? username,
    String? bio,
    String? avatarUrl,
    String? pushToken,
    String? skiLevel,
    String? home,
  }) {
    return _run(() => _profileRepository.updateProfile(
          fullName: fullName,
          username: username,
          bio: bio,
          avatarUrl: avatarUrl,
          pushToken: pushToken,
          skiLevel: skiLevel,
          home: home,
        ));
  }

  Future<AppResult<Profile>> getProfileById(String userId) {
    return _run(() => _profileRepository.getProfileById(userId));
  }

  Future<AppResult<Profile>> uploadAvatar(File imageFile) {
    return _run(() => _profileRepository.uploadAvatar(imageFile));
  }

  Future<AppResult<T>> _run<T>(Future<T> Function() fn) async {
    try {
      return AppSuccess(await fn());
    } catch (e, st) {
      return AppFailure(AppError.from(e, st));
    }
  }
}
