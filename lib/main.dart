// lib/main.dart (MODIFIED)
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/draft_overview_screen.dart';
import 'screens/team_selection_screen.dart';
import 'services/analytics_service.dart';
import 'services/firebase_service.dart';
import 'services/precomputed_analytics_service.dart'; // Add this
import 'utils/analytics_server.dart';
import 'utils/theme_config.dart';
import 'utils/theme_manager.dart';
import 'services/message_service.dart';
import 'providers/auth_provider.dart';
import 'package:flutter/foundation.dart';

import 'widgets/admin/analytics_setup_widget.dart';
import 'widgets/admin/message_admin_panel.dart';

// Secret tap counter for admin access
int _secretTapCount = 0;
DateTime? _lastTapTime;

void main() async {
  // Initialize services
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase with additional logging
  try {
    await FirebaseService.initialize();
    debugPrint('Firebase initialized successfully in main.dart');
    
    // Preload common analytics data in background
    _preloadCommonAnalytics();
  } catch (e) {
    debugPrint('Firebase initialization error in main.dart: $e');
  }

  AnalyticsService.initializeAnalytics(measurementId: 'G-8QGNSTTZGH');

  // Turn on debug output for the app
  if (kDebugMode) {
    debugPrint = (String? message, {int? wrapWidth}) {
      if (message != null) {
        print(message);
      }
    };
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

// Preload common analytics data to reduce initial loading time
Future<void> _preloadCommonAnalytics() async {
  // Run this in background so app startup isn't delayed
  Future.delayed(Duration.zero, () async {
    try {
      // Get the latest stats timestamp (this also warms up the connection)
      final timestamp = await PrecomputedAnalyticsService.getLatestStatsTimestamp();
      debugPrint('Analytics data last updated: ${timestamp?.toString() ?? 'unknown'}');
      
      // Preload team needs data which is commonly used
      await PrecomputedAnalyticsService.getConsensusTeamNeeds();
      
      // Preload overall position distribution
      await PrecomputedAnalyticsService.getPositionBreakdownByTeam(team: 'All Teams');
      
      debugPrint('Preloaded common analytics data');
    } catch (e) {
      debugPrint('Error preloading analytics data: $e');
    }
  });
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
          home: const TeamSelectionScreen(), // Keep this
          routes: {
            // Remove the '/' route if it exists
            '/draft': (context) => DraftApp(
              selectedTeams: ModalRoute.of(context)?.settings.arguments != null 
              ? [ModalRoute.of(context)?.settings.arguments as String] 
              : null,
            ),
            // Other routes...
          },
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
            // Original Message Management Card
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
            const SizedBox(height: 12),
            // New Analytics Setup Widget
            const AnalyticsSetupWidget(), // Add this line
          ],
        ),
      ),
    );
  }
}