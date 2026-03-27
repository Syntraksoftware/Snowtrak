import 'package:dio/dio.dart';

class CommunityApi {
  CommunityApi({required Dio dio}) : _dio = dio;

  final Dio _dio;

  List<Map<String, dynamic>> _parseListItems(dynamic data, String legacyKey) {
    if (data is Map) {
      final typed = Map<String, dynamic>.from(data);
      if (typed['items'] is List) {
        return List<Map<String, dynamic>>.from(typed['items']);
      }
      if (typed[legacyKey] is List) {
        return List<Map<String, dynamic>>.from(typed[legacyKey]);
      }
    }
    return [];
  }

  Future<List<Map<String, dynamic>>> getSubthreads({int limit = 50}) async {
    final response = await _dio.get(
      '/subthreads',
      queryParameters: {
        'limit': limit,
      },
    );

    return _parseListItems(response.data, 'subthreads');
  }

  Future<List<Map<String, dynamic>>> getPostsBySubthread(
    String subthreadId, {
    int limit = 20,
    int offset = 0,
  }) async {
    final response = await _dio.get(
      '/subthreads/$subthreadId/posts',
      queryParameters: {
        'limit': limit,
        'offset': offset,
      },
    );

    return _parseListItems(response.data, 'posts');
  }

  Future<List<Map<String, dynamic>>> getCommentsByPost(String postId) async {
    final response = await _dio.get('/posts/$postId/comments');
    return _parseListItems(response.data, 'comments');
  }

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

    return _parseListItems(response.data, 'posts');
  }

  Future<Map<String, dynamic>> createPost({
    required String subthreadId,
    required String title,
    required String content,
  }) async {
    final response = await _dio.post(
      '/posts',
      data: {
        'subthread_id': subthreadId,
        'title': title,
        'content': content,
      },
    );

    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<Map<String, dynamic>> createComment({
    required String postId,
    required String content,
    String? parentId,
  }) async {
    final payload = <String, dynamic>{
      'post_id': postId,
      'content': content,
    };
    if (parentId != null && parentId.trim().isNotEmpty) {
      payload['parent_id'] = parentId;
    }

    final response = await _dio.post('/comments', data: payload);
    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<Map<String, dynamic>> votePost({
    required String postId,
    required int voteType,
  }) async {
    final response = await _dio.post(
      '/posts/$postId/vote',
      data: {
        'vote_type': voteType,
      },
    );

    return Map<String, dynamic>.from(response.data as Map);
  }
}
