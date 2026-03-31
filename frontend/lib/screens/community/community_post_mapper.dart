import 'package:syntrak/models/post.dart';

/// Maps community API JSON into [Post] models (threads feed, replies).
class CommunityPostMapper {
  CommunityPostMapper._();

  static bool _looksLikeUuid(String s) {
    final t = s.trim();
    return RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
    ).hasMatch(t);
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
      createdAt: createdAt,
      timestampLabel: timestampLabel(createdAt),
      likeCount: likeCount,
      replyCount: replyCountFromApi ?? replies.length,
      repostCount: repostCount,
      shareCount: shareCount,
      likedByCurrentUser: likedByCurrentUser,
      repostedByCurrentUser: repostedByCurrentUser,
      replies: replies,
    );
  }

  /// Maps API `quoted_post` object into a [Post] for embed UI (no nesting).
  static Post? mapQuotedPostPreview(dynamic raw) {
    if (raw is! Map) {
      return null;
    }
    final m = Map<String, dynamic>.from(raw);
    final createdAt =
        DateTime.tryParse((m['created_at'] ?? '').toString()) ?? DateTime.now();
    final titleRaw = m['title']?.toString();
    final body = (m['content'] ?? '').toString();
    final authorName = authorDisplayName(
      firstName: m['author_first_name']?.toString(),
      lastName: m['author_last_name']?.toString(),
      fallback: m['author_email']?.toString() ??
          m['user_id']?.toString() ??
          'unknown',
    );
    return Post(
      id: (m['post_id'] ?? m['id'] ?? '').toString(),
      author: PostAuthor(
        id: (m['user_id'] ?? '').toString(),
        displayName: authorName,
        username: usernameFromEmailOrId(
          m['author_email']?.toString(),
          m['user_id']?.toString(),
        ),
      ),
      text: body.isNotEmpty ? body : (titleRaw ?? '').toString(),
      topic: topicFromStructuredTitle(titleRaw),
      serverTitle: titleRaw,
      subthreadId: '',
      quotedPost: null,
      quotedPostId: null,
      isComment: false,
      parentPostId: '',
      quotedComment: null,
      quotedCommentId: null,
      createdAt: createdAt,
      timestampLabel: timestampLabel(createdAt),
    );
  }

  /// Maps API `quoted_comment` object into a [Post] for embed UI (no nesting).
  static Post? mapQuotedCommentPreview(dynamic raw) {
    if (raw is! Map) {
      return null;
    }
    final m = Map<String, dynamic>.from(raw);
    final createdAt =
        DateTime.tryParse((m['created_at'] ?? '').toString()) ?? DateTime.now();
    final body = (m['content'] ?? '').toString();
    final authorName = authorDisplayName(
      firstName: m['author_first_name']?.toString(),
      lastName: m['author_last_name']?.toString(),
      fallback: m['author_email']?.toString() ??
          m['user_id']?.toString() ??
          'unknown',
    );
    return Post(
      id: (m['id'] ?? '').toString(),
      author: PostAuthor(
        id: (m['user_id'] ?? '').toString(),
        displayName: authorName,
        username: usernameFromEmailOrId(
          m['author_email']?.toString(),
          m['user_id']?.toString(),
        ),
      ),
      text: body,
      isComment: true,
      parentPostId: '',
      subthreadId: '',
      quotedPost: null,
      quotedPostId: null,
      quotedComment: null,
      quotedCommentId: null,
      createdAt: createdAt,
      timestampLabel: timestampLabel(createdAt),
    );
  }

  /// First segment of titles stored as `"{topic} > {preview}"` from compose flow.
  static String? topicFromStructuredTitle(String? title) {
    final t = (title ?? '').trim();
    const sep = ' > ';
    final i = t.indexOf(sep);
    if (i <= 0) {
      return null;
    }
    final topic = t.substring(0, i).trim();
    return topic.isEmpty ? null : topic;
  }

  static List<Post> mapRepliesFromComments(
    List<Map<String, dynamic>> comments, {
    String threadSubthreadId = '',
    String parentPostId = '',
  }) {
    if (comments.isEmpty) {
      return const [];
    }

    final root = comments
        .where((c) =>
            (c['parent_id'] == null || c['parent_id'].toString().isEmpty))
        .toList();

    return root.map((comment) {
      final rootId = (comment['id'] ?? '').toString();
      final nested = comments
          .where((c) => (c['parent_id'] ?? '').toString() == rootId)
          .map(
            (c) => mapCommentToPost(
              c,
              threadSubthreadId: threadSubthreadId,
              parentPostId: parentPostId,
            ),
          )
          .toList();

      final mappedRoot = mapCommentToPost(
        comment,
        threadSubthreadId: threadSubthreadId,
        parentPostId: parentPostId,
      );
      return mappedRoot.copyWith(
        replies: nested,
        replyCount: nested.length,
      );
    }).toList();
  }

  static Post mapCommentToPost(
    Map<String, dynamic> comment, {
    String threadSubthreadId = '',
    String parentPostId = '',
  }) {
    final createdAt =
        DateTime.tryParse((comment['created_at'] ?? '').toString()) ??
            DateTime.now();
    final authorName = authorDisplayName(
      firstName: comment['author_first_name']?.toString(),
      lastName: comment['author_last_name']?.toString(),
      fallback: comment['author_email']?.toString() ??
          comment['user_id']?.toString() ??
          'unknown',
    );
    final repostCount = (comment['repost_count'] as num?)?.toInt() ?? 0;
    final repostedByCurrentUser =
        comment['reposted_by_current_user'] == true;

    return Post(
      id: (comment['id'] ?? '').toString(),
      author: PostAuthor(
        id: (comment['user_id'] ?? '').toString(),
        displayName: authorName,
        username: usernameFromEmailOrId(
          comment['author_email']?.toString(),
          comment['user_id']?.toString(),
        ),
      ),
      text: (comment['content'] ?? '').toString(),
      subthreadId: threadSubthreadId,
      isComment: true,
      parentPostId: parentPostId,
      repostCount: repostCount,
      repostedByCurrentUser: repostedByCurrentUser,
      createdAt: createdAt,
      timestampLabel: timestampLabel(createdAt),
    );
  }

  static String authorDisplayName({
    String? firstName,
    String? lastName,
    required String fallback,
  }) {
    final first = (firstName ?? '').trim();
    final last = (lastName ?? '').trim();
    if (first.isNotEmpty || last.isNotEmpty) {
      return '$first $last'.trim();
    }
    final fb = fallback.trim();
    if (_looksLikeUuid(fb)) {
      return 'Member';
    }
    if (fb.contains('@')) {
      return fb.split('@').first;
    }
    return usernameFromEmailOrId(null, fb);
  }

  static String usernameFromEmailOrId(String? email, String? fallbackId) {
    final e = (email ?? '').trim();
    if (e.contains('@')) {
      return e.split('@').first;
    }

    final id = (fallbackId ?? '').trim();
    if (id.isEmpty) {
      return 'user';
    }
    if (_looksLikeUuid(id)) {
      return 'member';
    }
    return id.length > 12 ? id.substring(0, 12) : id;
  }

  static String timestampLabel(DateTime createdAt) {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inMinutes < 1) return 'now';
    if (diff.inHours < 1) return '${diff.inMinutes}m';
    if (diff.inDays < 1) return '${diff.inHours}h';
    return '${diff.inDays}d';
  }
}
