// lib/features/cricket_scoring/api/appwrite_constants.dart
// Configuration constants for Appwrite
import '../../config/secrets.dart';

class AppwriteConstants {
  // Database ID
  static const String databaseId = 'cricket_scorer';
  
  // Collection IDs
  static const String usersCollection = 'users';
  static const String teamsCollection = 'teams';
  static const String playersCollection = 'players';
  static const String matchesCollection = 'matches';
  static const String tournamentsCollection = 'tournaments';
  static const String notificationsCollection = 'notifications';
  static const String userRolesCollection = 'user_roles';
  static const String userBansCollection = 'user_bans';
  static const String matchApprovalsCollection = 'match_approvals';
  
  // API Configuration (from Secrets)
  static String get endPoint => Secrets.appwriteEndpoint;
  static String get projectId => Secrets.appwriteProjectId;
}

