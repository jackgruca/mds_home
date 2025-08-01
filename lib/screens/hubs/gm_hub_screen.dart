import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mds_home/widgets/common/custom_app_bar.dart';
import 'package:mds_home/widgets/common/responsive_layout_builder.dart';
import '../../widgets/auth/auth_dialog.dart';
import '../../widgets/common/app_drawer.dart';
import '../../widgets/common/top_nav_bar.dart';
import '../../widgets/home/home_slideshow.dart';
import '../../widgets/home/stacked_tool_links.dart';
import 'package:collection/collection.dart'; // For firstWhereOrNull
import '../../utils/theme_config.dart';
import '../../utils/seo_helper.dart';


// Helper function to find a specific sub-item (tool) within a NavItem hub
// and format it for the StackedToolLinks widget.
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

// Find the GM Hub NavItem from the main list
final NavItem? _gmHubNavItem = topNavItems.firstWhereOrNull((item) => item.route == '/gm-hub');

// Only show these four tools as previews on the GM Hub landing page
final List<String> _gmHubPreviewRoutes = [
  '/draft',
  '/draft/big-board',
  '/gm-hub/bust-evaluation',
  '/team-builder/cap',
  '/team-builder/fa-tracker',
];

final List<Map<String, dynamic>> _previewTools = _gmHubPreviewRoutes.map((route) {
  IconData icon = Icons.build_circle_outlined;
  String desc = 'Access this tool.';
  switch (route) {
    case '/draft':
      icon = Icons.format_list_numbered;
      desc = 'Simulate the NFL draft with real-time analytics.';
      break;
    case '/draft/big-board':
      icon = Icons.leaderboard;
      desc = 'View and customize player rankings.';
      break;
    case '/gm-hub/bust-evaluation':
      icon = Icons.psychology;
      desc = 'Evaluate draft picks against expectations.';
      break;
    case '/team-builder/cap':
      icon = Icons.account_balance_wallet;
      desc = 'Explore team cap space scenarios.';
      break;
    case '/team-builder/fa-tracker':
      icon = Icons.person_search;
      desc = 'Track free agent signings and availability.';
      break;
  }
  return _findAndFormatTool(_gmHubNavItem, route, icon: icon, desc: desc);
}).whereNotNull().toList();

class GmHubScreen extends StatelessWidget {
  GmHubScreen({super.key});

  // Placeholder slide data (replace with actual GM Hub relevant slides)
  final List<Map<String, String>> _slides = [
    {
      'title': 'Build Your Championship Roster',
      'desc': 'Utilize our suite of tools to construct the ultimate team.',
      'image': 'assets/images/GM/PIT Draft.png', // Updated to PIT Draft image
      'route': '/team-builder/roster', // Example route
    },
    {
      'title': 'Master the NFL Draft',
      'desc': 'Leverage insights from mock drafts and big boards.',
      'image': 'assets/images/GM/big board.png', // Use GM big board image
      'route': '/draft',
    },
     {
      'title': 'Navigate Free Agency Like a Pro',
      'desc': 'Track player movement and manage your cap space effectively.',
      'image': 'assets/images/placeholder/gm_hub_slide_3.png', // Placeholder path
      'route': '/team-builder/fa-tracker',
    },
  ];

  @override
  Widget build(BuildContext context) {
    // Update SEO meta tags for GM Hub page
    WidgetsBinding.instance.addPostFrameCallback((_) {
      SEOHelper.updateForGMHub();
    });
    
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
            // Blog section could be added back here if desired for this hub
            _buildFooterSignup(context, isDarkMode), // Use the restored footer
          ],
        ),
      ),
    );
  }

  // Restored Footer Signup Widget
  Widget _buildFooterSignup(BuildContext context, bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      color: isDarkMode ? Theme.of(context).colorScheme.surface.withOpacity(0.1) : Colors.blue.shade50,
      child: Column(
        children: [
          Text(
            'Ready to build your dynasty?',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Theme.of(context).colorScheme.onSurface),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 15),
          Text(
            'Sign up for full access to GM Hub tools and gain a competitive edge.',
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
            child: const Text('Unlock GM Hub'),
          ),
        ],
      ),
    );
  }
}

class _ToolCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final String? route;
  final bool isPlaceholder;

  const _ToolCard({
    required this.title,
    required this.description,
    required this.icon,
    this.route,
    this.isPlaceholder = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool canNavigate = route != null && !isPlaceholder;
    final Color contentColor = isPlaceholder
        ? theme.colorScheme.onSurface.withOpacity(0.4)
        : theme.colorScheme.onSurface;

    return Card(
      elevation: isPlaceholder ? 0 : 4,
      shadowColor: theme.colorScheme.primary.withOpacity(0.2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isPlaceholder
            ? BorderSide(color: theme.dividerColor, width: 1.5)
            : BorderSide.none,
      ),
      color: isPlaceholder
          ? theme.colorScheme.surface.withOpacity(0.5)
          : theme.cardColor,
      child: InkWell(
        onTap: canNavigate ? () => Navigator.pushNamed(context, route!) : null,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, size: 36, color: isPlaceholder ? contentColor : theme.colorScheme.primary),
              const Spacer(),
              Text(
                title,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: contentColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: theme.textTheme.bodySmall?.copyWith(color: contentColor.withOpacity(0.8)),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
} 