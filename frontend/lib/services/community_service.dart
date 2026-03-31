import 'package:syntrak/core/errors/app_error.dart';
import 'package:syntrak/core/errors/app_result.dart';
import 'package:syntrak/features/community/data/community_repository.dart';

class CommunityService {
  CommunityService({required CommunityRepository communityRepository})
      : _communityRepository = communityRepository;

  final CommunityRepository _communityRepository;

  Future<AppResult<List<Map<String, dynamic>>>> getPostsByUserId(
    String userId, {
    int limit = 20,
    int offset = 0,
  }) {
    return _run(() => _communityRepository.getPostsByUserId(
          userId,
          limit: limit,
          offset: offset,
        ));
  }

  Future<AppResult<List<Map<String, dynamic>>>> getSubthreads({int limit = 50}) {
    return _run(() => _communityRepository.getSubthreads(limit: limit));
  }

  Future<AppResult<Map<String, dynamic>>> createSubthread({
    required String name,
    String? description,
  }) {
    return _run(() => _communityRepository.createSubthread(
          name: name,
          description: description,
        ));
  }

  Future<AppResult<List<Map<String, dynamic>>>> getPostsBySubthread(
    String subthreadId, {
    int limit = 20,
    int offset = 0,
  }) {
    return _run(() => _communityRepository.getPostsBySubthread(
          subthreadId,
          limit: limit,
          offset: offset,
        ));
  }

  Future<AppResult<List<Map<String, dynamic>>>> getFeedPosts({
    int limit = 20,
    int offset = 0,
  }) {
    return _run(() => _communityRepository.getFeedPosts(
          limit: limit,
          offset: offset,
        ));
  }

  Future<AppResult<List<Map<String, dynamic>>>> getCommentsByPost(
    String postId,
  ) {
    return _run(() => _communityRepository.getCommentsByPost(postId));
  }

  /// Batched comments for a feed page (avoids N+1 GETs when Supabase batch is used).
  Future<AppResult<Map<String, List<Map<String, dynamic>>>>> getCommentsForPosts(
    List<String> postIds,
  ) {
    return _run(() => _communityRepository.getCommentsForPosts(postIds));
  }

  Future<AppResult<Map<String, dynamic>>> createPost({
    required String subthreadId,
    required String title,
    required String content,
  }) {
    return _run(() => _communityRepository.createPost(
          subthreadId: subthreadId,
          title: title,
          content: content,
        ));
  }

  Future<AppResult<Map<String, dynamic>>> createComment({
    required String postId,
    required String content,
    String? parentId,
  }) {
    return _run(() => _communityRepository.createComment(
          postId: postId,
          content: content,
          parentId: parentId,
        ));
  }

  Future<AppResult<Map<String, dynamic>>> votePost({
    required String postId,
    required int voteType,
  }) {
    return _run(() => _communityRepository.votePost(
          postId: postId,
          voteType: voteType,
        ));
  }

  Future<AppResult<T>> _run<T>(Future<T> Function() fn) async {
    try {
      return AppSuccess(await fn());
    } catch (e, st) {
      return AppFailure(AppError.from(e, st));
    }
  }
}
