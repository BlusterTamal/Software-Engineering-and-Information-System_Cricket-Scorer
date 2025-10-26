// lib\features\cricket_scoring\models\user_ban_model.dart

class UserBanModel {
  final String id;
  final String userId;
  final String bannedBy;
  final String reason;
  final DateTime bannedAt;
  final bool isActive;
  final String? unbannedBy;
  final DateTime? unbannedAt;

  const UserBanModel({
    required this.id,
    required this.userId,
    required this.bannedBy,
    required this.reason,
    required this.bannedAt,
    this.isActive = true,
    this.unbannedBy,
    this.unbannedAt,
  });

  factory UserBanModel.fromMap(Map<String, dynamic> map) {
    return UserBanModel(
      id: map['\$id'] ?? '',
      userId: map['userId'] ?? '',
      bannedBy: map['bannedBy'] ?? '',
      reason: map['reason'] ?? '',
      bannedAt: DateTime.parse(map['bannedAt']),
      isActive: map['isActive'] ?? true,
      unbannedBy: map['unbannedBy'],
      unbannedAt: map['unbannedAt'] != null ? DateTime.parse(map['unbannedAt']) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'bannedBy': bannedBy,
      'reason': reason,
      'bannedAt': bannedAt.toIso8601String(),
      'isActive': isActive,
      'unbannedBy': unbannedBy,
      'unbannedAt': unbannedAt?.toIso8601String(),
    };
  }

  UserBanModel copyWith({
    String? id,
    String? userId,
    String? bannedBy,
    String? reason,
    DateTime? bannedAt,
    bool? isActive,
    String? unbannedBy,
    DateTime? unbannedAt,
  }) {
    return UserBanModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      bannedBy: bannedBy ?? this.bannedBy,
      reason: reason ?? this.reason,
      bannedAt: bannedAt ?? this.bannedAt,
      isActive: isActive ?? this.isActive,
      unbannedBy: unbannedBy ?? this.unbannedBy,
      unbannedAt: unbannedAt ?? this.unbannedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserBanModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'UserBanModel(id: $id, userId: $userId, reason: $reason, isActive: $isActive)';
  }
}