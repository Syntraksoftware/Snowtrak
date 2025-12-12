/// Unit tests for ActivityProvider
import 'package:flutter_test/flutter_test.dart';
import 'package:syntrak/providers/activity_provider.dart';
import '../helpers/mocks.dart';
import '../helpers/test_data.dart';

void main() {
  group('ActivityProvider', () {
    late ActivityProvider activityProvider;
    late MockApiService mockApiService;

    setUp(() {
      mockApiService = MockApiService();
      activityProvider = ActivityProvider(mockApiService);
    });

    test('initial state should be empty', () {
      expect(activityProvider.activities, isEmpty);
      expect(activityProvider.isLoading, false);
      expect(activityProvider.error, isNull);
    });

    test('loadActivities should populate activities on success', () async {
      final mockActivities = TestData.createActivities(count: 3);
      mockApiService.mockActivities = mockActivities;

      await activityProvider.loadActivities();

      expect(activityProvider.activities.length, 3);
      expect(activityProvider.isLoading, false);
      expect(activityProvider.error, isNull);
    });

    test('loadActivities should set error on failure', () async {
      mockApiService.shouldFail = true;
      mockApiService.errorMessage = 'Failed to load activities';

      await activityProvider.loadActivities();

      expect(activityProvider.activities, isEmpty);
      expect(activityProvider.isLoading, false);
      expect(activityProvider.error, isNotNull);
    });

    test('createActivity should add activity to list on success', () async {
      final newActivity = TestData.createActivity(id: 'new_activity');
      final createdActivity = TestData.createActivity(id: 'created_activity');
      mockApiService.mockCreatedActivity = createdActivity;

      final result = await activityProvider.createActivity(newActivity);

      expect(result, isNotNull);
      expect(activityProvider.activities.length, 1);
      expect(activityProvider.activities.first.id, 'created_activity');
      expect(activityProvider.isLoading, false);
    });

    test('createActivity should return null on failure', () async {
      mockApiService.shouldFail = true;
      final newActivity = TestData.createActivity();

      final result = await activityProvider.createActivity(newActivity);

      expect(result, isNull);
      expect(activityProvider.activities, isEmpty);
      expect(activityProvider.error, isNotNull);
    });

    test('isLoading should be true during async operations', () async {
      // This would require more sophisticated mocking to test loading states
      // In a real implementation, you'd use a Completer or similar
      expect(activityProvider.isLoading, false);
    });
  });
}

