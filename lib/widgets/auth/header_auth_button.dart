// // Create a new file: lib/widgets/auth/header_auth_button.dart

// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import '../../providers/auth_provider.dart';
// import '../../screens/user_preferences_screen.dart';
// import '../../utils/theme_config.dart';
// import 'auth_dialog.dart';

// class HeaderAuthButton extends StatelessWidget {
//   const HeaderAuthButton({super.key});

//   void _showAuthDialog(BuildContext context) {
//     showDialog(
//       context: context,
//       builder: (context) => const AuthDialog(initialMode: AuthMode.signIn),
//     );
//   }

//   void _handleSignOut(BuildContext context) async {
//     final authProvider = Provider.of<AuthProvider>(context, listen: false);
//     await authProvider.signOut();
    
//     if (context.mounted) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text('You have been signed out'),
//           backgroundColor: Colors.blue,
//         ),
//       );
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
//     return Consumer<AuthProvider>(
//       builder: (context, authProvider, child) {
//         final user = authProvider.user;
        
//         if (authProvider.isLoading) {
//           return const SizedBox(
//             width: 20,
//             height: 20,
//             child: CircularProgressIndicator(
//               strokeWidth: 2,
//             ),
//           );
//         }
        
//         if (user != null) {
//           // User is logged in - show avatar with dropdown
//           return PopupMenuButton<String>(
//             offset: const Offset(0, 40),
//             child: Padding(
//               padding: const EdgeInsets.all(8.0),
//               child: Row(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   CircleAvatar(
//                     radius: 14,
//                     backgroundColor: isDarkMode ? ThemeConfig.gold : ThemeConfig.deepRed,
//                     child: Text(
//                       user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
//                       style: const TextStyle(
//                         color: Colors.white,
//                         fontSize: 12,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                   ),
//                   const SizedBox(width: 4),
//                   const Icon(Icons.arrow_drop_down, size: 16),
//                 ],
//               ),
//             ),
//             itemBuilder: (context) => [
//               PopupMenuItem(
//                 value: 'account',
//                 enabled: false,
//                 child: Row(
//                   children: [
//                     Icon(Icons.person, 
//                       size: 16, 
//                       color: isDarkMode ? Colors.white70 : Colors.black87
//                     ),
//                     const SizedBox(width: 8),
//                     Text(
//                       user.name,
//                       style: TextStyle(
//                         fontWeight: FontWeight.bold,
//                         color: isDarkMode ? Colors.white : Colors.black,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//               const PopupMenuDivider(),
//               const PopupMenuItem(
//                 value: 'profile',
//                 child: Row(
//                   children: [
//                     Icon(Icons.settings, size: 16),
//                     SizedBox(width: 8),
//                     Text('Profile Settings'),
//                   ],
//                 ),
//               ),
//               const PopupMenuItem(
//                 value: 'signout',
//                 child: Row(
//                   children: [
//                     Icon(Icons.logout, size: 16),
//                     SizedBox(width: 8),
//                     Text('Sign Out'),
//                   ],
//                 ),
//               ),
//               const PopupMenuItem(
//                 value: 'preferences',
//                 child: Row(
//                   children: [
//                     Icon(Icons.settings, size: 16),
//                     SizedBox(width: 8),
//                     Text('User Preferences'),
//                   ],
//                 ),
//               ),
//             ],
//             onSelected: (value) {
//               switch (value) {
//                 case 'profile':
//                   // TODO: Implement profile screen
//                   break;
//                 case 'signout':
//                   _handleSignOut(context);
//                   break;
//                 case 'preferences':
//                   Navigator.push(
//                     context,
//                     MaterialPageRoute(
//                       builder: (context) => const UserPreferencesScreen(),
//                     ),
//                   );
//                   break;
//               }
//             },
//           );
//         } else {
//           // User is not logged in - show sign in button
//           return TextButton.icon(
//             onPressed: () => _showAuthDialog(context),
//             icon: const Icon(Icons.login, size: 16),
//             label: const Text('Members'),
//             style: ElevatedButton.styleFrom(
//               backgroundColor: isDarkMode ? ThemeConfig.brightRed : ThemeConfig.deepRed,
//               foregroundColor: Colors.white,
//               padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//               textStyle: const TextStyle(fontSize: 14),
//             ),
//           );
//         }
//       },
//     );
//   }
// }