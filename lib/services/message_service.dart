// lib/services/message_service.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service to manage user feedback messages
class MessageService {
  // Key for storing messages in SharedPreferences
  static const String _messagesKey = 'user_feedback_messages';

  /// Save a user message to local storage
  /// In a production app, this would likely send to a server
  static Future<void> saveUserMessage({
    required String name,
    required String email,
    required String message,
    required String feedbackType,
  }) async {
    try {
      // Create message object
      final Map<String, dynamic> messageData = {
        'name': name,
        'email': email,
        'message': message,
        'feedbackType': feedbackType,
        'timestamp': DateTime.now().toIso8601String(),
        'status': 'pending', // pending, sent, read, etc.
      };

      // Get shared preferences instance
      final prefs = await SharedPreferences.getInstance();

      // Get existing messages
      List<Map<String, dynamic>> messages = [];
      final String? existingMessagesJson = prefs.getString(_messagesKey);
      
      if (existingMessagesJson != null) {
        final List<dynamic> parsed = jsonDecode(existingMessagesJson);
        messages = parsed.cast<Map<String, dynamic>>();
      }

      // Add new message
      messages.add(messageData);

      // Save updated messages list
      await prefs.setString(_messagesKey, jsonEncode(messages));

      // In a real app, you might also want to send this to a server
      // This could be implemented later with Firebase, AWS, or your own backend
      await _syncWithServer(messageData);

      debugPrint('Message saved successfully: ${messageData['timestamp']}');
    } catch (e) {
      debugPrint('Error saving message: $e');
      throw Exception('Failed to save message: $e');
    }
  }

  /// Get all stored messages
  static Future<List<Map<String, dynamic>>> getAllMessages() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? messagesJson = prefs.getString(_messagesKey);
      
      if (messagesJson != null) {
        final List<dynamic> parsed = jsonDecode(messagesJson);
        return parsed.cast<Map<String, dynamic>>();
      }
      
      return [];
    } catch (e) {
      debugPrint('Error getting messages: $e');
      return [];
    }
  }

  /// Clear all messages (for testing or admin purposes)
  static Future<void> clearAllMessages() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_messagesKey);
    } catch (e) {
      debugPrint('Error clearing messages: $e');
    }
  }

  /// Mock function to simulate syncing with a server
  /// This would be replaced with actual API calls in production
  static Future<void> _syncWithServer(Map<String, dynamic> messageData) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));
    
    // For now, just log that we would send this to a server
    debugPrint('Would send message to server: ${messageData['feedbackType']} from ${messageData['name']}');
    
    // Here you would implement actual server communication
    // Example:
    // final response = await http.post(
    //   Uri.parse('https://your-api.com/messages'),
    //   headers: {'Content-Type': 'application/json'},
    //   body: jsonEncode(messageData),
    // );
    // 
    // if (response.statusCode != 200) {
    //   throw Exception('Failed to sync message with server');
    // }
  }

  /// Get count of pending messages
  static Future<int> getPendingMessageCount() async {
    final messages = await getAllMessages();
    return messages.where((msg) => msg['status'] == 'pending').length;
  }

  /// Mark a message as sent (would be called after successful server sync in production)
  static Future<void> markMessageAsSent(String timestamp) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? messagesJson = prefs.getString(_messagesKey);
      
      if (messagesJson != null) {
        final List<dynamic> parsed = jsonDecode(messagesJson);
        final List<Map<String, dynamic>> messages = parsed.cast<Map<String, dynamic>>();
        
        for (int i = 0; i < messages.length; i++) {
          if (messages[i]['timestamp'] == timestamp) {
            messages[i]['status'] = 'sent';
          }
        }
        
        await prefs.setString(_messagesKey, jsonEncode(messages));
      }
    } catch (e) {
      debugPrint('Error marking message as sent: $e');
    }
  }
}