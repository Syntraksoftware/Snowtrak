import 'package:syntrak/services/apis/auth_api.dart';

class AuthRepository {
  AuthRepository(this._api);

  final AuthApi _api;

  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    String? firstName,
    String? lastName,
  }) {
    return _api.register(
      email: email,
      password: password,
      firstName: firstName,
      lastName: lastName,
    );
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) {
    return _api.login(email: email, password: password);
  }

  Future<Map<String, dynamic>> refreshToken(String refreshToken) {
    return _api.refreshToken(refreshToken);
  }
}
