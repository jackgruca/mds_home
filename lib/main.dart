// lib/main.dart (MODIFIED)
import 'package:flutter/material.dart';
import 'package:mds_home/screens/blog/blog_list_screen.dart';
import 'package:mds_home/screens/home_screen.dart';
import 'package:mds_home/utils/blog_router.dart';
import 'package:provider/provider.dart';
import 'screens/player_projections_screen.dart';
import 'screens/team_selection_screen.dart';
import 'screens/historical_data_screen.dart';
import 'screens/hubs/gm_hub_screen.dart';
import 'screens/hubs/fantasy_hub_screen.dart';
import 'screens/hubs/data_explorer_screen.dart';
import 'screens/wr_model_screen.dart';
import 'screens/player_season_stats_screen.dart';
import 'screens/nfl_rosters_screen.dart';
import 'screens/historical_game_data_screen.dart';
import 'services/analytics_query_service.dart';
import 'services/analytics_service.dart';
import 'services/firebase_service.dart';
import 'services/precomputed_analytics_service.dart'; // Add this
import 'utils/analytics_server.dart';
import 'utils/theme_config.dart';
import 'utils/theme_manager.dart';
import 'providers/auth_provider.dart';
import 'package:flutter/foundation.dart';

import 'widgets/admin/analytics_setup_widget.dart';
import 'widgets/admin/message_admin_panel.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'screens/fantasy/big_board_screen.dart';
import 'screens/fantasy/player_comparison_screen.dart';
import 'package:mds_home/ff_draft/screens/ff_home_screen.dart';
import 'package:mds_home/ff_draft/screens/ff_draft_setup_screen.dart';
import 'screens/rankings/rankings_placeholder_screen.dart';
import 'screens/rankings/qb_rankings_screen.dart';
import 'screens/depth_charts_screen.dart';
import 'screens/fantasy/player_trends_screen.dart';
import 'screens/fantasy/bust_evaluation_screen.dart';


// Secret tap counter for admin access

void main() async {
  // Initialize services
  WidgetsFlutterBinding.ensureInitialized();
  setUrlStrategy(PathUrlStrategy());

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
    testDraftCount();
  }

  void testDraftCount() async {
    int? count = await AnalyticsQueryService.getDraftCount();
    print('🔥 Total drafts in Firestore: $count');
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeManager>(
      builder: (context, themeManager, _) {
        return MaterialApp(
          navigatorObservers: [AnalyticsRouteObserver()],
          debugShowCheckedModeBanner: false,
          title: 'StickToTheModel',
          theme: themeManager.lightTheme,
          darkTheme: themeManager.darkTheme,
          themeMode: themeManager.themeMode,
          home: const HomeScreen(),
          onGenerateRoute: (settings) {
            // Handle blog routes first
            final blogRoute = BlogRouter.handleBlogRoute(settings);
            if (blogRoute != null) {
              return blogRoute;
            }
            
            // Handle regular routes
            switch (settings.name) {
              case '/':
                return MaterialPageRoute(builder: (_) => const HomeScreen());
              case '/draft':
                return MaterialPageRoute(builder: (_) => const TeamSelectionScreen());
              case '/draft/fantasy':
                return MaterialPageRoute(builder: (_) => const FFHomeScreen());
              case '/ff-draft':
                return MaterialPageRoute(builder: (_) => const FFHomeScreen());
              case '/ff-draft/setup':
                return MaterialPageRoute(builder: (_) => const FFDraftSetupScreen());
              case '/data':
                return MaterialPageRoute(builder: (_) => const DataExplorerScreen());
              case '/data/passing':
                return MaterialPageRoute(
                  builder: (_) => const PlayerSeasonStatsScreen(),
                  settings: const RouteSettings(arguments: {'position': 'QB'}),
                );
              case '/data/rushing':
                return MaterialPageRoute(
                  builder: (_) => const PlayerSeasonStatsScreen(),
                  settings: const RouteSettings(arguments: {'position': 'RB'}),
                );
              case '/data/receiving':
                return MaterialPageRoute(
                  builder: (_) => const PlayerSeasonStatsScreen(),
                  settings: const RouteSettings(arguments: {'position': 'WR'}),
                );
              case '/data/fantasy':
                return MaterialPageRoute(
                  builder: (_) => const PlayerSeasonStatsScreen(),
                  settings: const RouteSettings(arguments: {'position': 'FANTASY'}),
                );
              case '/projections':
                return MaterialPageRoute(builder: (_) => const PlayerProjectionsScreen());
              case '/blog':
                return MaterialPageRoute(builder: (_) => const BlogListScreen());
              case '/gm-hub': 
                return MaterialPageRoute(builder: (_) => GmHubScreen());
              case '/fantasy':
                return MaterialPageRoute(builder: (_) => const FantasyHubScreen());
              case '/fantasy/big-board':
                return MaterialPageRoute(builder: (_) => const BigBoardScreen());
              case '/fantasy/player-comparison':
                return MaterialPageRoute(builder: (_) => const PlayerComparisonScreen());
              case '/fantasy/trends':
                return MaterialPageRoute(builder: (_) => const PlayerTrendsScreen());
              case '/fantasy/bust-evaluation':
                return MaterialPageRoute(builder: (_) => const BustEvaluationScreen());
              // Rankings section - placeholder routes
              case '/rankings':
                return MaterialPageRoute(builder: (_) => const RankingsPlaceholderScreen(title: 'Rankings Hub'));
              case '/rankings/qb':
                return MaterialPageRoute(builder: (_) => const QBRankingsScreen());
              case '/rankings/rb':
                return MaterialPageRoute(builder: (_) => const RankingsPlaceholderScreen(title: 'RB Rankings'));
              case '/rankings/wr':
                return MaterialPageRoute(builder: (_) => const RankingsPlaceholderScreen(title: 'WR Rankings'));
              case '/rankings/te':
                return MaterialPageRoute(builder: (_) => const RankingsPlaceholderScreen(title: 'TE Rankings'));
              case '/rankings/ol':
                return MaterialPageRoute(builder: (_) => const RankingsPlaceholderScreen(title: 'OL Rankings'));
              case '/rankings/dl':
                return MaterialPageRoute(builder: (_) => const RankingsPlaceholderScreen(title: 'DL Rankings'));
              case '/rankings/lb':
                return MaterialPageRoute(builder: (_) => const RankingsPlaceholderScreen(title: 'LB Rankings'));
              case '/rankings/secondary':
                return MaterialPageRoute(builder: (_) => const RankingsPlaceholderScreen(title: 'Secondary Rankings'));
              case '/rankings/coaching':
                return MaterialPageRoute(builder: (_) => const RankingsPlaceholderScreen(title: 'Coaching Rankings'));
              case '/data/historical':
                return MaterialPageRoute(builder: (_) => const HistoricalDataScreen());
              case '/historical-data':
                return MaterialPageRoute(builder: (_) => const HistoricalDataScreen());
              case '/wr-model':
                return MaterialPageRoute(builder: (_) => const WRModelScreen());
              case '/player-season-stats':
                return MaterialPageRoute(builder: (_) => const PlayerSeasonStatsScreen());
              case '/nfl-rosters':
                return MaterialPageRoute(builder: (_) => const NflRostersScreen());
              case '/historical-game-data':
                return MaterialPageRoute(builder: (_) => const HistoricalGameDataScreen());
              case '/depth-charts':
                return MaterialPageRoute(builder: (_) => const DepthChartsScreen());
              default:
                return MaterialPageRoute(builder: (_) => const HomeScreen());
            }
          },
          initialRoute: '/',
          useInheritedMediaQuery: true,
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