class AppUser {
  const AppUser({
    required this.id,
    required this.username,
    required this.role,
    required this.isApproved,
    this.email,
    this.prefersDark = false,
  });

  final int id;
  final String username;
  final String role;
  final bool isApproved;
  final String? email;
  final bool prefersDark;

  bool get requiresApproval => !isApproved;

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'] is int ? json['id'] as int : int.tryParse('${json['id']}') ?? 0,
      username: json['username'] as String? ?? '',
      role: json['role'] as String? ?? '',
      isApproved: (json['isApproved'] ?? json['approved']) == true,
      email: json['email'] as String?,
      prefersDark: json['prefersDark'] == true,
    );
  }

  AppUser copyWith({
    int? id,
    String? username,
    String? role,
    bool? isApproved,
    String? email,
    bool? prefersDark,
  }) {
    return AppUser(
      id: id ?? this.id,
      username: username ?? this.username,
      role: role ?? this.role,
      isApproved: isApproved ?? this.isApproved,
      email: email ?? this.email,
      prefersDark: prefersDark ?? this.prefersDark,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'role': role,
      'isApproved': isApproved,
      'email': email,
      'prefersDark': prefersDark,
    };
  }
}
