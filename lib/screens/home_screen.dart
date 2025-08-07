import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:mds_home/widgets/common/custom_app_bar.dart';
import '../utils/theme_manager.dart';
import '../utils/theme_config.dart';
import '../utils/seo_helper.dart';
import '../widgets/auth/auth_dialog.dart';
import '../widgets/common/responsive_layout_builder.dart';
import '../widgets/common/app_drawer.dart';
import '../widgets/common/top_nav_bar.dart';
import '../widgets/home/hero_section.dart';
import '../widgets/home/feature_section.dart';
import '../widgets/home/blog_section.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  // Animation controller for scroll-triggered animations
  late AnimationController _scrollAnimationController;
  final ScrollController _scrollController = ScrollController();
  
  // Global key for scrolling to tools section
  final GlobalKey _toolsSectionKey = GlobalKey();

  final Map<String, Map<String, dynamic>> _toolCategories = {
    'Fantasy Hub': {
      'description': 'Dominate your fantasy leagues with data-driven insights and strategic tools',
      'tools': [
        {
          'icon': Icons.sports_football,
          'title': 'Fantasy Hub',
          'desc': 'Fantasy big board, ADP analysis, custom rankings, stat predictor, mock draft sim, player comparison, player trends, my custom rankings.',
          'route': '/fantasy',
          'image': null,
        },
        {
          'icon': Icons.leaderboard,
          'title': 'Fantasy Big Board',
          'desc': 'Fantasy player rankings and tiers.',
          'route': '/fantasy/big-board',
          'image': null,
        },
        {
          'icon': Icons.show_chart,
          'title': 'ADP Analysis',
          'desc': 'Historical ADP vs performance analysis.',
          'route': '/fantasy/adp',
          'image': 'assets/images/FF/shiva.png',
        },
      ],
    },
    'Be a GM': {
      'description': 'Understand the business side of a championship team with premium scouting and player profile tools',
      'tools': [
        {
          'icon': Icons.assignment_ind,
          'title': 'Be a GM Hub',
          'desc': 'Draft big board, draft mock draft simulator, historical drafts, bust or brilliant, depth chart, rosters.',
          'route': '/gm-hub',
          'image': null,
        },
        {
          'icon': Icons.leaderboard,
          'title': 'Draft Big Board',
          'desc': '2026 NFL Draft prospect rankings.',
          'route': '/draft/big-board',
          'image': 'assets/images/GM/big board.png',
        },
        {
          'icon': Icons.format_list_numbered,
          'title': 'Draft Mock Draft Simulator',
          'desc': 'Interactive 7-round draft simulator with team needs and trade scenarios.',
          'route': '/draft',
          'image': 'assets/images/GM/PIT Draft.png',
        },
      ],
    },
    'Betting': {
      'description': 'Make smarter wagers with data-driven insights and predictive models',
      'tools': [
        {
          'icon': Icons.paid,
          'title': 'Betting Hub',
          'desc': 'Central hub for betting insights, models, and tools.',
          'route': '/betting/hub',
          'image': null,
        },
        {
          'icon': Icons.show_chart,
          'title': 'Line Tracker',
          'desc': 'Track real-time odds and line movement across sportsbooks.',
          'route': '/line-tracker',
          'image': null,
        },
        {
          'icon': Icons.calculate,
          'title': 'Create Your Model',
          'desc': 'Build and test your own betting models with custom parameters.',
          'route': '/betting/model',
          'image': null,
        },
      ],
    },
    'Data Center': {
      'description': 'Access comprehensive NFL analytics and performance insights',
      'tools': [
        {
          'icon': Icons.analytics,
          'title': 'Data Center',
          'desc': 'Historical game data, player season stats, player data.',
          'route': '/data',
          'image': null,
        },
        {
          'icon': Icons.history,
          'title': 'Historical Game Data',
          'desc': 'Browse historical NFL game data and trends.',
          'route': '/historical-game-data',
          'image': null,
        },
        {
          'icon': Icons.person,
          'title': 'Player Season Stats',
          'desc': 'Detailed player statistics by season.',
          'route': '/player-season-stats',
          'image': null,
        },
      ],
    },
    'Rankings': {
      'description': 'Expert player rankings and position analysis',
      'tools': [
        {
          'icon': Icons.leaderboard,
          'title': 'Rankings Hub',
          'desc': 'QB, WR, TE, RB, pass offense, run offense rankings.',
          'route': '/rankings',
          'image': null,
        },
        {
          'icon': Icons.sports,
          'title': 'QB Rankings',
          'desc': 'Comprehensive quarterback rankings and analysis.',
          'route': '/rankings/qb',
          'image': null,
        },
        {
          'icon': Icons.sports_handball,
          'title': 'WR Rankings',
          'desc': 'Wide receiver rankings and projections.',
          'route': '/rankings/wr',
          'image': null,
        },
      ],
    },
  };

  final List<Map<String, String>> _blogPosts = [
    // {
    //   'title': 'NFL Draft Surprises & Sleepers',
    //   'excerpt': 'Unpacking the most unexpected picks and hidden gems from the recent NFL draft...',
    //   'date': '2024-04-28',
    //   'imageUrl': 'assets/images/blog/draft_analysis_blog.jpg',
    //   'route': '/blog/draft-surprises'
    // },
  ];
  
  @override
  void initState() {
    super.initState();
    _scrollAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    
    _scrollController.addListener(_onScroll);
    
    // Update SEO for homepage
    WidgetsBinding.instance.addPostFrameCallback((_) {
      SEOHelper.updateForHomepage();
    });
  }
  
  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _scrollAnimationController.dispose();
    super.dispose();
  }
  
  void _onScroll() {
    // Update animation controller based on scroll position
    final scrollPosition = _scrollController.position.pixels;
    final maxScroll = _scrollController.position.maxScrollExtent;
    
    // Normalize the scroll position to a value between 0 and 1
    final scrollFraction = (scrollPosition / 500).clamp(0.0, 1.0);
    _scrollAnimationController.value = scrollFraction;
  }

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
            child: Material(
              elevation: 2,
              borderRadius: BorderRadius.circular(24),
              shadowColor: ThemeConfig.brightRed.withOpacity(0.3),
              child: ElevatedButton(
                onPressed: () {
                  HapticFeedback.lightImpact(); // Add haptic feedback
                  showDialog(context: context, builder: (_) => const AuthDialog());
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: ThemeConfig.darkNavy,
                  foregroundColor: Colors.white,
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
      body: AnimatedBuilder(
        animation: _scrollAnimationController,
        builder: (context, child) {
          return Stack(
            children: [
              // Background design element that changes with scroll
              Positioned(
                top: -100 + (_scrollAnimationController.value * 50),
                right: -50,
                child: Container(
                  width: 300,
                  height: 300,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        ThemeConfig.brightRed.withOpacity(0.2),
                        ThemeConfig.brightRed.withOpacity(0.0),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: -150,
                left: -100,
                child: Container(
                  width: 400,
                  height: 400,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        ThemeConfig.darkNavy.withOpacity(0.2),
                        ThemeConfig.darkNavy.withOpacity(0.0),
                      ],
                    ),
                  ),
                ),
              ),
              
              // Main content
              SingleChildScrollView(
                controller: _scrollController,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Hero Section
                    AnimationConfiguration.synchronized(
                      duration: const Duration(milliseconds: 800),
                      child: FadeInAnimation(
                        child: SlideAnimation(
                          verticalOffset: 30.0,
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
                            child: HeroSection(
                              featuredTools: const [], // Empty since we're not using featured tool chips anymore
                              onGetStarted: () {
                                // Scroll to the tools section
                                Scrollable.ensureVisible(
                                  _toolsSectionKey.currentContext!,
                                  duration: const Duration(milliseconds: 500),
                                  curve: Curves.easeInOut,
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                    
                    // Feature Section
                    AnimationConfiguration.synchronized(
                      duration: const Duration(milliseconds: 800),
                      child: FadeInAnimation(
                        child: SlideAnimation(
                          verticalOffset: 30.0,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: _buildToolsSection(),
                          ),
                        ),
                      ),
                    ),
                    
                    // Stats section
                    AnimationConfiguration.synchronized(
                      duration: const Duration(milliseconds: 800),
                      child: FadeInAnimation(
                        child: SlideAnimation(
                          verticalOffset: 30.0,
                          child: _buildStatsSection(context),
                        ),
                      ),
                    ),
                    
                    // Blog Section (if there are blog posts)
                    if (_blogPosts.isNotEmpty)
                      AnimationConfiguration.synchronized(
                        duration: const Duration(milliseconds: 800),
                        child: FadeInAnimation(
                          child: SlideAnimation(
                            verticalOffset: 30.0,
                            child: BlogSection(blogPosts: _blogPosts),
                          ),
                        ),
                      ),
                    
                    // Footer Signup
                    AnimationConfiguration.synchronized(
                      duration: const Duration(milliseconds: 800),
                      child: FadeInAnimation(
                        child: SlideAnimation(
                          verticalOffset: 30.0,
                          child: _buildFooterSignup(context, isDarkMode),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildToolsSection() {
    return Container(
      key: _toolsSectionKey,
      padding: const EdgeInsets.only(top: 40),
      child: FeatureSection(categorizedTools: _toolCategories),
    );
  }
  
  Widget _buildStatsSection(BuildContext context) {
    // Use a blue gradient background and gold text for the header
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 40, horizontal: 16),
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            ThemeConfig.darkNavy,
            ThemeConfig.darkNavy.withOpacity(0.85),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'TRUSTED BY SERIOUS FOOTBALL MINDS',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
              color: ThemeConfig.gold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
          ResponsiveLayoutBuilder(
            mobile: (context) => Column(
              children: _buildStatItems(context, textColor: Colors.white),
            ),
            desktop: (context) => Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: _buildStatItems(context, textColor: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
  
  List<Widget> _buildStatItems(BuildContext context, {Color textColor = Colors.white}) {
    final stats = [
      {'number': '300K+', 'label': 'Mock Drafts Run'},
      {'number': '25K+', 'label': 'Users'},
      {'number': '10M+', 'label': 'NFL Data Points'},
    ];
    return stats.map((stat) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Column(
          children: [
            Text(
              stat['number']!,
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: textColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              stat['label']!,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: textColor.withOpacity(0.8),
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  Widget _buildFooterSignup(BuildContext context, bool isDarkMode) {
    // Use a blue gradient background and white text, matching the hero section's gradient
    return Container(
      margin: const EdgeInsets.only(top: 32),
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            ThemeConfig.darkNavy,
            ThemeConfig.darkNavy.withOpacity(0.85),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border(
          top: BorderSide(
            color: ThemeConfig.brightRed.withOpacity(0.2),
            width: 2,
          ),
        ),
      ),
      child: Column(
        children: [
          Text(
            'Ready to elevate your football IQ?',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'Join our community of data-driven football minds and get full access to all our premium tools.',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.white.withOpacity(0.85),
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(32),
            shadowColor: ThemeConfig.brightRed.withOpacity(0.4),
            child: ElevatedButton(
              onPressed: () {
                HapticFeedback.lightImpact();
                showDialog(context: context, builder: (_) => const AuthDialog());
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: ThemeConfig.brightRed,
                foregroundColor: Colors.white,
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
    );
  }
} 