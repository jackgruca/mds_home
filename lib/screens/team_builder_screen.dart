import 'package:flutter/material.dart';
import 'package:mds_home/widgets/common/app_drawer.dart';
import 'package:mds_home/widgets/common/custom_app_bar.dart';
import 'package:mds_home/widgets/common/responsive_layout_builder.dart';
import 'package:mds_home/widgets/common/top_nav_bar.dart';
import 'package:mds_home/widgets/auth/auth_dialog.dart';
import 'package:mds_home/widgets/home/home_slideshow.dart';
import 'package:mds_home/widgets/home/stacked_tool_links.dart';
import 'package:mds_home/widgets/home/blog_section.dart';

class GmHubScreen extends StatelessWidget {
  // Renamed constructor
  GmHubScreen({super.key});

  // --- Placeholder Data (routes might need updating if hub route changed) ---
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
      'route': '/gm-hub/needs', // Updated example route to match potential hub route prefix
    },
    // Add more team-builder specific slides
  ];

  final List<Map<String, dynamic>> _tools = [
    {
      'icon': Icons.drafts, 
      'title': 'Mock Draft Simulator', 
      'desc': 'Run unlimited draft simulations.',
      'route': '/draft',
    },
    {
      'icon': Icons.person_search, 
      'title': 'Prospect Comparisons', 
      'desc': 'Compare draft prospects side-by-side.',
      'route': '/gm-hub/prospects', // Updated example route
    },
    {
      'icon': Icons.receipt_long, 
      'title': 'Free Agent Tracker', 
      'desc': 'Monitor the latest signings and rumors.',
      'route': '/gm-hub/fa-tracker', // Updated example route
    },
     {
      'icon': Icons.build_circle, 
      'title': 'Roster Builder', 
      'desc': 'Experiment with different roster constructions.',
      'route': '/gm-hub/roster', // Updated example route
    },
    // Add more relevant team building tools/links
  ];

 final List<Map<String, String>> _blogPosts = [
     {
        'title': 'NFL Draft Surprises & Sleepers',
        'excerpt': 'Unpacking the most unexpected picks and hidden gems...',
        'date': '2024-04-28',
        'imageUrl': 'assets/images/blog/draft_analysis_blog.jpg',
        'route': '/blog/draft-surprises'
      },
      // Add more team building/draft related blog posts
  ];
 // --- End Placeholder Data ---

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);
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
            BlogSection(blogPosts: _blogPosts, title: 'Latest Offseason Buzz'),
          ],
        ),
      ),
    );
  }
} 