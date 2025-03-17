// lib/services/email_service.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../utils/app_config.dart';

/// Service for sending emails from the contact form
class EmailService {
  // EmailJS service configuration from AppConfig
  static const String _emailJsServiceId = AppConfig.emailJsServiceId;
  static const String _emailJsTemplateId = AppConfig.emailJsTemplateId;
  static const String _emailJsUserId = AppConfig.emailJsUserId;
  static const String _emailJsBaseUrl = 'https://api.emailjs.com/api/v1.0/email/send';

  /// Send an email using EmailJS
  static Future<bool> sendEmail({
    required String name,
    required String email,
    required String message,
    required String feedbackType,
  }) async {
    try {
      // Prepare the payload according to EmailJS format
      final payload = jsonEncode({
        'service_id': _emailJsServiceId,
        'template_id': _emailJsTemplateId,
        'user_id': _emailJsUserId,
        'template_params': {
          'from_name': name,
          'from_email': email,
          'message': message,
          'feedback_type': feedbackType,
          'to_email': 'YOUR_RECIPIENT_EMAIL', // Can be configured in the template as well
        }
      });

      // Send the request to EmailJS
      final response = await http.post(
        Uri.parse(_emailJsBaseUrl),
        headers: {
          'Content-Type': 'application/json',
        },
        body: payload,
      );

      // Check if the email was sent successfully
      if (response.statusCode >= 200 && response.statusCode < 300) {
        debugPrint('Email sent successfully');
        return true;
      } else {
        debugPrint('Failed to send email. Status code: ${response.statusCode}');
        debugPrint('Response body: ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('Error sending email: $e');
      return false;
    }
  }

  /// Send email in production, log in development to prevent accidental emails
  static Future<bool> sendContactFormEmail({
    required String name,
    required String email,
    required String message,
    required String feedbackType,
  }) async {
    // In debug mode, just log the email and pretend it was sent
    if (kDebugMode) {
      debugPrint('DEBUG MODE: Would send email with:');
      debugPrint('From: $name <$email>');
      debugPrint('Feedback Type: $feedbackType');
      debugPrint('Message: $message');
      return true;
    }
    
    // In production, actually send the email
    return sendEmail(
      name: name,
      email: email,
      message: message,
      feedbackType: feedbackType,
    );
  }
}