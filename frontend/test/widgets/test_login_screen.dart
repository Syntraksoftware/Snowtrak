/// Widget tests for LoginScreen
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:syntrak/screens/auth/login_screen.dart';
import 'package:syntrak/providers/auth_provider.dart';
import '../helpers/mocks.dart';

void main() {
  group('LoginScreen Widget Tests', () {
    late MockApiService mockApiService;
    late MockStorageService mockStorageService;
    late AuthProvider authProvider;

    setUp(() {
      mockApiService = MockApiService();
      mockStorageService = MockStorageService();
      authProvider = AuthProvider(mockApiService, mockStorageService);
    });

    Widget createTestWidget() {
      return MaterialApp(
        home: MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
          ],
          child: const LoginScreen(),
        ),
      );
    }

    testWidgets('should display email and password fields', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      expect(find.byType(TextFormField), findsNWidgets(2));
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
    });

    testWidgets('should display login button', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      expect(find.text('Login'), findsOneWidget);
      expect(find.byType(ElevatedButton), findsOneWidget);
    });

    testWidgets('should display register link', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      expect(find.text('Don\'t have an account? Register'), findsOneWidget);
    });

    testWidgets('should allow entering email and password', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      final emailField = find.byType(TextFormField).first;
      final passwordField = find.byType(TextFormField).last;

      await tester.enterText(emailField, 'test@example.com');
      await tester.enterText(passwordField, 'password123');

      expect(find.text('test@example.com'), findsOneWidget);
      expect(find.text('password123'), findsOneWidget);
    });

    testWidgets('should show error message on login failure', (WidgetTester tester) async {
      mockApiService.shouldFail = true;
      mockApiService.errorMessage = 'Invalid credentials';

      await tester.pumpWidget(createTestWidget());

      final emailField = find.byType(TextFormField).first;
      final passwordField = find.byType(TextFormField).last;
      final loginButton = find.text('Login');

      await tester.enterText(emailField, 'wrong@example.com');
      await tester.enterText(passwordField, 'wrong');
      await tester.tap(loginButton);
      await tester.pumpAndSettle();

      // Error should be displayed (implementation dependent)
      expect(find.textContaining('Invalid'), findsWidgets);
    });
  });
}

