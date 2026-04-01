# Testing Guide

Comprehensive testing setup for the Syntrak application with best practices.

## Overview

The test suite covers both backend (Python/FastAPI) and frontend (Flutter) components with unit tests, integration tests, and widget tests.

## Backend Testing

### Setup

**Important**: Use a virtual environment (Python is externally managed on macOS).

```bash
cd backend

# Create and activate virtual environment
python3 -m venv venv
source venv/bin/activate  # macOS/Linux

# Install dependencies
pip install -r requirements.txt -r requirements-test.txt
```

**Or use the test script:**
```bash
cd backend
./tests/run_tests.sh
```

### Running Tests

```bash
# Run all tests
pytest

# Run with coverage
pytest --cov=app --cov-report=html

# Run specific test file
pytest tests/test_auth.py

# Run specific test
pytest tests/test_auth.py::TestLoginEndpoint::test_login_success
```

### Test Structure

- **`tests/conftest.py`**: Shared fixtures (app, client, test users)
- **`tests/test_auth.py`**: Authentication endpoint tests
- **`tests/test_users.py`**: User endpoint tests
- **`tests/test_security.py`**: Password hashing tests
- **`tests/test_jwt.py`**: JWT token tests
- **`tests/test_storage.py`**: Storage layer tests
- **`tests/test_main.py`**: Application setup tests

### Coverage

Target: **80%+ coverage**

Coverage report: `htmlcov/index.html`

## Frontend Testing

### Setup

```bash
cd frontend
flutter pub get
```

### Running Tests

```bash
# Run all tests
flutter test

# Run with coverage
flutter test --coverage

# Run specific test file
flutter test test/providers/test_auth_provider.dart
```

### Test Structure

- **`test/helpers/`**: Test utilities, mocks, and test data factories
- **`test/services/`**: Service layer tests
- **`test/providers/`**: State management tests
- **`test/widgets/`**: UI component tests

### Coverage

Target: **80%+ coverage**

Coverage report: `coverage/lcov.info`

Generate HTML report:
```bash
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

## Test Scripts

### Backend

```bash
./backend/tests/run_tests.sh
```

### Frontend

```bash
./frontend/test/run_tests.sh
```

## CI/CD Integration

Tests run automatically on push/PR via GitHub Actions (`.github/workflows/tests.yml`):

- Backend tests with pytest
- Frontend tests with Flutter
- Coverage reporting to Codecov

## Best Practices

### 1. Test Isolation
- Each test is independent
- Use fixtures for clean state
- Mock external dependencies

### 2. Naming Conventions
- Tests: `test_<functionality>_<scenario>`
- Test classes: `Test<Component>`
- Mocks: `Mock<Service>`

### 3. Test Data
- Use factories for consistent test data
- Avoid hardcoded values
- Use realistic test scenarios

### 4. Assertions
- Clear, specific assertions
- Test both success and failure paths
- Include edge cases

### 5. Coverage
- Focus on critical paths
- Don't aim for 100% (maintainability)
- Target 80%+ on important modules

## Writing New Tests

### Backend Example

```python
def test_login_success(client, clean_storage, test_user):
    response = client.post(
        "/api/v1/auth/login",
        json={"email": test_user.email, "password": "testpassword123"}
    )
    assert response.status_code == 200
    assert "access_token" in response.json()
```

### Frontend Example

```dart
test('login should set authenticated state on success', () async {
  final mockResponse = TestData.createAuthSessionJson();
  mockApiService.mockLoginResponse = mockResponse;

  final result = await authProvider.login('test@example.com', 'password123');

  expect(result, true);
  expect(authProvider.isAuthenticated, true);
});
```

## Debugging Tests

### Backend
```bash
# Verbose output
pytest -v

# Show print statements
pytest -s

# Stop on first failure
pytest -x
```

### Frontend
```bash
# Verbose output
flutter test --verbose

# Run specific test
flutter test test/providers/test_auth_provider.dart
```

## Common Issues

### Backend
- **Import errors**: Ensure virtual environment is activated
- **Database conflicts**: Tests use in-memory storage (auto-cleaned)

### Frontend
- **Mock errors**: Ensure mocks match actual service signatures
- **Async issues**: Use `await` and `pumpAndSettle()` for widget tests

## Next Steps

1. Add integration tests for end-to-end flows
2. Add performance tests for critical paths
3. Set up test coverage badges
4. Add mutation testing (optional)

