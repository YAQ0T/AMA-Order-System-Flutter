class AppUser {
  const AppUser({
    required this.id,
    required this.username,
    required this.role,
    required this.isApproved,
    this.email,
  });

  final int id;
  final String username;
  final String role;
  final bool isApproved;
  final String? email;

  bool get requiresApproval => !isApproved;

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'] is int ? json['id'] as int : int.tryParse('${json['id']}') ?? 0,
      username: json['username'] as String? ?? '',
      role: json['role'] as String? ?? '',
      isApproved: (json['isApproved'] ?? json['approved']) == true,
      email: json['email'] as String?,
    );
  }
}
