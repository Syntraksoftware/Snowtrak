class Post {
  final String id;
  final PostAuthor author;
  final String text;
  final List<String>? media;
  final DateTime createdAt;
  final String timestampLabel;
  final int likeCount;
  final int replyCount;
  final int repostCount;
  final bool likedByCurrentUser;
  final bool repostedByCurrentUser;
  final List<Post>? replies;

  Post({
    required this.id,
    required this.author,
    required this.text,
    this.media,
    required this.createdAt,
    required this.timestampLabel,
    this.likeCount = 0,
    this.replyCount = 0,
    this.repostCount = 0,
    this.likedByCurrentUser = false,
    this.repostedByCurrentUser = false,
    this.replies,
  });

  Post copyWith({
    String? id,
    PostAuthor? author,
    String? text,
    List<String>? media,
    DateTime? createdAt,
    String? timestampLabel,
    int? likeCount,
    int? replyCount,
    int? repostCount,
    bool? likedByCurrentUser,
    bool? repostedByCurrentUser,
    List<Post>? replies,
  }) {
    return Post(
      id: id ?? this.id,
      author: author ?? this.author,
      text: text ?? this.text,
      media: media ?? this.media,
      createdAt: createdAt ?? this.createdAt,
      timestampLabel: timestampLabel ?? this.timestampLabel,
      likeCount: likeCount ?? this.likeCount,
      replyCount: replyCount ?? this.replyCount,
      repostCount: repostCount ?? this.repostCount,
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
