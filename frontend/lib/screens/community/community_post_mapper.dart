import 'package:syntrak/models/post.dart';

/// Maps community API JSON into [Post] models (threads feed, replies).
class CommunityPostMapper {
  CommunityPostMapper._();

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

    final replies = mapRepliesFromComments(rawComments);

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
      text: (rawPost['content'] ?? rawPost['title'] ?? '').toString(),
      createdAt: createdAt,
      timestampLabel: timestampLabel(createdAt),
      likeCount: 0,
      replyCount: replies.length,
      repostCount: 0,
      replies: replies,
    );
  }

  static List<Post> mapRepliesFromComments(
    List<Map<String, dynamic>> comments,
  ) {
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
          .map(mapCommentToPost)
          .toList();

      final mappedRoot = mapCommentToPost(comment);
      return mappedRoot.copyWith(
        replies: nested,
        replyCount: nested.length,
      );
    }).toList();
  }

  static Post mapCommentToPost(Map<String, dynamic> comment) {
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
    return usernameFromEmailOrId(fallback, fallback);
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
