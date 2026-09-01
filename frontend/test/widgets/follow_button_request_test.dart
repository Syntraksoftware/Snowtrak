import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:snowtrak/core/di/service_locator.dart';
import 'package:snowtrak/core/errors/app_result.dart';
import 'package:snowtrak/models/follow_stats.dart';
import 'package:snowtrak/services/apis/follow_api.dart';
import 'package:snowtrak/services/follow_service.dart';
import 'package:snowtrak/widgets/follow_button.dart';

class _StubFollowService extends FollowService {
  _StubFollowService(this.stats) : super(followApi: FollowApi(dio: Dio()));

  FollowStats stats;
  final List<String> approved = <String>[];
  final List<String> denied = <String>[];

  @override
  Future<AppResult<FollowStats>> getStats(String userId) async =>
      AppSuccess(stats);

  @override
  Future<AppResult<void>> approveRequest(String userId) async {
    approved.add(userId);
    // What the server does: the requester becomes a follower.
    stats = const FollowStats(followerCount: 1, isFollowedBy: true);
    return const AppSuccess(null);
  }

  @override
  Future<AppResult<void>> denyRequest(String userId) async {
    denied.add(userId);
    stats = const FollowStats();
    return const AppSuccess(null);
  }
}

Widget _host(Widget child) => MaterialApp(
      home: Scaffold(
        body: Center(child: SizedBox(width: 320, child: child)),
      ),
    );

void main() {
  late _StubFollowService service;

  void install(FollowStats stats) {
    service = _StubFollowService(stats);
    sl.registerSingleton<FollowService>(service);
  }

  tearDown(sl.reset);

  testWidgets('a request pending on you offers Accept and Decline, not Follow',
      (tester) async {
    install(const FollowStats(requestsYou: true));

    await tester.pumpWidget(_host(const FollowButton(userId: 'requester-1')));
    await tester.pumpAndSettle();

    expect(find.text('Accept'), findsOneWidget);
    expect(find.text('Decline'), findsOneWidget);
    expect(find.text('Follow'), findsNothing);
  });

  testWidgets('accepting calls approve and settles back to a normal button',
      (tester) async {
    install(const FollowStats(requestsYou: true));

    await tester.pumpWidget(_host(const FollowButton(userId: 'requester-1')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Accept'));
    await tester.pumpAndSettle();

    expect(service.approved, ['requester-1']);
    expect(find.text('Accept'), findsNothing);
    expect(find.text('Follow'), findsOneWidget);
  });

  testWidgets('declining calls deny, not approve', (tester) async {
    install(const FollowStats(requestsYou: true));

    await tester.pumpWidget(_host(const FollowButton(userId: 'requester-1')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Decline'));
    await tester.pumpAndSettle();

    expect(service.denied, ['requester-1']);
    expect(service.approved, isEmpty);
  });

  testWidgets('their request outranks your own pending one', (tester) async {
    // Both directions at once: you asked them, they asked you. Deciding on
    // theirs is the actionable half, so Requested must not win the slot.
    install(const FollowStats(requestsYou: true, hasRequested: true));

    await tester.pumpWidget(_host(const FollowButton(userId: 'requester-1')));
    await tester.pumpAndSettle();

    expect(find.text('Accept'), findsOneWidget);
    expect(find.text('Requested'), findsNothing);
  });
}
