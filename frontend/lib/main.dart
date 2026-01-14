import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:syntrak/core/theme.dart';
import 'package:syntrak/models/notification.dart';
import 'package:syntrak/providers/auth_provider.dart';
import 'package:syntrak/providers/activity_provider.dart';
import 'package:syntrak/providers/notification_provider.dart';
import 'package:syntrak/screens/auth/login_screen.dart';
import 'package:syntrak/screens/home/home_screen.dart';
import 'package:syntrak/services/api_service.dart';
import 'package:syntrak/services/notification_service.dart';
import 'package:syntrak/services/storage_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SyntrakApp());
}

class SyntrakApp extends StatefulWidget {
  const SyntrakApp({super.key});

  @override
  State<SyntrakApp> createState() => _SyntrakAppState();
}

class _SyntrakAppState extends State<SyntrakApp> {
  // Global key for Navigator to maintain state across rebuilds
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) {
          final storage = StorageService();
          // Initialize storage and wait for it
          storage.init().then((_) {
            // Storage initialized
          });
          return storage;
        }),
        ChangeNotifierProxyProvider<StorageService, AuthProvider>(
          create: (context) {
            print('🔍 [Main] Creating AuthProvider');
            final storage = Provider.of<StorageService>(context, listen: false);
            final apiService = ApiService();
            final auth = AuthProvider(apiService, storage);
            // Initialize storage first, then check auth
            print('🔍 [Main] Initializing storage and checking auth...');
            storage.init().then((_) {
              print('🔍 [Main] Storage initialized, calling checkAuth');
              // Storage is ready, now check auth
              auth.checkAuth();
            }).catchError((error) {
              print(
                  '🔍 [Main] Storage init error: $error, calling checkAuth anyway');
              // If storage init fails, still check auth (will show login)
              auth.checkAuth();
            });
            return auth;
          },
          update: (_, storage, previous) {
            if (previous == null) {
              print('🔍 [Main] Updating AuthProvider (previous was null)');
              final apiService = ApiService();
              final auth = AuthProvider(apiService, storage);
              // Initialize storage first, then check auth
              storage.init().then((_) {
                print(
                    '🔍 [Main] Storage initialized in update, calling checkAuth');
                auth.checkAuth();
              }).catchError((error) {
                print('🔍 [Main] Storage init error in update: $error');
                auth.checkAuth();
              });
              return auth;
            }
            return previous;
          },
        ),
        ChangeNotifierProxyProvider<StorageService, ActivityProvider>(
          create: (_) => ActivityProvider(ApiService()),
          update: (_, storage, previous) =>
              previous ?? ActivityProvider(ApiService()),
        ),
        // Notification Provider
        ChangeNotifierProvider(
          create: (_) => NotificationProvider()..loadNotifications(),
        ),
      ],
      child: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          print(
              '🔍 [Main] Building MaterialApp. isLoading: ${authProvider.isLoading}, isAuthenticated: ${authProvider.isAuthenticated}');
          return MaterialApp(
            navigatorKey: _navigatorKey,
            title: 'Syntrak',
            debugShowCheckedModeBanner: false,
            theme: SyntrakTheme.lightTheme,
            darkTheme: SyntrakTheme.darkTheme,
            themeMode: ThemeMode.light,
            // Use home for simpler navigation that handles hot reload better
            home: _AppWrapper(authProvider: authProvider),
          );
        },
      ),
    );
  }
}

// Wrapper widget to maintain stable Navigator identity and set up notifications
class _AppWrapper extends StatefulWidget {
  final AuthProvider authProvider;

  const _AppWrapper({required this.authProvider});

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
    // Use the same logic as _buildHome but in a stable widget
    if (widget.authProvider.isLoading) {
      return _LoadingScreenWithTimeout(authProvider: widget.authProvider);
    }
    if (widget.authProvider.isAuthenticated) {
      return const HomeScreen();
    } else {
      return const LoginScreen();
    }
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
    _timeoutTimer = Timer(const Duration(seconds: 10), () {
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
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
