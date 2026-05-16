import 'package:syntrak/core/errors/app_result.dart';
import 'package:syntrak/models/post.dart';
import 'package:syntrak/screens/community/community_post_mapper.dart';
import 'package:syntrak/services/community_service.dart';

class ThreadsFeedLoaderResult {
  const ThreadsFeedLoaderResult({
    required this.activeSubthreadId,
    required this.posts,
  });

  final String? activeSubthreadId;
  final List<Post> posts;
}

class ThreadsFeedLoader {
  ThreadsFeedLoader._();

  static String pickDefaultSubthreadId(List<Map<String, dynamic>> subthreads) {
    for (final s in subthreads) {
      if ((s['name'] ?? '').toString().toLowerCase().trim() == 'chat') {
        return (s['id'] ?? '').toString();
      }
    }
    return (subthreads.first['id'] ?? '').toString();
  }

  static Future<AppResult<ThreadsFeedLoaderResult>> load({
    required CommunityService service,
    required int pageSize,
    required Future<AppResult<Map<String, List<Map<String, dynamic>>>>> Function(
      List<String> postIds,
    )
    fetchBatchComments,
  }) async {
    final subResult = await service.getSubthreads(limit: 50);
    switch (subResult) {
      case AppFailure(:final error):
        return AppFailure(error);
      case AppSuccess(:final value):
        if (value.isEmpty) {
          return const AppSuccess(
            ThreadsFeedLoaderResult(activeSubthreadId: null, posts: []),
          );
        }
        final activeSubthreadId = pickDefaultSubthreadId(value);
        final postsResult = await service.getFeedPosts(limit: pageSize);
        switch (postsResult) {
          case AppFailure(:final error):
            return AppFailure(error);
          case AppSuccess(:final value):
            final postsData = value;
            final postIds = postsData
                .map((p) => (p['post_id'] ?? '').toString())
                .where((id) => id.isNotEmpty)
                .toList();
            final batchResult = await fetchBatchComments(postIds);
            switch (batchResult) {
              case AppFailure(:final error):
                return AppFailure(error);
              case AppSuccess(:final value):
                final byPost = value;
                final mapped = <Post>[];
                for (final rawPost in postsData) {
                  final pid = (rawPost['post_id'] ?? '').toString();
                  final comments = byPost[pid] ?? <Map<String, dynamic>>[];
                  mapped.add(CommunityPostMapper.mapBackendPost(rawPost, comments));
                }
                return AppSuccess(
                  ThreadsFeedLoaderResult(
                    activeSubthreadId: activeSubthreadId,
                    posts: mapped,
                  ),
                );
            }
        }
    }
  }
}
