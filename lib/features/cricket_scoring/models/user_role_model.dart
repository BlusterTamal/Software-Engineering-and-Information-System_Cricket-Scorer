// lib\features\cricket_scoring\models\user_role_model.dart

class UserRoleModel {
  final String id;
  final String userId;
  final String role;
  final String assignedBy;
  final DateTime assignedAt;
  final bool isActive;

  const UserRoleModel({
    required this.id,
    required this.userId,
    required this.role,
    required this.assignedBy,
    required this.assignedAt,
    this.isActive = true,
  });

  factory UserRoleModel.fromMap(Map<String, dynamic> map) {
    return UserRoleModel(
      id: map['\$id'] ?? '',
      userId: map['userId'] ?? '',
      role: map['role'] ?? '',
      assignedBy: map['assignedBy'] ?? '',
      assignedAt: DateTime.parse(map['assignedAt']),
      isActive: map['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'role': role,
      'assignedBy': assignedBy,
      'assignedAt': assignedAt.toIso8601String(),
      'isActive': isActive,
    };
  }

  UserRoleModel copyWith({
    String? id,
    String? userId,
    String? role,
    String? assignedBy,
    DateTime? assignedAt,
    bool? isActive,
  }) {
    return UserRoleModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      role: role ?? this.role,
      assignedBy: assignedBy ?? this.assignedBy,
      assignedAt: assignedAt ?? this.assignedAt,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserRoleModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'UserRoleModel(id: $id, userId: $userId, role: $role, isActive: $isActive)';
  }
}