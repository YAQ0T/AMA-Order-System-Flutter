class OrderLogEntry {
  const OrderLogEntry({
    required this.id,
    required this.previousDescription,
    required this.newDescription,
    required this.createdAt,
    this.changedBy,
    this.editorName,
  });

  final int id;
  final String previousDescription;
  final String newDescription;
  final DateTime createdAt;
  final int? changedBy;
  final String? editorName;

  factory OrderLogEntry.fromJson(Map<String, dynamic> json) {
    return OrderLogEntry(
      id: json['id'] is int ? json['id'] as int : int.tryParse('${json['id']}') ?? 0,
      previousDescription: json['previousDescription'] as String? ?? '',
      newDescription: json['newDescription'] as String? ?? '',
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
      changedBy: json['changedBy'] as int?,
      editorName: (json['Editor'] as Map<String, dynamic>?)?['username'] as String?,
    );
  }
}
