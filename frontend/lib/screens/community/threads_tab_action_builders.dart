import 'package:syntrak/models/post.dart';
import 'package:syntrak/models/user.dart';
import 'package:syntrak/screens/community/thread_draft_builders.dart';

class ThreadsTabActionBuilders {
  ThreadsTabActionBuilders._();

  static String tempId(String prefix) =>
      '${prefix}_${DateTime.now().millisecondsSinceEpoch}';

  static Post normalizeConfirmedAuthor(Post confirmed, User user) {
    if (confirmed.author.id != user.id) {
      return confirmed;
    }
    return confirmed.copyWith(author: CommunityDraftBuilders.buildAuthor(user));
  }

  static Post optimisticPost({
    required String tempId,
    required User user,
    required String text,
    required String titleLine,
    required String subthreadId,
    required String topic,
    required String? quotedPostId,
    required String? quotedCommentId,
    required Post? previewPost,
    required Post? previewComment,
    required List<String> mediaUrls,
  }) {
    return Post(
      id: tempId,
      author: CommunityDraftBuilders.buildAuthor(user),
      text: text,
      topic: topic.isEmpty ? null : topic,
      serverTitle: titleLine,
      subthreadId: subthreadId,
      quotedPost: previewPost,
      quotedPostId: quotedPostId,
      quotedComment: previewComment,
      quotedCommentId: quotedCommentId,
      media: mediaUrls.isEmpty ? null : List<String>.from(mediaUrls),
      createdAt: DateTime.now(),
      timestampLabel: 'now',
    );
  }

  static Post optimisticCommentRepost({
    required String tempId,
    required User user,
    required Post source,
    required String titleLine,
    required String subthreadId,
    List<String>? mediaUrls,
  }) {
    return Post(
      id: tempId,
      author: CommunityDraftBuilders.buildAuthor(user),
      text: source.text,
      serverTitle: titleLine,
      subthreadId: subthreadId,
      media: mediaUrls == null ? null : List<String>.from(mediaUrls),
      createdAt: DateTime.now(),
      timestampLabel: 'now',
    );
  }

  static Post optimisticPostRepost({
    required String tempId,
    required User user,
    required Post source,
    required String subthreadId,
  }) {
    return Post(
      id: tempId,
      author: CommunityDraftBuilders.buildAuthor(user),
      text: source.text,
      topic: source.topic,
      serverTitle: source.composeServerTitle(),
      subthreadId: subthreadId,
      quotedPost: source.quotedPost,
      quotedPostId: source.quotedPostId,
      media: source.media == null ? null : List<String>.from(source.media!),
      createdAt: DateTime.now(),
      timestampLabel: 'now',
    );
  }

  static Post optimisticReply({
    required String tempId,
    required User user,
    required String text,
  }) {
    return Post(
      id: tempId,
      author: CommunityDraftBuilders.buildAuthor(user),
      text: text,
      createdAt: DateTime.now(),
      timestampLabel: 'now',
    );
  }
}
