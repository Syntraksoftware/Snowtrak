import 'package:syntrak/models/post.dart';

class ThreadsTabPostState {
  ThreadsTabPostState._();

  static void prepend(List<Post> posts, Post post) {
    posts.insert(0, post);
  }

  static void replaceById(List<Post> posts, String id, Post next) {
    final index = posts.indexWhere((p) => p.id == id);
    if (index != -1) {
      posts[index] = next;
    }
  }

  static void removeById(List<Post> posts, String id) {
    posts.removeWhere((p) => p.id == id);
  }

  static void toggleLike(List<Post> posts, String id) {
    final index = posts.indexWhere((p) => p.id == id);
    if (index == -1) return;
    final current = posts[index];
    posts[index] = current.copyWith(
      likedByCurrentUser: !current.likedByCurrentUser,
      likeCount: current.likedByCurrentUser
          ? current.likeCount - 1
          : current.likeCount + 1,
    );
  }

  static void appendLocalReply({
    required List<Post> posts,
    required String postId,
    required Post localReply,
  }) {
    final index = posts.indexWhere((p) => p.id == postId);
    if (index == -1) return;
    final current = posts[index];
    final replies = <Post>[...(current.replies ?? []), localReply];
    posts[index] = current.copyWith(
      replies: replies,
      replyCount: replies.length,
    );
  }

  static void replaceReply({
    required List<Post> posts,
    required String postId,
    required String tempReplyId,
    required Post confirmedReply,
  }) {
    final index = posts.indexWhere((p) => p.id == postId);
    if (index == -1) return;
    final current = posts[index];
    final nextReplies = (current.replies ?? [])
        .map((reply) => reply.id == tempReplyId ? confirmedReply : reply)
        .toList()
        .cast<Post>();
    posts[index] = current.copyWith(
      replies: nextReplies,
      replyCount: nextReplies.length,
    );
  }
}
