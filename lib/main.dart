// lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/team_selection_screen.dart';
import 'services/analytics_service.dart';
import 'utils/analytics_observer.dart';
import 'utils/theme_config.dart';
import 'utils/theme_manager.dart';
import 'services/message_service.dart';
import 'providers/auth_provider.dart';
import 'package:flutter/foundation.dart';

import 'widgets/admin/message_admin_panel.dart';

// Secret tap counter for admin access
int _secretTapCount = 0;
DateTime? _lastTapTime;

void main() {
  // Initialize services
  WidgetsFlutterBinding.ensureInitialized();
  
  if (kIsWeb) {
    AnalyticsService.initializeAnalytics(measurementId: 'G-8QGNSTTZGH');
  }
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeManager()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    // Initialize auth provider
    Future.delayed(Duration.zero, () {
      Provider.of<AuthProvider>(context, listen: false).initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeManager>(
      builder: (context, themeManager, _) {
        return MaterialApp(
          navigatorObservers: [AnalyticsRouteObserver()],
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
                      settings: const RouteSettings(name: '/admin_access'),
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
  void initState() {
    super.initState();
    // Track screen view
    if (kIsWeb) {
      AnalyticsService.logPageView('/admin_access');
    }
  }
  
  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }
  
  void _checkPassword() {
    // Simple password for development
    if (_passwordController.text == 'admin123') {
      if (kIsWeb) {
        AnalyticsService.logEvent('admin_login_success');
      }
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          settings: const RouteSettings(name: '/admin_panel'),
          builder: (context) => const AdminPanel(),
        ),
      );
    } else {
      if (kIsWeb) {
        AnalyticsService.logEvent('admin_login_failure');
      }
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
    // Track screen view
    if (kIsWeb) {
      AnalyticsService.logPageView('/admin_panel');
    }
    
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
                  if (kIsWeb) {
                    AnalyticsService.logEvent('admin_action', parameters: {
                      'action': 'view_messages'
                    });
                  }
                  final messageCount = await MessageService.getPendingMessageCount();
                  if (context.mounted) {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        settings: const RouteSettings(name: '/message_admin'),
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