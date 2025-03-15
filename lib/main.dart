// lib/main.dart - Update with dependencies
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/team_selection_screen.dart';
import 'utils/theme_config.dart';
import 'utils/theme_manager.dart';
import 'services/message_service.dart'; // Add this import

import 'package:flutter/foundation.dart';

import 'widgets/admin/message_admin_panel.dart';

// Secret tap counter for admin access
int _secretTapCount = 0;
DateTime? _lastTapTime;

void main() {
  // Initialize services
  WidgetsFlutterBinding.ensureInitialized();
  
  // Turn on debug output for the app
  if (kDebugMode) {
    debugPrint = (String? message, {int? wrapWidth}) {
      if (message != null) {
        print(message);
      }
    };
  }
  
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeManager(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeManager>(
      builder: (context, themeManager, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'NFL Draft App',
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeManager.themeMode,
          home: GestureDetector(
            // Add a detector for admin access (5 quick taps on title bar)
            onTap: () {
              final now = DateTime.now();
              if (_lastTapTime != null && 
                  now.difference(_lastTapTime!).inSeconds < 3) {
                _secretTapCount++;
                
                // Check for admin access after 5 quick taps
                if (_secretTapCount >= 5) {
                  // Reset the counter
                  _secretTapCount = 0;
                  
                  // Show the admin panel
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const AdminAccessScreen(),
                    ),
                  );
                }
              } else {
                // Reset counter if too much time has passed
                _secretTapCount = 1;
              }
              _lastTapTime = now;
            },
            // Make sure the gesture detector doesn't interfere with other interactions
            behavior: HitTestBehavior.translucent,
            child: const TeamSelectionScreen(),
          ),
        );
      },
    );
  }
}

// Simple password screen before showing admin panel
class AdminAccessScreen extends StatefulWidget {
  const AdminAccessScreen({super.key});

  @override
  _AdminAccessScreenState createState() => _AdminAccessScreenState();
}

class _AdminAccessScreenState extends State<AdminAccessScreen> {
  final _passwordController = TextEditingController();
  bool _showError = false;
  
  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }
  
  void _checkPassword() {
    // Simple password for development
    if (_passwordController.text == 'admin123') {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const AdminPanel(),
        ),
      );
    } else {
      setState(() {
        _showError = true;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin Access')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.admin_panel_settings, size: 64, color: Colors.blue),
            const SizedBox(height: 20),
            const Text(
              'Admin Access Required',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 30),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(
                labelText: 'Password',
                border: const OutlineInputBorder(),
                errorText: _showError ? 'Invalid password' : null,
              ),
              obscureText: true,
              onSubmitted: (_) => _checkPassword(),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _checkPassword,
              child: const Text('Login'),
            ),
          ],
        ),
      ),
    );
  }
}

// Simple admin panel to access various admin features
class AdminPanel extends StatelessWidget {
  const AdminPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin Panel')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Admin Tools',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Card(
              child: ListTile(
                leading: const Icon(Icons.message),
                title: const Text('Message Management'),
                subtitle: const Text('View and manage user feedback messages'),
                onTap: () async {
                  final messageCount = await MessageService.getPendingMessageCount();
                  if (context.mounted) {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const MessageAdminPanel(),
                      ),
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}