import 'user.dart';

class ActivityLog {
  ActivityLog({
    required this.id,
    required this.action,
    required this.targetType,
    required this.targetId,
    required this.createdAt,
    this.user,
    this.details,
    this.description,
    this.ipAddress,
    this.category,
  });

  final int id;
  final String action;
  final String targetType;
  final int? targetId;
  final DateTime createdAt;
  final AppUser? user;
  final Map<String, dynamic>? details;
  final String? description;
  final String? ipAddress;
  final String? category;

  factory ActivityLog.fromJson(Map<String, dynamic> json) {
    final action = json['action'] as String? ?? '';
    final category = json['type'] as String?;
    final rawTargetType = json['targetType'] ?? json['entityType'];
    final rawTargetId = json['targetId'] ?? json['entityId'];
    return ActivityLog(
      id: json['id'] is int ? json['id'] as int : int.tryParse('${json['id']}') ?? 0,
      action: action.isNotEmpty ? action : (category ?? ''),
      targetType: rawTargetType as String? ?? '',
      targetId: rawTargetId is int ? rawTargetId : int.tryParse('$rawTargetId'),
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
      user: json['User'] == null ? null : AppUser.fromJson(json['User'] as Map<String, dynamic>),
      details: (json['details'] as Map?)?.cast<String, dynamic>(),
      description: json['description'] as String?,
      ipAddress: json['ipAddress'] as String?,
      category: category,
    );
  }

  String get actionLabel => action.replaceAll('_', ' ').trim();

  String get targetLabel {
    final idPart = targetId == null ? '' : ' $targetId';
    return '$targetType$idPart'.trim();
  }
}
