import 'package:dio/dio.dart';

class CommunityApi {
  CommunityApi({required Dio dio}) : _dio = dio;

  final Dio _dio;

  Future<List<Map<String, dynamic>>> getPostsByUserId(
    String userId, {
    int limit = 20,
    int offset = 0,
  }) async {
    final response = await _dio.get(
      '/posts/user/$userId',
      queryParameters: {
        'limit': limit,
        'offset': offset,
      },
    );

    if (response.data is Map && response.data['posts'] != null) {
      return List<Map<String, dynamic>>.from(response.data['posts']);
    }

    return [];
  }
}
