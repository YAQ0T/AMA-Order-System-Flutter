import 'user.dart';

class ActivityLog {
  ActivityLog({
    required this.id,
    required this.type,
    required this.entityType,
    required this.entityId,
    required this.createdAt,
    this.user,
    this.details,
  });

  final int id;
  final String type;
  final String entityType;
  final int? entityId;
  final DateTime createdAt;
  final AppUser? user;
  final Map<String, dynamic>? details;

  factory ActivityLog.fromJson(Map<String, dynamic> json) {
    return ActivityLog(
      id: json['id'] is int ? json['id'] as int : int.tryParse('${json['id']}') ?? 0,
      type: json['action'] as String? ?? json['type'] as String? ?? '',
      entityType: json['entityType'] as String? ?? '',
      entityId: json['entityId'] is int ? json['entityId'] as int : int.tryParse('${json['entityId']}'),
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
      user: json['User'] == null ? null : AppUser.fromJson(json['User'] as Map<String, dynamic>),
      details: (json['details'] as Map?)?.cast<String, dynamic>(),
    );
  }
}
