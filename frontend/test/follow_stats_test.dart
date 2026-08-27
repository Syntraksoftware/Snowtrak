import 'package:flutter_test/flutter_test.dart';
import 'package:snowtrak/models/follow_stats.dart';

void main() {
  test('toggling follow moves the follower count in the right direction', () {
    const notFollowing = FollowStats(followerCount: 3, followingCount: 9);

    final followed = notFollowing.toggled();
    expect(followed.isFollowing, isTrue);
    expect(followed.followerCount, 4);
    // Following someone changes their follower count, never the "following"
    // number shown on their profile.
    expect(followed.followingCount, 9);

    final unfollowed = followed.toggled();
    expect(unfollowed.isFollowing, isFalse);
    expect(unfollowed.followerCount, 3);
  });

  test('unfollowing at zero does not go negative', () {
    // Stale counts happen: the edge can go away between the fetch and the tap.
    // The optimistic number should still be sane.
    const stale = FollowStats(followerCount: 0, isFollowing: true);
    expect(stale.toggled().followerCount, 0);
  });

  test('missing fields decode to zero rather than throwing', () {
    final stats = FollowStats.fromJson(<String, dynamic>{});
    expect(stats.followerCount, 0);
    expect(stats.isFollowing, isFalse);
  });
}
