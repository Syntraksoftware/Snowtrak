import 'package:dio/dio.dart';
import 'package:snowtrak/models/duel.dart';

/// `/api/v1/duels` on activity-backend.
class DuelApi {
  DuelApi({required Dio dio}) : _dio = dio;

  final Dio _dio;

  /// Challenges someone who follows you back.
  ///
  /// The window is not sent: it opens when the opponent accepts, which is
  /// what keeps it non-retroactive.
  Future<Duel> create({
    required String opponentId,
    required DuelMetric metric,
    required DuelDuration duration,
  }) =>
      _one(
        () => _dio.post<Map<String, dynamic>>(
          '/duels',
          data: {
            'opponent_id': opponentId,
            'metric': metric.value,
            'duration': duration.value,
          },
        ),
      );

  Future<List<Duel>> list({
    DuelStatus? status,
    int limit = 20,
    int offset = 0,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/duels',
      queryParameters: {
        if (status != null) 'status': status.name,
        'limit': limit,
        'offset': offset,
      },
    );
    final items = response.data?['items'];
    if (items is! List) {
      throw const FormatException('Duel list response had no items');
    }
    return items
        .whereType<Map<String, dynamic>>()
        .map(Duel.fromJson)
        .toList();
  }

  Future<Duel> get(String duelId) =>
      _one(() => _dio.get<Map<String, dynamic>>('/duels/$duelId'));

  Future<Duel> accept(String duelId) =>
      _one(() => _dio.post<Map<String, dynamic>>('/duels/$duelId/accept'));

  Future<Duel> decline(String duelId) =>
      _one(() => _dio.post<Map<String, dynamic>>('/duels/$duelId/decline'));

  /// Withdraws a challenge the opponent has not answered.
  Future<Duel> cancel(String duelId) =>
      _one(() => _dio.delete<Map<String, dynamic>>('/duels/$duelId'));

  Future<DuelRecord> record(String userId) async {
    final response =
        await _dio.get<Map<String, dynamic>>('/users/$userId/duel_record');
    final data = response.data;
    if (data == null) {
      throw const FormatException('Duel record response was empty');
    }
    return DuelRecord.fromJson(data);
  }

  Future<Duel> _one(
    Future<Response<Map<String, dynamic>>> Function() request,
  ) async {
    final response = await request();
    final data = response.data;
    if (data == null) {
      throw const FormatException('Duel response was empty');
    }
    return Duel.fromJson(data);
  }
}
