import 'package:dio/dio.dart';
import 'package:snowtrak/models/duel.dart';
import 'package:snowtrak/models/leaderboard_entry.dart';

/// `/api/v1/leaderboard` on activity-backend.
///
/// The board aggregates `activities`, so it lives with the activities, not
/// with the follow graph. See docs/service-ownership.md.
class LeaderboardApi {
  LeaderboardApi({required Dio dio}) : _dio = dio;

  final Dio _dio;

  Future<Leaderboard> getBoard({
    DuelMetric metric = DuelMetric.vertical,
    String scope = globalScope,
    int limit = 50,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/leaderboard',
      queryParameters: {
        'metric': metric.value,
        'scope': scope,
        'limit': limit,
      },
    );
    final data = response.data;
    if (data == null) {
      throw const FormatException('Leaderboard response was empty');
    }
    return Leaderboard.fromJson(data);
  }

  /// A settled week. [week] is the ISO date of its Monday.
  Future<Leaderboard> getWeek(
    String week, {
    DuelMetric metric = DuelMetric.vertical,
    String scope = globalScope,
    int limit = 50,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/leaderboard/weeks/$week',
      queryParameters: {
        'metric': metric.value,
        'scope': scope,
        'limit': limit,
      },
    );
    final data = response.data;
    if (data == null) {
      throw const FormatException('Leaderboard week response was empty');
    }
    return Leaderboard.fromJson(data);
  }

  Future<LeaderboardPlacing> getMyPlacing({
    DuelMetric metric = DuelMetric.vertical,
    String scope = globalScope,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/leaderboard/me',
      queryParameters: {'metric': metric.value, 'scope': scope},
    );
    final data = response.data;
    if (data == null) {
      throw const FormatException('Leaderboard placing response was empty');
    }
    return LeaderboardPlacing.fromJson(data);
  }
}
