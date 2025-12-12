/// Unit tests for ApiService
import 'package:flutter_test/flutter_test.dart';
import 'package:syntrak/services/api_service.dart';

void main() {
  group('ApiService', () {
    late ApiService apiService;

    setUp(() {
      apiService = ApiService();
    });

    test('setToken should store token', () {
      apiService.setToken('test_token');
      // Token is private, but we can test by making an authenticated request
      // In a real test, you'd mock the HTTP client
    });

    test('setToken should update token', () {
      apiService.setToken('test_token');
      apiService.setToken(null);
      // Token is cleared by setting to null
    });

    // Note: Full integration tests would require mocking Dio or using a test server
    // These are examples of what to test when mocking is set up
    
    group('Authentication', () {
      test('login should return AuthSession on success', () async {
        // This would require mocking Dio responses
        // Example structure:
        // when(mockDio.post('/auth/login', ...))
        //     .thenAnswer((_) async => Response(
        //       data: TestData.createAuthSession().toJson(),
        //       statusCode: 200,
        //     ));
        // 
        // final session = await apiService.login('test@example.com', 'password');
        // expect(session, isA<AuthSession>());
      });

      test('login should throw on invalid credentials', () async {
        // Mock 401 response
        // expect(() => apiService.login('wrong@example.com', 'wrong'),
        //     throwsException);
      });
    });

    group('Activities', () {
      test('getActivities should return list of activities', () async {
        // Mock successful response
        // final activities = await apiService.getActivities();
        // expect(activities, isA<List<Activity>>());
      });

      test('createActivity should return created activity', () async {
        // Mock successful creation
        // final activity = TestData.createActivity();
        // final created = await apiService.createActivity(activity);
        // expect(created.id, isNotNull);
      });
    });
  });
}

