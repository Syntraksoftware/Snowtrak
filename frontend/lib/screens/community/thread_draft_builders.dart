import 'package:syntrak/models/post.dart';
import 'package:syntrak/models/user.dart';

class CommunityDraftBuilders {
  CommunityDraftBuilders._();

  static PostAuthor buildAuthor(User user) {
    final displayName = user.firstName != null && user.lastName != null
        ? '${user.firstName} ${user.lastName}'
        : user.email.split('@')[0];
    return PostAuthor(
      id: user.id,
      displayName: displayName,
      username: user.email.split('@')[0],
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
