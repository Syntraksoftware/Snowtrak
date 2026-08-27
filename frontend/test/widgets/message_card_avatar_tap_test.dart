import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:snowtrak/models/post.dart';
import 'package:snowtrak/screens/profile/user_profile_screen.dart';
import 'package:snowtrak/widgets/message_card.dart';

Post _post({required String id, required String authorId, List<Post>? replies}) {
  return Post(
    id: id,
    author: PostAuthor(
      id: authorId,
      displayName: 'User $authorId',
      username: authorId,
    ),
    text: 'post $id',
    createdAt: DateTime.parse('2026-01-01T00:00:00Z'),
    timestampLabel: '1h',
    replies: replies,
  );
}

void main() {
  testWidgets('avatar tap reports the tapped post, not the parent', (tester) async {
    // The callback used to be a VoidCallback bound to the outer post, so an
    // expanded reply's avatar opened the wrong person's profile.
    final tapped = <String>[];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MessageCard(
            post: _post(
              id: 'parent',
              authorId: 'alice',
              replies: [_post(id: 'reply', authorId: 'bob')],
            ),
            showInlineReplies: true,
            isExpanded: true,
            onAvatarTap: (post) => tapped.add(post.author.id),
          ),
        ),
      ),
    );

    final avatars = find.byType(CircleAvatar);
    expect(avatars, findsNWidgets(2));

    await tester.tap(avatars.first);
    await tester.tap(avatars.last);

    expect(tapped, ['alice', 'bob']);
  });

  testWidgets('openUserProfile ignores an empty user id', (tester) async {
    // The feed mapper falls back to '' when a post carries no user_id.
    final navigator = GlobalKey<NavigatorState>();

    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navigator,
        home: const Scaffold(body: SizedBox()),
      ),
    );

    await openUserProfile(navigator.currentContext!, '   ');
    await tester.pumpAndSettle();

    expect(find.byType(UserProfileScreen), findsNothing);
  });
}
