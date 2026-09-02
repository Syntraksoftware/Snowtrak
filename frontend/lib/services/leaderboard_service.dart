import 'package:snowtrak/core/errors/app_error.dart';
import 'package:snowtrak/core/errors/app_result.dart';
import 'package:snowtrak/models/duel.dart';
import 'package:snowtrak/models/leaderboard_entry.dart';
import 'package:snowtrak/services/apis/leaderboard_api.dart';

/// ponytail: no repository layer, matching FollowService. Add one if the
/// board ever needs an offline cache.
class LeaderboardService {
  LeaderboardService({required LeaderboardApi leaderboardApi})
      : _api = leaderboardApi;

  final LeaderboardApi _api;

  Future<AppResult<Leaderboard>> getBoard({
    DuelMetric metric = DuelMetric.vertical,
    String scope = globalScope,
    int limit = 50,
  }) =>
      _run(() => _api.getBoard(metric: metric, scope: scope, limit: limit));

  Future<AppResult<Leaderboard>> getWeek(
    String week, {
    DuelMetric metric = DuelMetric.vertical,
    String scope = globalScope,
    int limit = 50,
  }) =>
      _run(() => _api.getWeek(week, metric: metric, scope: scope, limit: limit));

  Future<AppResult<LeaderboardPlacing>> getMyPlacing({
    DuelMetric metric = DuelMetric.vertical,
    String scope = globalScope,
  }) =>
      _run(() => _api.getMyPlacing(metric: metric, scope: scope));

  Future<AppResult<T>> _run<T>(Future<T> Function() fn) async {
    try {
      return AppSuccess(await fn());
    } catch (e, st) {
      return AppFailure(AppError.from(e, st));
    }
  }
}
