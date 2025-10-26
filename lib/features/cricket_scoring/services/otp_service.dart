// lib\features\cricket_scoring\services\otp_service.dart

import 'dart:math';
import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../api/appwrite_constants.dart';
import 'email_providers.dart';
import '../../../main.dart';

class OTPService {
  static const String _otpCollection = AppwriteConstants.otpVerificationsCollection;
  static const int _otpLength = 6;
  static const int _otpExpiryMinutes = 5;

  late EmailProvider _emailProvider;

  static final Map<String, Map<String, dynamic>> _otpStorage = {};

  OTPService() {

    _configureEmailProvider();
  }

  void _configureEmailProvider() {


    _emailProvider = MockEmailProvider();



  }

  String _generateOTP() {
    final random = Random();
    final otp = random.nextInt(900000) + 100000;
    return otp.toString();
  }

  Future<String> sendOTPToEmail(String email, {String? purpose = 'verification'}) async {
    try {
      print('🔄 Generating OTP for email: $email');

      final otp = _generateOTP();
      final expiryTime = DateTime.now().add(Duration(minutes: _otpExpiryMinutes));

      if (purpose == 'password_reset') {

        _otpStorage[email] = {
          'otp': otp,
          'purpose': purpose,
          'isUsed': false,
          'createdAt': DateTime.now().toIso8601String(),
          'expiresAt': expiryTime.toIso8601String(),
          'attempts': 0,
        };
        print('✅ OTP stored in memory for password reset');
      } else {

        final otpData = {
          'email': email,
          'otp': otp,
          'purpose': purpose ?? 'verification',
          'isUsed': false,
          'createdAt': DateTime.now().toIso8601String(),
          'expiresAt': expiryTime.toIso8601String(),
          'attempts': 0,
        };

        await databases.createDocument(
          databaseId: AppwriteConstants.databaseId,
          collectionId: _otpCollection,
          documentId: ID.unique(),
          data: otpData,
        );
        print('✅ OTP stored in database');
      }

      await _sendEmailOTP(email, otp, purpose ?? 'verification');

      print('✅ OTP sent to email successfully');
      return otp;

    } catch (e) {
      print('❌ Error sending OTP: $e');
      throw Exception('Failed to send OTP: $e');
    }
  }

  Future<bool> verifyOTP(String email, String otp, {String? purpose = 'verification'}) async {
    try {
      print('🔄 Verifying OTP for email: $email');

      if (purpose == 'password_reset') {

        if (!_otpStorage.containsKey(email)) {
          print('❌ No OTP found for email: $email');
          return false;
        }

        final otpData = _otpStorage[email]!;
        final storedOTP = otpData['otp'];
        final attempts = otpData['attempts'] ?? 0;
        final expiresAt = DateTime.parse(otpData['expiresAt']);

        if (DateTime.now().isAfter(expiresAt)) {
          print('❌ OTP expired for email: $email');
          _otpStorage.remove(email);
          return false;
        }

        if (attempts >= 3) {
          print('❌ Too many OTP verification attempts');
          _otpStorage.remove(email);
          throw Exception('Too many verification attempts. Please request a new OTP.');
        }

        if (storedOTP == otp) {

          _otpStorage[email]!['isUsed'] = true;
          _otpStorage[email]!['verifiedAt'] = DateTime.now().toIso8601String();

          print('✅ OTP verified successfully');
          return true;
        } else {

          _otpStorage[email]!['attempts'] = attempts + 1;

          print('❌ Invalid OTP provided');
          return false;
        }
      } else {

        final otpRecords = await databases.listDocuments(
          databaseId: AppwriteConstants.databaseId,
          collectionId: _otpCollection,
          queries: [
            Query.equal('email', email),
            Query.equal('purpose', purpose ?? 'verification'),
            Query.equal('isUsed', false),
            Query.greaterThan('expiresAt', DateTime.now().toIso8601String()),
            Query.orderDesc('createdAt'),
            Query.limit(1),
          ],
        );

        if (otpRecords.documents.isEmpty) {
          print('❌ No valid OTP found for email: $email');
          return false;
        }

        final otpRecord = otpRecords.documents.first;
        final storedOTP = otpRecord.data['otp'];
        final attempts = otpRecord.data['attempts'] ?? 0;

        if (attempts >= 3) {
          print('❌ Too many OTP verification attempts');
          throw Exception('Too many verification attempts. Please request a new OTP.');
        }

        if (storedOTP == otp) {

          await databases.updateDocument(
            databaseId: AppwriteConstants.databaseId,
            collectionId: _otpCollection,
            documentId: otpRecord.$id,
            data: {
              'isUsed': true,
              'verifiedAt': DateTime.now().toIso8601String(),
            },
          );

          print('✅ OTP verified successfully');
          return true;
        } else {

          await databases.updateDocument(
            databaseId: AppwriteConstants.databaseId,
            collectionId: _otpCollection,
            documentId: otpRecord.$id,
            data: {
              'attempts': attempts + 1,
            },
          );

          print('❌ Invalid OTP provided');
          return false;
        }
      }

    } catch (e) {
      print('❌ Error verifying OTP: $e');
      throw Exception('Failed to verify OTP: $e');
    }
  }

  Future<void> _sendEmailOTP(String email, String otp, String purpose) async {
    try {
      await _emailProvider.sendOTPEmail(
        to: email,
        otp: otp,
        purpose: purpose,
      );

      print('✅ OTP sent successfully to $email');

    } catch (e) {
      print('❌ Error sending email: $e');
      throw Exception('Failed to send email: $e');
    }
  }

  Future<void> cleanupExpiredOTPs() async {
    try {
      print('🔄 Cleaning up expired OTPs...');

      final expiredOTPs = await databases.listDocuments(
        databaseId: AppwriteConstants.databaseId,
        collectionId: _otpCollection,
        queries: [
          Query.lessThan('expiresAt', DateTime.now().toIso8601String()),
        ],
      );

      for (final otpDoc in expiredOTPs.documents) {
        await databases.deleteDocument(
          databaseId: AppwriteConstants.databaseId,
          collectionId: _otpCollection,
          documentId: otpDoc.$id,
        );
      }

      print('✅ Cleaned up ${expiredOTPs.documents.length} expired OTPs');

    } catch (e) {
      print('⚠️ Error cleaning up expired OTPs: $e');
    }
  }

  Future<String> resendOTP(String email, {String? purpose = 'verification'}) async {
    try {
      print('🔄 Resending OTP for email: $email');

      final oldOTPs = await databases.listDocuments(
        databaseId: AppwriteConstants.databaseId,
        collectionId: _otpCollection,
        queries: [
          Query.equal('email', email),
          Query.equal('purpose', purpose ?? 'verification'),
        ],
      );

      for (final otpDoc in oldOTPs.documents) {
        await databases.deleteDocument(
          databaseId: AppwriteConstants.databaseId,
          collectionId: _otpCollection,
          documentId: otpDoc.$id,
        );
      }

      return await sendOTPToEmail(email, purpose: purpose);

    } catch (e) {
      print('❌ Error resending OTP: $e');
      throw Exception('Failed to resend OTP: $e');
    }
  }

  Future<bool> hasValidOTP(String email, {String? purpose = 'verification'}) async {
    try {
      final otpRecords = await databases.listDocuments(
        databaseId: AppwriteConstants.databaseId,
        collectionId: _otpCollection,
        queries: [
          Query.equal('email', email),
          Query.equal('purpose', purpose ?? 'verification'),
          Query.equal('isUsed', false),
          Query.greaterThan('expiresAt', DateTime.now().toIso8601String()),
          Query.limit(1),
        ],
      );

      return otpRecords.documents.isNotEmpty;
    } catch (e) {
      print('❌ Error checking valid OTP: $e');
      return false;
    }
  }
}
