import 'package:dio/dio.dart';
import 'package:syntrak/features/community/data/community_repository.dart';

class CommunityService {
  CommunityService({required CommunityRepository communityRepository})
      : _communityRepository = communityRepository;

  final CommunityRepository _communityRepository;

  Future<List<Map<String, dynamic>>> getPostsByUserId(
    String userId, {
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      return _communityRepository.getPostsByUserId(
        userId,
        limit: limit,
        offset: offset,
      );
    } on DioException {
      return [];
    } catch (_) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getSubthreads({int limit = 50}) {
    return _communityRepository.getSubthreads(limit: limit);
  }

  Future<List<Map<String, dynamic>>> getPostsBySubthread(
    String subthreadId, {
    int limit = 20,
    int offset = 0,
  }) {
    return _communityRepository.getPostsBySubthread(
      subthreadId,
      limit: limit,
      offset: offset,
    );
  }

  Future<List<Map<String, dynamic>>> getCommentsByPost(String postId) {
    return _communityRepository.getCommentsByPost(postId);
  }

  Future<Map<String, dynamic>> createPost({
    required String subthreadId,
    required String title,
    required String content,
  }) {
    return _communityRepository.createPost(
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
    return _communityRepository.createComment(
      postId: postId,
      content: content,
      parentId: parentId,
    );
  }

  Future<Map<String, dynamic>> votePost({
    required String postId,
    required int voteType,
  }) {
    return _communityRepository.votePost(
      postId: postId,
      voteType: voteType,
    );
  }
}
