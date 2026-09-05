/// The activities cache holds one person's activity history, some of it
/// private, on a device more than one person may sign into. These tests are
/// about the scope that keeps those apart -- not about caching working.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:snowtrak/models/activity.dart';
import 'package:snowtrak/services/feed/activities_feed_cache.dart';
import 'package:snowtrak/services/feed/feed_cache_store.dart';

Activity _activity(String id, {required String userId}) {
  final at = DateTime.utc(2026, 9, 1, 9);
  return Activity(
    id: id,
    userId: userId,
    type: ActivityType.alpine,
    name: id,
    distance: 1000,
    duration: 600,
    elevationGain: 500,
    startTime: at,
    endTime: at.add(const Duration(hours: 2)),
    averagePace: 300,
    maxPace: 0,
    isPublic: false,
    createdAt: at,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  test('one account cannot read another\'s pages', () async {
    final cache = ActivitiesFeedCache();

    cache.owner = 'alex';
    await cache.writePage(1, [_activity('alex-1', userId: 'alex')]);

    cache.owner = 'blake';
    expect(await cache.readPage(1), isNull);

    // And Alex's pages are still Alex's -- the scope separates, it does not
    // overwrite.
    cache.owner = 'alex';
    expect(await cache.readPage(1), hasLength(1));
  });

  test('clear removes the current owner\'s pages and leaves the rest',
      () async {
    final cache = ActivitiesFeedCache();

    cache.owner = 'alex';
    await cache.writePage(1, [_activity('alex-1', userId: 'alex')]);
    cache.owner = 'blake';
    await cache.writePage(1, [_activity('blake-1', userId: 'blake')]);

    await cache.clear();

    expect(await cache.readPage(1), isNull);
    cache.owner = 'alex';
    expect(
      await cache.readPage(1),
      hasLength(1),
      reason: 'another account\'s pages are not this one\'s to delete',
    );
  });

  test('pages written by the v1 public-feed cache are not read back',
      () async {
    // What an install upgrading in place actually has on disk: pages of
    // GET /activities/, written under the old prefix and the old fixed
    // scope. Reading them would paint strangers' runs on the first frame
    // and make the fix look like it did not land.
    final legacy = FeedCacheStore(storageKeyPrefix: 'activities_feed_cache_v1');
    await legacy.writePage(
      scope: 'default',
      page: 1,
      items: [_activity('ana-day-3', userId: 'ana').toCacheJson()],
    );

    final cache = ActivitiesFeedCache()..owner = 'alex';
    expect(await cache.readPage(1), isNull);

    // Also nothing for a signed-out reader, which is what 'default' would
    // most plausibly collide with.
    cache.owner = null;
    expect(await cache.readPage(1), isNull);
  });

  test('a page survives a round trip for the owner that wrote it', () async {
    final cache = ActivitiesFeedCache()..owner = 'alex';

    await cache.writePage(1, [_activity('alex-1', userId: 'alex')]);

    final read = await cache.readPage(1);
    expect(read, isNotNull);
    expect(read!.single.id, 'alex-1');
    expect(read.single.userId, 'alex');
  });
}
