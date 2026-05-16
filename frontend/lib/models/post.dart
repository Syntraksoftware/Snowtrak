class Post {
  final String id;
  final PostAuthor author;
  final String text;
  /// Optional community/topic label (from structured post title), shown in feed header.
  final String? topic;
  /// Original API `title` (structured preview line); used when reposting verbatim.
  final String? serverTitle;
  /// Subthread this post belongs to (for creating reposts in the same channel).
  final String subthreadId;
  /// Embedded original when this post is a quote.
  final Post? quotedPost;
  /// Server FK for quotes; used when reposting a quote post verbatim.
  final String? quotedPostId;
  /// True when this model represents a thread comment (not a top-level post).
  final bool isComment;
  /// Parent thread post id when [isComment] is true.
  final String parentPostId;
  /// Embedded original when this post is a quote of a comment.
  final Post? quotedComment;
  final String? quotedCommentId;
  final List<String>? media;
  final DateTime createdAt;
  final String timestampLabel;
  final int likeCount;
  final int replyCount;
  final int repostCount;
  final int shareCount;
  final bool likedByCurrentUser;
  final bool repostedByCurrentUser;
  final List<Post>? replies;

  Post({
    required this.id,
    required this.author,
    required this.text,
    this.topic,
    this.serverTitle,
    this.subthreadId = '',
    this.quotedPost,
    this.quotedPostId,
    this.isComment = false,
    this.parentPostId = '',
    this.quotedComment,
    this.quotedCommentId,
    this.media,
    required this.createdAt,
    required this.timestampLabel,
    this.likeCount = 0,
    this.replyCount = 0,
    this.repostCount = 0,
    this.shareCount = 0,
    this.likedByCurrentUser = false,
    this.repostedByCurrentUser = false,
    this.replies,
  });

  /// Title string to send on API create (repost duplicate / fallback).
  String composeServerTitle() {
    final raw = (serverTitle ?? '').trim();
    if (raw.isNotEmpty) return raw;
    final t = (topic ?? '').trim();
    final body = text.trim();
    if (t.isEmpty) {
      return body.length > 48 ? '${body.substring(0, 48)}...' : body;
    }
    final base = body.length > 48 ? '${body.substring(0, 48)}...' : body;
    return '$t > $base';
  }

  Post copyWith({
    String? id,
    PostAuthor? author,
    String? text,
    String? topic,
    String? serverTitle,
    String? subthreadId,
    Post? quotedPost,
    String? quotedPostId,
    bool? isComment,
    String? parentPostId,
    Post? quotedComment,
    String? quotedCommentId,
    List<String>? media,
    DateTime? createdAt,
    String? timestampLabel,
    int? likeCount,
    int? replyCount,
    int? repostCount,
    int? shareCount,
    bool? likedByCurrentUser,
    bool? repostedByCurrentUser,
    List<Post>? replies,
  }) {
    return Post(
      id: id ?? this.id,
      author: author ?? this.author,
      text: text ?? this.text,
      topic: topic ?? this.topic,
      serverTitle: serverTitle ?? this.serverTitle,
      subthreadId: subthreadId ?? this.subthreadId,
      quotedPost: quotedPost ?? this.quotedPost,
      quotedPostId: quotedPostId ?? this.quotedPostId,
      isComment: isComment ?? this.isComment,
      parentPostId: parentPostId ?? this.parentPostId,
      quotedComment: quotedComment ?? this.quotedComment,
      quotedCommentId: quotedCommentId ?? this.quotedCommentId,
      media: media ?? this.media,
      createdAt: createdAt ?? this.createdAt,
      timestampLabel: timestampLabel ?? this.timestampLabel,
      likeCount: likeCount ?? this.likeCount,
      replyCount: replyCount ?? this.replyCount,
      repostCount: repostCount ?? this.repostCount,
      shareCount: shareCount ?? this.shareCount,
      likedByCurrentUser: likedByCurrentUser ?? this.likedByCurrentUser,
      repostedByCurrentUser:
          repostedByCurrentUser ?? this.repostedByCurrentUser,
      replies: replies ?? this.replies,
    );
  }
}

class PostAuthor {
  final String id;
  final String displayName;
  final String username;
  final String? avatarUrl;

  PostAuthor({
    required this.id,
    required this.displayName,
    required this.username,
    this.avatarUrl,
  });
}
