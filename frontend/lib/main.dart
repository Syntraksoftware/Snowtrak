import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:syntrak/core/config/app_environment.dart';
import 'package:syntrak/core/di/service_locator.dart';
import 'package:syntrak/core/logging/app_logger.dart';
import 'package:syntrak/core/theme.dart';
import 'package:syntrak/models/notification.dart'; // notification model
import 'package:syntrak/providers/auth_provider.dart';
import 'package:syntrak/providers/activity_provider.dart';
import 'package:syntrak/providers/notification_provider.dart';
import 'package:syntrak/screens/auth/login_screen.dart';
import 'package:syntrak/screens/home/home_screen.dart';
import 'package:syntrak/services/api_service.dart';
import 'package:syntrak/services/notification_service.dart';
import 'package:syntrak/services/storage_service.dart';


//todo: rename app name to snowtrak 

Future<void> main() async {
  await bootstrapAndRun();
  //main endpoint to start the app
  //collecting necessary components and start run the app 
}

Future<void> bootstrapAndRun({AppEnvironment? environment}) async {
  WidgetsFlutterBinding.ensureInitialized(); // initialisation 
  await setupServiceLocatorWithEnvironment(environment: environment); //injected to container
  //service locator: manage dependices and provide them to the app when needed

  runApp(const SyntrakApp());
}

class SyntrakApp extends StatefulWidget { 
  //extends: inherit from statefulwidget 
  //stateful widget to manage app state and dependencise
  const SyntrakApp({super.key}); //super: pass key to parent class
  //current blueprint of app 

  @override
  State<SyntrakApp> createState(){
    return _SyntrakAppState();
  }
  //starting the app after initialization, create state for the app
}

class _SyntrakAppState extends State<SyntrakApp> {
  // Global key for Navigator to maintain state across rebuilds
  // change of pages 
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  //snack bar messages key 
  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();

  @override
  void initState() {
    super.initState(); //parent class initialization
    AppLogger.instance.attachScaffoldMessenger(_scaffoldMessengerKey);
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) {// storage service: local storage and data persistency
          final storage = StorageService();
          // Initialize storage and wait for it
          storage.init().then((_) {
            // Storage initialized
          });
          return storage;
        }),

        ChangeNotifierProxyProvider<StorageService, AuthProvider>(
          create: (context) {
            AppLogger.instance.debug('[Main] Creating AuthProvider');
            // wait for storage to be initialized before creating AuthProvider

            final storage = Provider.of<StorageService>(context, listen: false);
            // listen false: do not rebuild when storage chanegs, handle manually with update methods 

            // activity provider: depend on the auth provider for user token and session manager 
            final apiService = sl<ApiService>();
            final auth = AuthProvider(apiService, storage);

            // Initialize storage first, then check auth
            AppLogger.instance.debug(
              '[Main] Initializing storage and checking auth...',
            );
            storage.init().then((_) {
              AppLogger.instance.debug(
                '[Main] Storage initialized, calling checkAuth',
              );
              // Storage is ready, now check auth
              auth.checkAuth();
            }).catchError((error) {
              AppLogger.instance.warning(
                '[Main] Storage init error, calling checkAuth anyway',
                error: error,
              );
              // If storage init fails, still check auth
              auth.checkAuth();
            });
            return auth;
          },
          update: (_, storage, previous) {
            if (previous == null) {
              AppLogger.instance.debug(
                '[Main] Updating AuthProvider (previous was null)',
              );
              final apiService = sl<ApiService>();
              final auth = AuthProvider(apiService, storage);
              // Initialize storage first, then check auth
              storage.init().then((_) {
                AppLogger.instance.debug(
                  '[Main] Storage initialized in update, calling checkAuth',
                );
                auth.checkAuth();
              }).catchError((error) {
                AppLogger.instance.warning(
                  '[Main] Storage init error in update',
                  error: error,
                );
                auth.checkAuth();
              });
              return auth;
            }
            return previous;
          },
        ),
        ChangeNotifierProxyProvider<StorageService, ActivityProvider>(//caching activity data and manage it 
        // proxy provider: depend on storage service to manage activity data and cache it, update when storage changes

          create: (_) => ActivityProvider(sl<ApiService>()), // request activity data from backend and manage it
          update: (_, storage, previous) =>
              previous ?? ActivityProvider(sl<ApiService>()),
        ),
        // Notification Provider
        ChangeNotifierProvider(
          create: (_) =>
              NotificationProvider(notificationsRepository: sl())
                ..loadNotifications(),
        ),
      ],
      child: MaterialApp(// inherited from parent widget, provide material design and theme to the app
        navigatorKey: _navigatorKey,
        scaffoldMessengerKey: _scaffoldMessengerKey,
        title: 'Syntrak',
        debugShowCheckedModeBanner: false,
        theme: SyntrakTheme.lightTheme,
        darkTheme: SyntrakTheme.darkTheme,
        themeMode: ThemeMode.light,
        // Use home for simpler navigation that handles hot reload better
        home: const _AppWrapper(),
      ),
    );
  }
}

// Wrapper widget
// manager for the entire app, handle auth state and show snackbar notifcations, maintain stable navigator key for consistent navigation and state management across the app
class _AppWrapper extends StatefulWidget {
  const _AppWrapper();

  @override
  State<_AppWrapper> createState() => _AppWrapperState();
}

class _AppWrapperState extends State<_AppWrapper> {
  @override
  void initState() {
    super.initState();
    // Set up notification callback for showing banners
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setupNotificationCallback();
      // Todo: considering moving this to initstate setup, if before the first frame there is a notification, we migh miss it, but if we set up the callback after the first frame, we might miss notifications that come in during app startup. Need to test and decide the best approach.
    });
  }

  void _setupNotificationCallback() {
    final notificationProvider = context.read<NotificationProvider>();
    notificationProvider.onNewNotification = (AppNotification notification) {
      // Show banner notification when a new notification is received from backend
      if (mounted) {
        NotificationService.showBanner(
          context,
          notification: notification,
          onTap: () {
            // Optional: Navigate to notification details or related screen
            NotificationService.showToast(
                context, 'Tapped: ${notification.title}');
          },
        );
      }
    };
  }

  @override
  Widget build(BuildContext context) {
    // Use Consumer to properly listen to auth state changes
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

// Safety widget: if loading takes too long, force show login
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
    // If still loading after 10 seconds, force check auth again
    _timeoutTimer = Timer(const Duration(seconds: 5), () {
      if (widget.authProvider.isLoading) {
        // Force complete the auth check
        widget.authProvider.checkAuth();
      }
    });
  }

  @override
  void dispose() {
    _timeoutTimer?.cancel();
    super.dispose();
    // Todo: need to cancel the timer if the widget is diposed: 

  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
