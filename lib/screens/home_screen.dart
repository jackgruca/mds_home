import 'package:flutter/material.dart';
import 'package:mds_home/widgets/common/custom_app_bar.dart';
import '../utils/theme_manager.dart';
import '../widgets/auth/auth_dialog.dart';
import '../widgets/common/responsive_layout_builder.dart';
import '../widgets/common/app_drawer.dart';
import '../widgets/common/top_nav_bar.dart';
import '../widgets/home/home_slideshow.dart';
import '../widgets/home/stacked_tool_links.dart';
import '../widgets/home/blog_section.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<Map<String, String>> _slides = [
    {
      'title': 'Run a Mock Draft',
      'desc': 'Simulate the NFL draft with real-time analytics.',
      'image': 'assets/images/GM/PIT Draft.png',
      'route': '/draft',
    },
    {
      'title': 'Fantasy Football Mock Drafts',
      'desc': 'Practice your fantasy draft strategy.',
      'image': 'assets/images/GM/big board.png',
      'route': '/draft/fantasy',
    },
    {
      'title': 'Player Big Boards',
      'desc': 'View and customize player rankings.',
      'image': 'assets/images/FF/shiva.png',
      'route': '/draft/big-board',
    },
    {
      'title': 'Games This Week',
      'desc': 'See matchups, odds, and projections for this week.',
      'image': 'assets/images/blog/draft_analysis_blog.jpg',
      'route': '/data',
    },
  ];

  final List<Map<String, dynamic>> _tools = [
    {
      'icon': Icons.format_list_numbered,
      'title': 'Mock Draft Simulator',
      'desc': 'Simulate the NFL draft with real-time analytics.',
      'route': '/draft',
    },
    {
      'icon': Icons.sports_football,
      'title': 'Fantasy Football Mock Drafts',
      'desc': 'Practice your fantasy draft strategy.',
      'route': '/draft/fantasy',
    },
    {
      'icon': Icons.leaderboard,
      'title': 'Player Big Boards',
      'desc': 'View and customize player rankings.',
      'route': '/draft/big-board',
    },
    {
      'icon': Icons.calendar_today,
      'title': 'Games This Week',
      'desc': 'See matchups, odds, and projections for this week.',
      'route': '/data',
    },
    {
      'icon': Icons.trending_up,
      'title': 'Player Analytics',
      'desc': 'Projections, stats, and fantasy insights.',
      'route': '/projections',
    },
    {
      'icon': Icons.paid,
      'title': 'Betting Analytics',
      'desc': 'Odds, trends, and historical ATS data.',
      'route': '/betting',
    },
  ];

  final List<Map<String, String>> _blogPosts = [
    {
      'title': 'NFL Draft Surprises & Sleepers',
      'excerpt': 'Unpacking the most unexpected picks and hidden gems from the recent NFL draft...',
      'date': '2024-04-28',
      'imageUrl': 'assets/images/blog/draft_analysis_blog.jpg',
      'route': '/blog/draft-surprises'
    },
    {
      'title': 'Advanced Metrics for Betting Success',
      'excerpt': 'Leverage cutting-edge analytics to gain an edge in NFL betting markets this season...',
      'date': '2024-04-25',
      'imageUrl': 'assets/images/blog/betting_metrics_blog.jpg',
      'route': '/blog/betting-metrics'
    },
    {
      'title': 'Breakout Player Projections 2024',
      'excerpt': 'Identifying the players poised for a significant leap in performance in the upcoming season...',
      'date': '2024-04-22',
      'imageUrl': 'assets/images/blog/player_projections_blog.jpg',
      'route': '/blog/breakout-players'
    },
  ];

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final currentRouteName = ModalRoute.of(context)?.settings.name;

    return Scaffold(
      appBar: CustomAppBar(
        titleWidget: Row(
          children: [
            const Text('StickToTheModel', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(width: 20),
            Expanded(child: TopNavBarContent(currentRoute: currentRouteName)),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ElevatedButton(
              onPressed: () => showDialog(context: context, builder: (_) => const AuthDialog()),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                textStyle: const TextStyle(fontSize: 14),
              ),
              child: const Text('Sign In / Sign Up'),
            ),
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              child: ResponsiveLayoutBuilder(
                mobile: (context) => Column(
                  children: [
                    HomeSlideshow(slides: _slides, isMobile: true),
                    const SizedBox(height: 24),
                    StackedToolLinks(tools: _tools),
                  ],
                ),
                desktop: (context) => Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 2, child: HomeSlideshow(slides: _slides)),
                    const SizedBox(width: 32),
                    Expanded(flex: 1, child: StackedToolLinks(tools: _tools)),
                  ],
                ),
              ),
            ),
            BlogSection(blogPosts: _blogPosts),
            _buildFooterSignup(context, isDarkMode),
          ],
        ),
      ),
    );
  }

  Widget _buildFooterSignup(BuildContext context, bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      color: isDarkMode ? Theme.of(context).colorScheme.surface.withOpacity(0.1) : Colors.blue.shade50,
      child: Column(
        children: [
          Text(
            'Want personalized NFL updates and insights?',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Theme.of(context).colorScheme.onSurface),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 15),
          Text(
            'Sign up for full access to all our tools and get the latest insights delivered to your inbox.',
            style: Theme.of(context).textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 25),
          ElevatedButton(
            onPressed: () => showDialog(context: context, builder: (_) => const AuthDialog()),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              textStyle: Theme.of(context).textTheme.titleMedium,
            ),
            child: const Text('Get Started Now'),
          ),
        ],
      ),
    );
  }
} 