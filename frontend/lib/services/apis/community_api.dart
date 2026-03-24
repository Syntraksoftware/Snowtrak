import 'package:dio/dio.dart';
import 'package:syntrak/services/service_registry.dart';

class CommunityApi {
  CommunityApi({Dio? dio}) : _dio = dio ?? ServiceRegistry.instance.community;

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
