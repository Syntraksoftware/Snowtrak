# Backend Tests

Comprehensive test suite for the Syntrak backend API.

## Test Structure

```
tests/
├── conftest.py          # Shared fixtures and configuration
├── test_auth.py         # Authentication endpoint tests
├── test_users.py        # User endpoint tests
├── test_security.py     # Password hashing tests
├── test_jwt.py          # JWT token tests
├── test_storage.py      # Storage layer tests
└── test_main.py         # Application setup tests
```

## Running Tests

### Setup Virtual Environment

**Important**: Python packages must be installed in a virtual environment (not system-wide).

```bash
cd /path/to/syntrak-application

# Create shared virtual environment at repo root (if it doesn't exist)
python3.11 -m venv .venv

# Install runtime + test dependencies
./.venv/bin/pip install -r backend/requirements.txt
./.venv/bin/pip install -r backend/main-backend/requirements-test.txt

# Optional activation
source .venv/bin/activate  # macOS/Linux
# .venv\Scripts\activate  # Windows
```

### Quick Start (Using Test Script)

```bash
cd backend/main-backend
./tests/run_tests.sh
```

This script will:
- Create virtual environment if needed
- Install all dependencies
- Run tests with coverage

### Run All Tests

```bash
pytest
```

### Run with Coverage

```bash
pytest --cov=app --cov-report=html
```

Coverage report will be generated in `htmlcov/index.html`

### Run Specific Test File

```bash
pytest tests/test_auth.py
```

### Run Specific Test

```bash
pytest tests/test_auth.py::TestLoginEndpoint::test_login_success
```

### Verbose Output

```bash
pytest -v
```

## Test Coverage

The test suite aims for **80%+ coverage** including:

- ✅ All API endpoints (auth, users)
- ✅ Core utilities (JWT, security, storage)
- ✅ Error handling and edge cases
- ✅ Authentication and authorization

## Best Practices

1. **Isolation**: Each test is independent and uses clean fixtures
2. **Fixtures**: Shared test data and clients in `conftest.py`
3. **Naming**: Tests follow `test_<functionality>_<scenario>` pattern
4. **Assertions**: Clear, specific assertions with helpful messages
5. **Coverage**: All critical paths are tested

## Continuous Integration

Tests should run automatically in CI/CD pipeline:

```yaml
# Example GitHub Actions
- name: Run tests
  run: |
    cd backend
    pip install -r requirements.txt -r requirements-test.txt
    pytest --cov=app --cov-report=xml
```

