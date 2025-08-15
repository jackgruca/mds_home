import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:mds_home/widgets/common/app_drawer.dart';
import 'package:mds_home/widgets/common/custom_app_bar.dart';
import 'package:mds_home/widgets/common/responsive_layout_builder.dart';
import 'package:mds_home/widgets/common/top_nav_bar.dart';
import 'package:mds_home/widgets/auth/auth_dialog.dart';
import 'package:mds_home/widgets/home/home_slideshow.dart';
import 'package:mds_home/widgets/home/stacked_tool_links.dart';
import 'package:mds_home/widgets/home/blog_section.dart';
import 'package:collection/collection.dart';
import '../utils/theme_config.dart';

class FantasyHubScreen extends StatelessWidget {
  // Constructor without const
  FantasyHubScreen({super.key});

  // --- Placeholder Data ---
  final List<Map<String, String>> _slides = [
    {
      'title': 'Compare Players Side-by-Side',
      'desc': 'Analyze and compare fantasy players with detailed stats.',
      'image': 'data/images/ff/shiva.png',
      'route': '/fantasy/player-comparison',
    },
    {
      'title': 'Create Your Fantasy Big Board',
      'desc': 'Compare rankings across major platforms and create your own.',
      'image': 'data/images/ff/shiva.png',
      'route': '/fantasy/big-board',
    },
    {
      'title': 'Fantasy Mock Draft Now!',
      'desc': 'Practice your strategy against realistic opponents.',
      'image': 'data/images/ff/shiva.png', 
      'route': '/draft/fantasy',
    },
  ];

  final List<Map<String, dynamic>> _tools = [
     {
      'icon': Icons.leaderboard,
      'title': 'Fantasy Big Board', 
      'desc': 'Create and compare player rankings.',
      'route': '/fantasy/big-board',
      'isPlaceholder': false,
    },
     {
      'icon': Icons.drafts,
      'title': 'Fantasy Draft Sim', 
      'desc': 'Prepare for your league draft.',
      'route': '/draft/fantasy',
      'isPlaceholder': false,
    },
     {
      'icon': Icons.trending_up, 
      'title': 'Player Rankings', 
      'desc': 'See the latest expert rankings.',
      'route': '/fantasy/rankings',
      'isPlaceholder': true,
    },
      {
      'icon': Icons.rule, 
      'title': 'Start/Sit Optimizer', 
      'desc': 'Get recommendations for your lineup.',
      'route': '/fantasy/start-sit',
      'isPlaceholder': true,
    },
  ];

  final List<Map<String, String>> _blogPosts = [
     {
        'title': 'Breakout Player Projections 2024',
        'excerpt': 'Identifying the players poised for a significant leap...',
        'date': '2024-04-22',
        'imageUrl': 'data/images/ff/shiva.png',
        'route': '/blog/breakout-players'
      },
      // Add more fantasy-related blog posts
  ];
 // --- End Placeholder Data ---

 @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);
    final currentRouteName = ModalRoute.of(context)?.settings.name;

    // Find the Fantasy Hub NavItem
    final NavItem? hubItem = topNavItems.firstWhereOrNull((item) => item.route == '/fantasy');
    
    // Prepare tool links data
    final List<Map<String, dynamic>> hubTools = (hubItem?.subItems ?? []).map((navItem) {
      String desc = 'Access the ${navItem.title} tool.';
      if (navItem.isPlaceholder) {
        desc = 'Coming soon!';
      }
      return {
        'icon': navItem.icon ?? Icons.sports_football,
        'title': navItem.title,
        'desc': desc,
        'route': navItem.route,
        'isPlaceholder': navItem.isPlaceholder,
      };
    }).toList();
    // Sort tools
    hubTools.sort((a, b) {
      bool aIsPlaceholder = a['isPlaceholder'] ?? false;
      bool bIsPlaceholder = b['isPlaceholder'] ?? false;
      if (aIsPlaceholder != bIsPlaceholder) {
        return aIsPlaceholder ? 1 : -1;
      }
      return a['title'].compareTo(b['title']);
    });

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
                // Hero Section
                AnimationConfiguration.staggeredList(
                  position: 0,
                  duration: const Duration(milliseconds: 800),
                  child: SlideAnimation(
                    verticalOffset: 50.0,
                    child: FadeInAnimation(
                      child: Container(
                        height: 200,
                        color: ThemeConfig.darkNavy,
                        child: Center(
                          child: Text(
                            'Fantasy Hub - Hero Section Placeholder',
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                // Original slideshow and tools section
                AnimationConfiguration.staggeredList(
                  position: 1,
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
                              StackedToolLinks(tools: hubTools),
                            ],
                          ),
                          desktop: (context) => Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(flex: 2, child: HomeSlideshow(slides: _slides)),
                              const SizedBox(width: 32),
                              Expanded(flex: 1, child: StackedToolLinks(tools: hubTools)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                AnimationConfiguration.staggeredList(
                  position: 2,
                  duration: const Duration(milliseconds: 600),
                  child: SlideAnimation(
                    verticalOffset: 30.0,
                    child: FadeInAnimation(
                      child: BlogSection(blogPosts: _blogPosts, title: 'Latest Fantasy Insights'),
                    ),
                  ),
                ),
          ],
        ),
          ),
        ),
      ),
    );
  }


  Widget _buildToolLink(BuildContext context, String title, String description, IconData icon, String routeName) {
    return InkWell(
      onTap: () {
        Navigator.pushNamed(context, routeName);
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(20),
        // ... existing code ...
      ),
    );
  }
} 