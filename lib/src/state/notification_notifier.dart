import 'package:flutter/material.dart';

import '../models/notification.dart';
import '../services/api_client.dart';
import '../services/notification_service.dart';

class NotificationNotifier extends ChangeNotifier {
  NotificationNotifier(ApiClient client) : _service = NotificationService(client);

  final NotificationService _service;
  List<AppNotification> notifications = [];
  bool loading = false;

  Future<void> load() async {
    loading = true;
    notifyListeners();
    try {
      notifications = await _service.fetchNotifications();
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> markRead(int id) async {
    await _service.markRead(id);
    notifications = notifications.where((n) => n.id != id).toList();
    notifyListeners();
  }

  @override
  void dispose() {
    super.dispose();
  }
}
