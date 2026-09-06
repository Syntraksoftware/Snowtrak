/// ActivityProvider is owner-scoped, and four screens depend on that.
///
/// Home's stats carousel, the profile training block, Progress' streaks and
/// the map all render whatever this provider holds. It used to hold
/// `GET /activities/` -- the public discovery feed -- so all four showed
/// other people's skiing as the viewer's own (#58). The endpoint tests below
/// are what stop that coming back; the owner tests are what stop the same
/// rows outliving a sign-out on a shared device.
library;

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:snowtrak/core/config/app_config.dart';
import 'package:snowtrak/core/config/app_environment.dart';
import 'package:snowtrak/core/errors/app_error.dart';
import 'package:snowtrak/core/errors/app_result.dart';
import 'package:snowtrak/features/activities/data/activities_repository.dart';
import 'package:snowtrak/models/activity.dart';
import 'package:snowtrak/models/user_stats.dart';
import 'package:snowtrak/providers/activity_provider.dart';
import 'package:snowtrak/services/activities_service.dart';
import 'package:snowtrak/services/apis/activities_api.dart';
import 'package:snowtrak/services/feed/activities_feed_cache.dart';

Activity _activity(String id, {String userId = 'alex'}) {
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
    isPublic: true,
    createdAt: at,
  );
}

/// Records which endpoint the provider reached for.
///
/// Subclasses the real service rather than an interface, matching
/// notification_provider_test.dart. `getActivities` is left live and
/// answering, so a regression shows up as "read the feed" rather than as a
/// crash that could be read as any other failure.
class _RecordingActivitiesService extends ActivitiesService {
  _RecordingActivitiesService({
    AppEnvironment environment = AppEnvironment.prod,
  }) : super(
          activitiesRepository: ActivitiesRepository(ActivitiesApi(dio: Dio())),
          appConfig: AppConfig(
            environment: environment,
            mainApiBaseUrl: 'http://localhost',
            activityApiBaseUrl: 'http://localhost',
            communityApiBaseUrl: 'http://localhost',
            mapApiBaseUrl: 'http://localhost',
          ),
        );

  final List<String> calls = <String>[];
  final List<int> requestedPages = <int>[];

  /// Keyed by page, so a paging test can hand out different rows per page.
  Map<int, List<Activity>> minePages = <int, List<Activity>>{};
  List<Activity> feed = <Activity>[_activity('public-feed-row', userId: 'ana')];
  bool fail = false;

  @override
  Future<AppResult<List<Activity>>> getActivities({
    int page = 1,
    int limit = 20,
  }) async {
    calls.add('getActivities');
    return AppSuccess(feed);
  }

  @override
  Future<AppResult<List<Activity>>> getMyActivities({
    int page = 1,
    int limit = 20,
  }) async {
    calls.add('getMyActivities');
    requestedPages.add(page);
    if (fail) {
      return const AppFailure(AppError(userMessage: 'boom'));
    }
    return AppSuccess(minePages[page] ?? const <Activity>[]);
  }

  @override
  Future<AppResult<UserStats>> getMyStats() async {
    return const AppFailure(AppError(userMessage: 'no stats'));
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _RecordingActivitiesService service;
  late ActivitiesFeedCache cache;
  late ActivityProvider provider;

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    service = _RecordingActivitiesService();
    cache = ActivitiesFeedCache();
    provider = ActivityProvider(service, cache);
  });

  group('reads the owner-scoped endpoint', () {
    test('loadActivities never touches the public feed', () async {
      service.minePages = {
        1: [_activity('mine-1'), _activity('mine-2')],
      };

      await provider.setOwner('alex');
      await provider.loadActivities(refresh: true, forceNetwork: true);

      expect(service.calls, ['getMyActivities']);
      expect(
        provider.activities.map((activity) => activity.id),
        ['mine-1', 'mine-2'],
      );
      expect(
        provider.activities.every((activity) => activity.userId == 'alex'),
        isTrue,
        reason: 'the provider must hold nobody else\'s activities',
      );
    });

    test('loadMore pages the owner-scoped endpoint too', () async {
      // A full first page is what sets hasMore, so loadMore has somewhere to
      // go. _pageSize is 20.
      service.minePages = {
        1: List.generate(20, (index) => _activity('page1-$index')),
        2: [_activity('page2-0')],
      };

      await provider.setOwner('alex');
      await provider.loadActivities(refresh: true, forceNetwork: true);
      expect(provider.hasMore, isTrue);

      await provider.loadMore();

      expect(service.calls, everyElement('getMyActivities'));
      expect(service.requestedPages, containsAllInOrder([1, 2]));
      expect(provider.activities.last.id, 'page2-0');
    });

    test('a failed load leaves the list empty, not filled from the feed',
        () async {
      service.fail = true;

      await provider.setOwner('alex');
      await provider.loadActivities(refresh: true, forceNetwork: true);

      expect(service.calls, isNot(contains('getActivities')));
      expect(provider.activities, isEmpty);
      expect(provider.error, isNotNull);
    });
  });

  group('owner switching', () {
    test('drops the previous account\'s rows from memory', () async {
      service.minePages = {
        1: [_activity('alex-1')],
      };
      await provider.setOwner('alex');
      await provider.loadActivities(refresh: true, forceNetwork: true);
      expect(provider.activities, isNotEmpty);

      await provider.setOwner('blake');

      expect(provider.activities, isEmpty);
      expect(provider.hasMore, isTrue);
    });

    test('signing out drops the previous account\'s cached pages', () async {
      service.minePages = {
        1: [_activity('alex-1')],
      };
      await provider.setOwner('alex');
      await provider.loadActivities(refresh: true, forceNetwork: true);
      // The write is what makes the next assertion meaningful.
      expect(await cache.readPage(1), isNotNull);

      await provider.setOwner(null);

      cache.owner = 'alex';
      expect(
        await cache.readPage(1),
        isNull,
        reason: 'a signed-out account\'s activities must not survive on disk',
      );
    });

    test('the same id twice is a no-op', () async {
      service.minePages = {
        1: [_activity('alex-1')],
      };
      await provider.setOwner('alex');
      await provider.loadActivities(refresh: true, forceNetwork: true);

      var notifications = 0;
      provider.addListener(() => notifications++);
      await provider.setOwner('alex');

      // AuthProvider notifies on every profile refresh, and the proxy
      // provider calls setOwner each time. Wiping the list on those would
      // blank the screen at random.
      expect(provider.activities, isNotEmpty);
      expect(notifications, 0);
    });

    test('hydrateFromCache reads only the current owner\'s pages', () async {
      service.minePages = {
        1: [_activity('alex-1')],
      };
      await provider.setOwner('alex');
      await provider.loadActivities(refresh: true, forceNetwork: true);

      final other = ActivityProvider(
        _RecordingActivitiesService(),
        ActivitiesFeedCache(),
      );
      await other.setOwner('blake');
      await other.hydrateFromCache();

      expect(other.activities, isEmpty);
    });
  });
}
