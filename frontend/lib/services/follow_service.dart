import 'package:snowtrak/core/errors/app_error.dart';
import 'package:snowtrak/core/errors/app_result.dart';
import 'package:snowtrak/models/follow_stats.dart';
import 'package:snowtrak/services/apis/follow_api.dart';

/// ponytail: no repository layer. The other repositories here forward calls
/// verbatim to their api, and one more pass-through file buys nothing. Add one
/// if follow ever needs caching or an outbox.
class FollowService {
  FollowService({required FollowApi followApi}) : _followApi = followApi;

  final FollowApi _followApi;

  Future<AppResult<FollowStats>> getStats(String userId) =>
      _run(() => _followApi.getStats(userId));

  Future<AppResult<String>> follow(String userId) =>
      _run(() => _followApi.follow(userId));

  Future<AppResult<void>> unfollow(String userId) =>
      _run(() => _followApi.unfollow(userId));

  Future<AppResult<void>> withdrawRequest(String userId) =>
      _run(() => _followApi.withdrawRequest(userId));

  Future<AppResult<List<Map<String, dynamic>>>> getFollowers(
    String userId, {
    int limit = 20,
    int offset = 0,
  }) =>
      _run(() => _followApi.getFollowers(userId, limit: limit, offset: offset));

  Future<AppResult<List<Map<String, dynamic>>>> getFollowing(
    String userId, {
    int limit = 20,
    int offset = 0,
  }) =>
      _run(() => _followApi.getFollowing(userId, limit: limit, offset: offset));

  Future<AppResult<void>> removeFollower(String userId) =>
      _run(() => _followApi.removeFollower(userId));

  Future<AppResult<List<Map<String, dynamic>>>> getRequests({
    int limit = 20,
    int offset = 0,
  }) =>
      _run(() => _followApi.getRequests(limit: limit, offset: offset));

  Future<AppResult<void>> approveRequest(String userId) =>
      _run(() => _followApi.approveRequest(userId));

  Future<AppResult<void>> denyRequest(String userId) =>
      _run(() => _followApi.denyRequest(userId));

  Future<AppResult<T>> _run<T>(Future<T> Function() fn) async {
    try {
      return AppSuccess(await fn());
    } catch (e, st) {
      return AppFailure(AppError.from(e, st));
    }
  }
}
