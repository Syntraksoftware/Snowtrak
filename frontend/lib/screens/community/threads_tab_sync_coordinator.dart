import 'package:syntrak/core/errors/app_result.dart';
import 'package:syntrak/features/community/data/community_outbox_service.dart';
import 'package:syntrak/screens/community/thread_outbox_helpers.dart';
import 'package:syntrak/services/community_service.dart';

// handles syncing outbox operations to the backend
class ThreadsTabSyncCoordinator {
  ThreadsTabSyncCoordinator({
    required CommunityService communityService,
  }) : _communityService = communityService;

  final CommunityService _communityService;

  late final Map<String, Future<bool> Function(CommunityOutboxOperation)>
      _operationHandlers = {
    'create_post': _handleCreatePost,
    'create_comment': _handleCreateComment,
    'vote_post': _handleVotePost,
  };

  Future<bool> _handleCreatePost(CommunityOutboxOperation operation) async {
    final qid = operation.payload['quoted_post_id']?.toString().trim();
    final qcid = operation.payload['quoted_comment_id']?.toString().trim();
    final result = await _communityService.createPost(
      subthreadId: (operation.payload['subthread_id'] ?? '').toString(),
      title: (operation.payload['title'] ?? '').toString(),
      content: (operation.payload['content'] ?? '').toString(),
      quotedPostId: (qid != null && qid.isNotEmpty) ? qid : null,
      quotedCommentId: (qcid != null && qcid.isNotEmpty) ? qcid : null,
      mediaUrls: parseOutboxMediaUrls(operation.payload),
    );
    return result.isSuccess;
  }

  Future<bool> _handleCreateComment(CommunityOutboxOperation operation) async {
    final result = await _communityService.createComment(
      postId: (operation.payload['post_id'] ?? '').toString(),
      content: (operation.payload['content'] ?? '').toString(),
      mediaUrls: parseOutboxMediaUrls(operation.payload),
    );
    return result.isSuccess;
  }

  Future<bool> _handleVotePost(CommunityOutboxOperation operation) async {
    final result = await _communityService.votePost(
      postId: (operation.payload['post_id'] ?? '').toString(),
      voteType: (operation.payload['vote_type'] as num?)?.toInt() ?? 0,
    );
    return result.isSuccess;
  }

  Future<List<CommunityOutboxOperation>> retryOutbox(
    List<CommunityOutboxOperation> operations, {
    required void Function(String operationType) onUnknownOperationType,
  }) async {
    final pending = <CommunityOutboxOperation>[];
    for (final operation in operations) {
      final handler = _operationHandlers[operation.type];
      if (handler == null) {
        onUnknownOperationType(operation.type);
        pending.add(operation.copyWith(retryCount: operation.retryCount + 1));
        continue;
      }

      final succeeded = await handler(operation);

      if (!succeeded) {
        pending.add(operation.copyWith(retryCount: operation.retryCount + 1));
      }
    }
    return pending;
  }

  Future<AppResult<Map<String, dynamic>>> syncPostVote({
    required String postId,
    required int voteType,
  }) {
    return _communityService.votePost(
      postId: postId,
      voteType: voteType,
    );
  }
}
