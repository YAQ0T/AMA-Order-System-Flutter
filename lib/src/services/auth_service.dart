import 'dart:convert';

import '../models/user.dart';
import 'api_client.dart';

class AuthResult {
  AuthResult({required this.user, required this.token});

  final AppUser user;
  final String token;
}

class AuthService {
  AuthService(this._client);

  final ApiClient _client;

  Future<AuthResult> login(String username, String password) async {
    final response = await _client.post('/api/auth/login', body: {
      'username': username,
      'password': password,
    });

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final token = data['token'] as String;
      final user = AppUser.fromJson(data['user'] as Map<String, dynamic>);
      return AuthResult(user: user, token: token);
    }

    final message = data['error'] as String? ?? 'Login failed';
    final requiresApproval = data['requiresApproval'] == true;
    throw AuthException(message, requiresApproval: requiresApproval);
  }

  Future<void> signup(String username, String password, String role) async {
    final response = await _client.post('/api/auth/register', body: {
      'username': username,
      'password': password,
      'role': role,
    });
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final data = jsonDecode(response.body) as Map<String, dynamic>? ?? {};
      throw AuthException(data['error'] as String? ?? 'Signup failed');
    }
  }

  Future<AppUser> me() async {
    final response = await _client.get('/api/auth/me');
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return AppUser.fromJson(data['user'] as Map<String, dynamic>);
    }
    throw AuthException(data['error'] as String? ?? 'Session expired');
  }

  Future<List<AppUser>> fetchTakers() async {
    final response = await _client.get('/api/auth/takers');
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final list = jsonDecode(response.body) as List<dynamic>;
      return list.map((u) => AppUser.fromJson(u as Map<String, dynamic>)).toList();
    }
    return [];
  }

  Future<List<AppUser>> fetchAccounters() async {
    final response = await _client.get('/api/auth/accounters');
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final list = jsonDecode(response.body) as List<dynamic>;
      return list.map((u) => AppUser.fromJson(u as Map<String, dynamic>)).toList();
    }
    return [];
  }
}

class AuthException implements Exception {
  AuthException(this.message, {this.requiresApproval = false});

  final String message;
  final bool requiresApproval;

  @override
  String toString() => message;
}
