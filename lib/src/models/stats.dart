import 'activity_log.dart';

class DashboardStats {
  DashboardStats({
    required this.totalUsers,
    required this.pendingApprovals,
    required this.totalOrders,
    required this.activeOrders,
    required this.usersByRole,
    required this.recentActivity,
  });

  final int totalUsers;
  final int pendingApprovals;
  final int totalOrders;
  final int activeOrders;
  final Map<String, int> usersByRole;
  final List<ActivityLog> recentActivity;

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    return DashboardStats(
      totalUsers: json['totalUsers'] as int? ?? 0,
      pendingApprovals: json['pendingApprovals'] as int? ?? 0,
      totalOrders: json['totalOrders'] as int? ?? 0,
      activeOrders: json['activeOrders'] as int? ?? 0,
      usersByRole: (json['usersByRole'] as Map<String, dynamic>? ?? {})
          .map((key, value) => MapEntry(key, value is int ? value : int.tryParse('$value') ?? 0)),
      recentActivity: (json['recentActivity'] as List<dynamic>? ?? [])
          .map((e) => ActivityLog.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
