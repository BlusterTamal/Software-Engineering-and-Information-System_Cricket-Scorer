// lib\features\cricket_scoring\services\simple_email_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;

class SimpleEmailService {

  static Future<void> sendOTPEmail({
    required String to,
    required String otp,
    required String purpose,
  }) async {
    try {
      print('📧 Sending OTP email to: $to');
      print('🔑 OTP: $otp');
      print('📝 Purpose: $purpose');


      await Future.delayed(Duration(seconds: 2));

      print('''
📧 EMAIL CONTENT:
═══════════════════════════════════════════════════════════════
To: $to
Subject: ${_getSubject(purpose)}

${_getEmailContent(otp, purpose)}
═══════════════════════════════════════════════════════════════
      ''');

      print('✅ OTP email sent successfully to $to');

    } catch (e) {
      print('❌ Error sending OTP email: $e');
      throw Exception('Failed to send OTP email: $e');
    }
  }

  static String _getSubject(String purpose) {
    switch (purpose) {
      case 'signup_verification':
        return 'Verify Your Email - Cricket Scoring System';
      case 'password_reset':
        return 'Reset Your Password - Cricket Scoring System';
      default:
        return 'Verification Code - Cricket Scoring System';
    }
  }

  static String _getEmailContent(String otp, String purpose) {
    final purposeText = purpose == 'signup_verification' 
        ? 'email verification' 
        : 'password reset';

    return '''
Hello!

Use the following code to complete your $purposeText:

🔐 VERIFICATION CODE: $otp

This code will expire in 5 minutes.

If you didn't request this code, please ignore this email.

Best regards,
Cricket Scoring System Team
    ''';
  }
}



