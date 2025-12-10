class AppNotification {
  AppNotification({
    required this.id,
    required this.message,
    required this.type,
    required this.createdAt,
    this.orderId,
    this.isRead = false,
  });

  final int id;
  final String message;
  final String type;
  final DateTime createdAt;
  final int? orderId;
  final bool isRead;

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] is int ? json['id'] as int : int.tryParse('${json['id']}') ?? 0,
      message: json['message'] as String? ?? '',
      type: json['type'] as String? ?? 'alert',
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
      orderId: json['orderId'] is int ? json['orderId'] as int : int.tryParse('${json['orderId']}'),
      isRead: json['isRead'] == true,
    );
  }
}
