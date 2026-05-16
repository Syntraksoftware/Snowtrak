import 'package:syntrak/core/errors/app_result.dart';
import 'package:syntrak/features/community/data/community_outbox_service.dart';
import 'package:syntrak/screens/community/thread_outbox_helpers.dart';
import 'package:syntrak/services/community_service.dart';

class ThreadsTabActionCoordinator {
  ThreadsTabActionCoordinator({
    required CommunityService communityService,
    required CommunityOutboxService outboxService,
  })  : _communityService = communityService,
        _outboxService = outboxService;

  final CommunityService _communityService;
  final CommunityOutboxService _outboxService;

  Future<AppResult<Map<String, dynamic>>> createPost({
    required String subthreadId,
    required String title,
    required String content,
    String? quotedPostId,
    String? quotedCommentId,
    List<String>? mediaUrls,
  }) {
    return _communityService.createPost(
      subthreadId: subthreadId,
      title: title,
      content: content,
      quotedPostId: quotedPostId,
      quotedCommentId: quotedCommentId,
      mediaUrls: mediaUrls,
    );
  }

  Future<AppResult<Map<String, dynamic>>> createPostRepost({
    required String subthreadId,
    required String title,
    required String content,
    required String repostOfPostId,
    String? quotedPostId,
    List<String>? mediaUrls,
  }) {
    return _communityService.createPost(
      subthreadId: subthreadId,
      title: title,
      content: content,
      quotedPostId: quotedPostId,
      repostOfPostId: repostOfPostId,
      mediaUrls: mediaUrls,
    );
  }

  Future<AppResult<Map<String, dynamic>>> createCommentRepost({
    required String subthreadId,
    required String title,
    required String content,
    required String repostOfCommentId,
    List<String>? mediaUrls,
  }) {
    return _communityService.createPost(
      subthreadId: subthreadId,
      title: title,
      content: content,
      repostOfCommentId: repostOfCommentId,
      mediaUrls: mediaUrls,
    );
  }

  Future<AppResult<Map<String, dynamic>>> createReply({
    required String postId,
    required String content,
    List<String>? mediaUrls,
  }) {
    return _communityService.createComment(
      postId: postId,
      content: content,
      mediaUrls: mediaUrls,
    );
  }

  Future<void> enqueueCreatePost({
    required String tempId,
    required String? subthreadId,
    required String title,
    required String content,
    String? quotedPostId,
    String? quotedCommentId,
    List<String>? mediaUrls,
  }) {
    return _outboxService.enqueue(
      CommunityOutboxOperation(
        id: tempId,
        type: 'create_post',
        payload: {
          'subthread_id': subthreadId,
          'title': title,
          'content': content,
          'temp_id': tempId,
          if (quotedPostId != null && quotedPostId.isNotEmpty)
            'quoted_post_id': quotedPostId,
          if (quotedCommentId != null && quotedCommentId.isNotEmpty)
            'quoted_comment_id': quotedCommentId,
          if (mediaUrls != null && mediaUrls.isNotEmpty) 'media_urls': mediaUrls,
        },
      ),
    );
  }

  Future<void> enqueueCreateComment({
    required String tempReplyId,
    required String postId,
    required String content,
    List<String>? mediaUrls,
  }) {
    return _outboxService.enqueue(
      CommunityOutboxOperation(
        id: tempReplyId,
        type: 'create_comment',
        payload: {
          'post_id': postId,
          'content': content,
          'temp_id': tempReplyId,
          if (mediaUrls != null && mediaUrls.isNotEmpty) 'media_urls': mediaUrls,
        },
      ),
    );
  }

  Future<void> enqueueVotePost({
    required String postId,
    required int voteType,
  }) {
    return _outboxService.enqueue(
      CommunityOutboxOperation(
        id: 'vote_${DateTime.now().millisecondsSinceEpoch}_$postId',
        type: 'vote_post',
        payload: {
          'post_id': postId,
          'vote_type': voteType,
        },
      ),
    );
  }

  Future<List<CommunityOutboxOperation>> loadOutbox() => _outboxService.load();

  Future<void> replaceOutbox(List<CommunityOutboxOperation> operations) =>
      _outboxService.replaceAll(operations);

  List<String>? parseMediaFromPayload(Map<String, dynamic> payload) =>
      parseOutboxMediaUrls(payload);
}