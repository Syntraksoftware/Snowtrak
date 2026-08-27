import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:snowtrak/core/di/service_locator.dart';
import 'package:snowtrak/core/errors/app_error.dart';
import 'package:snowtrak/core/errors/app_result.dart';
import 'package:snowtrak/screens/profile/follow_requests_screen.dart';
import 'package:snowtrak/services/apis/follow_api.dart';
import 'package:snowtrak/services/follow_service.dart';

/// A settled stand-in: every call resolves immediately rather than through a
/// [Completer], and the lists below record what the screen asked for.
class _FakeFollowService extends FollowService {
  _FakeFollowService() : super(followApi: FollowApi(dio: Dio()));

  List<Map<String, dynamic>> requests = <Map<String, dynamic>>[];
  final List<String> approved = <String>[];
  final List<String> denied = <String>[];

  /// Set to make the next [approveRequest] call fail, e.g. with a 404 when
  /// the requester withdrew first.
  AppError? approveError;

  @override
  Future<AppResult<List<Map<String, dynamic>>>> getRequests({
    int limit = 20,
    int offset = 0,
  }) async =>
      AppSuccess(requests);

  @override
  Future<AppResult<void>> approveRequest(String userId) async {
    final error = approveError;
    if (error != null) return AppFailure(error);
    approved.add(userId);
    return const AppSuccess(null);
  }

  @override
  Future<AppResult<void>> denyRequest(String userId) async {
    denied.add(userId);
    return const AppSuccess(null);
  }
}

Widget _host(Widget child) => MaterialApp(home: child);

void main() {
  late _FakeFollowService fakeService;

  setUp(() {
    fakeService = _FakeFollowService();
    sl.registerSingleton<FollowService>(fakeService);
  });

  tearDown(sl.reset);

  testWidgets('approving removes the row and calls the service', (tester) async {
    fakeService.requests = [
      {'user_id': 'u-9', 'first_name': 'Pow', 'last_name': 'Fan'},
    ];

    await tester.pumpWidget(_host(const FollowRequestsScreen()));
    await tester.pumpAndSettle();
    expect(find.text('Pow Fan'), findsOneWidget);

    await tester.tap(find.text('Approve'));
    await tester.pumpAndSettle();

    expect(fakeService.approved, contains('u-9'));
    expect(find.text('Pow Fan'), findsNothing);
  });

  testWidgets('an empty list says so rather than showing nothing', (tester) async {
    fakeService.requests = [];
    await tester.pumpWidget(_host(const FollowRequestsScreen()));
    await tester.pumpAndSettle();
    expect(find.text('No follow requests'), findsOneWidget);
  });

  testWidgets('denying removes the row and calls the service', (tester) async {
    fakeService.requests = [
      {'user_id': 'u-3', 'first_name': 'Nix', 'last_name': 'Groom'},
    ];

    await tester.pumpWidget(_host(const FollowRequestsScreen()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Deny'));
    await tester.pumpAndSettle();

    expect(fakeService.denied, contains('u-3'));
    expect(find.text('Nix Groom'), findsNothing);
  });

  testWidgets('a 404 on approve leaves the row gone -- the request no longer '
      'exists', (tester) async {
    fakeService.requests = [
      {'user_id': 'u-7', 'first_name': 'Val', 'last_name': 'Ridge'},
    ];
    fakeService.approveError = AppError(
      userMessage: "We couldn't find that resource.",
      retryable: false,
      cause: DioException(
        requestOptions: RequestOptions(path: '/follows/me/requests/u-7/approve'),
        response: Response<void>(
          requestOptions: RequestOptions(path: '/follows/me/requests/u-7/approve'),
          statusCode: 404,
        ),
      ),
    );

    await tester.pumpWidget(_host(const FollowRequestsScreen()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Approve'));
    await tester.pumpAndSettle();

    // The request vanished server-side (withdrawn), so the row staying gone
    // is correct -- restoring it would resurrect a request nobody can act on.
    expect(find.text('Val Ridge'), findsNothing);
    expect(fakeService.approved, isEmpty);
  });

  testWidgets('a network failure on approve restores the row and warns',
      (tester) async {
    fakeService.requests = [
      {'user_id': 'u-4', 'first_name': 'Ori', 'last_name': 'Fjord'},
    ];
    fakeService.approveError = const AppError(
      userMessage: 'No internet connection. Try again when you are online.',
      retryable: true,
    );

    await tester.pumpWidget(_host(const FollowRequestsScreen()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Approve'));
    await tester.pumpAndSettle();

    expect(find.text('Ori Fjord'), findsOneWidget);
    expect(
      find.text('No internet connection. Try again when you are online.'),
      findsOneWidget,
    );
  });
}
