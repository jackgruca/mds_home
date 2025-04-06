// In lib/utils/admin_auth.dart
import 'package:shared_preferences/shared_preferences.dart';

class AdminAuth {
  // Check if admin is logged in
  static Future<bool> isAdminLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool('isAdminLoggedIn') ?? false;
    
    // Check if login has expired (24 hours)
    if (isLoggedIn) {
      final loginTimeStr = prefs.getString('adminLoginTime');
      if (loginTimeStr != null) {
        final loginTime = DateTime.parse(loginTimeStr);
        final now = DateTime.now();
        final difference = now.difference(loginTime);
        
        // If more than 24 hours, log out
        if (difference.inHours > 24) {
          await logoutAdmin();
          return false;
        }
      }
    }
    
    return isLoggedIn;
  }
  
  // Log out admin
  static Future<void> logoutAdmin() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isAdminLoggedIn', false);
    await prefs.remove('adminLoginTime');
  }
}