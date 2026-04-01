import 'package:syntrak/models/post.dart';
import 'package:syntrak/screens/community/mappers/community_author_mapper.dart';
import 'package:syntrak/screens/community/mappers/community_comment_tree_mapper.dart';
import 'package:syntrak/screens/community/mappers/community_post_field_parsers.dart';
import 'package:syntrak/screens/community/mappers/community_quote_mapper.dart';

/// Maps community API JSON into [Post] models (threads feed, replies).
class CommunityPostMapper {
  CommunityPostMapper._();

  /// API `media_urls` jsonb → [Post.media].
  static List<String>? parseMediaUrls(dynamic raw) {
    return CommunityPostFieldParsers.parseMediaUrls(raw);
  }

  static Post mapBackendPost(
    Map<String, dynamic> rawPost,
    List<Map<String, dynamic>> rawComments,
  ) {
    final createdAt =
        DateTime.tryParse((rawPost['created_at'] ?? '').toString()) ??
            DateTime.now();
    final authorName = authorDisplayName(
      firstName: rawPost['author_first_name']?.toString(),
      lastName: rawPost['author_last_name']?.toString(),
      fallback: rawPost['author_email']?.toString() ??
          rawPost['user_id']?.toString() ??
          'unknown',
    );

    final threadPid =
        (rawPost['post_id'] ?? rawPost['id'] ?? '').toString();
    final replies = mapRepliesFromComments(
      rawComments,
      threadSubthreadId: (rawPost['subthread_id'] ?? '').toString(),
      parentPostId: threadPid,
    );

    final likeCount = (rawPost['like_count'] as num?)?.toInt() ?? 0;
    final replyCountFromApi = (rawPost['reply_count'] as num?)?.toInt();
    final repostCount = (rawPost['repost_count'] as num?)?.toInt() ?? 0;
    final shareCount = (rawPost['share_count'] as num?)?.toInt() ?? 0;
    final likedByCurrentUser = rawPost['liked_by_current_user'] == true;
    final repostedByCurrentUser = rawPost['reposted_by_current_user'] == true;

    final content = (rawPost['content'] ?? '').toString();
    final titleRaw = rawPost['title']?.toString();
    final quoted = mapQuotedPostPreview(rawPost['quoted_post']);
    final qidRaw = rawPost['quoted_post_id']?.toString().trim();
    final quotedId = (qidRaw != null && qidRaw.isNotEmpty) ? qidRaw : null;
    final quotedComment = mapQuotedCommentPreview(rawPost['quoted_comment']);
    final qcidRaw = rawPost['quoted_comment_id']?.toString().trim();
    final quotedCommentId =
        (qcidRaw != null && qcidRaw.isNotEmpty) ? qcidRaw : null;

    return Post(
      id: (rawPost['post_id'] ?? rawPost['id'] ?? '').toString(),
      author: PostAuthor(
        id: (rawPost['user_id'] ?? '').toString(),
        displayName: authorName,
        username: usernameFromEmailOrId(
          rawPost['author_email']?.toString(),
          rawPost['user_id']?.toString(),
        ),
      ),
      text: content.isNotEmpty
          ? content
          : (titleRaw ?? '').toString(),
      topic: topicFromStructuredTitle(titleRaw),
      serverTitle: titleRaw,
      subthreadId: (rawPost['subthread_id'] ?? '').toString(),
      quotedPost: quoted,
      quotedPostId: quotedId,
      quotedComment: quotedComment,
      quotedCommentId: quotedCommentId,
      createdAt: createdAt,
      timestampLabel: timestampLabel(createdAt),
      likeCount: likeCount,
      replyCount: replyCountFromApi ?? replies.length,
      repostCount: repostCount,
      shareCount: shareCount,
      likedByCurrentUser: likedByCurrentUser,
      repostedByCurrentUser: repostedByCurrentUser,
      media: parseMediaUrls(rawPost['media_urls']),
      replies: replies,
    );
  }

  /// Maps API `quoted_post` object into a [Post] for embed UI (no nesting).
  static Post? mapQuotedPostPreview(dynamic raw) {
    return CommunityQuoteMapper.mapQuotedPostPreview(raw);
  }

  /// Maps API `quoted_comment` object into a [Post] for embed UI (no nesting).
  static Post? mapQuotedCommentPreview(dynamic raw) {
    return CommunityQuoteMapper.mapQuotedCommentPreview(raw);
  }

  /// First segment of titles stored as `"{topic} > {preview}"` from compose flow.
  static String? topicFromStructuredTitle(String? title) {
    return CommunityPostFieldParsers.topicFromStructuredTitle(title);
  }

  static List<Post> mapRepliesFromComments(
    List<Map<String, dynamic>> comments, {
    String threadSubthreadId = '',
    String parentPostId = '',
  }) {
    return CommunityCommentTreeMapper.mapRepliesFromComments(
      comments,
      threadSubthreadId: threadSubthreadId,
      parentPostId: parentPostId,
    );
  }

  static Post mapCommentToPost(
    Map<String, dynamic> comment, {
    String threadSubthreadId = '',
    String parentPostId = '',
  }) {
    return CommunityCommentTreeMapper.mapCommentToPost(
      comment,
      threadSubthreadId: threadSubthreadId,
      parentPostId: parentPostId,
    );
  }

  static String authorDisplayName({
    String? firstName,
    String? lastName,
    required String fallback,
  }) {
    return CommunityAuthorMapper.authorDisplayName(
      firstName: firstName,
      lastName: lastName,
      fallback: fallback,
    );
  }

  static String usernameFromEmailOrId(String? email, String? fallbackId) {
    return CommunityAuthorMapper.usernameFromEmailOrId(email, fallbackId);
  }

  static String timestampLabel(DateTime createdAt) {
    return CommunityPostFieldParsers.timestampLabel(createdAt);
  }
}
