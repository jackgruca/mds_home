// lib/services/message_service.dart
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'cache_service.dart';
import 'email_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'batch_operation_service.dart';
import 'cache_service.dart';

/// Service to manage user feedback messages
class MessageService {
  // Key for storing messages in SharedPreferences
  static const String _messagesKey = 'user_feedback_messages';
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'messages';

  /// Save a user message to local storage and send via email
  static Future<bool> saveUserMessage({
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

      // Send email using EmailJS
      final emailSent = await EmailService.sendContactFormEmail(
        name: name,
        email: email,
        message: message,
        feedbackType: feedbackType,
      );

      // If email sent successfully, update status
      if (emailSent) {
        await markMessageAsSent(messageData['timestamp']);
      }

      debugPrint('Message saved successfully: ${messageData['timestamp']}');
      debugPrint('Email sent successfully: $emailSent');
      
      return emailSent;
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
        final messages = parsed.cast<Map<String, dynamic>>();
        
        // Sort by timestamp descending (newest first)
        messages.sort((a, b) {
          final aTime = DateTime.tryParse(a['timestamp'] ?? '') ?? DateTime(1970);
          final bTime = DateTime.tryParse(b['timestamp'] ?? '') ?? DateTime(1970);
          return bTime.compareTo(aTime);
        });
        
        return messages;
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

  /// Get count of pending messages
  static Future<int> getPendingMessageCount() async {
    final messages = await getAllMessages();
    return messages.where((msg) => msg['status'] == 'pending').length;
  }

  /// Mark a message as sent
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

  static Future<List<Map<String, dynamic>>> getRecentMessages({int limit = 20}) async {
  try {
    // Use caching
    final cacheKey = 'recent_messages_$limit';
    final cachedData = CacheService.getData(cacheKey);
    if (cachedData != null) return cachedData;
    
    final snapshot = await FirebaseFirestore.instance
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .get();
    
    final messages = snapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return data;
    }).toList();
    
    // Store in cache
    CacheService.setData(cacheKey, messages);
    
    return messages;
  } catch (e) {
    debugPrint('Error getting recent messages: $e');
    return [];
  }
}
// Update to use batch operations
  static Future<bool> markMultipleMessagesAsSent(List<String> messageIds) async {
    try {
      await BatchOperationService.updateMultipleDocuments(
        collectionPath: _collection,
        documentIds: messageIds,
        updateData: {
          'status': 'sent',
          'sentAt': DateTime.now().toIso8601String(),
        },
      );
      
      // Invalidate cache
      CacheService.removeItem('recent_messages');
      
      return true;
    } catch (e) {
      debugPrint('Error marking messages as sent: $e');
      return false;
    }
  }
  
  // Another example with batch operations
  static Future<bool> bulkDeleteMessages(List<String> messageIds) async {
    try {
      await BatchOperationService.deleteMultipleDocuments(
        collectionPath: _collection,
        documentIds: messageIds,
      );
      
      // Invalidate cache
      CacheService.removeItem('recent_messages');
      
      return true;
    } catch (e) {
      debugPrint('Error deleting messages: $e');
      return false;
    }
  }
}