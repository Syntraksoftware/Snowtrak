import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import 'package:syntrak/services/apis/community_api_helpers.dart';

class CommunityApi {
  CommunityApi({required Dio dio}) : _dio = dio;

  final Dio _dio;

  /// Parses a list payload. Does not return `[]` on unexpected shapes (avoids
  /// masking API/parsing failures as an empty feed).
  List<Map<String, dynamic>> _parseListItems(dynamic data, String legacyKey) {
    return CommunityApiHelpers.parseListItems(data, legacyKey);
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

  Future<Map<String, dynamic>> createSubthread({
    required String name,
    String? description,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/subthreads',
      data: <String, dynamic>{
        'name': name,
        if (description != null && description.trim().isNotEmpty)
          'description': description,
      },
    );
    final data = response.data;
    if (data == null) {
      throw const FormatException('Create subthread response was empty');
    }
    return Map<String, dynamic>.from(data);
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

  /// Global feed: all posts across subthreads, newest first.
  Future<List<Map<String, dynamic>>> getFeedPosts({
    int limit = 20,
    int offset = 0,
  }) async {
    final response = await _dio.get(
      '/feed',
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

  Future<List<Map<String, dynamic>>> getPostConversation(String postId) async {
    final response = await _dio.get('/posts/$postId/conversation');
    return _parseListItems(response.data, 'comments');
  }

  /// One HTTP round trip for comments on many posts (backend Supabase `in` query).
  Future<Map<String, List<Map<String, dynamic>>>> getCommentsForPosts(
    List<String> postIds,
  ) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/posts/comments/batch',
      data: <String, dynamic>{'post_ids': postIds},
    );
    final data = response.data;
    if (data == null) {
      throw const FormatException('Batch comments response was empty');
    }
    final items = data['items'];
    if (items is! List) {
      throw const FormatException(
        'Batch comments response missing items list',
      );
    }
    final out = <String, List<Map<String, dynamic>>>{};
    for (final el in items) {
      if (el is! Map) {
        continue;
      }
      final bundle = Map<String, dynamic>.from(el);
      final pid = bundle['post_id']?.toString() ?? '';
      if (pid.isEmpty) {
        continue;
      }
      final rawList = bundle['comments'];
      if (rawList is! List) {
        out[pid] = [];
        continue;
      }
      out[pid] = [
        for (final c in rawList) Map<String, dynamic>.from(c as Map),
      ];
    }
    return out;
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
    String? quotedPostId,
    String? repostOfPostId,
    String? quotedCommentId,
    String? repostOfCommentId,
    List<String>? mediaUrls,
  }) async {
    // Trailing slash required: POST /api/v1/posts -> 307 to /api/v1/posts/ and Dio
    // mishandles POST body on redirect, breaking creates from the app.
    final response = await _dio.post(
      '/posts/',
      data: {
        'subthread_id': subthreadId,
        'title': title,
        'content': content,
        if (quotedPostId != null && quotedPostId.isNotEmpty)
          'quoted_post_id': quotedPostId,
        if (repostOfPostId != null && repostOfPostId.isNotEmpty)
          'repost_of_post_id': repostOfPostId,
        if (quotedCommentId != null && quotedCommentId.isNotEmpty)
          'quoted_comment_id': quotedCommentId,
        if (repostOfCommentId != null && repostOfCommentId.isNotEmpty)
          'repost_of_comment_id': repostOfCommentId,
        if (mediaUrls != null && mediaUrls.isNotEmpty) 'media_urls': mediaUrls,
      },
    );

    return Map<String, dynamic>.from(response.data as Map);
  }

  /// Single file → public URL for [media_urls] on post/comment create.
  Future<String> uploadMedia(XFile file) async {
    final path = file.path;
    if (path.isEmpty) {
      throw const FormatException('File path missing (web upload not supported here)');
    }
    final mime = CommunityApiHelpers.mimeTypeForUploadFilename(file.name);
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(
        path,
        filename: file.name,
        contentType: MediaType.parse(mime),
      ),
    });
    final response = await _dio.post<Map<String, dynamic>>(
      '/media/upload',
      data: formData,
    );
    final data = response.data;
    final url = data?['url']?.toString();
    if (url == null || url.isEmpty) {
      throw const FormatException('Upload response missing url');
    }
    return url;
  }

  Future<Map<String, dynamic>> createComment({
    required String postId,
    required String content,
    String? parentId,
    List<String>? mediaUrls,
  }) async {
    final payload = <String, dynamic>{
      'post_id': postId,
      'content': content,
    };
    if (parentId != null && parentId.trim().isNotEmpty) {
      payload['parent_id'] = parentId;
    }
    if (mediaUrls != null && mediaUrls.isNotEmpty) {
      payload['media_urls'] = mediaUrls;
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

  Future<Map<String, dynamic>> repostPost({
    required String postId,
  }) async {
    final response = await _dio.post('/posts/$postId/repost');
    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<Map<String, dynamic>> undoRepost({
    required String postId,
  }) async {
    final response = await _dio.delete('/posts/$postId/repost');
    return Map<String, dynamic>.from(response.data as Map);
  }
}
