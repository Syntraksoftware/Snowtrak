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

  /// Follow, or ask to. Returns `following` or `requested` — a private
  /// account turns the first into the second and the client cannot guess.
  Future<String> follow(String userId) async {
    final response = await _dio.post<Map<String, dynamic>>('/follows/$userId');
    return response.data?['state'] as String? ?? 'following';
  }

  Future<void> unfollow(String userId) => _dio.delete<void>('/follows/$userId');

  /// Take back a request you sent.
  Future<void> withdrawRequest(String userId) =>
      _dio.delete<void>('/follows/$userId/request');

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

  /// People asking to follow you, newest first.
  Future<List<Map<String, dynamic>>> getRequests({
    int limit = 20,
    int offset = 0,
  }) =>
      _list('/follows/me/requests', limit: limit, offset: offset);

  Future<void> approveRequest(String userId) =>
      _dio.post<void>('/follows/me/requests/$userId/approve');

  Future<void> denyRequest(String userId) =>
      _dio.delete<void>('/follows/me/requests/$userId');
}
