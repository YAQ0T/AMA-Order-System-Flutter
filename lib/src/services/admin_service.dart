import 'dart:convert';

import '../models/activity_log.dart';
import '../models/order.dart';
import '../models/stats.dart';
import '../models/user.dart';
import 'api_client.dart';

class AdminService {
  AdminService(this._client);

  final ApiClient _client;

  Future<DashboardStats> fetchStats() async {
    final res = await _client.get('/api/admin/stats');
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return DashboardStats.fromJson(data);
    }
    throw Exception(data['error'] ?? 'Failed to fetch stats');
  }

  Future<List<AppUser>> fetchUsers({bool? pendingOnly}) async {
    final path = pendingOnly == true ? '/api/admin/users/pending' : '/api/admin/users';
    final res = await _client.get(path);
    final data = jsonDecode(res.body);
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return (data as List<dynamic>)
          .map((e) => AppUser.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    throw Exception('Failed to fetch users');
  }

  Future<void> approveUser(int id) async {
    final res = await _client.put('/api/admin/users/$id/approve', body: {});
    if (res.statusCode < 200 || res.statusCode >= 300) {
      final data = jsonDecode(res.body);
      throw Exception(data['error'] ?? 'Failed to approve user');
    }
  }

  Future<void> updateUserEmail(int id, String email) async {
    final res = await _client.put('/api/admin/users/$id/email', body: {'email': email});
    if (res.statusCode < 200 || res.statusCode >= 300) {
      final data = jsonDecode(res.body);
      throw Exception(data['error'] ?? 'Failed to update email');
    }
  }

  Future<void> deleteUser(int id) async {
    final res = await _client.delete('/api/admin/users/$id');
    if (res.statusCode < 200 || res.statusCode >= 300) {
      final data = jsonDecode(res.body);
      throw Exception(data['error'] ?? 'Failed to delete user');
    }
  }

  Future<List<OrderModel>> fetchOrders() async {
    final res = await _client.get('/api/admin/orders');
    final data = jsonDecode(res.body);
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return (data as List<dynamic>)
          .map((e) => OrderModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    throw Exception('Failed to fetch orders');
  }

  Future<void> deleteOrder(int id) async {
    final res = await _client.delete('/api/admin/orders/$id');
    if (res.statusCode < 200 || res.statusCode >= 300) {
      final data = jsonDecode(res.body);
      throw Exception(data['error'] ?? 'Failed to delete order');
    }
  }

  Future<List<ActivityLog>> fetchActivityLogs({int limit = 50, bool all = false}) async {
    final path = all ? '/api/admin/logs/all' : '/api/admin/logs';
    final res = await _client.get(path, query: {'limit': '$limit'});
    final data = jsonDecode(res.body);
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return (data as List<dynamic>)
          .map((e) => ActivityLog.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    throw Exception('Failed to fetch logs');
  }
}
