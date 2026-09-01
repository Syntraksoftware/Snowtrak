import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:snowtrak/core/errors/app_error.dart';
import 'package:snowtrak/core/errors/app_result.dart';
import 'package:snowtrak/models/notification.dart';
import 'package:snowtrak/providers/notification_provider.dart';
import 'package:snowtrak/services/apis/follow_api.dart';
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

void main() {
  late _FakeFollowService service;
  late NotificationProvider provider;

  setUp(() {
    service = _FakeFollowService();
    provider = NotificationProvider(followService: service);
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
}
