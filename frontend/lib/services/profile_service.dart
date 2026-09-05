import 'dart:io';

import 'package:dio/dio.dart';
import 'package:snowtrak/core/errors/app_error.dart';
import 'package:snowtrak/core/errors/app_result.dart';
import 'package:snowtrak/features/profile/data/profile_repository.dart';
import 'package:snowtrak/models/profile.dart';
import 'package:snowtrak/models/user.dart';

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
    String? bio,
    String? avatarUrl,
    String? pushToken,
    String? skiLevel,
    String? home,
  }) {
    return _run(() => _profileRepository.updateProfile(
          bio: bio,
          avatarUrl: avatarUrl,
          pushToken: pushToken,
          skiLevel: skiLevel,
          home: home,
        ));
  }

  /// Sets or clears the caller's chosen handle.
  ///
  /// Catches here, not in [_run], because a taken handle needs its own
  /// user-facing message rather than the generic 4xx copy `AppError.from`
  /// gives every other failure -- the same shape `AuthService.register`
  /// uses for its own 409.
  Future<AppResult<String?>> setUsername(String? username) async {
    try {
      return AppSuccess(await _profileRepository.setUsername(username));
    } on DioException catch (e) {
      if (e.response?.statusCode == 409) {
        return AppFailure(
          AppError(
            userMessage: 'That username is taken',
            cause: e,
            retryable: false,
          ),
        );
      }
      return AppFailure(AppError.from(e));
    } catch (e, st) {
      return AppFailure(AppError.from(e, st));
    }
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
