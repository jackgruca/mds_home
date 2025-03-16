// lib/utils/admin_route.dart
import 'package:flutter/material.dart';
import '../widgets/admin/message_admin_panel.dart';
import '../widgets/admin/message_admin_panel.dart';

/// Helper class to handle admin routes
class AdminRoute {
  // Secret gestures or taps to access admin features (for development only)
  static void attemptAdminAccess(BuildContext context, {int tapCount = 0}) {
    // When tap count reaches 5, show admin panel
    if (tapCount >= 5) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const MessageAdminPanel(),
        ),
      );
    }
  }
  
  // Show the admin panel directly (for development/testing)
  static void showAdminPanel(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const MessageAdminPanel(),
      ),
    );
  }
}