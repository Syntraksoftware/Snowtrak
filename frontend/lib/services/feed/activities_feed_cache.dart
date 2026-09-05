import 'package:snowtrak/models/activity.dart';
import 'package:snowtrak/services/feed/feed_cache_store.dart';

/// On-device pages of the viewer's own activities.
///
/// Scoped per account. The pages are one person's activity history, some of
/// it `private`, and this device is shared: without a scope the next person
/// to sign in reads the last one's rows straight off disk, before any
/// request goes out. [owner] is what keeps those apart, and [clear] is what
/// removes them on the way out.
class ActivitiesFeedCache {
  /// `_v2` because `_v1` holds pages of the *public* feed, written when
  /// ActivityProvider read `/activities/`. An install upgrading in place
  /// would otherwise paint strangers' runs from disk on the first frame and
  /// look unfixed. The old keys age out on their own TTL.
  ActivitiesFeedCache({FeedCacheStore? store})
      : _store = store ??
            FeedCacheStore(storageKeyPrefix: 'activities_feed_cache_v2');

  static const cacheTtl = Duration(minutes: 30);

  /// Before anyone signs in. Nothing is written here in practice --
  /// ActivityProvider has no activities to cache until it has an owner --
  /// but a read needs a key either way.
  static const anonymousScope = 'anonymous';

  final FeedCacheStore _store;

  /// The account these pages belong to, or null before sign-in.
  String? owner;

  String get _scope => owner ?? anonymousScope;

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

  /// Removes the current owner's pages. Not the whole prefix: another
  /// account's pages are not this one's to delete.
  Future<void> clear() => _store.clearScope(_scope);
}
