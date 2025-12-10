import 'package:flutter/material.dart';

import '../models/order.dart';
import '../services/api_client.dart';
import '../services/order_service.dart';
import 'auth_notifier.dart';

class OrderNotifier extends ChangeNotifier {
  OrderNotifier(ApiClient client) : _service = OrderService(client);

  final OrderService _service;
  List<OrderModel> orders = [];
  bool loading = false;
  String? error;
  String statusFilter = 'active';
  String searchTerm = '';
  final List<String> _productCache = [];

  Future<void> loadOrders({String? status, String? search}) async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      statusFilter = status ?? statusFilter;
      searchTerm = search ?? searchTerm;
      orders = await _service.fetchOrders(
        status: statusFilter == 'all' ? null : statusFilter,
        search: searchTerm,
      );
    } catch (e) {
      error = '$e';
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> createOrder(OrderDraft draft) async {
    loading = true;
    notifyListeners();
    try {
      final created = await _service.createOrder(draft);
      orders = [created, ...orders];
      for (final item in draft.items) {
        final name = item.name.trim();
        if (name.isNotEmpty && !_productCache.contains(name)) {
          _productCache.add(name);
        }
      }
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> updateStatus(
    int orderId,
    String status, {
    bool? notifyMaker,
    bool? notifyAccounter,
    bool? skipEmail,
  }) async {
    try {
      final payload = <String, dynamic>{'status': status};
      if (notifyMaker != null) payload['notifyMaker'] = notifyMaker;
      if (notifyAccounter != null) payload['notifyAccounter'] = notifyAccounter;
      if (skipEmail != null) payload['skipEmail'] = skipEmail;
      final updated = await _service.updateOrder(orderId, payload);
      orders = orders.map((o) => o.id == orderId ? updated : o).toList();
      notifyListeners();
    } catch (e) {
      error = '$e';
      notifyListeners();
    }
  }

  Future<void> deleteOrder(int orderId) async {
    await _service.deleteOrder(orderId);
    orders.removeWhere((o) => o.id == orderId);
    notifyListeners();
  }

  Future<void> updateItemStatus(
    OrderModel order,
    int itemId,
    String status, {
    bool? notifyMaker,
    bool? notifyAccounter,
    bool? skipEmail,
  }) async {
    final updatedItems = order.items
        .map((item) => {
              'id': item.id,
              'name': item.name,
              'quantity': item.quantity,
              'price': item.price,
              'status': item.id == itemId ? status : item.status
            })
        .toList();
    final payload = <String, dynamic>{'items': updatedItems};
    if (notifyMaker != null) payload['notifyMaker'] = notifyMaker;
    if (notifyAccounter != null) payload['notifyAccounter'] = notifyAccounter;
    if (skipEmail != null) payload['skipEmail'] = skipEmail;
    await _service.updateOrder(order.id, payload);
    // Refresh full list to pick up server-calculated fields/logs
    await loadOrders(status: statusFilter, search: searchTerm);
    notifyListeners();
  }

  Future<void> updateOrderDetails(
    int orderId,
    Map<String, dynamic> payload, {
    bool? notifyMaker,
    bool? notifyAccounter,
    bool? skipEmail,
  }) async {
    final fullPayload = {...payload};
    if (notifyMaker != null) fullPayload['notifyMaker'] = notifyMaker;
    if (notifyAccounter != null) fullPayload['notifyAccounter'] = notifyAccounter;
    if (skipEmail != null) fullPayload['skipEmail'] = skipEmail;
    final updated = await _service.updateOrder(orderId, fullPayload);
    orders = orders.map((o) => o.id == orderId ? updated : o).toList();
    notifyListeners();
  }

  void handleAuthChanged(AuthNotifier auth) {
    if (!auth.isAuthenticated) {
      orders = [];
      _productCache.clear();
      notifyListeners();
    } else {
      loadOrders();
    }
  }

  Future<List<String>> suggestProducts(String query) async {
    final trimmed = query.trim();
    if (trimmed.length < 2) return [];

    // Always include cached local names that match.
    final localMatches = _productCache
        .where((name) => name.toLowerCase().startsWith(trimmed.toLowerCase()))
        .toList();

    try {
      final remote = await _service.suggestItems(trimmed);
      // Merge unique suggestions, prioritize local.
      final set = {...localMatches};
      set.addAll(remote);
      return set.take(6).toList();
    } catch (_) {
      return localMatches.take(6).toList();
    }
  }
}
