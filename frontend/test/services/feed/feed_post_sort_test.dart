import 'package:flutter_test/flutter_test.dart';
import 'package:syntrak/models/post.dart';
import 'package:syntrak/services/feed/feed_post_sort.dart';

void main() {
  Post postAt(DateTime createdAt, {String id = '1'}) {
    return Post(
      id: id,
      author: PostAuthor(
        id: 'u1',
        displayName: 'User',
        username: 'user',
      ),
      text: 'hello',
      createdAt: createdAt,
      timestampLabel: 'now',
    );
  }

  test('byRecent orders newest posts first', () {
    final older = postAt(DateTime(2024, 1, 1), id: 'old');
    final newer = postAt(DateTime(2024, 6, 1), id: 'new');

    final sorted = FeedPostSort.byRecent([older, newer]);

    expect(sorted.map((post) => post.id).toList(), ['new', 'old']);
  });
}
