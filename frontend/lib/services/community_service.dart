import 'package:image_picker/image_picker.dart';
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

  Future<AppResult<List<Map<String, dynamic>>>> getPostConversation(
    String postId,
  ) {
    return _run(() => _communityRepository.getPostConversation(postId));
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
    String? quotedPostId,
    String? repostOfPostId,
    String? quotedCommentId,
    String? repostOfCommentId,
    List<String>? mediaUrls,
  }) {
    return _run(() => _communityRepository.createPost(
          subthreadId: subthreadId,
          title: title,
          content: content,
          quotedPostId: quotedPostId,
          repostOfPostId: repostOfPostId,
          quotedCommentId: quotedCommentId,
          repostOfCommentId: repostOfCommentId,
          mediaUrls: mediaUrls,
        ));
  }

  Future<AppResult<String>> uploadMedia(XFile file) {
    return _run(() => _communityRepository.uploadMedia(file));
  }

  Future<AppResult<Map<String, dynamic>>> createComment({
    required String postId,
    required String content,
    String? parentId,
    List<String>? mediaUrls,
  }) {
    return _run(() => _communityRepository.createComment(
          postId: postId,
          content: content,
          parentId: parentId,
          mediaUrls: mediaUrls,
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

  Future<AppResult<Map<String, dynamic>>> repostPost({
    required String postId,
  }) {
    return _run(() => _communityRepository.repostPost(postId: postId));
  }

  Future<AppResult<Map<String, dynamic>>> undoRepost({
    required String postId,
  }) {
    return _run(() => _communityRepository.undoRepost(postId: postId));
  }

  Future<AppResult<Unit>> sharePost({
    required String postId,
  }) async {
    return const AppFailure(
      AppError(
        userMessage: 'Share functionality coming soon.',
        retryable: false,
      ),
    );
  }

  Future<AppResult<T>> _run<T>(Future<T> Function() fn) async {
    try {
      return AppSuccess(await fn());
    } catch (e, st) {
      return AppFailure(AppError.from(e, st));
    }
  }
}
