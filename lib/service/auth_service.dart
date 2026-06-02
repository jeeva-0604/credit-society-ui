import 'dart:convert';
import 'package:http/http.dart' as http;
import 'apiservice.dart';

class AuthService {
  static final AuthService _singleton = AuthService._internal();
  factory AuthService() => _singleton;
  AuthService._internal();

  final String _baseUrl = ApiService.getBaseUrl().replaceAll(RegExp(r'/+$'), '');

  bool _isAuthenticated = false;
  bool get isAuthenticated => _isAuthenticated;

  /// Calls POST /auth/login?email=EMAIL&password=PASSWORD
  /// Stores the access token in ApiService on success.
  /// Returns true on success, false on failure.
  Future<bool> login(String email, String password) async {
    try {
      final url = Uri.parse("$_baseUrl/auth/login")
          .replace(queryParameters: {"email": email, "password": password});

      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final token = body["access_token"] as String?;
        if (token != null && token.isNotEmpty) {
          ApiService().setAccessToken(token);
          _isAuthenticated = true;
          return true;
        }
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  void logout() {
    ApiService().setAccessToken('');
    _isAuthenticated = false;
  }
}
