import 'package:flutter/material.dart';
import 'package:mds_home/widgets/common/custom_app_bar.dart';
import 'package:mds_home/widgets/common/responsive_layout_builder.dart';
import '../../widgets/auth/auth_dialog.dart';
import '../../widgets/common/app_drawer.dart';
import '../../widgets/common/top_nav_bar.dart';
import '../../widgets/home/home_slideshow.dart';
import '../../widgets/home/stacked_tool_links.dart';
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

// Find the Fantasy Hub NavItem
final NavItem? _fantasyHubNavItem = topNavItems.firstWhereOrNull((item) => item.route == '/fantasy');

// Define the curated list of tools for Fantasy Hub preview
final List<Map<String, dynamic>> _previewTools = [
  _findAndFormatTool(_fantasyHubNavItem, '/draft/fantasy', desc: 'Practice your fantasy draft strategy.', icon: Icons.sports_football), // Fantasy Draft Simulator
  _findAndFormatTool(_fantasyHubNavItem, '/projections', desc: 'View rest-of-season player projections.', icon: Icons.trending_up), // RoS Projections
  _findAndFormatTool(_fantasyHubNavItem, '/fantasy/rankings', desc: 'Customize player rankings and big boards.', icon: Icons.leaderboard), // Player Rankings*
  _findAndFormatTool(_fantasyHubNavItem, '/fantasy/trade', desc: 'Analyze potential fantasy trades.', icon: Icons.swap_horiz), // Trade Analyzer*
  _findAndFormatTool(_fantasyHubNavItem, '/fantasy/waiver', desc: 'Get waiver wire recommendations.', icon: Icons.pan_tool), // Waiver Wire Assistant*
  _findAndFormatTool(_fantasyHubNavItem, '/fantasy/start-sit', desc: 'Optimize your weekly lineup decisions.', icon: Icons.check_circle_outline), // Start/Sit Optimizer*
].whereNotNull().toList();

class FantasyHubScreen extends StatelessWidget {
  // Removed const
  FantasyHubScreen({super.key});

  // Placeholder slide data (replace with actual Fantasy Hub relevant slides)
  final List<Map<String, String>> _slides = [
    {
      'title': 'Dominate Your Fantasy League',
      'desc': 'Draft better, trade smarter, and set winning lineups.',
      'image': 'assets/images/placeholder/fantasy_hub_slide_1.png', // Placeholder
      'route': '/fantasy/rankings',
    },
    {
      'title': 'Ace Your Fantasy Draft',
      'desc': 'Prepare with mock drafts, rankings, and strategy tools.',
      'image': 'assets/images/placeholder/fantasy_hub_slide_2.png', // Placeholder
      'route': '/draft/fantasy',
    },
     {
      'title': 'In-Season Management Tools',
      'desc': 'Optimize trades, waivers, and start/sit decisions weekly.',
      'image': 'assets/images/placeholder/fantasy_hub_slide_3.png', // Placeholder
      'route': '/fantasy/trade',
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
                    // Use the curated preview tools list
                    StackedToolLinks(tools: _previewTools),
                  ],
                ),
                desktop: (context) => Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 2, child: HomeSlideshow(slides: _slides)),
                    const SizedBox(width: 32),
                    // Use the curated preview tools list
                    Expanded(flex: 1, child: StackedToolLinks(tools: _previewTools)),
                  ],
                ),
              ),
            ),
            _buildFooterSignup(context, isDarkMode), // Use the footer
          ],
        ),
      ),
    );
  }

  // Footer Signup Widget (Adjust text for Fantasy Hub)
  Widget _buildFooterSignup(BuildContext context, bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      color: isDarkMode ? Theme.of(context).colorScheme.surface.withOpacity(0.1) : Colors.blue.shade50,
      child: Column(
        children: [
          Text(
            'Ready for fantasy glory?',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Theme.of(context).colorScheme.onSurface),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 15),
          Text(
            'Sign up for full access to Fantasy Hub tools and crush your league.',
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
            child: const Text('Unlock Fantasy Hub'),
          ),
        ],
      ),
    );
  }
} 