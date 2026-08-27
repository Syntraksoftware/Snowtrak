import 'package:dio/dio.dart';
import 'package:snowtrak/models/follow_stats.dart';

/// `/api/v1/follows` on community-backend.
///
/// Not under `/users` — that domain belongs to main-backend, and the follow
/// graph lives next to the feed that reads it. See docs/service-ownership.md.
class FollowApi {
  FollowApi({required Dio dio}) : _dio = dio;

  final Dio _dio;

  Future<FollowStats> getStats(String userId) async {
    final response = await _dio.get<Map<String, dynamic>>('/follows/$userId/stats');
    final data = response.data;
    if (data == null) {
      throw const FormatException('Follow stats response was empty');
    }
    return FollowStats.fromJson(data);
  }

  Future<void> follow(String userId) => _dio.post<void>('/follows/$userId');

  Future<void> unfollow(String userId) => _dio.delete<void>('/follows/$userId');

  /// People who follow [userId], newest first.
  Future<List<Map<String, dynamic>>> getFollowers(
    String userId, {
    int limit = 20,
    int offset = 0,
  }) =>
      _list('/follows/$userId/followers', limit: limit, offset: offset);

  /// People [userId] follows, newest first.
  Future<List<Map<String, dynamic>>> getFollowing(
    String userId, {
    int limit = 20,
    int offset = 0,
  }) =>
      _list('/follows/$userId/following', limit: limit, offset: offset);

  Future<List<Map<String, dynamic>>> _list(
    String path, {
    required int limit,
    required int offset,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      path,
      queryParameters: {'limit': limit, 'offset': offset},
    );
    final items = response.data?['items'];
    if (items is! List) {
      throw const FormatException('Follow list response had no items');
    }
    return items.cast<Map<String, dynamic>>();
  }

  /// Drop somebody who follows you.
  Future<void> removeFollower(String userId) =>
      _dio.delete<void>('/follows/me/followers/$userId');
}
