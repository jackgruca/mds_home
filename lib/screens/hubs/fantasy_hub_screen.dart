import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:mds_home/models/bust_evaluation.dart';
import 'package:mds_home/services/bust_evaluation_service.dart';
import 'package:mds_home/utils/team_logo_utils.dart';
import '../../widgets/common/custom_app_bar.dart';
import '../../widgets/common/app_drawer.dart';
import '../../widgets/common/top_nav_bar.dart';
import '../../widgets/auth/auth_dialog.dart';
import '../../widgets/design_system/index.dart';
import 'package:collection/collection.dart';

class FantasyHubScreen extends StatefulWidget {
  const FantasyHubScreen({super.key});

  @override
  _FantasyHubScreenState createState() => _FantasyHubScreenState();
}

class _FantasyHubScreenState extends State<FantasyHubScreen> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final currentRouteName = ModalRoute.of(context)?.settings.name;
    final theme = Theme.of(context);

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
      body: AnimationLimiter(
        child: CustomScrollView(
          slivers: [
            _Header(),
            _ToolGrid(),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.all(24.0),
      sliver: SliverToBoxAdapter(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Fantasy Hub',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your command center for dominating your fantasy league.',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ToolGrid extends StatelessWidget {
  static final List<Map<String, dynamic>> _tools = [
    {
      'icon': Icons.tune,
      'title': 'Custom Rankings',
      'subtitle': 'Build your own player rankings',
      'route': '/fantasy/custom-rankings',
    },
    {
      'icon': Icons.analytics,
      'title': 'Player Projections',
      'subtitle': 'Create custom stat projections',
      'route': '/fantasy/player-projections',
    },
    {
      'icon': Icons.leaderboard,
      'title': 'Big Board',
      'subtitle': 'Player rankings & tiers',
      'route': '/fantasy/big-board',
    },
    {
      'icon': Icons.compare,
      'title': 'Player Comparison',
      'subtitle': 'Head-to-head analysis',
      'route': '/fantasy/player-comparison',
    },
    {
      'icon': Icons.trending_up,
      'title': 'Player Trends',
      'subtitle': 'Performance analytics',
      'route': '/fantasy/trends',
    },
    {
      'icon': Icons.sports_football,
      'title': 'Mock Draft',
      'subtitle': 'Fantasy draft simulator',
      'route': '/ff-draft',
    },
    {
      'icon': Icons.assessment,
      'title': 'Draft Setup',
      'subtitle': 'Configure your league',
      'route': '/ff-draft/setup',
    },
    {
      'icon': Icons.analytics,
      'title': 'Player Stats',
      'subtitle': 'Season-by-season data',
      'route': '/player-season-stats',
    },
    {
      'icon': Icons.groups,
      'title': 'NFL Rosters',
      'subtitle': 'Team depth charts',
      'route': '/nfl-rosters',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      sliver: SliverToBoxAdapter(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Fantasy Tools',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 16.0,
                crossAxisSpacing: 16.0,
                childAspectRatio: 1.1,
              ),
              itemCount: _tools.length,
              itemBuilder: (context, index) {
                final tool = _tools[index];
                return AnimationConfiguration.staggeredGrid(
                  position: index,
                  duration: const Duration(milliseconds: 375),
                  columnCount: 2,
                  child: ScaleAnimation(
                    child: FadeInAnimation(
                      child: MdsCard(
                        type: MdsCardType.elevated,
                        onTap: () => Navigator.pushNamed(context, tool['route'] as String),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              tool['icon'] as IconData,
                              size: 32,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              tool['title'] as String,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              tool['subtitle'] as String,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
} 