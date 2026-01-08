import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:syntrak/core/theme.dart';
import 'package:syntrak/providers/auth_provider.dart';
import 'package:syntrak/providers/activity_provider.dart';
import 'package:syntrak/screens/auth/login_screen.dart';
import 'package:syntrak/screens/home/home_screen.dart';
import 'package:syntrak/services/api_service.dart';
import 'package:syntrak/services/storage_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SyntrakApp());
}

class SyntrakApp extends StatelessWidget {
  const SyntrakApp({super.key});

  Widget _buildHome(AuthProvider authProvider) {
    print(
        '🔍 [Main] _buildHome called. isLoading: ${authProvider.isLoading}, isAuthenticated: ${authProvider.isAuthenticated}');
    // Safety timeout: if loading takes more than 10 seconds, show login
    if (authProvider.isLoading) {
      print('🔍 [Main] Showing loading screen');
      return _LoadingScreenWithTimeout(
        authProvider: authProvider,
      );
    }
    if (authProvider.isAuthenticated) {
      print('🔍 [Main] User is authenticated, showing HomeScreen');
      return const HomeScreen();
    } else {
      print('🔍 [Main] User not authenticated, showing LoginScreen');
      return const LoginScreen();
    }
  }

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
      ],
      child: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          print(
              '🔍 [Main] Building MaterialApp. isLoading: ${authProvider.isLoading}, isAuthenticated: ${authProvider.isAuthenticated}');

          return MaterialApp(
            title: 'Syntrak',
            debugShowCheckedModeBanner: false,
            // Remove key to prevent Navigator recreation issues
            // The home widget will update automatically via Consumer
            theme: SyntrakTheme.lightTheme,
            darkTheme: SyntrakTheme.darkTheme,
            themeMode: ThemeMode.light, // Can be changed to system or dark
            home: _buildHome(authProvider),
          );
        },
      ),
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
