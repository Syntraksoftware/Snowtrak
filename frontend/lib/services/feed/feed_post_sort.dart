import 'package:snowtrak/models/post.dart';

/// Sort helpers for community feed lists.
abstract final class FeedPostSort {
  /// Newest posts first (descending [Post.createdAt]).
  static List<Post> byRecent(Iterable<Post> posts) {
    final sorted = List<Post>.from(posts);
    sortInPlace(sorted);
    return sorted;
  }

  static void sortInPlace(List<Post> posts) {
    posts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }
}
