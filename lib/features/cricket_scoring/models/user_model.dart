// lib\features\cricket_scoring\models\user_model.dart

class UserModel {
  final String id;
  final String uid;
  final String email;
  final String username;
  final String fullName;
  final String? photoUrl;
  final String? nidFrontUrl;
  final bool isVerifiedScorer;
  final String role;
  final bool isBanned;
  final String? banReason;
  final String? bannedBy;
  final DateTime? bannedAt;
  final String? phone;
  final bool? isGoogleUser;
  final String? googleId;

  const UserModel({
    required this.id,
    required this.uid,
    required this.email,
    required this.username,
    required this.fullName,
    this.photoUrl,
    this.nidFrontUrl,
    this.isVerifiedScorer = false,
    this.role = 'user',
    this.isBanned = false,
    this.banReason,
    this.bannedBy,
    this.bannedAt,
    this.phone,
    this.isGoogleUser,
    this.googleId,
  });

  bool get isRealAdmin => email == 'tamalp241@gmail.com';
  bool get isAdmin => role == 'admin' || isRealAdmin;
  bool get isModerator => role == 'moderator';
  bool get isUser => role == 'user';

  bool get canAssignRoles => isRealAdmin;
  bool get canApproveMatches => isAdmin || isModerator;
  bool get canBanUsers => isAdmin || isRealAdmin;
  bool get canBanModerators => isRealAdmin;
  bool get canBanAdmins => isRealAdmin;

  bool canUserBan(UserModel targetUser) {
    if (isRealAdmin) return true;
    if (isAdmin && !targetUser.isRealAdmin) return true;
    return false;
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['\$id'] ?? '',
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      username: map['username'] ?? '',
      fullName: map['fullName'] ?? '',
      photoUrl: map['photoUrl'],
      nidFrontUrl: map['nidFrontUrl'],
      isVerifiedScorer: map['isVerifiedScorer'] ?? false,
      role: map['role'] ?? 'user',
      isBanned: map['isBanned'] ?? false,
      banReason: map['banReason'],
      bannedBy: map['bannedBy'],
      bannedAt: map['bannedAt'] != null ? DateTime.parse(map['bannedAt']) : null,
      phone: map['phone'],
      isGoogleUser: map['isGoogleUser'],
      googleId: map['googleId'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'username': username,
      'fullName': fullName,
      'photoUrl': photoUrl,
      'nidFrontUrl': nidFrontUrl,
      'isVerifiedScorer': isVerifiedScorer,
      'role': role,
      'isBanned': isBanned,
      'banReason': banReason,
      'bannedBy': bannedBy,
      'bannedAt': bannedAt?.toIso8601String(),
      'phone': phone,
      'isGoogleUser': isGoogleUser,
      'googleId': googleId,
    };
  }

  UserModel copyWith({
    String? id,
    String? uid,
    String? email,
    String? username,
    String? fullName,
    String? photoUrl,
    String? nidFrontUrl,
    bool? isVerifiedScorer,
    String? role,
    bool? isBanned,
    String? banReason,
    String? bannedBy,
    DateTime? bannedAt,
    String? phone,
    bool? isGoogleUser,
    String? googleId,
  }) {
    return UserModel(
      id: id ?? this.id,
      uid: uid ?? this.uid,
      email: email ?? this.email,
      username: username ?? this.username,
      fullName: fullName ?? this.fullName,
      photoUrl: photoUrl ?? this.photoUrl,
      nidFrontUrl: nidFrontUrl ?? this.nidFrontUrl,
      isVerifiedScorer: isVerifiedScorer ?? this.isVerifiedScorer,
      role: role ?? this.role,
      isBanned: isBanned ?? this.isBanned,
      banReason: banReason ?? this.banReason,
      bannedBy: bannedBy ?? this.bannedBy,
      bannedAt: bannedAt ?? this.bannedAt,
      phone: phone ?? this.phone,
      isGoogleUser: isGoogleUser ?? this.isGoogleUser,
      googleId: googleId ?? this.googleId,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'UserModel(id: $id, email: $email, username: $username, role: $role)';
  }
}