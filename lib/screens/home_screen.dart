import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:mds_home/widgets/common/custom_app_bar.dart';
import '../utils/theme_manager.dart';
import '../utils/theme_config.dart';
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
      'title': 'Mock Draft Simulator',
      'desc': 'Simulate the NFL draft with real-time analytics and team-building tools.',
      'image': 'assets/images/GM/PIT Draft.png',
      'route': '/draft',
    },
    {
      'title': 'Data Hub',
      'desc': 'Explore advanced NFL data, stats, and analytics.',
      'image': 'assets/images/data/moneyBall.jpeg',
      'route': '/data',
    },
    {
      'title': 'Player Big Boards',
      'desc': 'View and customize player rankings from multiple sources.',
      'image': 'assets/images/FF/shiva.png',
      'route': '/fantasy/big-board',
    },
    {
      'title': 'Fantasy Football Mock Draft',
      'desc': 'Practice your fantasy draft strategy and get ready for your league.',
      'image': 'assets/images/GM/big board.png',
      'route': '/draft/fantasy',
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
      'route': '/fantasy/big-board',
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
      'route': '/wr-model',
    },
    {
      'icon': Icons.paid,
      'title': 'Betting Analytics',
      'desc': 'Odds, trends, and historical ATS data.',
      'route': '/data/historical',
    },
  ];

  final List<Map<String, String>> _blogPosts = [
    // {
    //   'title': 'NFL Draft Surprises & Sleepers',
    //   'excerpt': 'Unpacking the most unexpected picks and hidden gems from the recent NFL draft...',
    //   'date': '2024-04-28',
    //   'imageUrl': 'assets/images/blog/draft_analysis_blog.jpg',
    //   'route': '/blog/draft-surprises'
    // },
    // {
    //   'title': 'Advanced Metrics for Betting Success',
    //   'excerpt': 'Leverage cutting-edge analytics to gain an edge in NFL betting markets this season...',
    //   'date': '2024-04-25',
    //   'imageUrl': 'assets/images/blog/betting_metrics_blog.jpg',
    //   'route': '/blog/betting-metrics'
    // },
    // {
    //   'title': 'Breakout Player Projections 2024',
    //   'excerpt': 'Identifying the players poised for a significant leap in performance in the upcoming season...',
    //   'date': '2024-04-22',
    //   'imageUrl': 'assets/images/blog/player_projections_blog.jpg',
    //   'route': '/blog/breakout-players'
    // },
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
            child:             Material(
              elevation: 2,
              borderRadius: BorderRadius.circular(24),
              shadowColor: ThemeConfig.gold.withOpacity(0.3),
              child: ElevatedButton(
                onPressed: () {
                  HapticFeedback.lightImpact(); // Add haptic feedback
                  showDialog(context: context, builder: (_) => const AuthDialog());
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: ThemeConfig.darkNavy,
                  foregroundColor: ThemeConfig.gold,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                child: const Text('Sign In / Sign Up'),
              ),
            ),
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: AnimationConfiguration.synchronized(
        duration: const Duration(milliseconds: 800),
        child: FadeInAnimation(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
            AnimationConfiguration.staggeredList(
              position: 0,
              duration: const Duration(milliseconds: 600),
              child: SlideAnimation(
                verticalOffset: 40.0,
                child: FadeInAnimation(
                  child: Padding(
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
                ),
              ),
            ),
            AnimationConfiguration.staggeredList(
              position: 1,
              duration: const Duration(milliseconds: 600),
              child: SlideAnimation(
                verticalOffset: 30.0,
                child: FadeInAnimation(
                  child: BlogSection(blogPosts: _blogPosts),
                ),
              ),
            ),
            _buildFooterSignup(context, isDarkMode),
          ],
        ),
          ),
        ),
      ),
    );
  }

  Widget _buildFooterSignup(BuildContext context, bool isDarkMode) {
    return AnimationConfiguration.staggeredList(
      position: 0,
      duration: const Duration(milliseconds: 600),
      child: SlideAnimation(
        verticalOffset: 30.0,
        child: FadeInAnimation(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDarkMode 
                  ? [
                      ThemeConfig.darkNavy.withOpacity(0.3),
                      ThemeConfig.darkNavy.withOpacity(0.1),
                    ]
                  : [
                      ThemeConfig.gold.withOpacity(0.1),
                      ThemeConfig.gold.withOpacity(0.05),
                    ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border(
                top: BorderSide(
                  color: ThemeConfig.gold.withOpacity(0.3),
                  width: 2,
                ),
              ),
            ),
            child: Column(
              children: [
                Text(
                  'Want personalized NFL updates and insights?',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  'Sign up for full access to all our tools and get the latest insights delivered to your inbox.',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                Material(
                  elevation: 4,
                  borderRadius: BorderRadius.circular(32),
                  shadowColor: ThemeConfig.gold.withOpacity(0.4),
                  child: ElevatedButton(
                    onPressed: () {
                      HapticFeedback.lightImpact(); // Add haptic feedback
                      showDialog(context: context, builder: (_) => const AuthDialog());
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ThemeConfig.darkNavy,
                      foregroundColor: ThemeConfig.gold,
                      padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 18),
                      textStyle: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(32),
                      ),
                    ),
                    child: const Text('Get Started Now'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 