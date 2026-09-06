import 'package:dio/dio.dart';

/// The account privacy flag, on main-backend.
///
/// The read side is `FollowStats.isPrivate`, which the profile header
/// already fetches via `FollowApi.getStats` -- this is the write half only.
class PrivacyApi {
  PrivacyApi({required Dio dio}) : _dio = dio;

  final Dio _dio;

  Future<bool> setPrivate(bool isPrivate) async {
    final response = await _dio.put<Map<String, dynamic>>(
      '/users/me/privacy',
      data: {'is_private': isPrivate},
    );
    return response.data?['is_private'] as bool? ?? isPrivate;
  }
}
