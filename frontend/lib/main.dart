import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:syntrak/core/config/app_environment.dart';
import 'package:syntrak/core/di/service_locator.dart';
import 'package:syntrak/core/logging/app_logger.dart';
import 'package:syntrak/core/theme.dart';
import 'package:syntrak/features/activities/data/activities_context_repository.dart';
import 'package:syntrak/features/auth/data/auth_session_store.dart';
import 'package:syntrak/models/notification.dart'; // notification model
import 'package:syntrak/providers/auth_provider.dart';
import 'package:syntrak/providers/activity_provider.dart';
import 'package:syntrak/providers/notification_provider.dart';
import 'package:syntrak/screens/auth/login_screen.dart';
import 'package:syntrak/screens/home/home_screen.dart';
import 'package:syntrak/services/notification_service.dart';
import 'package:syntrak/services/storage_service.dart';

Future<void> main() async {
  await bootstrapAndRun();
}

Future<void> bootstrapAndRun({AppEnvironment? environment}) async {
  WidgetsFlutterBinding.ensureInitialized();
  await setupServiceLocatorWithEnvironment(
    environment: environment,
  );

  runApp(const SyntrakApp());
}

class SyntrakApp extends StatefulWidget {
  const SyntrakApp({super.key});

  @override
  State<SyntrakApp> createState() => _SyntrakAppState();
}

class _SyntrakAppState extends State<SyntrakApp> {
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
        ChangeNotifierProvider<ActivityProvider>(
          create: (_) => sl<ActivityProvider>(),
        ),
        Provider<ActivitiesContextRepository>(
          create: (_) => sl<ActivitiesContextRepository>(),
        ),
        ChangeNotifierProvider(
          create: (_) => NotificationProvider(notificationsRepository: sl())
            ..loadNotifications(),
        ),
      ],
      child: MaterialApp(
        navigatorKey: _navigatorKey,
        scaffoldMessengerKey: _scaffoldMessengerKey,
        title: 'Syntrak',
        debugShowCheckedModeBanner: false,
        theme: SyntrakTheme.lightTheme,
        darkTheme: SyntrakTheme.darkTheme,
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
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setupNotificationCallback();
    });
  }

  void _setupNotificationCallback() {
    final notificationProvider = context.read<NotificationProvider>();
    notificationProvider.onNewNotification = (AppNotification notification) {
      if (mounted) {
        NotificationService.showBanner(
          context,
          notification: notification,
          onTap: () {
            NotificationService.showToast(
              context,
              'Tapped: ${notification.title}',
            );
          },
        );
      }
    };
  }

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

  @override
  void initState() {
    super.initState();
    _timeoutTimer = Timer(const Duration(seconds: 5), () {
      if (widget.authProvider.isLoading) {
        widget.authProvider.checkAuth();
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
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
