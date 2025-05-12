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

class GmHubScreen extends StatelessWidget {
  GmHubScreen({super.key});

  // --- Hub Specific Data ---
  // Slideshow data for GM Hub
  final List<Map<String, String>> _slides = [
     {
      'title': 'Run a Mock Draft',
      'desc': 'Simulate the NFL draft with your settings.',
      'image': 'assets/images/blog/draft_analysis_blog.jpg',
      'route': '/draft',
    },
    {
      'title': 'Analyze Team Needs',
      'desc': 'Identify key areas for improvement this offseason.',
      'image': 'assets/images/placeholder/team_needs.png', // Placeholder
      'route': '/gm-hub/needs',
    },
    // Add more GM Hub specific slides if needed
  ];

  // Blog posts (keep as is for now)
  final List<Map<String, String>> _blogPosts = [
     {
        'title': 'NFL Draft Surprises & Sleepers',
        'excerpt': 'Unpacking the most unexpected picks and hidden gems...',
        'date': '2024-04-28',
        'imageUrl': 'assets/images/blog/draft_analysis_blog.jpg',
        'route': '/blog/draft-surprises'
      },
      // Add more GM Hub/draft related blog posts
  ];
 // --- End Hub Specific Data ---

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);
    final currentRouteName = ModalRoute.of(context)?.settings.name;

    // Find the GM Hub NavItem using firstWhereOrNull
    final NavItem? gmHubItem = topNavItems.firstWhereOrNull((item) => item.route == '/gm-hub');
    
    // Prepare tool links data from NavItem subItems (handle potential null gmHubItem)
    final List<Map<String, dynamic>> hubTools = (gmHubItem?.subItems ?? []).map((navItem) {
      String desc = 'Access the ${navItem.title} tool.'; 
      if (navItem.isPlaceholder) {
        desc = 'Coming soon!';
      }
      return {
        'icon': navItem.icon ?? Icons.build, // Provide a default icon
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
        return aIsPlaceholder ? 1 : -1; // Non-placeholders first
      }
      return a['title'].compareTo(b['title']); // Then alphabetical
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
              // Re-introduce ResponsiveLayoutBuilder for Slideshow + Tools
              child: ResponsiveLayoutBuilder(
                mobile: (context) => Column(
                  children: [
                    HomeSlideshow(slides: _slides, isMobile: true), // Use hub slides
                    const SizedBox(height: 24),
                    StackedToolLinks(tools: hubTools), // Use hub tools
                  ],
                ),
                desktop: (context) => Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 2, child: HomeSlideshow(slides: _slides)), // Use hub slides
                    const SizedBox(width: 32),
                    Expanded(flex: 1, child: StackedToolLinks(tools: hubTools)), // Use hub tools
                  ],
                ),
              ),
            ),
            BlogSection(blogPosts: _blogPosts, title: 'Latest GM Hub Buzz'),
          ],
        ),
      ),
    );
  }
} 