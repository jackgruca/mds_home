// lib/widgets/common/app_drawer.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/theme_config.dart';
import '../auth/auth_dialog.dart';

class AppDrawer extends StatelessWidget {
  final String currentRoute;

  const AppDrawer({
    super.key,
    this.currentRoute = '/',
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Drawer(
      child: Column(
        children: [
          // DrawerHeader
          DrawerHeader(
            decoration: BoxDecoration(
              color: isDarkMode ? AppTheme.darkNavy : AppTheme.deepRed,
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'NFL Draft Tools',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Plan, Analyze, Win',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          
          // Auth Widget
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Consumer<AuthProvider>(
              builder: (context, authProvider, _) {
                if (authProvider.isLoading) {
                  return const Center(child: CircularProgressIndicator(strokeWidth: 2));
                }
                
                if (authProvider.isLoggedIn) {
                  // Show user info
                  final user = authProvider.user;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: isDarkMode ? AppTheme.brightBlue : AppTheme.deepRed,
                            child: Text(
                              user?.name.isNotEmpty == true ? user!.name[0].toUpperCase() : '?',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  user?.name ?? 'User',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                Text(
                                  user?.email ?? '',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade700,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: () {
                          authProvider.signOut();
                          Navigator.pop(context); // Close drawer after sign out
                        },
                        icon: const Icon(Icons.logout, size: 16),
                        label: const Text('Sign Out'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                      ),
                    ],
                  );
                } else {
                  // Show sign in button
                  return ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context); // Close drawer first
                      showDialog(
                        context: context,
                        builder: (context) => const AuthDialog(initialMode: AuthMode.signIn),
                      );
                    },
                    icon: const Icon(Icons.login, size: 16),
                    label: const Text('Sign In / Register'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDarkMode ? AppTheme.brightBlue : AppTheme.deepRed,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                  );
                }
              },
            ),
          ),
          
          const Divider(),
          
          // Menu Items
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                ListTile(
                  leading: const Icon(Icons.sports_football),
                  title: const Text('Mock Draft Simulator'),
                  selected: currentRoute == '/',
                  selectedTileColor: isDarkMode ? 
                      AppTheme.darkNavy.withOpacity(0.1) : 
                      AppTheme.deepRed.withOpacity(0.1),
                  selectedColor: isDarkMode ? AppTheme.brightBlue : AppTheme.deepRed,
                  onTap: () {
                    if (currentRoute != '/') {
                      Navigator.pop(context);
                      Navigator.pushReplacementNamed(context, '/');
                    } else {
                      Navigator.pop(context);
                    }
                  },
                ),
                
                ListTile(
                  leading: const Icon(Icons.person),
                  title: const Text('Player Projections'),
                  selected: currentRoute == '/player-projections',
                  selectedTileColor: isDarkMode ? 
                      AppTheme.darkNavy.withOpacity(0.1) : 
                      AppTheme.deepRed.withOpacity(0.1),
                  selectedColor: isDarkMode ? AppTheme.brightBlue : AppTheme.deepRed,
                  onTap: () {
                    Navigator.pop(context);
                    if (currentRoute != '/player-projections') {
                      Navigator.pushNamed(context, '/player-projections');
                    }
                  },
                ),
                
                ListTile(
                  leading: const Icon(Icons.trending_up),
                  title: const Text('Betting Analytics'),
                  selected: currentRoute == '/betting-analytics',
                  selectedTileColor: isDarkMode ? 
                      AppTheme.darkNavy.withOpacity(0.1) : 
                      AppTheme.deepRed.withOpacity(0.1),
                  selectedColor: isDarkMode ? AppTheme.brightBlue : AppTheme.deepRed,
                  onTap: () {
                    Navigator.pop(context);
                    if (currentRoute != '/betting-analytics') {
                      Navigator.pushNamed(context, '/betting-analytics');
                    }
                  },
                ),
                
                ListTile(
                  leading: const Icon(Icons.article),
                  title: const Text('Blog'),
                  selected: currentRoute == '/blog',
                  selectedTileColor: isDarkMode ? 
                      AppTheme.darkNavy.withOpacity(0.1) : 
                      AppTheme.deepRed.withOpacity(0.1),
                  selectedColor: isDarkMode ? AppTheme.brightBlue : AppTheme.deepRed,
                  onTap: () {
                    Navigator.pop(context);
                    if (currentRoute != '/blog') {
                      Navigator.pushNamed(context, '/blog');
                    }
                  },
                ),
                
                const Divider(),
                
                ListTile(
                  leading: const Icon(Icons.help_outline),
                  title: const Text('Help & FAQ'),
                  onTap: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Help & FAQ coming soon'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          
          // Footer with version
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'v1.0.0',
              style: TextStyle(
                fontSize: 12,
                color: isDarkMode ? Colors.grey.shade500 : Colors.grey.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}