/// Unit tests for StorageService
import 'package:flutter_test/flutter_test.dart';
import '../helpers/mocks.dart';

void main() {
  group('StorageService', () {
    late MockStorageService storageService;

    setUp(() {
      storageService = MockStorageService();
    });

    test('init should load token and userId from storage', () async {
      storageService = MockStorageService(
        token: 'test_token',
        userId: 'test_user_id',
      );

      await storageService.init();

      expect(storageService.token, 'test_token');
      expect(storageService.userId, 'test_user_id');
    });

    test('init should handle null values', () async {
      storageService = MockStorageService();

      await storageService.init();

      expect(storageService.token, isNull);
      expect(storageService.userId, isNull);
    });

    test('saveToken should store token and userId', () async {
      await storageService.saveToken('new_token', 'new_user_id');

      expect(storageService.token, 'new_token');
      expect(storageService.userId, 'new_user_id');
    });

    test('clearToken should remove token and userId', () async {
      storageService = MockStorageService(
        token: 'test_token',
        userId: 'test_user_id',
      );

      await storageService.clearToken();

      expect(storageService.token, isNull);
      expect(storageService.userId, isNull);
    });

    test('setLocationPermissionAsked should update flag', () async {
      expect(storageService.locationPermissionAsked, false);

      await storageService.setLocationPermissionAsked(true);

      expect(storageService.locationPermissionAsked, true);
    });
  });
}

