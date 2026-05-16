import 'package:syntrak/models/post.dart';
import 'package:syntrak/screens/community/mappers/community_author_mapper.dart';
import 'package:syntrak/screens/community/mappers/community_post_field_parsers.dart';

class CommunityQuoteMapper {
  CommunityQuoteMapper._();

  static Post? mapQuotedPostPreview(dynamic raw) {
    if (raw is! Map) {
      return null;
    }
    final m = Map<String, dynamic>.from(raw);
    final createdAt =
        DateTime.tryParse((m['created_at'] ?? '').toString()) ?? DateTime.now();
    final titleRaw = m['title']?.toString();
    final body = (m['content'] ?? '').toString();
    final authorName = CommunityAuthorMapper.authorDisplayName(
      firstName: m['author_first_name']?.toString(),
      lastName: m['author_last_name']?.toString(),
      fallback: m['author_email']?.toString() ?? m['user_id']?.toString() ?? 'unknown',
    );
    return Post(
      id: (m['post_id'] ?? m['id'] ?? '').toString(),
      author: PostAuthor(
        id: (m['user_id'] ?? '').toString(),
        displayName: authorName,
        username: CommunityAuthorMapper.usernameFromEmailOrId(
          m['author_email']?.toString(),
          m['user_id']?.toString(),
        ),
      ),
      text: body.isNotEmpty ? body : (titleRaw ?? '').toString(),
      topic: CommunityPostFieldParsers.topicFromStructuredTitle(titleRaw),
      serverTitle: titleRaw,
      subthreadId: '',
      quotedPost: null,
      quotedPostId: null,
      isComment: false,
      parentPostId: '',
      quotedComment: null,
      quotedCommentId: null,
      createdAt: createdAt,
      timestampLabel: CommunityPostFieldParsers.timestampLabel(createdAt),
    );
  }

  static Post? mapQuotedCommentPreview(dynamic raw) {
    if (raw is! Map) {
      return null;
    }
    final m = Map<String, dynamic>.from(raw);
    final createdAt =
        DateTime.tryParse((m['created_at'] ?? '').toString()) ?? DateTime.now();
    final body = (m['content'] ?? '').toString();
    final authorName = CommunityAuthorMapper.authorDisplayName(
      firstName: m['author_first_name']?.toString(),
      lastName: m['author_last_name']?.toString(),
      fallback: m['author_email']?.toString() ?? m['user_id']?.toString() ?? 'unknown',
    );
    return Post(
      id: (m['id'] ?? '').toString(),
      author: PostAuthor(
        id: (m['user_id'] ?? '').toString(),
        displayName: authorName,
        username: CommunityAuthorMapper.usernameFromEmailOrId(
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
      timestampLabel: CommunityPostFieldParsers.timestampLabel(createdAt),
    );
  }
}
