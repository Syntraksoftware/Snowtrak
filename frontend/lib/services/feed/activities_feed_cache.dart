import 'package:snowtrak/models/activity.dart';
import 'package:snowtrak/services/feed/feed_cache_store.dart';

class ActivitiesFeedCache {
  ActivitiesFeedCache({FeedCacheStore? store})
      : _store = store ??
            FeedCacheStore(storageKeyPrefix: 'activities_feed_cache_v1');

  static const cacheTtl = Duration(minutes: 30);
  static const _scope = 'default';

  final FeedCacheStore _store;

  Future<List<Activity>?> readPage(int page) async {
    final rawItems = await _store.readPage(
      scope: _scope,
      page: page,
      maxAge: cacheTtl,
    );
    if (rawItems == null) return null;

    return rawItems.map(Activity.fromCacheJson).toList();
  }

  Future<void> writePage(int page, List<Activity> activities) async {
    await _store.writePage(
      scope: _scope,
      page: page,
      items: activities.map((activity) => activity.toCacheJson()).toList(),
    );
  }

  Future<void> clear() => _store.clearScope(_scope);
}
