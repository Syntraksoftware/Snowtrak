import 'package:snowtrak/models/activity.dart';
import 'package:snowtrak/models/post.dart';
import 'package:snowtrak/services/feed/feed_post_sort.dart';

/// Rebases server feed payloads with recent on-device optimistic state.
abstract final class FeedRebase {
  static List<Post> mergeCommunityPosts({
    required List<Post> serverPosts,
    required List<Post> localPosts,
  }) {
    if (localPosts.isEmpty) {
      return FeedPostSort.byRecent(serverPosts);
    }

    final localById = {for (final post in localPosts) post.id: post};
    final serverIds = serverPosts.map((post) => post.id).toSet();

    final merged = serverPosts.map((serverPost) {
      final local = localById[serverPost.id];
      if (local == null) return serverPost;

      return serverPost.copyWith(
        likedByCurrentUser: local.likedByCurrentUser,
        repostedByCurrentUser: local.repostedByCurrentUser,
        likeCount: local.likeCount > serverPost.likeCount
            ? local.likeCount
            : serverPost.likeCount,
        replyCount: local.replyCount > serverPost.replyCount
            ? local.replyCount
            : serverPost.replyCount,
        repostCount: local.repostCount > serverPost.repostCount
            ? local.repostCount
            : serverPost.repostCount,
      );
    }).toList();

    final optimisticOnly = localPosts
        .where((post) => !serverIds.contains(post.id))
        .toList();

    if (optimisticOnly.isEmpty) return FeedPostSort.byRecent(merged);
    return FeedPostSort.byRecent([...optimisticOnly, ...merged]);
  }

  static List<Activity> mergeActivities({
    required List<Activity> serverActivities,
    required List<Activity> localActivities,
  }) {
    if (localActivities.isEmpty) return serverActivities;

    final localById = {for (final item in localActivities) item.id: item};
    final serverIds = serverActivities.map((item) => item.id).toSet();

    final merged = serverActivities.map((serverItem) {
      return localById[serverItem.id] ?? serverItem;
    }).toList();

    final optimisticOnly = localActivities
        .where((item) => !serverIds.contains(item.id))
        .toList();

    if (optimisticOnly.isEmpty) return merged;
    return [...optimisticOnly, ...merged];
  }
}
