# Flutter Tests

Comprehensive test suite for the Syntrak Flutter frontend.

## Test Structure

```
test/
├── helpers/
│   ├── test_helpers.dart    # Test helper exports
│   ├── test_data.dart       # Test data factories
│   └── mocks.dart           # Mock classes
├── services/
│   ├── test_api_service.dart
│   └── test_storage_service.dart
├── providers/
│   ├── test_auth_provider.dart
│   └── test_activity_provider.dart
├── widgets/
│   └── test_login_screen.dart
└── widget_test.dart         # Basic app test
```

## Running Tests

### Run All Tests

```bash
cd frontend
flutter test
```

### Run Specific Test File

```bash
flutter test test/providers/test_auth_provider.dart
```

### Run with Coverage

```bash
flutter test --coverage
```

Coverage report will be generated in `coverage/lcov.info`

### View Coverage Report

```bash
# Install lcov (macOS)
brew install lcov

# Generate HTML report
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

## Test Types

### Unit Tests

Test individual functions, classes, and services in isolation:

- **Services**: API calls, storage operations
- **Providers**: State management logic
- **Models**: Data validation and transformations

### Widget Tests

Test UI components and user interactions:

- **Screens**: Login, register, home, record
- **Widgets**: Buttons, forms, dialogs
- **Navigation**: Route transitions

## Best Practices

1. **Isolation**: Each test is independent
2. **Mocking**: Use mocks for external dependencies (API, storage)
3. **Test Data**: Use factories for consistent test data
4. **Naming**: Follow `test_<functionality>_<scenario>` pattern
5. **Coverage**: Aim for 80%+ coverage on critical paths

## Mocking

For complex mocks, use `mockito` with code generation:

1. Create mock class with `@GenerateMocks` annotation
2. Run `flutter pub run build_runner build`
3. Use generated mocks in tests

Example:
```dart
@GenerateMocks([ApiService])
void main() {
  test('example', () {
    final mockApi = MockApiService();
    when(mockApi.login(any, any)).thenAnswer((_) async => mockSession);
  });
}
```

## Continuous Integration

Tests should run automatically in CI/CD:

```yaml
# Example GitHub Actions
- name: Run Flutter tests
  run: |
    cd frontend
    flutter pub get
    flutter test --coverage
```

## Test Coverage Goals

- ✅ All services (API, storage, location)
- ✅ All providers (auth, activity)
- ✅ Critical screens (login, register, home)
- ✅ Error handling paths
- ✅ Edge cases and validation


