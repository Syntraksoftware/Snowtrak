/// Follower counts plus the viewer's relationship to a profile.
///
/// One `/follows/{id}/stats` call fills the whole profile header, so it does
/// not take three requests to draw one button.
class FollowStats {
  const FollowStats({
    this.followerCount = 0,
    this.followingCount = 0,
    this.isFollowing = false,
    this.isFollowedBy = false,
    this.isPrivate = false,
    this.hasRequested = false,
  });

  final int followerCount;
  final int followingCount;

  /// The viewer follows this profile.
  final bool isFollowing;

  /// This profile follows the viewer — what makes a "Follows you" badge.
  final bool isFollowedBy;

  /// This account approves its followers, so Follow sends a request.
  final bool isPrivate;

  /// The viewer has a request pending on this account.
  final bool hasRequested;

  factory FollowStats.fromJson(Map<String, dynamic> json) {
    return FollowStats(
      followerCount: (json['follower_count'] as num?)?.toInt() ?? 0,
      followingCount: (json['following_count'] as num?)?.toInt() ?? 0,
      isFollowing: json['is_following'] as bool? ?? false,
      isFollowedBy: json['is_followed_by'] as bool? ?? false,
      isPrivate: json['is_private'] as bool? ?? false,
      hasRequested: json['has_requested'] as bool? ?? false,
    );
  }

  /// The optimistic result of tapping Follow / Following on a public
  /// account, before the request lands. Reverted by re-fetching on failure.
  FollowStats toggled() {
    return FollowStats(
      followerCount: isFollowing
          ? (followerCount > 0 ? followerCount - 1 : 0)
          : followerCount + 1,
      followingCount: followingCount,
      isFollowing: !isFollowing,
      isFollowedBy: isFollowedBy,
      isPrivate: isPrivate,
      hasRequested: hasRequested,
    );
  }

  /// The optimistic result of asking, or of taking the ask back.
  ///
  /// The follower count does not move: a request is not a follower, and
  /// showing it as one would be a lie the server corrects a second later.
  FollowStats requested() {
    return FollowStats(
      followerCount: followerCount,
      followingCount: followingCount,
      isFollowing: isFollowing,
      isFollowedBy: isFollowedBy,
      isPrivate: isPrivate,
      hasRequested: !hasRequested,
    );
  }
}
