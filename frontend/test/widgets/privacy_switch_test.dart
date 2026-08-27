import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:snowtrak/core/config/app_config.dart';
import 'package:snowtrak/core/config/app_environment.dart';
import 'package:snowtrak/core/di/service_locator.dart';
import 'package:snowtrak/core/errors/app_result.dart';
import 'package:snowtrak/core/network/auth_token_store.dart';
import 'package:snowtrak/features/auth/data/auth_repository.dart';
import 'package:snowtrak/features/auth/data/auth_session_store.dart';
import 'package:snowtrak/features/profile/data/profile_repository.dart';
import 'package:snowtrak/models/follow_stats.dart';
import 'package:snowtrak/models/user.dart';
import 'package:snowtrak/providers/auth_provider.dart';
import 'package:snowtrak/screens/settings/privacy_settings_screen.dart';
import 'package:snowtrak/services/apis/auth_api.dart';
import 'package:snowtrak/services/apis/follow_api.dart';
import 'package:snowtrak/services/apis/privacy_api.dart';
import 'package:snowtrak/services/apis/users_api.dart';
import 'package:snowtrak/services/auth_service.dart';
import 'package:snowtrak/services/follow_service.dart';
import 'package:snowtrak/services/profile_service.dart';
import 'package:snowtrak/services/storage_service.dart';

/// A settled stand-in for the profile header's own [FollowService] fake in
/// `follow_button_layout_test.dart`: stats are set up before the pump and
/// resolve immediately, no [Completer] needed.
class _FakeFollowService extends FollowService {
  _FakeFollowService() : super(followApi: FollowApi(dio: Dio()));

  FollowStats stats = const FollowStats();

  @override
  Future<AppResult<FollowStats>> getStats(String userId) async =>
      AppSuccess(stats);
}

/// Stands in for [PrivacyApi] so the screen never reaches the network. Real
/// `PrivacyApi` is exercised by the write path in `privacy_api_test.dart`
/// -- this fake is only about what the screen does with the result.
class _FakePrivacyApi implements PrivacyApi {
  bool? lastWritten;
  bool shouldFail = false;

  @override
  Future<bool> setPrivate(bool isPrivate) async {
    if (shouldFail) {
      throw DioException(requestOptions: RequestOptions(path: '/users/me/privacy'));
    }
    lastWritten = isPrivate;
    return isPrivate;
  }
}

/// Real [AuthProvider] with every dependency wired to something inert --
/// none of them are exercised, since [user] is overridden directly rather
/// than produced by `checkAuth()`'s storage/network round trip.
class _FakeAuthProvider extends AuthProvider {
  _FakeAuthProvider(this._user)
      : super(
          AuthService(
            authRepository: AuthRepository(AuthApi(dio: Dio())),
            tokenStore: AuthTokenStore(),
            appConfig: AppConfig(
              environment: AppEnvironment.dev,
              mainApiBaseUrl: 'http://localhost',
              activityApiBaseUrl: 'http://localhost',
              communityApiBaseUrl: 'http://localhost',
              mapApiBaseUrl: 'http://localhost',
            ),
          ),
          ProfileService(
            profileRepository: ProfileRepository(UsersApi(dio: Dio())),
          ),
          AuthSessionStore(StorageService()),
        );

  final User _user;

  @override
  User? get user => _user;
}

Widget _host(Widget child, {required AuthProvider authProvider}) {
  return ChangeNotifierProvider<AuthProvider>.value(
    value: authProvider,
    child: MaterialApp(home: child),
  );
}

void main() {
  late _FakeFollowService fakeFollowService;
  late _FakePrivacyApi fakePrivacyApi;
  late _FakeAuthProvider fakeAuthProvider;

  setUp(() {
    fakeFollowService = _FakeFollowService();
    fakePrivacyApi = _FakePrivacyApi();
    fakeAuthProvider = _FakeAuthProvider(User(id: 'me', email: 'me@snowtrak.test'));
    sl.registerSingleton<FollowService>(fakeFollowService);
    sl.registerSingleton<PrivacyApi>(fakePrivacyApi);
    addTearDown(sl.reset);
  });

  testWidgets('the switch reflects the account and writes on change',
      (tester) async {
    fakeFollowService.stats = const FollowStats(isPrivate: false);

    await tester.pumpWidget(
      _host(const PrivacySettingsScreen(), authProvider: fakeAuthProvider),
    );
    await tester.pumpAndSettle();

    final toggle = find.byKey(const Key('private-account-switch'));
    expect(tester.widget<SwitchListTile>(toggle).value, isFalse);

    await tester.tap(toggle);
    await tester.pumpAndSettle();

    expect(fakePrivacyApi.lastWritten, isTrue);
    expect(tester.widget<SwitchListTile>(toggle).value, isTrue);
  });

  testWidgets('a failed write restores what the server last said',
      (tester) async {
    fakeFollowService.stats = const FollowStats(isPrivate: false);
    fakePrivacyApi.shouldFail = true;

    await tester.pumpWidget(
      _host(const PrivacySettingsScreen(), authProvider: fakeAuthProvider),
    );
    await tester.pumpAndSettle();

    final toggle = find.byKey(const Key('private-account-switch'));
    await tester.tap(toggle);
    await tester.pumpAndSettle();

    expect(fakePrivacyApi.lastWritten, isNull);
    expect(tester.widget<SwitchListTile>(toggle).value, isFalse);
  });
}
