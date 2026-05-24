import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:syntrak/models/post.dart';
import 'package:syntrak/services/feed/post_cache_codec.dart';

class CachedCommunityFeed {
  const CachedCommunityFeed({
    required this.activeSubthreadId,
    required this.posts,
    required this.cachedAt,
    required this.offset,
  });

  final String? activeSubthreadId;
  final List<Post> posts;
  final DateTime cachedAt;
  final int offset;

  bool isFresh(Duration maxAge) =>
      DateTime.now().difference(cachedAt) <= maxAge;
}

class CommunityFeedCache {
  static const _storageKey = 'community_feed_cache_v1';
  static const cacheTtl = Duration(minutes: 15);
  static const prefetchPageSize = 15;

  Future<CachedCommunityFeed?> read() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null) return null;

    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      final cachedAt = DateTime.parse(json['cachedAt'] as String);
      final posts = (json['posts'] as List)
          .map((item) => PostCacheCodec.fromJson(item as Map<String, dynamic>))
          .toList();
      return CachedCommunityFeed(
        activeSubthreadId: json['activeSubthreadId'] as String?,
        posts: posts,
        cachedAt: cachedAt,
        offset: json['offset'] as int? ?? posts.length,
      );
    } catch (_) {
      await prefs.remove(_storageKey);
      return null;
    }
  }

  Future<void> write({
    required String? activeSubthreadId,
    required List<Post> posts,
    required int offset,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final payload = jsonEncode({
      'cachedAt': DateTime.now().toIso8601String(),
      'activeSubthreadId': activeSubthreadId,
      'offset': offset,
      'posts': posts.map(PostCacheCodec.toJson).toList(),
    });
    await prefs.setString(_storageKey, payload);
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
  }
}
