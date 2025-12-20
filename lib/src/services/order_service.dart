import 'dart:convert';

import '../models/order.dart';
import 'api_client.dart';

class OrderService {
  OrderService(this._client);

  final ApiClient _client;

  Future<List<OrderModel>> fetchOrders({
    String? status,
    String? search,
    int? limit,
    int? offset,
    bool includeHistory = true,
  }) {
    return _fetchList('/api/orders',
        status: status, search: search, limit: limit, offset: offset, includeHistory: includeHistory);
  }

  Future<List<OrderModel>> fetchAccounterOrders({
    String? status,
    String? search,
    int? limit,
    int? offset,
    bool includeHistory = true,
  }) {
    return _fetchList('/api/orders/accounter',
        status: status, search: search, limit: limit, offset: offset, includeHistory: includeHistory);
  }

  Future<List<OrderModel>> fetchMakerOrders({
    String? status,
    String? search,
    int? limit,
    int? offset,
    bool includeHistory = true,
  }) {
    return _fetchList('/api/orders/maker',
        status: status, search: search, limit: limit, offset: offset, includeHistory: includeHistory);
  }

  Future<List<OrderModel>> fetchTakerOrders({
    String? status,
    String? search,
    int? limit,
    int? offset,
    bool includeHistory = true,
  }) {
    return _fetchList('/api/orders/taker',
        status: status, search: search, limit: limit, offset: offset, includeHistory: includeHistory);
  }

  Future<List<OrderModel>> fetchAdminOrders({
    String? status,
    String? search,
    int? limit,
    int? offset,
    bool includeHistory = true,
  }) {
    return _fetchList('/api/orders/admin',
        status: status, search: search, limit: limit, offset: offset, includeHistory: includeHistory);
  }

  Future<List<OrderModel>> _fetchList(
    String path, {
    String? status,
    String? search,
    int? limit,
    int? offset,
    bool includeHistory = true,
  }) async {
    final query = <String, String>{};
    if (status != null && status.isNotEmpty) query['status'] = status;
    if (search != null && search.isNotEmpty) query['search'] = search;
    if (limit != null) query['limit'] = '$limit';
    if (offset != null) query['offset'] = '$offset';
    query['includeHistory'] = includeHistory ? 'true' : 'false';

    final response = await _client.get(path, query: query.isEmpty ? null : query);
    final data = jsonDecode(response.body);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final list = (data is List ? data : (data['orders'] as List<dynamic>?)) ?? [];
      return list.map((raw) => OrderModel.fromJson(raw as Map<String, dynamic>)).toList();
    }
    throw Exception('Unable to fetch orders: ${data is Map ? data['error'] : response.body}');
  }

  Future<OrderModel> createOrder(OrderDraft draft) async {
    final response = await _client.post('/api/orders', body: draft.toJson());
    try {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return OrderModel.fromJson(data);
      }
      throw Exception(data['error'] as String? ?? 'Failed to create order');
    } catch (e) {
      // Surface server message if available, else generic error.
      throw Exception('Failed to create order: ${response.body.isNotEmpty ? response.body : e}');
    }
  }

  Future<OrderModel> updateOrder(int id, Map<String, dynamic> payload) async {
    final response = await _client.put('/api/orders/$id', body: payload);
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return OrderModel.fromJson(data);
    }
    throw Exception(data['error'] as String? ?? 'Failed to update order');
  }

  Future<void> deleteOrder(int id) async {
    final res = await _client.delete('/api/orders/$id');
    if (res.statusCode < 200 || res.statusCode >= 300) {
      final data = jsonDecode(res.body);
      throw Exception(data['error'] ?? 'Failed to delete order');
    }
  }

  Future<List<String>> suggestItems(String query) async {
    final res = await _client.get('/api/items/suggestions', query: {'q': query});
    if (res.statusCode >= 200 && res.statusCode < 300) {
      final data = jsonDecode(res.body) as List<dynamic>;
      return data.map((e) => '$e').toList();
    }
    return [];
  }

  Future<List<String>> suggestTitles(String query) async {
    final res = await _client.get('/api/orders/suggestions', query: {'q': query});
    if (res.statusCode >= 200 && res.statusCode < 300) {
      final data = jsonDecode(res.body) as List<dynamic>;
      return data.map((e) => '$e').toList();
    }
    return [];
  }
}
