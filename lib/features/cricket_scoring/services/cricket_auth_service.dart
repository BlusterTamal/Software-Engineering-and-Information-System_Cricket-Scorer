// lib\features\cricket_scoring\services\cricket_auth_service.dart

import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart';
import '../api/appwrite_constants.dart';
import '../models/user_model.dart';
import 'google_oauth_service.dart';
import 'otp_service.dart';
import '../../../main.dart';

class CricketAuthService {

  final GoogleOAuthService _googleOAuthService = GoogleOAuthService();
  final OTPService _otpService = OTPService();

  CricketAuthService() {}

  Future<UserModel> signUp({
    required String email,
    required String password,
    required String username,
    required String fullName,
    String? phone,
  }) async {
    try {
      print('🔄 Creating user account for: $email');
      print('🔄 Using project ID: ${AppwriteConstants.projectId}');
      print('🔄 Using endpoint: ${AppwriteConstants.endPoint}');

      final user = await account.create(
        userId: ID.unique(),
        email: email,
        password: password,
        name: fullName,
      );

      print('✅ User account created successfully: ${user.$id}');

      String userRole = 'user';
      if (email == 'tamalp241@gmail.com') {
        userRole = 'admin';
        print('🔑 Special admin email detected - assigning admin role');
      }

      final userData = {
        'uid': user.$id,
        'email': email,
        'username': username,
        'fullName': fullName,
        'photoUrl': null,
        'nidFrontUrl': null,
        'isVerifiedScorer': false,
        'role': userRole,
        'isBanned': false,
        'banReason': null,
        'bannedBy': null,
        'bannedAt': null,
        'phone': phone,
      };

      print('🔄 Creating complete user document in database...');

      try {

        await databases.createDocument(
          databaseId: AppwriteConstants.databaseId,
          collectionId: AppwriteConstants.usersCollection,
          documentId: user.$id,
          data: userData,
        );
        print('✅ Complete user document created successfully');

        await _createUserRoleRecord(
          userId: user.$id,
          role: userRole,
          assignedBy: user.$id,
        );
        print('✅ User role record created successfully');

        if (userRole == 'admin') {
          await _createAdminRecords(user.$id, email, fullName);
          print('✅ Admin records created successfully');
        }

      } catch (e) {
        print('❌ Could not create user records in database: $e');

        print('⚠️ Appwrite account created but database records failed');
        throw Exception('Failed to create user profile. Please try again.');
      }

      return UserModel(
        id: user.$id,
        uid: user.$id,
        email: email,
        username: username,
        fullName: fullName,
        photoUrl: null,
        nidFrontUrl: null,
        isVerifiedScorer: false,
        role: userRole,
        isBanned: false,
        banReason: null,
        bannedBy: null,
        bannedAt: null,
        phone: phone,
      );
    } on AppwriteException catch (e) {
      print('❌ Appwrite error during signup: ${e.code} - ${e.message}');
      if (e.code == 404) {
        throw Exception('Database not found. Please check your Appwrite configuration.');
      } else if (e.code == 401) {
        throw Exception('Authentication failed. Please check your Appwrite credentials.');
      } else if (e.code == 409) {
        throw Exception('User already exists with this email or username.');
      } else if (e.code == 400) {
        throw Exception('Invalid data provided. Please check your input.');
      }
      throw Exception('Sign up failed: ${e.message ?? "Unknown error"}');
    } catch (e) {
      print('❌ General error during signup: $e');
      throw Exception('Sign up failed: $e');
    }
  }

  Future<UserModel> signIn({
    required String email,
    required String password,
  }) async {
    try {
      print('🔄 Attempting to sign in user: $email');
      print('🔄 Using project ID: ${AppwriteConstants.projectId}');
      print('🔄 Using endpoint: ${AppwriteConstants.endPoint}');

      final session = await account.createEmailPasswordSession(
        email: email,
        password: password,
      );

      print('✅ User authenticated successfully: ${session.userId}');

      UserModel user;
      try {
        final userDoc = await databases.getDocument(
          databaseId: AppwriteConstants.databaseId,
          collectionId: AppwriteConstants.usersCollection,
          documentId: session.userId,
        );

        print('✅ User document retrieved from database');

        user = UserModel(
          id: userDoc.$id,
          uid: userDoc.data['uid'] ?? userDoc.$id,
          email: userDoc.data['email'] ?? email,
          username: userDoc.data['username'] ?? '',
          fullName: userDoc.data['fullName'] ?? '',
          photoUrl: userDoc.data['photoUrl'],
          nidFrontUrl: userDoc.data['nidFrontUrl'],
          isVerifiedScorer: userDoc.data['isVerifiedScorer'] ?? false,
          role: userDoc.data['role'] ?? 'user',
          isBanned: userDoc.data['isBanned'] ?? false,
          banReason: userDoc.data['banReason'],
          bannedBy: userDoc.data['bannedBy'],
          bannedAt: userDoc.data['bannedAt'] != null ? DateTime.parse(userDoc.data['bannedAt']) : null,
          phone: userDoc.data['phone'],
        );
      } catch (e) {
        print('❌ Database access failed: $e');

        await signOut();
        throw Exception('User profile not found. Please contact support.');
      }

      if (user.isBanned) {
        await signOut();
        throw Exception('Your account has been banned. Reason: ${user.banReason ?? "No reason provided"}');
      }

      if (email == 'tamalp241@gmail.com') {
        if (user.role != 'admin') {
          print('🔄 Updating user role to admin for: $email');

          final adminData = {
            'uid': user.uid,
            'email': user.email,
            'username': user.username,
            'fullName': user.fullName,
            'photoUrl': user.photoUrl,
            'nidFrontUrl': user.nidFrontUrl,
            'isVerifiedScorer': user.isVerifiedScorer,
            'role': 'admin',
            'isBanned': false,
            'banReason': null,
            'bannedBy': null,
            'bannedAt': null,
            'phone': user.phone,
          };

          await databases.updateDocument(
            databaseId: AppwriteConstants.databaseId,
            collectionId: AppwriteConstants.usersCollection,
            documentId: user.id,
            data: adminData,
          );

          await _createUserRoleRecord(
            userId: user.id,
            role: 'admin',
            assignedBy: user.id,
          );

          print('✅ User role updated to admin');
          user = user.copyWith(role: 'admin');
        }
      }

      print('✅ User signed in successfully');
      print('✅ User role: ${user.role}');
      print('✅ User is admin: ${user.isAdmin}');
      print('✅ User is moderator: ${user.isModerator}');

      return user;
    } on AppwriteException catch (e) {
      print('❌ Appwrite error during signin: ${e.code} - ${e.message}');
      if (e.code == 401) {
        throw Exception('Invalid email or password');
      } else if (e.code == 404) {
        throw Exception('User not found. Please check your email address.');
      } else if (e.code == 429) {
        throw Exception('Too many login attempts. Please try again later.');
      } else if (e.code == 500) {
        throw Exception('Server error. Please try again later.');
      }
      throw Exception('Sign in failed: ${e.message ?? "Unknown error"}');
    } catch (e) {
      print('❌ General error during signin: $e');
      throw Exception('Sign in failed: $e');
    }
  }

  Future<void> signOut() async {
    try {
      await account.deleteSession(sessionId: 'current');
    } on AppwriteException catch (e) {

      print('Sign out error: ${e.message}');
    }
  }

  Future<bool> isLoggedIn() async {
    try {
      await account.get();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<UserModel> getCurrentUser() async {
    try {
      final user = await account.get();

      UserModel userModel;
      try {
        final userDoc = await databases.getDocument(
          databaseId: AppwriteConstants.databaseId,
          collectionId: AppwriteConstants.usersCollection,
          documentId: user.$id,
        );

        userModel = UserModel(
          id: userDoc.$id,
          uid: userDoc.data['uid'] ?? userDoc.$id,
          email: userDoc.data['email'] ?? user.email,
          username: userDoc.data['username'] ?? user.name ?? '',
          fullName: userDoc.data['fullName'] ?? user.name ?? '',
          photoUrl: userDoc.data['photoUrl'],
          nidFrontUrl: userDoc.data['nidFrontUrl'],
          isVerifiedScorer: userDoc.data['isVerifiedScorer'] ?? false,
          role: userDoc.data['role'] ?? 'user',
          isBanned: userDoc.data['isBanned'] ?? false,
          banReason: userDoc.data['banReason'],
          bannedBy: userDoc.data['bannedBy'],
          bannedAt: userDoc.data['bannedAt'] != null ? DateTime.parse(userDoc.data['bannedAt']) : null,
          phone: userDoc.data['phone'],
        );
      } catch (e) {
        print('❌ Database access failed: $e');

        await signOut();
        throw Exception('User profile not found. Please contact support.');
      }

      if (userModel.isBanned) {
        await signOut();
        throw Exception('Your account has been banned. Reason: ${userModel.banReason ?? "No reason provided"}');
      }

      return userModel;
    } on AppwriteException catch (e) {
      if (e.code == 401) {
        throw Exception('User not authenticated');
      }
      throw Exception('Failed to get current user: ${e.message ?? "Unknown error"}');
    }
  }

  Future<UserModel> updateProfile({
    String? username,
    String? fullName,
    String? phone,
    String? photoUrl,
    String? nidFrontUrl,
  }) async {
    try {
      final currentUser = await getCurrentUser();

      final updatedUser = currentUser.copyWith(
        username: username ?? currentUser.username,
        fullName: fullName ?? currentUser.fullName,
        phone: phone ?? currentUser.phone,
        photoUrl: photoUrl ?? currentUser.photoUrl,
        nidFrontUrl: nidFrontUrl ?? currentUser.nidFrontUrl,
      );

      await databases.updateDocument(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.usersCollection,
        documentId: currentUser.id,
        data: updatedUser.toMap(),
      );

      return updatedUser;
    } on AppwriteException catch (e) {
      throw Exception('Failed to update profile: ${e.message ?? "Unknown error"}');
    }
  }

  Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    try {
      await account.updatePassword(
        password: newPassword,
        oldPassword: oldPassword,
      );
    } on AppwriteException catch (e) {
      if (e.code == 400) {
        throw Exception('Invalid old password');
      }
      throw Exception('Failed to change password: ${e.message ?? "Unknown error"}');
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await account.createRecovery(
        email: email,
        url: 'https://your-app.com/reset-password',
      );
    } on AppwriteException catch (e) {
      throw Exception('Failed to send reset email: ${e.message ?? "Unknown error"}');
    }
  }

  Future<UserModel> signUpWithGoogleAndOTP() async {
    try {
      print('🔄 Starting Google OAuth2 sign-up with OTP verification...');

      final user = await _googleOAuthService.signInWithGoogle();

      await _otpService.sendOTPToEmail(user.email, purpose: 'signup_verification');

      print('✅ OTP sent to ${user.email} for verification');
      return user;

    } catch (e) {
      print('❌ Error in Google OAuth2 sign-up: $e');
      throw Exception('Google sign-up failed: $e');
    }
  }

  Future<UserModel> verifyGoogleSignUpOTP(String email, String otp) async {
    try {
      print('🔄 Verifying OTP for Google sign-up: $email');

      final isValid = await _otpService.verifyOTP(email, otp, purpose: 'signup_verification');

      if (!isValid) {
        throw Exception('Invalid OTP. Please try again.');
      }

      final userDoc = await databases.getDocument(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.usersCollection,
        documentId: email,
      );

      final user = UserModel.fromMap(userDoc.data);

      await account.updateVerification(
        userId: user.id,
        secret: otp,
      );

      print('✅ Google sign-up OTP verified successfully');
      return user;

    } catch (e) {
      print('❌ Error verifying Google sign-up OTP: $e');
      throw Exception('OTP verification failed: $e');
    }
  }

  Future<UserModel> signInWithGoogle() async {
    try {
      return await _googleOAuthService.signInWithGoogle();
    } catch (e) {
      print('❌ Error in Google sign-in: $e');
      throw Exception('Google sign-in failed: $e');
    }
  }

  Future<String> sendPasswordResetOTP(String email) async {
    try {
      print('🔄 Sending password reset OTP to: $email');

      final users = await databases.listDocuments(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.usersCollection,
        queries: [Query.equal('email', email), Query.limit(1)],
      );

      if (users.documents.isEmpty) {
        throw Exception('No account found with this email address.');
      }

      final otp = await _otpService.sendOTPToEmail(email, purpose: 'password_reset');

      print('✅ Password reset OTP sent successfully');

      return otp;

    } catch (e) {
      print('❌ Error sending password reset: $e');
      throw Exception('Failed to send password reset: $e');
    }
  }

  Future<bool> verifyPasswordResetOTP(String email, String otp) async {
    try {
      print('🔄 Verifying password reset OTP for: $email');

      final isValid = await _otpService.verifyOTP(email, otp, purpose: 'password_reset');

      if (isValid) {
        print('✅ Password reset OTP verified successfully');
      } else {
        print('❌ Invalid password reset OTP');
      }

      return isValid;

    } catch (e) {
      print('❌ Error verifying password reset OTP: $e');
      throw Exception('OTP verification failed: $e');
    }
  }

  Future<void> updatePasswordWithOTP(String email, String newPassword) async {
    try {
      print('🔄 Updating password for: $email');

      final users = await databases.listDocuments(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.usersCollection,
        queries: [Query.equal('email', email), Query.limit(1)],
      );

      if (users.documents.isEmpty) {
        throw Exception('User not found.');
      }

      final userDoc = users.documents.first;
      final userId = userDoc.$id;

      await account.updatePassword(
        password: newPassword,
        oldPassword: '',
      );

      print('✅ Password updated successfully');

    } catch (e) {
      print('❌ Error updating password: $e');
      throw Exception('Failed to update password: $e');
    }
  }

  Future<void> signOutAll() async {
    try {
      await _googleOAuthService.signOut();
      await signOut();
      print('✅ Signed out from all services');
    } catch (e) {
      print('⚠️ Error during sign out: $e');
    }
  }

  Future<void> deleteAccount() async {
    try {
      final currentUser = await getCurrentUser();

      await databases.deleteDocument(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.usersCollection,
        documentId: currentUser.id,
      );

    } on AppwriteException catch (e) {
      throw Exception('Failed to delete account: ${e.message ?? "Unknown error"}');
    }
  }

  Future<void> _createUserRoleRecord({
    required String userId,
    required String role,
    required String assignedBy,
  }) async {
    try {
      final roleData = {
        'userId': userId,
        'role': role,
        'assignedBy': assignedBy,
        'assignedAt': DateTime.now().toIso8601String(),
        'isActive': true,
      };

      await databases.createDocument(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.userRolesCollection,
        documentId: ID.unique(),
        data: roleData,
      );
    } catch (e) {
      print('⚠️ Could not create user role record: $e');

    }
  }

  Future<void> _createAdminRecords(String userId, String email, String fullName) async {
    try {

      final notificationData = {
        'userId': userId,
        'title': 'Welcome to Admin Panel',
        'message': 'You have been granted admin privileges. You can now manage users, approve matches, and access all admin features.',
        'type': 'admin_welcome',
        'isRead': false,
        'createdAt': DateTime.now().toIso8601String(),
        'data': '{"role": "admin", "email": "$email"}',
      };

      await databases.createDocument(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.notificationsCollection,
        documentId: ID.unique(),
        data: notificationData,
      );

      print('✅ Admin welcome notification created');
    } catch (e) {
      print('⚠️ Could not create admin records: $e');

    }
  }

  Future<void> assignUserRole({
    required String targetUserId,
    required String role,
    required String assignedBy,
  }) async {
    try {

      final currentUserDoc = await databases.getDocument(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.usersCollection,
        documentId: targetUserId,
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

      await databases.updateDocument(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.usersCollection,
        documentId: targetUserId,
        data: updatedUserData,
      );

      await _createUserRoleRecord(
        userId: targetUserId,
        role: role,
        assignedBy: assignedBy,
      );

      final notificationData = {
        'userId': targetUserId,
        'title': 'Role Updated',
        'message': 'Your role has been updated to $role by an administrator.',
        'type': 'role_update',
        'isRead': false,
        'createdAt': DateTime.now().toIso8601String(),
        'data': '{"role": "$role", "assignedBy": "$assignedBy"}',
      };

      await databases.createDocument(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.notificationsCollection,
        documentId: ID.unique(),
        data: notificationData,
      );

      print('✅ User role assigned successfully');
    } on AppwriteException catch (e) {
      print('❌ Error assigning user role: ${e.code} - ${e.message}');
      throw Exception('Failed to assign user role: ${e.message ?? "Unknown error"}');
    }
  }

  Future<void> banUser({
    required String targetUserId,
    required String reason,
    required String bannedBy,
  }) async {
    try {

      final currentUserDoc = await databases.getDocument(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.usersCollection,
        documentId: targetUserId,
      );

      final updatedUserData = {
        'uid': currentUserDoc.data['uid'],
        'email': currentUserDoc.data['email'],
        'username': currentUserDoc.data['username'],
        'fullName': currentUserDoc.data['fullName'],
        'photoUrl': currentUserDoc.data['photoUrl'],
        'nidFrontUrl': currentUserDoc.data['nidFrontUrl'],
        'isVerifiedScorer': currentUserDoc.data['isVerifiedScorer'] ?? false,
        'role': currentUserDoc.data['role'],
        'isBanned': true,
        'banReason': reason,
        'bannedBy': bannedBy,
        'bannedAt': DateTime.now().toIso8601String(),
        'phone': currentUserDoc.data['phone'],
      };

      await databases.updateDocument(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.usersCollection,
        documentId: targetUserId,
        data: updatedUserData,
      );

      final banData = {
        'userId': targetUserId,
        'bannedBy': bannedBy,
        'reason': reason,
        'bannedAt': DateTime.now().toIso8601String(),
        'isActive': true,
      };

      await databases.createDocument(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.userBansCollection,
        documentId: ID.unique(),
        data: banData,
      );

      final notificationData = {
        'userId': targetUserId,
        'title': 'Account Banned',
        'message': 'Your account has been banned. Reason: $reason',
        'type': 'account_banned',
        'isRead': false,
        'createdAt': DateTime.now().toIso8601String(),
        'data': '{"reason": "$reason", "bannedBy": "$bannedBy"}',
      };

      await databases.createDocument(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.notificationsCollection,
        documentId: ID.unique(),
        data: notificationData,
      );

      print('✅ User banned successfully');
    } on AppwriteException catch (e) {
      throw Exception('Failed to ban user: ${e.message ?? "Unknown error"}');
    }
  }

  Future<void> unbanUser({
    required String targetUserId,
    required String unbannedBy,
  }) async {
    try {

      final currentUserDoc = await databases.getDocument(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.usersCollection,
        documentId: targetUserId,
      );

      final updatedUserData = {
        'uid': currentUserDoc.data['uid'],
        'email': currentUserDoc.data['email'],
        'username': currentUserDoc.data['username'],
        'fullName': currentUserDoc.data['fullName'],
        'photoUrl': currentUserDoc.data['photoUrl'],
        'nidFrontUrl': currentUserDoc.data['nidFrontUrl'],
        'isVerifiedScorer': currentUserDoc.data['isVerifiedScorer'] ?? false,
        'role': currentUserDoc.data['role'],
        'isBanned': false,
        'banReason': null,
        'bannedBy': null,
        'bannedAt': null,
        'phone': currentUserDoc.data['phone'],
      };

      await databases.updateDocument(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.usersCollection,
        documentId: targetUserId,
        data: updatedUserData,
      );

      final banRecords = await databases.listDocuments(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.userBansCollection,
        queries: [
          Query.equal('userId', targetUserId),
          Query.equal('isActive', true),
        ],
      );

      if (banRecords.documents.isNotEmpty) {
        final banRecord = banRecords.documents.first;
        await databases.updateDocument(
          databaseId: AppwriteConstants.databaseId,
          collectionId: AppwriteConstants.userBansCollection,
          documentId: banRecord.$id,
          data: {
            'isActive': false,
            'unbannedBy': unbannedBy,
            'unbannedAt': DateTime.now().toIso8601String(),
          },
        );
      }

      final notificationData = {
        'userId': targetUserId,
        'title': 'Account Unbanned',
        'message': 'Your account has been unbanned. You can now access the application again.',
        'type': 'account_unbanned',
        'isRead': false,
        'createdAt': DateTime.now().toIso8601String(),
        'data': '{"unbannedBy": "$unbannedBy"}',
      };

      await databases.createDocument(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.notificationsCollection,
        documentId: ID.unique(),
        data: notificationData,
      );

      print('✅ User unbanned successfully');
    } on AppwriteException catch (e) {
      throw Exception('Failed to unban user: ${e.message ?? "Unknown error"}');
    }
  }
}