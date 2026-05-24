import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Metadata shared by paginated on-device feed caches.
class CachedFeedPageMeta {
  const CachedFeedPageMeta({
    required this.cachedAt,
    required this.page,
    required this.itemCount,
  });

  final DateTime cachedAt;
  final int page;
  final int itemCount;

  bool isFresh(Duration maxAge) =>
      DateTime.now().difference(cachedAt) <= maxAge;
}

/// SharedPreferences helper for JSON feed pages keyed by namespace + user.
class FeedCacheStore {
  FeedCacheStore({required this.storageKeyPrefix});

  final String storageKeyPrefix;

  String _pageKey({required String scope, required int page}) =>
      '${storageKeyPrefix}_${scope}_page_$page';

  String _metaKey(String scope) => '${storageKeyPrefix}_${scope}_meta';

  Future<List<Map<String, dynamic>>?> readPage({
    required String scope,
    required int page,
    required Duration maxAge,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_pageKey(scope: scope, page: page));
    if (raw == null) return null;

    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      final cachedAt = DateTime.parse(json['cachedAt'] as String);
      if (DateTime.now().difference(cachedAt) > maxAge) {
        return null;
      }
      return (json['items'] as List)
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();
    } catch (_) {
      await prefs.remove(_pageKey(scope: scope, page: page));
      return null;
    }
  }

  Future<void> writePage({
    required String scope,
    required int page,
    required List<Map<String, dynamic>> items,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final payload = jsonEncode({
      'cachedAt': DateTime.now().toIso8601String(),
      'page': page,
      'items': items,
    });
    await prefs.setString(_pageKey(scope: scope, page: page), payload);
    await prefs.setString(
      _metaKey(scope),
      jsonEncode({
        'cachedAt': DateTime.now().toIso8601String(),
        'lastPage': page,
        'itemCount': items.length,
      }),
    );
  }

  Future<CachedFeedPageMeta?> readMeta(String scope) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_metaKey(scope));
    if (raw == null) return null;
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      return CachedFeedPageMeta(
        cachedAt: DateTime.parse(json['cachedAt'] as String),
        page: json['lastPage'] as int,
        itemCount: json['itemCount'] as int,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> clearScope(String scope) async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs
        .getKeys()
        .where((key) => key.startsWith('${storageKeyPrefix}_${scope}_'))
        .toList();
    for (final key in keys) {
      await prefs.remove(key);
    }
  }
}
