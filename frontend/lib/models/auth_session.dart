import 'package:syntrak/models/user.dart';

class AuthSession {
  final String accessToken;
  final String? refreshToken;
  final DateTime? expiresAt;
  final User user;

  AuthSession({
    required this.accessToken,
    this.refreshToken,
    this.expiresAt,
    required this.user,
  });

  bool get isExpired {
    if (expiresAt != null) {
      // if expires at is not null, check if it is expired
      return DateTime.now().isAfter(expiresAt!);
    } else {
      // if expires at is null, return false
      return false;
    }
  }

  factory AuthSession.fromJson(Map<String, dynamic> json) {
    return AuthSession(
      accessToken: json['access_token'],
      refreshToken: json['refresh_token'],
      expiresAt: json['expires_at'] != null
          ? DateTime.parse(json['expires_at'])
          : null,
      user: User.fromJson(json['user']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'access_token': accessToken,
      'refresh_token': refreshToken,
      'expires_at': expiresAt?.toIso8601String(),
      'user': user.toJson(),
    };
  }
}
