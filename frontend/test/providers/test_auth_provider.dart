/// Unit tests for AuthProvider
import 'package:flutter_test/flutter_test.dart';
import 'package:syntrak/providers/auth_provider.dart';
import '../helpers/mocks.dart';
import '../helpers/test_data.dart';

void main() {
  group('AuthProvider', () {
    late AuthProvider authProvider;
    late MockApiService mockApiService;
    late MockStorageService mockStorageService;

    setUp(() {
      mockApiService = MockApiService();
      mockStorageService = MockStorageService();
      authProvider = AuthProvider(mockApiService, mockStorageService);
    });

    test('initial state should be unauthenticated', () {
      expect(authProvider.isAuthenticated, false);
      expect(authProvider.user, isNull);
      expect(authProvider.session, isNull);
    });

    test('login should set authenticated state on success', () async {
      // Mock successful login response
      final mockResponse = TestData.createAuthSessionJson();
      mockApiService.mockLoginResponse = mockResponse;

      final result = await authProvider.login('test@example.com', 'password123');

      expect(result, true);
      expect(authProvider.isAuthenticated, true);
      expect(authProvider.user, isNotNull);
      expect(authProvider.session, isNotNull);
    });

    test('login should set error on failure', () async {
      mockApiService.shouldFail = true;
      mockApiService.errorMessage = 'Invalid credentials';

      final result = await authProvider.login('wrong@example.com', 'wrong');

      expect(result, false);
      expect(authProvider.isAuthenticated, false);
      expect(authProvider.error, isNotNull);
    });

    test('register should set authenticated state on success', () async {
      final mockResponse = TestData.createAuthSessionJson(
        user: TestData.createUser(
          email: 'new@example.com',
          firstName: 'New',
          lastName: 'User',
        ),
      );
      mockApiService.mockRegisterResponse = mockResponse;

      final result = await authProvider.register(
        'new@example.com',
        'password123',
        firstName: 'New',
        lastName: 'User',
      );

      expect(result, true);
      expect(authProvider.isAuthenticated, true);
      expect(authProvider.user, isNotNull);
    });

    test('logout should clear authenticated state', () async {
      // First login
      final mockResponse = TestData.createAuthSessionJson();
      mockApiService.mockLoginResponse = mockResponse;
      await authProvider.login('test@example.com', 'password123');
      
      expect(authProvider.isAuthenticated, true);

      // Then logout
      await authProvider.logout();

      expect(authProvider.isAuthenticated, false);
      expect(authProvider.user, isNull);
      expect(authProvider.session, isNull);
    });

    test('checkAuth should restore session from storage', () async {
      final mockUser = TestData.createUser();
      mockApiService.mockUser = mockUser;
      
      mockStorageService = MockStorageService(
        token: 'valid_token',
        userId: 'user_123',
      );
      
      authProvider = AuthProvider(mockApiService, mockStorageService);
      
      await authProvider.checkAuth();

      expect(authProvider.isAuthenticated, true);
      expect(authProvider.user, isNotNull);
    });

    test('checkAuth should handle expired token', () async {
      mockStorageService = MockStorageService(
        token: 'expired_token',
        userId: 'user_123',
      );
      
      // Mock getCurrentUser to fail (expired token)
      mockApiService.shouldFail = true;
      mockApiService.errorMessage = 'Token expired';
      
      authProvider = AuthProvider(mockApiService, mockStorageService);
      
      await authProvider.checkAuth();

      expect(authProvider.isAuthenticated, false);
    });
  });
}

