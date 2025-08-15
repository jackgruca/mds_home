import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Added for haptic feedback
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart'; // Added for animations
import 'package:mds_home/widgets/common/app_drawer.dart';
import 'package:mds_home/widgets/common/custom_app_bar.dart';
import 'package:mds_home/widgets/common/responsive_layout_builder.dart';
import 'package:mds_home/widgets/common/top_nav_bar.dart';
import 'package:mds_home/widgets/auth/auth_dialog.dart';
import 'package:mds_home/widgets/home/stacked_tool_links.dart';
import 'package:mds_home/widgets/home/blog_section.dart';
import '../utils/theme_config.dart'; // Added for theme colors

class DataExplorerScreen extends StatelessWidget {
  // Constructor without const
  DataExplorerScreen({super.key});

  // --- Placeholder Data ---
   final List<Map<String, String>> _slides = [
    {
      'title': 'Explore Historical Data',
      'desc': 'Query decades of NFL game and betting results.',
      'image': 'data/images/data/moneyBall.jpeg', // Use actual image
      'route': '/data/historical',
    },
    {
      'title': 'Visualize Trends',
      'desc': 'Create custom charts and spot patterns.',
      'image': 'data/images/data/moneyBall.jpeg', // Use actual image
      'route': '/data/charts',
    },
    // Add more data-explorer specific slides
  ];

 final List<Map<String, dynamic>> _tools = [
     {
      'icon': Icons.table_chart, 
      'title': 'Historical Game Results', 
      'desc': 'Access detailed box scores and stats.',
      'route': '/data/historical',
    },
     {
      'icon': Icons.person_pin_circle, 
      'title': 'Player Career Stats', 
      'desc': 'Track player performance over their careers.',
      'route': '/data/player-stats',
    },
     {
      'icon': Icons.timeline, 
      'title': 'Team Performance Trends', 
      'desc': 'Analyze team success over seasons.',
      'route': '/data/team-trends',
    },
     {
      'icon': Icons.query_stats, 
      'title': 'Custom Query Builder', 
      'desc': 'Build and save your own data queries.',
      'route': '/data/query',
    },
    // Add more relevant data tools/links
  ];

 final List<Map<String, String>> _blogPosts = [
     // Add data/analytics related blog posts
     {
        'title': 'Using Data to Find Betting Value',
        'excerpt': 'A look at how historical data can inform...',
        'date': '2024-03-15',
        'imageUrl': 'data/images/data/moneyBall.jpeg', // Use actual image
        'route': '/blog/data-betting-value' // Example route
      },
  ];
 // --- End Placeholder Data ---

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);
    final currentRouteName = ModalRoute.of(context)?.settings.name;

    // Find the Data Explorer NavItem
    final NavItem hubItem = topNavItems.firstWhere((item) => item.route == '/data');
    
    // Prepare tool links data from NavItem subItems
    final List<Map<String, dynamic>> hubTools = (hubItem.subItems ?? []).map((navItem) {
      String desc = 'Access the ${navItem.title} tool.';
      if (navItem.isPlaceholder) {
        desc = 'Coming soon!';
      }
      return {
        'icon': navItem.icon ?? Icons.analytics, // Provide a default icon
        'title': navItem.title,
        'desc': desc,
        'route': navItem.route,
        'isPlaceholder': navItem.isPlaceholder,
      };
    }).toList();
    // Sort tools: implemented first, then placeholders alphabetically
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
            AnimationConfiguration.staggeredList(
              position: 0,
              duration: const Duration(milliseconds: 600),
              child: SlideAnimation(
                verticalOffset: 40.0,
                child: FadeInAnimation(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                    child: StackedToolLinks(tools: hubTools), // Use generated tools
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
                  child: BlogSection(blogPosts: _blogPosts, title: 'Data Insights & Techniques'),
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
} 