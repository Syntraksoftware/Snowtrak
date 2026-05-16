import 'package:syntrak/models/post.dart';
import 'package:syntrak/screens/community/mappers/community_author_mapper.dart';
import 'package:syntrak/screens/community/mappers/community_post_field_parsers.dart';

class CommunityCommentTreeMapper {
  CommunityCommentTreeMapper._();

  static List<Post> mapRepliesFromComments(
    List<Map<String, dynamic>> comments, {
    String threadSubthreadId = '',
    String parentPostId = '',
  }) {
    if (comments.isEmpty) {
      return const [];
    }

    final root = comments
        .where((c) => (c['parent_id'] == null || c['parent_id'].toString().isEmpty))
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
        DateTime.tryParse((comment['created_at'] ?? '').toString()) ?? DateTime.now();
    final authorName = CommunityAuthorMapper.authorDisplayName(
      firstName: comment['author_first_name']?.toString(),
      lastName: comment['author_last_name']?.toString(),
      fallback: comment['author_email']?.toString() ??
          comment['user_id']?.toString() ??
          'unknown',
    );
    final repostCount = (comment['repost_count'] as num?)?.toInt() ?? 0;
    final repostedByCurrentUser = comment['reposted_by_current_user'] == true;

    return Post(
      id: (comment['id'] ?? '').toString(),
      author: PostAuthor(
        id: (comment['user_id'] ?? '').toString(),
        displayName: authorName,
        username: CommunityAuthorMapper.usernameFromEmailOrId(
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
      media: CommunityPostFieldParsers.parseMediaUrls(comment['media_urls']),
      createdAt: createdAt,
      timestampLabel: CommunityPostFieldParsers.timestampLabel(createdAt),
    );
  }
}
