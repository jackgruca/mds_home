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

class BettingHubScreen extends StatelessWidget {
  BettingHubScreen({super.key});

  // Keep placeholder blog posts for now, or fetch dynamically
  final List<Map<String, String>> _slides = [
    {
      'title': "This Week's Sharpest Angles",
      'desc': 'Find the best edges based on current lines and data.',
      'image': 'assets/images/blog/betting_metrics_blog.jpg',
      'route': '/betting/angles', // Example link
    },
     {
      'title': 'Track Line Movements',
      'desc': 'See how odds are shifting across sportsbooks.',
      'image': 'assets/images/placeholder/line_movement.png', // Placeholder image
      'route': '/betting/lines', 
    },
  ];

  final List<Map<String, String>> _blogPosts = [
     {
        'title': 'Advanced Metrics for Betting Success',
        'excerpt': 'Leverage cutting-edge analytics to gain an edge...',
        'date': '2024-04-25',
        'imageUrl': 'assets/images/blog/betting_metrics_blog.jpg',
        'route': '/blog/betting-metrics'
      },
  ];

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);
    final currentRouteName = ModalRoute.of(context)?.settings.name;

    // Find the Betting Hub NavItem
    final NavItem? hubItem = topNavItems.firstWhereOrNull((item) => item.route == '/betting');
    
    // Prepare tool links data
    final List<Map<String, dynamic>> hubTools = (hubItem?.subItems ?? []).map((navItem) {
      String desc = 'Access the ${navItem.title} tool.';
      if (navItem.isPlaceholder) {
        desc = 'Coming soon!';
      }
      return {
        'icon': navItem.icon ?? Icons.paid,
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
            BlogSection(blogPosts: _blogPosts, title: 'Latest Betting Analysis'),
          ],
        ),
      ),
    );
  }
} 