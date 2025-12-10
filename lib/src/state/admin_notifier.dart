import 'package:flutter/material.dart';

import '../models/activity_log.dart';
import '../models/order.dart';
import '../models/stats.dart';
import '../models/user.dart';
import '../services/admin_service.dart';
import '../services/api_client.dart';

class AdminNotifier extends ChangeNotifier {
  AdminNotifier(ApiClient client) : _service = AdminService(client);

  final AdminService _service;

  DashboardStats? stats;
  List<AppUser> users = [];
  List<AppUser> pendingUsers = [];
  List<OrderModel> orders = [];
  List<ActivityLog> logs = [];
  List<ActivityLog> auditLogs = [];
  bool loading = false;
  String? error;

  void reset() {
    stats = null;
    users = [];
    pendingUsers = [];
    orders = [];
    logs = [];
    auditLogs = [];
    loading = false;
    error = null;
    notifyListeners();
  }

  Future<void> refreshAll() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      stats = await _service.fetchStats();
      users = await _service.fetchUsers();
      pendingUsers = await _service.fetchUsers(pendingOnly: true);
      orders = await _service.fetchOrders();
      logs = await _service.fetchActivityLogs(limit: 50, all: false);
      auditLogs = await _service.fetchActivityLogs(limit: 200, all: true);
    } catch (e) {
      error = '$e';
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> approveUser(int id) async {
    await _service.approveUser(id);
    await refreshUsers();
  }

  Future<void> refreshUsers() async {
    users = await _service.fetchUsers();
    pendingUsers = await _service.fetchUsers(pendingOnly: true);
    notifyListeners();
  }

  Future<void> updateEmail(int id, String email) async {
    await _service.updateUserEmail(id, email);
    await refreshUsers();
  }

  Future<void> deleteUser(int id) async {
    await _service.deleteUser(id);
    await refreshUsers();
  }

  Future<void> reloadOrders() async {
    orders = await _service.fetchOrders();
    notifyListeners();
  }

  Future<void> deleteOrder(int id) async {
    await _service.deleteOrder(id);
    orders.removeWhere((o) => o.id == id);
    notifyListeners();
  }
}
