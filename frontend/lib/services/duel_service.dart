import 'package:snowtrak/core/errors/app_error.dart';
import 'package:snowtrak/core/errors/app_result.dart';
import 'package:snowtrak/models/duel.dart';
import 'package:snowtrak/services/apis/duel_api.dart';

/// ponytail: no repository layer, matching FollowService.
class DuelService {
  DuelService({required DuelApi duelApi}) : _api = duelApi;

  final DuelApi _api;

  Future<AppResult<Duel>> challenge({
    required String opponentId,
    required DuelMetric metric,
    required DuelDuration duration,
  }) =>
      _run(() => _api.create(
            opponentId: opponentId,
            metric: metric,
            duration: duration,
          ));

  Future<AppResult<List<Duel>>> list({
    DuelStatus? status,
    int limit = 20,
    int offset = 0,
  }) =>
      _run(() => _api.list(status: status, limit: limit, offset: offset));

  Future<AppResult<Duel>> get(String duelId) => _run(() => _api.get(duelId));

  Future<AppResult<Duel>> accept(String duelId) =>
      _run(() => _api.accept(duelId));

  Future<AppResult<Duel>> decline(String duelId) =>
      _run(() => _api.decline(duelId));

  Future<AppResult<Duel>> cancel(String duelId) =>
      _run(() => _api.cancel(duelId));

  Future<AppResult<DuelRecord>> record(String userId) =>
      _run(() => _api.record(userId));

  Future<AppResult<T>> _run<T>(Future<T> Function() fn) async {
    try {
      return AppSuccess(await fn());
    } catch (e, st) {
      return AppFailure(AppError.from(e, st));
    }
  }
}
