import 'package:syntrak/providers/auth_provider.dart';

/// Result of [ensureAuthenticatedSession]: token refreshed and session valid,
/// or a user-facing error message.
sealed class AuthenticatedSessionResult {
  const AuthenticatedSessionResult();
}

/// Session is ready for authenticated API calls (profile, community, etc.).
/// [resolvedUserId] is [viewUserId] if set, otherwise the signed-in user's id.
final class AuthenticatedSessionOk extends AuthenticatedSessionResult {
  const AuthenticatedSessionOk({this.resolvedUserId});

  /// May be null when [requireUserId] was false and the profile has no user id yet.
  final String? resolvedUserId;
}

/// Could not establish an authenticated session (no login, refresh failed, etc.).
final class AuthenticatedSessionError extends AuthenticatedSessionResult {
  const AuthenticatedSessionError(this.message);

  final String message;
}

/// Ensures the user has a valid session and refreshes the access token if needed.
///
/// Use [requireUserId] when the caller needs a target user id (e.g. profile by id,
/// posts by user). When true, fails with "User not found" if neither [viewUserId]
/// nor [AuthProvider.user] provides an id.
Future<AuthenticatedSessionResult> ensureAuthenticatedSession(
  AuthProvider auth, {
  String? viewUserId,
  bool requireUserId = false,
}) async {
  if (auth.session == null) {
    return const AuthenticatedSessionError('Not authenticated');
  }

  final refreshed = await auth.refreshTokenIfNeeded();
  if (!refreshed) {
    return const AuthenticatedSessionError(
      'Session expired. Please login again.',
    );
  }

  if (auth.session == null) {
    return const AuthenticatedSessionError('Not authenticated');
  }

  final resolved = viewUserId ?? auth.user?.id;
  if (requireUserId && resolved == null) {
    return const AuthenticatedSessionError('User not found');
  }

  return AuthenticatedSessionOk(resolvedUserId: resolved);
}
