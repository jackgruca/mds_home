// lib/widgets/auth/auth_status_widget.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/theme_config.dart';
import 'auth_dialog.dart';

class AuthStatusWidget extends StatelessWidget {
  const AuthStatusWidget({super.key});

  void _showAuthDialog(BuildContext context, {required AuthMode initialMode}) {
    showDialog(
      context: context,
      builder: (context) => AuthDialog(
        initialMode: initialMode,
      ),
    );
  }

  void _handleSignOut(BuildContext context) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.signOut();
    
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You have been signed out'),
          backgroundColor: Colors.blue,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final user = authProvider.user;
        
        if (authProvider.isLoading) {
          return const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
            ),
          );
        }
        
        if (user != null) {
          // User is logged in
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 12,
                backgroundColor: isDarkMode ? ThemeConfig.gold : ThemeConfig.deepRed,
                child: Text(
                  user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      user.name,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? Colors.white : Colors.black87,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      user.isSubscribed ? 'Subscribed' : 'Not Subscribed',
                      style: TextStyle(
                        fontSize: 10,
                        color: user.isSubscribed 
                            ? Colors.green
                            : (isDarkMode ? Colors.white70 : Colors.black54),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, size: 16),
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'profile',
                    child: Row(
                      children: [
                        Icon(Icons.person, size: 16),
                        SizedBox(width: 8),
                        Text('Profile'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'signout',
                    child: Row(
                      children: [
                        Icon(Icons.logout, size: 16),
                        SizedBox(width: 8),
                        Text('Sign Out'),
                      ],
                    ),
                  ),
                ],
                onSelected: (value) {
                  switch (value) {
                    case 'profile':
                      // TODO: Implement profile screen
                      break;
                    case 'signout':
                      _handleSignOut(context);
                      break;
                  }
                },
              ),
            ],
          );
        } else {
          // User is not logged in
          return ElevatedButton(
            onPressed: () => _showAuthDialog(context, initialMode: AuthMode.signIn),
            style: ElevatedButton.styleFrom(
              backgroundColor: isDarkMode ? ThemeConfig.brightRed : ThemeConfig.deepRed,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              minimumSize: const Size(0, 32),
              textStyle: const TextStyle(fontSize: 12),
            ),
            child: const Text('Sign In/Sign Up'),
          );
        }
      },
    );
  }
}