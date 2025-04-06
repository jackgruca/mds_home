// In lib/utils/admin_route.dart (update existing file)
import 'package:flutter/material.dart';
import '../screens/admin_login_screen.dart';
import '../utils/admin_auth.dart';
import '../widgets/admin/message_admin_panel.dart';

/// Helper class to handle admin routes
class AdminRoute {
  // Navigate to admin panel with proper authentication
  static Future<void> navigateToAdminPanel(BuildContext context) async {
    final isLoggedIn = await AdminAuth.isAdminLoggedIn();
    
    if (context.mounted) {
      if (isLoggedIn) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const MessageAdminPanel(),
          ),
        );
      } else {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const AdminLoginScreen(),
          ),
        );
      }
    }
  }
  
  // Add logout method
  static Future<void> logoutAdmin(BuildContext context) async {
    await AdminAuth.logoutAdmin();
    
    if (context.mounted) {
      Navigator.of(context).popUntil((route) => route.isFirst);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Logged out of admin panel'),
        ),
      );
    }
  }
}