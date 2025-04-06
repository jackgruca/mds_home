// lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/draft_overview_screen.dart';
import 'screens/team_selection_screen.dart';
import 'services/analytics_aggregation_service.dart';
import 'services/analytics_data_manager.dart';
import 'services/analytics_service.dart';
import 'services/firebase_service.dart';
import 'utils/analytics_server.dart';
import 'utils/theme_config.dart';
import 'utils/theme_manager.dart';
import 'services/message_service.dart';
import 'providers/auth_provider.dart';
import 'package:flutter/foundation.dart';
import 'services/analytics_data_manager.dart';


import 'widgets/admin/message_admin_panel.dart';

// Secret tap counter for admin access
int _secretTapCount = 0;
DateTime? _lastTapTime;

void main() async {
  // Initialize services
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  try {
    await FirebaseService.initialize();
    debugPrint('Firebase initialized successfully in main.dart');
  } catch (e) {
    debugPrint('Firebase initialization error in main.dart: $e');
  }

  // Initialize analytics
  AnalyticsService.initializeAnalytics(measurementId: 'G-8QGNSTTZGH');

  try {
  // Just initialize the manager, but don't load data until needed
  AnalyticsDataManager().initialize();
  debugPrint('Analytics data manager initialized (data will load on demand)');
} catch (e) {
  debugPrint('Error initializing analytics data manager: $e');
}

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