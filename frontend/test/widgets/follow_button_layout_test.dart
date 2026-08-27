import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:snowtrak/core/di/service_locator.dart';
import 'package:snowtrak/core/errors/app_error.dart';
import 'package:snowtrak/core/errors/app_result.dart';
import 'package:snowtrak/models/follow_stats.dart';
import 'package:snowtrak/services/apis/follow_api.dart';
import 'package:snowtrak/services/follow_service.dart';
import 'package:snowtrak/widgets/follow_button.dart';

class _StubFollowService extends FollowService {
  _StubFollowService(this.stats) : super(followApi: FollowApi(dio: Dio()));

  final Completer<AppResult<FollowStats>> stats;

  @override
  Future<AppResult<FollowStats>> getStats(String userId) => stats.future;
}

/// A settled stand-in for the privacy-state tests below: stats and the
/// server's follow response are set up before the pump, and every call
/// resolves immediately rather than through a [Completer].
class _FakeFollowService extends FollowService {
  _FakeFollowService() : super(followApi: FollowApi(dio: Dio()));

  FollowStats stats = const FollowStats();
  String followState = 'following';
  final List<String> withdrawn = <String>[];

  @override
  Future<AppResult<FollowStats>> getStats(String userId) async =>
      AppSuccess(stats);

  @override
  Future<AppResult<String>> follow(String userId) async =>
      AppSuccess(followState);

  @override
  Future<AppResult<void>> unfollow(String userId) async =>
      const AppSuccess(null);

  @override
  Future<AppResult<void>> withdrawRequest(String userId) async {
    withdrawn.add(userId);
    return const AppSuccess(null);
  }
}

/// Centred and width-bounded so the button reports its natural height rather
/// than stretching to fill the body -- the height is the thing under test.
Widget _host(Widget child) {
  return MaterialApp(
    home: Scaffold(
      body: Center(
        child: SizedBox(
          width: 320,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [child],
          ),
        ),
      ),
    ),
  );
}

Completer<AppResult<FollowStats>> _install() {
  final pending = Completer<AppResult<FollowStats>>();
  sl.registerSingleton<FollowService>(_StubFollowService(pending));
  return pending;
}

void main() {
  testWidgets('the block is the same height before and after the stats land',
      (tester) async {
    // The reported bug: the button rendered nothing while it was loading, so
    // it popped into the profile card and shoved everything below it down.
    final pending = _install();
    addTearDown(sl.reset);

    await tester.pumpWidget(_host(const FollowButton(userId: 'someone')));
    await tester.pump();
    final whileLoading = tester.getSize(find.byType(FollowButton));

    pending.complete(
      const AppSuccess(FollowStats(followerCount: 12, followingCount: 34)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Follow'), findsOneWidget);
    expect(tester.getSize(find.byType(FollowButton)), whileLoading);
  });

  testWidgets('a failed load keeps the slot and offers a retry',
      (tester) async {
    final pending = _install();
    addTearDown(sl.reset);

    await tester.pumpWidget(_host(const FollowButton(userId: 'someone')));
    await tester.pump();
    final whileLoading = tester.getSize(find.byType(FollowButton));

    pending.complete(
      const AppFailure(AppError(userMessage: 'nope', retryable: true)),
    );
    await tester.pumpAndSettle();

    // A grey block that never resolves is worse than no block at all.
    expect(find.text('Retry'), findsOneWidget);
    expect(tester.getSize(find.byType(FollowButton)), whileLoading);
  });

  testWidgets('a private account shows Follow, then Requested', (tester) async {
    final fakeService = _FakeFollowService();
    sl.registerSingleton<FollowService>(fakeService);
    addTearDown(sl.reset);

    fakeService.stats = const FollowStats(isPrivate: true);
    fakeService.followState = 'requested';

    await tester.pumpWidget(_host(const FollowButton(userId: 'user-2')));
    await tester.pumpAndSettle();
    expect(find.text('Follow'), findsOneWidget);

    await tester.tap(find.text('Follow'));
    await tester.pumpAndSettle();
    expect(find.text('Requested'), findsOneWidget);
    expect(find.text('Following'), findsNothing);
  });

  testWidgets('tapping Requested withdraws', (tester) async {
    final fakeService = _FakeFollowService();
    sl.registerSingleton<FollowService>(fakeService);
    addTearDown(sl.reset);

    fakeService.stats = const FollowStats(isPrivate: true, hasRequested: true);

    await tester.pumpWidget(_host(const FollowButton(userId: 'user-2')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Requested'));
    await tester.pumpAndSettle();

    expect(fakeService.withdrawn, contains('user-2'));
    expect(find.text('Follow'), findsOneWidget);
  });
}
