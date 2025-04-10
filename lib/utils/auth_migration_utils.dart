// lib/utils/auth_migration_utils.dart (corrected)
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/user.dart';
import '../services/firebase_auth_service.dart';

class AuthMigrationUtils {
  // Migrate all users from SharedPreferences to Firebase
  static Future<void> migrateUsersToFirebase(BuildContext context) async {
    try {
      // Get all users from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final usersJson = prefs.getString('registered_users');
      
      if (usersJson == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No local users found')),
        );
        return;
      }
      
      final decoded = jsonDecode(usersJson) as Map<String, dynamic>;
      final users = <User>[];
      final passwords = <String>[];
      
      for (var entry in decoded.entries) {
        final userData = User.fromJson(jsonDecode(entry.key));
        users.add(userData);
        passwords.add(entry.value as String);
      }
      
      // Initialize Firebase Auth
      await FirebaseAuthService.initialize();
      
      // Show progress dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          title: Text('Migrating Users'),
          content: SizedBox(
            height: 100,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Migrating users to Firebase...'),
                ],
              ),
            ),
          ),
        ),
      );
      
      // Migrate each user
      int successCount = 0;
      for (int i = 0; i < users.length; i++) {
        try {
          final user = users[i];
          final password = passwords[i];
          
          // Use the register method instead of createUserWithEmail
          await FirebaseAuthService.register(
            email: user.email,
            password: password,
            name: user.name,
            isSubscribed: user.isSubscribed,
          );
          
          // After registration, update the user with additional data
          if (user.favoriteTeams != null || user.draftPreferences != null || user.customDraftData != null) {
            final currentUser = FirebaseAuthService.currentUser;
            if (currentUser != null) {
              final updatedUser = currentUser.copyWith(
                favoriteTeams: user.favoriteTeams,
                draftPreferences: user.draftPreferences
                // customDraftData: user.customDraftData,
              );
              await FirebaseAuthService.updateUser(updatedUser);
            }
          }
          
          successCount++;
        } catch (e) {
          debugPrint('Error migrating user ${users[i].email}: $e');
        }
      }
      
      // Close progress dialog
      if (context.mounted) {
        Navigator.pop(context);
      }
      
      // Show result
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Migrated $successCount out of ${users.length} users')),
        );
      }
    } catch (e) {
      debugPrint('Error migrating users: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error migrating users: $e')),
        );
      }
    }
  }
}