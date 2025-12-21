import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';

class AuthNotifier extends ChangeNotifier {
  AuthNotifier(ApiClient client) : _service = AuthService(client) {
    _client = client;
    restoreSession();
  }

  static const _tokenKey = 'token';
  static const _userKey = 'user';

  late final ApiClient _client;
  final AuthService _service;

  AppUser? user;
  String? token;
  bool isLoading = false;
  bool initializing = true;
  String? error;

  bool get isAuthenticated => token != null && user != null;
  bool get isApproved => user?.isApproved ?? false;
  bool get prefersDark => user?.prefersDark ?? false;

  Future<void> restoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    final savedToken = prefs.getString(_tokenKey);
    if (savedToken == null) {
      initializing = false;
      notifyListeners();
      return;
    }

    token = savedToken;
    _client.updateToken(token);

    final cachedUser = _loadCachedUser(prefs);
    user = cachedUser ?? _userFromToken(savedToken);
    if (cachedUser == null && user != null) {
      await _persistUser(user!, prefs: prefs);
    }

    initializing = false;
    notifyListeners();

    try {
      final refreshed = await _service.me();
      user = refreshed;
      await _persistUser(refreshed, prefs: prefs);
    } catch (_) {
      // Keep cached user/token; do not auto-logout on refresh errors.
    }
    notifyListeners();
  }

  Future<void> login(String username, String password) async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      final result = await _service.login(username, password);
      token = result.token;
      user = result.user;
      _client.updateToken(token);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenKey, token!);
      await _persistUser(user!, prefs: prefs);
    } on AuthException catch (ex) {
      error = ex.message;
      rethrow;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signup(String username, String password, String role) async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      await _service.signup(username, password, role);
    } on AuthException catch (ex) {
      error = ex.message;
      rethrow;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    token = null;
    user = null;
    _client.updateToken(null);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
    notifyListeners();
  }

  Future<void> setThemePreference(bool prefersDark) async {
    if (user == null) return;
    final previous = user!;
    user = previous.copyWith(prefersDark: prefersDark);
    notifyListeners();
    try {
      await _persistUser(user!);
      user = await _service.updateThemePreference(prefersDark);
      await _persistUser(user!);
      notifyListeners();
    } catch (_) {
      user = previous;
      await _persistUser(user!);
      notifyListeners();
      rethrow;
    }
  }

  Future<List<AppUser>> fetchAssignableTakers() => _service.fetchTakers();
  Future<List<AppUser>> fetchAccounters() => _service.fetchAccounters();

  AppUser? _loadCachedUser(SharedPreferences prefs) {
    final raw = prefs.getString(_userKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      final data = jsonDecode(raw);
      if (data is Map<String, dynamic>) {
        return AppUser.fromJson(data);
      }
    } catch (_) {
      return null;
    }
    return null;
  }

  Future<void> _persistUser(AppUser user, {SharedPreferences? prefs}) async {
    final storage = prefs ?? await SharedPreferences.getInstance();
    await storage.setString(_userKey, jsonEncode(user.toJson()));
  }

  AppUser? _userFromToken(String token) {
    final payload = _decodeJwtPayload(token);
    if (payload == null) return null;
    return AppUser.fromJson({
      'id': payload['id'],
      'username': payload['username'],
      'role': payload['role'],
      'isApproved': payload['isApproved'],
    });
  }

  Map<String, dynamic>? _decodeJwtPayload(String token) {
    final parts = token.split('.');
    if (parts.length != 3) return null;
    try {
      final normalized = base64Url.normalize(parts[1]);
      final jsonString = utf8.decode(base64Url.decode(normalized));
      final data = jsonDecode(jsonString);
      if (data is Map<String, dynamic>) {
        return data;
      }
    } catch (_) {
      return null;
    }
    return null;
  }
}
