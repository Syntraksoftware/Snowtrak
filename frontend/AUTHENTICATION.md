# Authentication Implementation

## Overview

The authentication system uses **JWT (JSON Web Tokens)** with access/refresh token pattern for secure, stateless authentication.

## Architecture

### Models

**`AuthSession`** (`lib/models/auth_session.dart`)
- `accessToken`: Short-lived JWT for API requests (typically 15-60 minutes)
- `refreshToken`: Long-lived token to obtain new access tokens (typically 7-30 days)
- `expiresAt`: Timestamp when access token expires
- `user`: Authenticated user profile
- `isExpired`: Computed property checking if access token is expired

### Services

**`ApiService`** (`lib/services/api_service.dart`)
- `register()`: Create new account → returns `AuthSession`
- `login()`: Authenticate user → returns `AuthSession`
- `refreshToken()`: Exchange refresh token for new `AuthSession`
- `getCurrentUser()`: Fetch current user profile (requires valid access token)

**`StorageService`** (`lib/services/storage_service.dart`)
- Persists entire `AuthSession` as JSON in SharedPreferences
- Auto-restores session on app restart

**`AuthProvider`** (`lib/providers/auth_provider.dart`)
- Manages authentication state across the app
- Handles automatic token refresh when expired
- Provides session lifecycle methods

## Authentication Flow

### 1. Registration
```dart
// User fills registration form
final success = await authProvider.register(
  email,
  password,
  firstName: firstName,
  lastName: lastName,
);

// Backend returns:
{
  "access_token": "eyJhbGc...",
  "refresh_token": "dGhpc2lz...",
  "expires_at": "2025-12-10T15:30:00Z",
  "user": {
    "id": "usr_123",
    "email": "athlete@example.com",
    "first_name": "Jane",
    "last_name": "Smith"
  }
}

// AuthProvider:
// 1. Parses response into AuthSession
// 2. Sets access token in ApiService
// 3. Saves entire session to storage
// 4. Sets isAuthenticated = true
```

### 2. Login
```dart
final success = await authProvider.login(email, password);

// Same flow as registration
// Backend validates credentials and returns AuthSession
```

### 3. Session Restoration (App Launch)
```dart
// main.dart initializes AuthProvider
// AuthProvider.checkAuth() runs automatically

Future<void> _checkAuth() async {
  // 1. Restore session from storage
  final session = await _restoreSession();
  
  if (session == null) {
    // No session → show login
    return;
  }
  
  // 2. Check if access token expired
  if (session.isExpired) {
    // 3. Try to refresh
    try {
      final newSession = await _refreshSession(session);
      // Success → save new session, continue
    } catch (e) {
      // Refresh failed → clear session, show login
    }
  } else {
    // 4. Token still valid → validate with backend
    final user = await apiService.getCurrentUser();
    // Success → user is authenticated
  }
}
```

### 4. Automatic Token Refresh
When an API call fails with 401 (Unauthorized):

```dart
// Option A: Manual refresh in AuthProvider
if (session.isExpired) {
  await authProvider.refreshSession();
}

// Option B: Dio interceptor (future enhancement)
_dio.interceptors.add(InterceptorsWrapper(
  onError: (error, handler) async {
    if (error.response?.statusCode == 401) {
      // Attempt refresh
      final newSession = await refreshToken();
      // Retry original request with new token
    }
  },
));
```

### 5. Logout
```dart
await authProvider.logout();

// Clears:
// - ApiService token
// - AuthProvider session
// - Storage (SharedPreferences)
// - Sets isAuthenticated = false
```

## Security Features

### JWT Structure
```
Header:
{
  "alg": "HS256",  // or RS256 for asymmetric
  "typ": "JWT"
}

Payload:
{
  "sub": "usr_123",           // user ID
  "email": "user@example.com",
  "iat": 1702214400,          // issued at
  "exp": 1702218000,          // expires at
  "type": "access"            // or "refresh"
}

Signature: HMAC-SHA256(header + payload + secret)
```

### Token Lifetimes (Backend Configuration)
- **Access Token**: 1 hour (short for security)
- **Refresh Token**: 7 days (convenience vs security tradeoff)

### Storage Security
- Uses `SharedPreferences` (encrypted on iOS, less secure on Android)
- **Future Enhancement**: Use `flutter_secure_storage` for sensitive data

### Best Practices
1. ✅ Never log tokens in production
2. ✅ Use HTTPS for all API calls
3. ✅ Validate tokens on backend for every request
4. ✅ Rotate refresh tokens on use (backend should issue new refresh token)
5. ✅ Implement token blacklist for logout (backend)
6. ⚠️ Consider biometric authentication for refresh token access

## Backend Requirements

### Endpoints

**POST `/api/v1/auth/register`**
```json
Request:
{
  "email": "user@example.com",
  "password": "securePassword123",
  "first_name": "Jane",
  "last_name": "Smith"
}

Response (200):
{
  "access_token": "jwt_access_token",
  "refresh_token": "jwt_refresh_token",
  "expires_at": "2025-12-10T15:30:00Z",
  "user": { ... }
}
```

**POST `/api/v1/auth/login`**
```json
Request:
{
  "email": "user@example.com",
  "password": "password123"
}

Response (200):
Same as register
```

**POST `/api/v1/auth/refresh`**
```json
Request:
{
  "refresh_token": "jwt_refresh_token"
}

Response (200):
{
  "access_token": "new_jwt_access_token",
  "refresh_token": "new_jwt_refresh_token",
  "expires_at": "2025-12-10T16:30:00Z",
  "user": { ... }
}

Error (401):
{
  "error": "Refresh token expired. Please login again."
}
```

**GET `/api/v1/users/me`**
```
Headers:
  Authorization: Bearer {access_token}

Response (200):
{
  "id": "usr_123",
  "email": "user@example.com",
  "first_name": "Jane",
  "last_name": "Smith"
}
```

## Future Enhancements

### OAuth 2.0 / Social Login
```dart
// Google Sign-In
Future<void> signInWithGoogle() async {
  final googleUser = await GoogleSignIn().signIn();
  final googleAuth = await googleUser?.authentication;
  
  final response = await apiService.oauthLogin(
    provider: 'google',
    idToken: googleAuth?.idToken,
  );
  
  _session = AuthSession.fromJson(response);
}

// Apple Sign-In, Facebook, etc.
```

### Biometric Authentication
```dart
import 'package:local_auth/local_auth.dart';

Future<bool> authenticateWithBiometrics() async {
  final localAuth = LocalAuthentication();
  
  final canAuthenticate = await localAuth.canCheckBiometrics;
  if (!canAuthenticate) return false;
  
  return await localAuth.authenticate(
    localizedReason: 'Authenticate to access Syntrak',
    options: const AuthenticationOptions(
      biometricOnly: true,
    ),
  );
}
```

### Multi-Factor Authentication (MFA)
```dart
// Step 1: Login returns MFA required
{
  "mfa_required": true,
  "mfa_token": "temp_token_123",
  "mfa_methods": ["totp", "sms"]
}

// Step 2: Submit MFA code
await apiService.verifyMfa(
  mfaToken: "temp_token_123",
  code: "123456",
  method: "totp",
);

// Returns full AuthSession on success
```

### Session Analytics
```dart
class AuthSession {
  final DateTime lastActivityAt;
  final String deviceId;
  final String ipAddress;
  final String userAgent;
}

// Backend tracks active sessions
// User can view and revoke sessions from profile
```

## Testing

### Unit Tests
```dart
test('AuthSession.isExpired returns true when token expired', () {
  final session = AuthSession(
    accessToken: 'token',
    expiresAt: DateTime.now().subtract(Duration(hours: 1)),
    user: testUser,
  );
  
  expect(session.isExpired, true);
});
```

### Integration Tests
```dart
testWidgets('Login flow saves session and navigates to home', (tester) async {
  await tester.pumpWidget(MyApp());
  
  // Enter credentials
  await tester.enterText(find.byKey(Key('email')), 'test@example.com');
  await tester.enterText(find.byKey(Key('password')), 'password');
  
  // Tap login
  await tester.tap(find.text('Login'));
  await tester.pumpAndSettle();
  
  // Verify navigation
  expect(find.byType(HomeScreen), findsOneWidget);
});
```
