// lib\features\cricket_scoring\services\admin_service.dart

import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart';
import '../api/appwrite_constants.dart';
import '../models/user_model.dart';
import '../models/user_role_model.dart';
import '../models/match_approval_model.dart';
import '../models/notification_model.dart';
import '../models/user_ban_model.dart';
import '../models/match_model.dart';

class AdminService {
  final Client _client;
  final Databases _databases;

  AdminService(this._client) : _databases = Databases(_client);

  Future<List<UserModel>> getAllUsers() async {
    try {
      final response = await _databases.listDocuments(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.usersCollection,
      );
      return response.documents.map((doc) => UserModel.fromMap(doc.data)).toList();
    } on AppwriteException catch (e) {
      throw Exception('Failed to fetch users: ${e.message ?? "Unknown error"}');
    }
  }

  Future<UserModel?> getUserById(String userId) async {
    try {
      final response = await _databases.getDocument(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.usersCollection,
        documentId: userId,
      );
      return UserModel.fromMap(response.data);
    } on AppwriteException catch (e) {
      if (e.code == 404) return null;
      throw Exception('Failed to fetch user: ${e.message ?? "Unknown error"}');
    }
  }

  Future<UserModel?> getUserByEmail(String email) async {
    try {
      final response = await _databases.listDocuments(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.usersCollection,
        queries: [Query.equal('email', email)],
      );
      if (response.documents.isNotEmpty) {
        return UserModel.fromMap(response.documents.first.data);
      }
      return null;
    } on AppwriteException catch (e) {
      throw Exception('Failed to fetch user by email: ${e.message ?? "Unknown error"}');
    }
  }

  Future<void> assignUserRole(String userId, String role, String assignedBy) async {
    try {

      final currentUserDoc = await _databases.getDocument(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.usersCollection,
        documentId: userId,
      );

      await _databases.createDocument(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.userRolesCollection,
        documentId: ID.unique(),
        data: {
          'userId': userId,
          'role': role,
          'assignedBy': assignedBy,
          'assignedAt': DateTime.now().toIso8601String(),
          'isActive': true,
        },
      );

      final updatedUserData = {
        'uid': currentUserDoc.data['uid'],
        'email': currentUserDoc.data['email'],
        'username': currentUserDoc.data['username'],
        'fullName': currentUserDoc.data['fullName'],
        'photoUrl': currentUserDoc.data['photoUrl'],
        'nidFrontUrl': currentUserDoc.data['nidFrontUrl'],
        'isVerifiedScorer': currentUserDoc.data['isVerifiedScorer'] ?? false,
        'role': role,
        'isBanned': currentUserDoc.data['isBanned'] ?? false,
        'banReason': currentUserDoc.data['banReason'],
        'bannedBy': currentUserDoc.data['bannedBy'],
        'bannedAt': currentUserDoc.data['bannedAt'],
        'phone': currentUserDoc.data['phone'],
      };

      await _databases.updateDocument(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.usersCollection,
        documentId: userId,
        data: updatedUserData,
      );

      final notificationData = {
        'userId': userId,
        'title': 'Role Updated',
        'message': 'Your role has been updated to $role by an administrator.',
        'type': 'role_update',
        'isRead': false,
        'createdAt': DateTime.now().toIso8601String(),
        'data': '{"role": "$role", "assignedBy": "$assignedBy"}',
      };

      await _databases.createDocument(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.notificationsCollection,
        documentId: ID.unique(),
        data: notificationData,
      );
    } on AppwriteException catch (e) {
      throw Exception('Failed to assign role: ${e.message ?? "Unknown error"}');
    }
  }

  Future<void> removeUserRole(String userId, String removedBy) async {
    try {

      final currentUserDoc = await _databases.getDocument(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.usersCollection,
        documentId: userId,
      );

      final rolesResponse = await _databases.listDocuments(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.userRolesCollection,
        queries: [Query.equal('userId', userId), Query.equal('isActive', true)],
      );

      for (final roleDoc in rolesResponse.documents) {
        await _databases.updateDocument(
          databaseId: AppwriteConstants.databaseId,
          collectionId: AppwriteConstants.userRolesCollection,
          documentId: roleDoc.$id,
          data: {'isActive': false},
        );
      }

      final updatedUserData = {
        'uid': currentUserDoc.data['uid'],
        'email': currentUserDoc.data['email'],
        'username': currentUserDoc.data['username'],
        'fullName': currentUserDoc.data['fullName'],
        'photoUrl': currentUserDoc.data['photoUrl'],
        'nidFrontUrl': currentUserDoc.data['nidFrontUrl'],
        'isVerifiedScorer': currentUserDoc.data['isVerifiedScorer'] ?? false,
        'role': 'user',
        'isBanned': currentUserDoc.data['isBanned'] ?? false,
        'banReason': currentUserDoc.data['banReason'],
        'bannedBy': currentUserDoc.data['bannedBy'],
        'bannedAt': currentUserDoc.data['bannedAt'],
        'phone': currentUserDoc.data['phone'],
      };

      await _databases.updateDocument(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.usersCollection,
        documentId: userId,
        data: updatedUserData,
      );
    } on AppwriteException catch (e) {
      throw Exception('Failed to remove role: ${e.message ?? "Unknown error"}');
    }
  }

  Future<void> banUser(String userId, String reason, String bannedBy) async {
    try {

      final currentUserDoc = await _databases.getDocument(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.usersCollection,
        documentId: userId,
      );

      await _databases.createDocument(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.userBansCollection,
        documentId: ID.unique(),
        data: {
          'userId': userId,
          'bannedBy': bannedBy,
          'reason': reason,
          'bannedAt': DateTime.now().toIso8601String(),
          'isActive': true,
        },
      );

      final updatedUserData = {
        'uid': currentUserDoc.data['uid'],
        'email': currentUserDoc.data['email'],
        'username': currentUserDoc.data['username'],
        'fullName': currentUserDoc.data['fullName'],
        'photoUrl': currentUserDoc.data['photoUrl'],
        'nidFrontUrl': currentUserDoc.data['nidFrontUrl'],
        'isVerifiedScorer': currentUserDoc.data['isVerifiedScorer'] ?? false,
        'role': currentUserDoc.data['role'] ?? 'user',
        'isBanned': true,
        'banReason': reason,
        'bannedBy': bannedBy,
        'bannedAt': DateTime.now().toIso8601String(),
        'phone': currentUserDoc.data['phone'],
      };

      await _databases.updateDocument(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.usersCollection,
        documentId: userId,
        data: updatedUserData,
      );
    } on AppwriteException catch (e) {
      throw Exception('Failed to ban user: ${e.message ?? "Unknown error"}');
    }
  }

  Future<void> unbanUser(String userId, String unbannedBy) async {
    try {

      final currentUserDoc = await _databases.getDocument(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.usersCollection,
        documentId: userId,
      );

      final bansResponse = await _databases.listDocuments(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.userBansCollection,
        queries: [Query.equal('userId', userId), Query.equal('isActive', true)],
      );

      for (final banDoc in bansResponse.documents) {
        await _databases.updateDocument(
          databaseId: AppwriteConstants.databaseId,
          collectionId: AppwriteConstants.userBansCollection,
          documentId: banDoc.$id,
          data: {
            'isActive': false,
            'unbannedBy': unbannedBy,
            'unbannedAt': DateTime.now().toIso8601String(),
          },
        );
      }

      final updatedUserData = {
        'uid': currentUserDoc.data['uid'],
        'email': currentUserDoc.data['email'],
        'username': currentUserDoc.data['username'],
        'fullName': currentUserDoc.data['fullName'],
        'photoUrl': currentUserDoc.data['photoUrl'],
        'nidFrontUrl': currentUserDoc.data['nidFrontUrl'],
        'isVerifiedScorer': currentUserDoc.data['isVerifiedScorer'] ?? false,
        'role': currentUserDoc.data['role'] ?? 'user',
        'isBanned': false,
        'banReason': null,
        'bannedBy': null,
        'bannedAt': null,
        'phone': currentUserDoc.data['phone'],
      };

      await _databases.updateDocument(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.usersCollection,
        documentId: userId,
        data: updatedUserData,
      );
    } on AppwriteException catch (e) {
      throw Exception('Failed to unban user: ${e.message ?? "Unknown error"}');
    }
  }

  Future<void> createMatchApprovalRequest(String matchId, String requestedBy, bool isOnline) async {
    try {
      await _databases.createDocument(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.matchApprovalsCollection,
        documentId: ID.unique(),
        data: {
          'matchId': matchId,
          'requestedBy': requestedBy,
          'isOnline': isOnline,
          'status': 'pending',
          'requestedAt': DateTime.now().toIso8601String(),
        },
      );
    } on AppwriteException catch (e) {
      throw Exception('Failed to create match approval request: ${e.message ?? "Unknown error"}');
    }
  }

  Future<List<MatchApprovalModel>> getPendingMatchApprovals() async {
    try {
      final response = await _databases.listDocuments(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.matchApprovalsCollection,
        queries: [Query.equal('status', 'pending')],
      );
      return response.documents.map((doc) => MatchApprovalModel.fromMap(doc.data)).toList();
    } on AppwriteException catch (e) {
      throw Exception('Failed to fetch pending approvals: ${e.message ?? "Unknown error"}');
    }
  }

  Future<void> approveMatch(String matchId, String approvedBy, String? comments) async {
    try {

      final approvalResponse = await _databases.listDocuments(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.matchApprovalsCollection,
        queries: [Query.equal('matchId', matchId)],
      );

      if (approvalResponse.documents.isNotEmpty) {
        await _databases.updateDocument(
          databaseId: AppwriteConstants.databaseId,
          collectionId: AppwriteConstants.matchApprovalsCollection,
          documentId: approvalResponse.documents.first.$id,
          data: {
            'status': 'approved',
            'reviewedBy': approvedBy,
            'reviewedAt': DateTime.now().toIso8601String(),
            'reviewComments': comments,
          },
        );
      }

      await _databases.updateDocument(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.matchesCollection,
        documentId: matchId,
        data: {
          'isApproved': true,
          'approvedBy': approvedBy,
          'approvedAt': DateTime.now().toIso8601String(),
        },
      );
    } on AppwriteException catch (e) {
      throw Exception('Failed to approve match: ${e.message ?? "Unknown error"}');
    }
  }

  Future<void> rejectMatch(String matchId, String rejectedBy, String reason) async {
    try {

      final approvalResponse = await _databases.listDocuments(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.matchApprovalsCollection,
        queries: [Query.equal('matchId', matchId)],
      );

      if (approvalResponse.documents.isNotEmpty) {
        await _databases.updateDocument(
          databaseId: AppwriteConstants.databaseId,
          collectionId: AppwriteConstants.matchApprovalsCollection,
          documentId: approvalResponse.documents.first.$id,
          data: {
            'status': 'rejected',
            'reviewedBy': rejectedBy,
            'reviewedAt': DateTime.now().toIso8601String(),
            'reviewComments': reason,
          },
        );
      }
    } on AppwriteException catch (e) {
      throw Exception('Failed to reject match: ${e.message ?? "Unknown error"}');
    }
  }

  Future<void> sendNotification(String userId, String title, String message, String type, {String? data}) async {
    try {
      await _databases.createDocument(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.notificationsCollection,
        documentId: ID.unique(),
        data: {
          'userId': userId,
          'title': title,
          'message': message,
          'type': type,
          'isRead': false,
          'createdAt': DateTime.now().toIso8601String(),
          'data': data,
        },
      );
    } on AppwriteException catch (e) {
      throw Exception('Failed to send notification: ${e.message ?? "Unknown error"}');
    }
  }

  Future<void> sendNotificationToAllUsers(String title, String message, String type, {String? data}) async {
    try {
      final users = await getAllUsers();
      for (final user in users) {
        await sendNotification(user.id, title, message, type, data: data);
      }
    } on AppwriteException catch (e) {
      throw Exception('Failed to send notification to all users: ${e.message ?? "Unknown error"}');
    }
  }

  Future<List<NotificationModel>> getUserNotifications(String userId) async {
    try {
      final response = await _databases.listDocuments(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.notificationsCollection,
        queries: [
          Query.equal('userId', userId),
          Query.orderDesc('createdAt'),
        ],
      );
      return response.documents.map((doc) => NotificationModel.fromMap(doc.data)).toList();
    } on AppwriteException catch (e) {
      throw Exception('Failed to fetch notifications: ${e.message ?? "Unknown error"}');
    }
  }

  Future<void> markNotificationAsRead(String notificationId) async {
    try {
      await _databases.updateDocument(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.notificationsCollection,
        documentId: notificationId,
        data: {'isRead': true},
      );
    } on AppwriteException catch (e) {
      throw Exception('Failed to mark notification as read: ${e.message ?? "Unknown error"}');
    }
  }

  Future<List<MatchModel>> getApprovedMatches() async {
    try {
      final response = await _databases.listDocuments(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.matchesCollection,
        queries: [
          Query.equal('isApproved', true),
          Query.orderDesc('matchDateTime'),
        ],
      );
      return response.documents.map((doc) => MatchModel.fromMap(doc.data)).toList();
    } on AppwriteException catch (e) {
      throw Exception('Failed to fetch approved matches: ${e.message ?? "Unknown error"}');
    }
  }

  bool canUserBan(UserModel user, UserModel targetUser) {
    if (user.isRealAdmin) return true;
    if (user.isAdmin && !targetUser.isRealAdmin) return true;
    return false;
  }

  bool canUserAssignRoles(UserModel user) {
    return user.isRealAdmin;
  }

  bool canUserApproveMatches(UserModel user) {
    return user.isAdmin || user.isModerator;
  }
}