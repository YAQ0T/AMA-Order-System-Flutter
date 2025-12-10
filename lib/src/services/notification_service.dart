import 'dart:convert';

import '../models/notification.dart';
import 'api_client.dart';

class NotificationService {
  NotificationService(this._client);

  final ApiClient _client;

  Future<List<AppNotification>> fetchNotifications() async {
    final res = await _client.get('/api/notifications');
    final data = jsonDecode(res.body);
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return (data as List<dynamic>)
          .map((e) => AppNotification.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    throw Exception('Failed to fetch notifications');
  }

  Future<void> markRead(int id) async {
    await _client.put('/api/notifications/$id/read', body: {});
  }
}
