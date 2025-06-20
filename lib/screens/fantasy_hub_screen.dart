import 'package:flutter/material.dart';
import 'package:mds_home/widgets/common/app_drawer.dart';
import 'package:mds_home/widgets/common/custom_app_bar.dart';
import 'package:mds_home/widgets/common/responsive_layout_builder.dart';
import 'package:mds_home/widgets/common/top_nav_bar.dart';
import 'package:mds_home/widgets/auth/auth_dialog.dart';
import 'package:mds_home/widgets/home/home_slideshow.dart';
import 'package:mds_home/widgets/home/stacked_tool_links.dart';
import 'package:mds_home/widgets/home/blog_section.dart';
import 'package:collection/collection.dart';

class FantasyHubScreen extends StatelessWidget {
  // Constructor without const
  FantasyHubScreen({super.key});

  // --- Placeholder Data ---
  final List<Map<String, String>> _slides = [
    {
      'title': 'Compare Players Side-by-Side',
      'desc': 'Analyze and compare fantasy players with detailed stats.',
      'image': 'assets/images/blog/player_projections_blog.jpg',
      'route': '/fantasy/player-comparison',
    },
    {
      'title': 'Create Your Fantasy Big Board',
      'desc': 'Compare rankings across major platforms and create your own.',
      'image': 'assets/images/blog/player_projections_blog.jpg',
      'route': '/fantasy/big-board',
    },
    {
      'title': 'Fantasy Mock Draft Now!',
      'desc': 'Practice your strategy against realistic opponents.',
      'image': 'assets/images/blog/player_projections_blog.jpg', 
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
        'imageUrl': 'assets/images/blog/player_projections_blog.jpg',
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
            BlogSection(blogPosts: _blogPosts, title: 'Latest Fantasy Insights'),
          ],
        ),
      ),
    );
  }
} 