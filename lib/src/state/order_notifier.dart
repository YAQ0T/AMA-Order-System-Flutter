import 'package:flutter/material.dart';

import '../models/order.dart';
import '../services/api_client.dart';
import '../services/order_service.dart';
import 'auth_notifier.dart';

class OrderNotifier extends ChangeNotifier {
  OrderNotifier(ApiClient client) : _service = OrderService(client);

  final OrderService _service;
  static const Set<String> _activeStatuses = {'pending', 'in-progress'};
  List<OrderModel> orders = [];
  bool loading = false;
  String? error;
  String statusFilter = 'active';
  String searchTerm = '';
  final List<String> _productCache = [];
  String? _role;

  Future<void> loadOrders({String? status, String? search}) async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      statusFilter = status ?? statusFilter;
      searchTerm = search ?? searchTerm;
      final normalizedStatus = statusFilter == 'all' ? null : statusFilter;
      final fetched = await _fetchByRole(normalizedStatus);
      orders = _applyStatusFilter(fetched);
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
      if (_matchesStatusFilter(created)) {
        orders = [created, ...orders];
      }
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
      orders = _mergeUpdatedOrder(updated);
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
    String? status, {
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
    orders = _mergeUpdatedOrder(updated);
    notifyListeners();
  }

  void handleAuthChanged(AuthNotifier auth) {
    _role = auth.user?.role;
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

  Future<List<OrderModel>> _fetchByRole(String? status) {
    switch (_role) {
      case 'accounter':
        return _service.fetchAccounterOrders(status: status, search: searchTerm);
      case 'maker':
        return _service.fetchMakerOrders(status: status, search: searchTerm);
      case 'taker':
        return _service.fetchTakerOrders(status: status, search: searchTerm);
      case 'admin':
        return _service.fetchAdminOrders(status: status, search: searchTerm);
      default:
        return _service.fetchOrders(status: status, search: searchTerm);
    }
  }

  bool _matchesStatusFilter(OrderModel order, {String? filter}) {
    final status = filter ?? statusFilter;
    if (status == 'all') return true;
    if (status == 'active') return _activeStatuses.contains(order.status);
    return order.status == status;
  }

  List<OrderModel> _applyStatusFilter(List<OrderModel> source, {String? filter}) {
    final status = filter ?? statusFilter;
    if (status == 'all') return source;
    if (status == 'active') {
      return source.where((o) => _activeStatuses.contains(o.status)).toList();
    }
    return source.where((o) => o.status == status).toList();
  }

  List<OrderModel> _mergeUpdatedOrder(OrderModel updated) {
    final matches = _matchesStatusFilter(updated);
    final index = orders.indexWhere((o) => o.id == updated.id);
    if (matches) {
      if (index == -1) {
        return [updated, ...orders];
      }
      final next = [...orders];
      next[index] = updated;
      return next;
    }
    if (index == -1) return orders;
    final next = [...orders]..removeAt(index);
    return next;
  }
}
