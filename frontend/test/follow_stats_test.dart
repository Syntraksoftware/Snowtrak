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

  test('parses the privacy fields', () {
    final stats = FollowStats.fromJson(const {
      'follower_count': 3,
      'following_count': 1,
      'is_following': false,
      'is_followed_by': false,
      'is_private': true,
      'has_requested': true,
    });
    expect(stats.isPrivate, isTrue);
    expect(stats.hasRequested, isTrue);
  });

  test('an older payload without the privacy fields still parses', () {
    final stats = FollowStats.fromJson(const {
      'follower_count': 3,
      'following_count': 1,
      'is_following': true,
      'is_followed_by': false,
    });
    expect(stats.isPrivate, isFalse);
    expect(stats.hasRequested, isFalse);
  });

  test('requesting flips only the request flag, never the count', () {
    const stats = FollowStats(followerCount: 7, isPrivate: true);
    final after = stats.requested();
    expect(after.hasRequested, isTrue);
    expect(after.isFollowing, isFalse);
    // A request is not a follower. The count must not move.
    expect(after.followerCount, 7);
  });

  test('withdrawing clears the flag', () {
    const stats = FollowStats(isPrivate: true, hasRequested: true);
    expect(stats.requested().hasRequested, isFalse);
  });
}
