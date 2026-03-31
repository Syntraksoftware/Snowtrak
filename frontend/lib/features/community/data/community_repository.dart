import 'package:syntrak/services/apis/community_api.dart';

class CommunityRepository {
  CommunityRepository(this._api);

  final CommunityApi _api;

  Future<List<Map<String, dynamic>>> getSubthreads({int limit = 50}) {
    return _api.getSubthreads(limit: limit);
  }

  Future<Map<String, dynamic>> createSubthread({
    required String name,
    String? description,
  }) {
    return _api.createSubthread(name: name, description: description);
  }

  Future<List<Map<String, dynamic>>> getPostsBySubthread(
    String subthreadId, {
    int limit = 20,
    int offset = 0,
  }) {
    return _api.getPostsBySubthread(
      subthreadId,
      limit: limit,
      offset: offset,
    );
  }

  Future<List<Map<String, dynamic>>> getFeedPosts({
    int limit = 20,
    int offset = 0,
  }) {
    return _api.getFeedPosts(limit: limit, offset: offset);
  }

  Future<List<Map<String, dynamic>>> getCommentsByPost(String postId) {
    return _api.getCommentsByPost(postId);
  }

  Future<List<Map<String, dynamic>>> getPostConversation(String postId) {
    return _api.getPostConversation(postId);
  }

  Future<Map<String, List<Map<String, dynamic>>>> getCommentsForPosts(
    List<String> postIds,
  ) {
    return _api.getCommentsForPosts(postIds);
  }

  Future<List<Map<String, dynamic>>> getPostsByUserId(
    String userId, {
    int limit = 20,
    int offset = 0,
  }) {
    return _api.getPostsByUserId(userId, limit: limit, offset: offset);
  }

  Future<Map<String, dynamic>> createPost({
    required String subthreadId,
    required String title,
    required String content,
  }) {
    return _api.createPost(
      subthreadId: subthreadId,
      title: title,
      content: content,
    );
  }

  Future<Map<String, dynamic>> createComment({
    required String postId,
    required String content,
    String? parentId,
  }) {
    return _api.createComment(
      postId: postId,
      content: content,
      parentId: parentId,
    );
  }

  Future<Map<String, dynamic>> votePost({
    required String postId,
    required int voteType,
  }) {
    return _api.votePost(postId: postId, voteType: voteType);
  }

  Future<Map<String, dynamic>> repostPost({
    required String postId,
  }) {
    return _api.repostPost(postId: postId);
  }

  Future<Map<String, dynamic>> undoRepost({
    required String postId,
  }) {
    return _api.undoRepost(postId: postId);
  }
}
