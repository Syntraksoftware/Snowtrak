import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:snowtrak/core/config/app_environment.dart';
import 'package:snowtrak/core/di/service_locator.dart';
import 'package:snowtrak/core/logging/app_logger.dart';
import 'package:snowtrak/core/theme.dart';
import 'package:snowtrak/features/activities/data/activities_context_repository.dart';
import 'package:snowtrak/features/auth/data/auth_session_store.dart';
import 'package:snowtrak/providers/auth_provider.dart';
import 'package:snowtrak/providers/activity_provider.dart';
import 'package:snowtrak/providers/duel_provider.dart';
import 'package:snowtrak/providers/notification_provider.dart';
import 'package:snowtrak/screens/auth/login_screen.dart';
import 'package:snowtrak/screens/home/home_screen.dart';
import 'package:snowtrak/services/storage_service.dart';

Future<void> main() async {
  await bootstrapAndRun();
}

Future<void> bootstrapAndRun({AppEnvironment? environment}) async {
  WidgetsFlutterBinding.ensureInitialized();
  await setupServiceLocatorWithEnvironment(
    environment: environment,
  );

  runApp(const SnowtrakApp());
}

class SnowtrakApp extends StatefulWidget {
  const SnowtrakApp({super.key});

  @override
  State<SnowtrakApp> createState() => _SnowtrakAppState();
}

class _SnowtrakAppState extends State<SnowtrakApp> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();

  @override
  void initState() {
    super.initState();
    AppLogger.instance.attachScaffoldMessenger(_scaffoldMessengerKey);
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => StorageService()),
        Provider<AuthSessionStore>(
          create: (context) => AuthSessionStore(
            context.read<StorageService>(),
          ),
        ),
        ChangeNotifierProxyProvider<AuthSessionStore, AuthProvider>(
          create: (context) {
            AppLogger.instance.debug('[Main] Creating AuthProvider');
            final sessionStore = context.read<AuthSessionStore>();
            final auth = sl<AuthProvider>(param1: sessionStore);
            auth.checkAuth();
            return auth;
          },
          update: (_, sessionStore, previous) {
            if (previous == null) {
              AppLogger.instance.debug(
                '[Main] Updating AuthProvider (previous was null)',
              );
              final auth = sl<AuthProvider>(param1: sessionStore);
              auth.checkAuth();
              return auth;
            }
            return previous;
          },
        ),
        // Proxied on auth, not a plain provider: ActivityProvider holds the
        // signed-in user's own activities, so it has to be told whose and
        // to drop the last account's when that changes. AuthProvider
        // notifies on sign-in, sign-out and a restored session, which is
        // every moment the answer moves.
        ChangeNotifierProxyProvider<AuthProvider, ActivityProvider>(
          create: (_) => sl<ActivityProvider>(),
          update: (_, auth, previous) {
            final activities = previous ?? sl<ActivityProvider>();
            unawaited(activities.setOwner(auth.user?.id));
            return activities;
          },
        ),
        Provider<ActivitiesContextRepository>(
          create: (_) => sl<ActivitiesContextRepository>(),
        ),
        ChangeNotifierProvider(
          // No viewer id yet: auth has not resolved at this point, so the
          // eager load reads follow requests only. The notifications screen
          // reloads with the viewer and picks up duels then.
          create: (_) =>
              NotificationProvider(followService: sl(), duelService: sl())
                ..loadNotifications(),
        ),
        ChangeNotifierProvider(
          create: (_) => DuelProvider(duelService: sl()),
        ),
      ],
      child: MaterialApp(
        navigatorKey: _navigatorKey,
        scaffoldMessengerKey: _scaffoldMessengerKey,
        title: 'Snowtrak',
        debugShowCheckedModeBanner: false,
        theme: SnowtrakTheme.lightTheme,
        darkTheme: SnowtrakTheme.darkTheme,
        themeMode: ThemeMode.light,
        home: const _AppWrapper(),
      ),
    );
  }
}

class _AppWrapper extends StatefulWidget {
  const _AppWrapper();

  @override
  State<_AppWrapper> createState() => _AppWrapperState();
}

class _AppWrapperState extends State<_AppWrapper> {
  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        AppLogger.instance.debug(
          '[AppWrapper] Building. isLoading: ${authProvider.isLoading}, '
          'isAuthenticated: ${authProvider.isAuthenticated}',
        );

        if (authProvider.isLoading) {
          return _LoadingScreenWithTimeout(authProvider: authProvider);
        }
        if (authProvider.isAuthenticated) {
          AppLogger.instance.debug('[AppWrapper] Showing HomeScreen');
          return const HomeScreen();
        } else {
          AppLogger.instance.debug('[AppWrapper] Showing LoginScreen');
          return const LoginScreen();
        }
      },
    );
  }
}

class _LoadingScreenWithTimeout extends StatefulWidget {
  final AuthProvider authProvider;

  const _LoadingScreenWithTimeout({required this.authProvider});

  @override
  State<_LoadingScreenWithTimeout> createState() =>
      _LoadingScreenWithTimeoutState();
}

class _LoadingScreenWithTimeoutState extends State<_LoadingScreenWithTimeout> {
  Timer? _timeoutTimer;
  bool _showSlowStartupHint = false;

  @override
  void initState() {
    super.initState();
    _timeoutTimer = Timer(const Duration(seconds: 5), () {
      if (mounted && widget.authProvider.isLoading) {
        setState(() {
          _showSlowStartupHint = true;
        });
      }
    });
  }

  @override
  void dispose() {
    _timeoutTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            if (_showSlowStartupHint) ...[
              const SizedBox(height: 12),
              const Text('Startup is taking longer than expected...'),
            ],
          ],
        ),
      ),
    );
  }
}
