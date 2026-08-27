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
  });

  final int followerCount;
  final int followingCount;

  /// The viewer follows this profile.
  final bool isFollowing;

  /// This profile follows the viewer — what makes a "Follows you" badge.
  final bool isFollowedBy;

  factory FollowStats.fromJson(Map<String, dynamic> json) {
    return FollowStats(
      followerCount: (json['follower_count'] as num?)?.toInt() ?? 0,
      followingCount: (json['following_count'] as num?)?.toInt() ?? 0,
      isFollowing: json['is_following'] as bool? ?? false,
      isFollowedBy: json['is_followed_by'] as bool? ?? false,
    );
  }

  /// The optimistic result of tapping Follow / Following, before the request
  /// lands. Reverted by re-fetching if the request fails.
  FollowStats toggled() {
    return FollowStats(
      followerCount: isFollowing
          ? (followerCount > 0 ? followerCount - 1 : 0)
          : followerCount + 1,
      followingCount: followingCount,
      isFollowing: !isFollowing,
      isFollowedBy: isFollowedBy,
    );
  }
}
