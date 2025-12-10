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

  late final ApiClient _client;
  final AuthService _service;

  AppUser? user;
  String? token;
  bool isLoading = false;
  bool initializing = true;
  String? error;

  bool get isAuthenticated => token != null && user != null;
  bool get isApproved => user?.isApproved ?? false;

  Future<void> restoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    final savedToken = prefs.getString('token');
    if (savedToken != null) {
      token = savedToken;
      _client.updateToken(token);
      try {
        user = await _service.me();
      } catch (_) {
        await logout();
      }
    }
    initializing = false;
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
      await prefs.setString('token', token!);
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
    await prefs.remove('token');
    notifyListeners();
  }

  Future<List<AppUser>> fetchAssignableTakers() => _service.fetchTakers();
  Future<List<AppUser>> fetchAccounters() => _service.fetchAccounters();
}
