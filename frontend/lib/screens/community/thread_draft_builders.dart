import 'package:snowtrak/models/post.dart';
import 'package:snowtrak/models/user.dart';
import 'package:snowtrak/screens/community/mappers/community_author_mapper.dart';

class CommunityDraftBuilders {
  CommunityDraftBuilders._();

  // TODO(#53): a chosen handle cannot reach an optimistic draft -- `User`
  // has no username field, so a draft shows the name rung and the
  // refreshed post shows @handle. Fix needs `username` on the auth
  // payload.
  static PostAuthor buildAuthor(User user) {
    final displayName = CommunityAuthorMapper.authorDisplayName(
      username: null,
      firstName: user.firstName,
      lastName: user.lastName,
      fallback: user.email,
    );
    return PostAuthor(
      id: user.id,
      displayName: displayName,
      username: '',
      avatarUrl: null,
    );
  }

  static String buildServerTitle({
    required String text,
    required String topic,
  }) {
    final body = text.trim();
    if (body.isNotEmpty) {
      final base = body.length > 48 ? '${body.substring(0, 48)}...' : body;
      if (topic.isEmpty) {
        return base;
      }
      return '$topic > $base';
    }
    if (topic.isNotEmpty) {
      return '$topic > Media';
    }
    return 'Media';
  }
}
