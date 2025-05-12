import 'package:flutter/material.dart';
import 'package:mds_home/widgets/common/app_drawer.dart';
import 'package:mds_home/widgets/common/custom_app_bar.dart';
import 'package:mds_home/widgets/common/responsive_layout_builder.dart';
import 'package:mds_home/widgets/common/top_nav_bar.dart';
import 'package:mds_home/widgets/auth/auth_dialog.dart';
import 'package:mds_home/widgets/home/stacked_tool_links.dart';
import 'package:mds_home/widgets/home/blog_section.dart';

class DataExplorerScreen extends StatelessWidget {
  // Constructor without const
  DataExplorerScreen({super.key});

  // --- Placeholder Data ---
   final List<Map<String, String>> _slides = [
    {
      'title': 'Explore Historical Data',
      'desc': 'Query decades of NFL game and betting results.',
      'image': 'assets/images/placeholder/historical_data.png', // Placeholder
      'route': '/data/historical',
    },
    {
      'title': 'Visualize Trends',
      'desc': 'Create custom charts and spot patterns.',
      'image': 'assets/images/placeholder/data_viz.png', // Placeholder
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
        'imageUrl': 'assets/images/placeholder/data_blog.png', // Placeholder
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
              child: StackedToolLinks(tools: hubTools), // Use generated tools
            ),
            BlogSection(blogPosts: _blogPosts, title: 'Data Insights & Techniques'),
          ],
        ),
      ),
    );
  }
} 