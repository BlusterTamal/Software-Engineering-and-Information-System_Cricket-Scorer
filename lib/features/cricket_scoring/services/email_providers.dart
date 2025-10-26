// lib\features\cricket_scoring\services\email_providers.dart

import 'package:http/http.dart' as http;
import 'dart:convert';

abstract class EmailProvider {
  Future<void> sendOTPEmail({
    required String to,
    required String otp,
    required String purpose,
  });
}

class SendGridProvider extends EmailProvider {
  final String apiKey;
  final String fromEmail;
  final String fromName;

  SendGridProvider({
    required this.apiKey,
    required this.fromEmail,
    required this.fromName,
  });

  @override
  Future<void> sendOTPEmail({
    required String to,
    required String otp,
    required String purpose,
  }) async {
    final url = Uri.parse('https://api.sendgrid.com/v3/mail/send');

    final emailData = {
      'personalizations': [
        {
          'to': [{'email': to}],
          'subject': _getSubject(purpose),
        }
      ],
      'from': {'email': fromEmail, 'name': fromName},
      'content': [
        {
          'type': 'text/html',
          'value': _getEmailTemplate(otp, purpose),
        }
      ],
    };

    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(emailData),
    );

    if (response.statusCode != 202) {
      throw Exception('Failed to send email: ${response.body}');
    }
  }

  String _getSubject(String purpose) {
    switch (purpose) {
      case 'signup_verification':
        return 'Verify Your Email - Cricket Scoring System';
      case 'password_reset':
        return 'Reset Your Password - Cricket Scoring System';
      default:
        return 'Verification Code - Cricket Scoring System';
    }
  }

  String _getEmailTemplate(String otp, String purpose) {
    final purposeText = purpose == 'signup_verification' 
        ? 'email verification' 
        : 'password reset';

    return '''
    <html>
    <body style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
      <div style="background: linear-gradient(135deg, #2E7D32, #4CAF50); padding: 20px; text-align: center;">
        <h1 style="color: white; margin: 0;">Cricket Scoring System</h1>
      </div>
      <div style="padding: 20px;">
        <h2>Your Verification Code</h2>
        <p>Use the following code to complete your $purposeText:</p>
        <div style="background: #f5f5f5; padding: 20px; text-align: center; margin: 20px 0;">
          <h1 style="color: #2E7D32; font-size: 32px; margin: 0; letter-spacing: 5px;">$otp</h1>
        </div>
        <p><strong>This code will expire in 5 minutes.</strong></p>
        <p>If you didn't request this code, please ignore this email.</p>
      </div>
    </body>
    </html>
    ''';
  }
}

class AWSSESProvider extends EmailProvider {
  final String accessKeyId;
  final String secretAccessKey;
  final String region;
  final String fromEmail;

  AWSSESProvider({
    required this.accessKeyId,
    required this.secretAccessKey,
    required this.region,
    required this.fromEmail,
  });

  @override
  Future<void> sendOTPEmail({
    required String to,
    required String otp,
    required String purpose,
  }) async {

    throw UnimplementedError('AWS SES implementation requires AWS SDK');
  }
}

class SMTPProvider extends EmailProvider {
  final String host;
  final int port;
  final String username;
  final String password;
  final bool useTLS;
  final String fromEmail;

  SMTPProvider({
    required this.host,
    required this.port,
    required this.username,
    required this.password,
    required this.useTLS,
    required this.fromEmail,
  });

  @override
  Future<void> sendOTPEmail({
    required String to,
    required String otp,
    required String purpose,
  }) async {

    throw UnimplementedError('SMTP implementation requires mailer package');
  }
}

class AppwriteEmailProvider extends EmailProvider {
  @override
  Future<void> sendOTPEmail({
    required String to,
    required String otp,
    required String purpose,
  }) async {

    throw UnimplementedError('Appwrite email requires Functions setup');
  }
}

class MailgunProvider extends EmailProvider {
  final String apiKey;
  final String domain;
  final String fromEmail;

  MailgunProvider({
    required this.apiKey,
    required this.domain,
    required this.fromEmail,
  });

  @override
  Future<void> sendOTPEmail({
    required String to,
    required String otp,
    required String purpose,
  }) async {
    final url = Uri.parse('https://api.mailgun.net/v3/$domain/messages');

    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Basic ${base64Encode(utf8.encode('api:$apiKey'))}',
      },
      body: {
        'from': fromEmail,
        'to': to,
        'subject': _getSubject(purpose),
        'html': _getEmailTemplate(otp, purpose),
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to send email: ${response.body}');
    }
  }

  String _getSubject(String purpose) {
    switch (purpose) {
      case 'signup_verification':
        return 'Verify Your Email - Cricket Scoring System';
      case 'password_reset':
        return 'Reset Your Password - Cricket Scoring System';
      default:
        return 'Verification Code - Cricket Scoring System';
    }
  }

  String _getEmailTemplate(String otp, String purpose) {
    final purposeText = purpose == 'signup_verification' 
        ? 'email verification' 
        : 'password reset';

    return '''
    <html>
    <body style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
      <div style="background: linear-gradient(135deg, #2E7D32, #4CAF50); padding: 20px; text-align: center;">
        <h1 style="color: white; margin: 0;">Cricket Scoring System</h1>
      </div>
      <div style="padding: 20px;">
        <h2>Your Verification Code</h2>
        <p>Use the following code to complete your $purposeText:</p>
        <div style="background: #f5f5f5; padding: 20px; text-align: center; margin: 20px 0;">
          <h1 style="color: #2E7D32; font-size: 32px; margin: 0; letter-spacing: 5px;">$otp</h1>
        </div>
        <p><strong>This code will expire in 5 minutes.</strong></p>
        <p>If you didn't request this code, please ignore this email.</p>
      </div>
    </body>
    </html>
    ''';
  }
}

class MockEmailProvider extends EmailProvider {
  @override
  Future<void> sendOTPEmail({
    required String to,
    required String otp,
    required String purpose,
  }) async {

    print('📧 Mock Email Sent to: $to');
    print('🔑 OTP: $otp');
    print('📝 Purpose: $purpose');
    print('⏰ Expires in: 5 minutes');
    print('---');

    await Future.delayed(Duration(seconds: 1));

    print('''
📧 EMAIL CONTENT:
═══════════════════════════════════════════════════════════════
To: $to
Subject: ${_getSubject(purpose)}

${_getEmailContent(otp, purpose)}
═══════════════════════════════════════════════════════════════
    ''');
  }

  String _getSubject(String purpose) {
    switch (purpose) {
      case 'signup_verification':
        return 'Verify Your Email - Cricket Scoring System';
      case 'password_reset':
        return 'Reset Your Password - Cricket Scoring System';
      default:
        return 'Verification Code - Cricket Scoring System';
    }
  }

  String _getEmailContent(String otp, String purpose) {
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
