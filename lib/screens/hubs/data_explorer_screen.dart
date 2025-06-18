import 'package:flutter/material.dart';
import 'package:mds_home/widgets/common/custom_app_bar.dart';
import 'package:mds_home/widgets/common/responsive_layout_builder.dart'; // Keep for potential future use
import '../../widgets/auth/auth_dialog.dart';
import '../../widgets/common/app_drawer.dart';
import '../../widgets/common/top_nav_bar.dart';
import '../../widgets/home/stacked_tool_links.dart'; // Import StackedToolLinks
import '../../widgets/home/blog_section.dart'; // Keep BlogSection
import 'package:collection/collection.dart'; // For firstWhereOrNull

// Helper function (can be extracted later)
Map<String, dynamic>? _findAndFormatTool(NavItem? hub, String route, {String? desc, IconData? icon}) {
  if (hub?.subItems == null) return null;
  final item = hub!.subItems!.firstWhereOrNull((i) => i.route == route);
  if (item == null) return null;
  return {
    'icon': icon ?? item.icon ?? Icons.build_circle_outlined,
    'title': item.title,
    'desc': desc ?? 'Access the ${item.title} tool.',
    'route': item.route,
    'isPlaceholder': item.isPlaceholder,
  };
}

// Find the Data Explorer NavItem
final NavItem? _dataExplorerNavItem = topNavItems.firstWhereOrNull((item) => item.route == '/data');

// Define the curated list of tools for Data Explorer preview
final List<Map<String, dynamic>> _previewTools = [
  // _findAndFormatTool(_dataExplorerNavItem, '/data/historical', desc: 'Query historical NFL game results.', icon: Icons.history), // Historical Game Results
  // _findAndFormatTool(_dataExplorerNavItem, '/wr-model', desc: 'Explore WR season-level model stats.', icon: Icons.analytics), // WR Season Stats
  _findAndFormatTool(_dataExplorerNavItem, '/data/player-stats', desc: 'Explore detailed player career statistics.', icon: Icons.person_pin), // Player Career Stats*
  _findAndFormatTool(_dataExplorerNavItem, '/data/team-trends', desc: 'Analyze team performance trends over time.', icon: Icons.timeline), // Team Performance Trends*
  _findAndFormatTool(_dataExplorerNavItem, '/data/metrics', desc: 'Access our database of advanced metrics.', icon: Icons.storage), // Advanced Metrics DB*
  _findAndFormatTool(_dataExplorerNavItem, '/data/query', desc: 'Build and run custom data queries.', icon: Icons.query_stats), // Custom Query Builder*
  _findAndFormatTool(_dataExplorerNavItem, '/data/charts', desc: 'Create interactive data visualizations.', icon: Icons.bar_chart), // Interactive Charts*
].whereNotNull().toList();

class DataExplorerScreen extends StatelessWidget {
  // Removed const
  DataExplorerScreen({super.key});

  // Placeholder blog data (replace with actual relevant blog posts)
   final List<Map<String, String>> _blogPosts = [
    {
      'title': 'Unlocking Insights with Historical Data',
      'excerpt': 'How to leverage past game results for future predictions...',
      'date': '2024-05-10',
      'imageUrl': 'assets/images/placeholder/data_blog_1.png', // Placeholder
      'route': '/blog/data-insights'
    },
    {
      'title': 'The Power of Advanced NFL Metrics',
      'excerpt': 'Exploring DVOA, EPA, and other key statistics...',
      'date': '2024-05-08',
      'imageUrl': 'assets/images/placeholder/data_blog_2.png', // Placeholder
      'route': '/blog/advanced-metrics'
    },
  ];

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
        child: Padding(
          // Add padding around the content
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Section Title for Tools
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Text(
                  'Explore Our Data Tools',
                  style: Theme.of(context).textTheme.headlineMedium,
                  textAlign: TextAlign.center,
                ),
              ),
              // Use StackedToolLinks for the curated tool list
              StackedToolLinks(tools: _previewTools),
              const SizedBox(height: 32), // Add spacing
              // Keep the Blog Section
              BlogSection(blogPosts: _blogPosts),
              const SizedBox(height: 32), // Add spacing before footer
              _buildFooterSignup(context, isDarkMode), // Use the footer
            ],
          ),
        ),
      ),
    );
  }

  // Footer Signup Widget (Adjust text for Data Explorer)
  Widget _buildFooterSignup(BuildContext context, bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      color: isDarkMode ? Theme.of(context).colorScheme.surface.withOpacity(0.1) : Colors.blue.shade50,
      child: Column(
        children: [
          Text(
            'Dive deeper into NFL data?',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Theme.of(context).colorScheme.onSurface),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 15),
          Text(
            'Sign up for full access to the Data Explorer and unlock powerful insights.',
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
            child: const Text('Unlock Data Explorer'),
          ),
        ],
      ),
    );
  }
} 