import 'package:snowtrak/models/post.dart';

/// Serializes community [Post] models for on-device feed cache storage.
abstract final class PostCacheCodec {
  static Map<String, dynamic> toJson(Post post) {
    return {
      'id': post.id,
      'author': {
        'id': post.author.id,
        'displayName': post.author.displayName,
        'username': post.author.username,
        'avatarUrl': post.author.avatarUrl,
      },
      'text': post.text,
      'topic': post.topic,
      'serverTitle': post.serverTitle,
      'subthreadId': post.subthreadId,
      'quotedPostId': post.quotedPostId,
      'isComment': post.isComment,
      'parentPostId': post.parentPostId,
      'quotedCommentId': post.quotedCommentId,
      'media': post.media,
      'visibility': post.visibility,
      'createdAt': post.createdAt.toIso8601String(),
      'timestampLabel': post.timestampLabel,
      'likeCount': post.likeCount,
      'replyCount': post.replyCount,
      'repostCount': post.repostCount,
      'shareCount': post.shareCount,
      'likedByCurrentUser': post.likedByCurrentUser,
      'repostedByCurrentUser': post.repostedByCurrentUser,
    };
  }

  static Post fromJson(Map<String, dynamic> json) {
    final authorJson = json['author'] as Map<String, dynamic>;
    return Post(
      id: json['id'] as String,
      author: PostAuthor(
        id: authorJson['id'] as String,
        displayName: authorJson['displayName'] as String,
        username: authorJson['username'] as String,
        avatarUrl: authorJson['avatarUrl'] as String?,
      ),
      text: json['text'] as String,
      topic: json['topic'] as String?,
      serverTitle: json['serverTitle'] as String?,
      subthreadId: json['subthreadId'] as String? ?? '',
      quotedPostId: json['quotedPostId'] as String?,
      isComment: json['isComment'] as bool? ?? false,
      parentPostId: json['parentPostId'] as String? ?? '',
      quotedCommentId: json['quotedCommentId'] as String?,
      media: (json['media'] as List?)?.cast<String>(),
      visibility: json['visibility'] as String? ?? 'public',
      createdAt: DateTime.parse(json['createdAt'] as String),
      timestampLabel: json['timestampLabel'] as String? ?? '',
      likeCount: json['likeCount'] as int? ?? 0,
      replyCount: json['replyCount'] as int? ?? 0,
      repostCount: json['repostCount'] as int? ?? 0,
      shareCount: json['shareCount'] as int? ?? 0,
      likedByCurrentUser: json['likedByCurrentUser'] as bool? ?? false,
      repostedByCurrentUser: json['repostedByCurrentUser'] as bool? ?? false,
    );
  }
}
