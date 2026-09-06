import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:snowtrak/core/errors/app_error.dart';
import 'package:snowtrak/core/errors/app_result.dart';
import 'package:snowtrak/models/duel.dart';
import 'package:snowtrak/models/notification.dart';
import 'package:snowtrak/providers/notification_provider.dart';
import 'package:snowtrak/services/apis/duel_api.dart';
import 'package:snowtrak/services/apis/follow_api.dart';
import 'package:snowtrak/services/duel_service.dart';
import 'package:snowtrak/services/follow_service.dart';

class _FakeFollowService extends FollowService {
  _FakeFollowService() : super(followApi: FollowApi(dio: Dio()));

  List<Map<String, dynamic>> requests = <Map<String, dynamic>>[];
  AppError? error;

  @override
  Future<AppResult<List<Map<String, dynamic>>>> getRequests({
    int limit = 20,
    int offset = 0,
  }) async {
    final failure = error;
    if (failure != null) return AppFailure(failure);
    return AppSuccess(requests);
  }
}

class _FakeDuelService extends DuelService {
  _FakeDuelService() : super(duelApi: DuelApi(dio: Dio()));

  List<Duel> duels = <Duel>[];

  @override
  Future<AppResult<List<Duel>>> list({
    DuelStatus? status,
    int limit = 20,
    int offset = 0,
  }) async =>
      AppSuccess(duels);
}

Duel _pendingDuel({
  required String challengerId,
  required String opponentId,
  required DateTime createdAt,
  String? challengerName,
}) {
  return Duel(
    id: 'duel-1',
    challengerId: challengerId,
    opponentId: opponentId,
    metric: DuelMetric.vertical,
    duration: DuelDuration.week,
    status: DuelStatus.pending,
    createdAt: createdAt,
    challengerName: challengerName,
  );
}

void main() {
  late _FakeFollowService service;
  late _FakeDuelService duelService;
  late NotificationProvider provider;

  setUp(() {
    service = _FakeFollowService();
    duelService = _FakeDuelService();
    provider = NotificationProvider(
      followService: service,
      duelService: duelService,
    );
  });

  test('carries the requester id in metadata, so a tap can open the profile',
      () async {
    service.requests = [
      {
        'user_id': 'abc-123',
        'first_name': 'Mei',
        'last_name': 'Wong',
        'created_at': '2026-09-01T10:00:00Z',
      },
    ];

    await provider.loadNotifications();

    final notification = provider.notifications.single;
    expect(notification.metadata?['user_id'], 'abc-123');
    expect(notification.type, NotificationType.follow);
    expect(notification.message, 'Mei Wong asked to follow you');
    expect(notification.isRead, isFalse);
  });

  test('falls back to the email handle when the requester has no name',
      () async {
    service.requests = [
      {'user_id': 'abc-123', 'email': 'skier@example.com'},
    ];

    await provider.loadNotifications();

    expect(provider.notifications.single.senderName, 'skier');
  });

  test('ids are stable across reloads, so a read one does not reappear unread',
      () async {
    service.requests = [
      {'user_id': 'abc-123', 'first_name': 'Mei'},
    ];
    await provider.loadNotifications();
    final firstId = provider.notifications.single.id;

    await provider.loadNotifications();

    expect(provider.notifications.single.id, firstId);
  });

  test('a failed read surfaces an error rather than an empty list', () async {
    service.error = const AppError(userMessage: 'No connection');

    await provider.loadNotifications();

    expect(provider.error, 'No connection');
    expect(provider.hasUnread, isFalse);
  });

  test('a pending duel you were challenged to becomes a notification',
      () async {
    duelService.duels = [
      _pendingDuel(
        challengerId: 'sam',
        opponentId: 'me',
        createdAt: DateTime.utc(2026, 9, 1, 10),
        challengerName: 'Sam Park',
      ),
    ];

    await provider.loadNotifications(viewerId: 'me');

    final notification = provider.notifications.single;
    expect(notification.type, NotificationType.challenge);
    expect(notification.metadata?['duel_id'], 'duel-1');
    expect(notification.message, contains('Sam Park'));
  });

  test('a duel you sent is not a notification for you', () async {
    // It is something you are waiting on, not something to answer.
    duelService.duels = [
      _pendingDuel(
        challengerId: 'me',
        opponentId: 'sam',
        createdAt: DateTime.utc(2026, 9, 1, 10),
      ),
    ];

    await provider.loadNotifications(viewerId: 'me');

    expect(provider.notifications, isEmpty);
  });

  test('without a viewer only follow requests are read', () async {
    // App start, before auth resolves: the provider cannot tell an incoming
    // duel from an outgoing one, so it reads neither.
    duelService.duels = [
      _pendingDuel(
        challengerId: 'sam',
        opponentId: 'me',
        createdAt: DateTime.utc(2026, 9, 1, 10),
      ),
    ];
    service.requests = [
      {'user_id': 'abc-123', 'first_name': 'Mei'},
    ];

    await provider.loadNotifications();

    expect(provider.notifications.single.type, NotificationType.follow);
  });

  test('the two sources interleave newest first', () async {
    service.requests = [
      {
        'user_id': 'abc-123',
        'first_name': 'Mei',
        'created_at': '2026-09-01T08:00:00Z',
      },
    ];
    duelService.duels = [
      _pendingDuel(
        challengerId: 'sam',
        opponentId: 'me',
        createdAt: DateTime.utc(2026, 9, 1, 12),
      ),
    ];

    await provider.loadNotifications(viewerId: 'me');

    expect(
      provider.notifications.map((n) => n.type),
      [NotificationType.challenge, NotificationType.follow],
    );
  });
}
