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
  Future<Map<String, BustEvaluationPlayer?>>? _featuredPlayersFuture;

  @override
  void initState() {
    super.initState();
    _featuredPlayersFuture = _loadFeaturedPlayers();
  }

  Future<Map<String, BustEvaluationPlayer?>> _loadFeaturedPlayers() async {
    try {
      // Ensure data is cached before trying to access it
      await BustEvaluationService.getAllPlayers();
      
      // Get random controversial/interesting players instead of static top performers
      final controversialPlayers = await BustEvaluationService.getRandomControversialPlayers();
      
      // Filter for different positions to show variety
      final randomWr = controversialPlayers.where((p) => p.position == 'WR').take(1).firstOrNull;
      final randomQb = controversialPlayers.where((p) => p.position == 'QB').take(1).firstOrNull;
      final randomRb = controversialPlayers.where((p) => p.position == 'RB').take(1).firstOrNull;
      
      // Fallback to any controversial player if position-specific ones aren't available
      final randomPlayer1 = randomWr ?? controversialPlayers.take(1).firstOrNull;
      final randomPlayer2 = randomQb ?? randomRb ?? controversialPlayers.skip(1).take(1).firstOrNull;
      
      return {'randomPlayer1': randomPlayer1, 'randomPlayer2': randomPlayer2};
    } catch (e) {
      print("Error loading featured players: $e");
      // In case of error, return a map with null values to avoid crashing the UI
      return {'randomPlayer1': null, 'randomPlayer2': null};
    }
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
      body: FutureBuilder<Map<String, BustEvaluationPlayer?>>(
        future: _featuredPlayersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
           if (snapshot.hasError || !snapshot.hasData) {
            return const Center(child: Text('Could not load featured players.'));
          }

          final randomPlayer1 = snapshot.data?['randomPlayer1'];
          final randomPlayer2 = snapshot.data?['randomPlayer2'];

          return AnimationLimiter(
            child: CustomScrollView(
              slivers: [
                _Header(),
                _FeaturedToolCard(),
                _DynamicPlayersSection(topWr: randomPlayer1, biggestBust: randomPlayer2),
                _ToolGrid(),
              ],
            ),
          );
        },
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

class _FeaturedToolCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      sliver: SliverToBoxAdapter(
        child: AnimationConfiguration.staggeredList(
          position: 0,
          duration: const Duration(milliseconds: 375),
          child: SlideAnimation(
            verticalOffset: 50.0,
            child: FadeInAnimation(
              child: MdsCard(
                type: MdsCardType.feature,
                onTap: () => Navigator.of(context).pushNamed('/fantasy/bust-evaluation'),
                gradientColors: [
                  Theme.of(context).colorScheme.primary,
                  Theme.of(context).colorScheme.primary.withOpacity(0.7)
                ],
                child: SizedBox(
                  height: 160,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Icon(Icons.psychology, color: Colors.white, size: 32),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Bust or Brilliant?',
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Evaluate players against their draft-day expectations.',
                            style: TextStyle(color: Colors.white70, fontSize: 16),
                          ),
                        ],
                      ),
                      const Row(
                        children: [
                          Text('Explore the Tool', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          SizedBox(width: 8),
                          Icon(Icons.arrow_forward, color: Colors.white, size: 16),
                        ],
                      )
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DynamicPlayersSection extends StatelessWidget {
  final BustEvaluationPlayer? topWr;
  final BustEvaluationPlayer? biggestBust;

  const _DynamicPlayersSection({
    required this.topWr,
    required this.biggestBust,
  });

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Daily Discoveries',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                if (topWr != null)
                  Expanded(
                    child: _DynamicPlayerCard(
                      player: topWr!,
                      title: 'Random Spotlight',
                      subtitle: 'Fresh insights daily',
                      gradientColors: [Colors.blue.shade600, Colors.purple.shade600],
                    ),
                  ),
                if (topWr != null && biggestBust != null) const SizedBox(width: 16),
                if (biggestBust != null)
                  Expanded(
                    child: _DynamicPlayerCard(
                      player: biggestBust!,
                      title: 'Wild Card Pick',
                      subtitle: 'Controversial choice',
                      gradientColors: [Colors.orange.shade600, Colors.red.shade600],
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DynamicPlayerCard extends StatelessWidget {
  final BustEvaluationPlayer player;
  final String title;
  final String subtitle;
  final List<Color> gradientColors;

  const _DynamicPlayerCard({
    required this.player,
    required this.title,
    required this.subtitle,
    required this.gradientColors,
  });

  @override
  Widget build(BuildContext context) {
    return AnimationConfiguration.staggeredGrid(
        position: 0,
        duration: const Duration(milliseconds: 375),
        columnCount: 2,
        child: ScaleAnimation(
          child: FadeInAnimation(
            child: MdsPlayerCard(
              type: MdsPlayerCardType.featured,
              playerName: player.playerName,
              team: player.team,
              position: player.position,
              teamColor: gradientColors[0],
              primaryStat: 'Performance Score',
              primaryStatValue: player.performanceScore != null 
                ? '${(player.performanceScore! * 100).toStringAsFixed(0)}%'
                : 'N/A',
              secondaryStat: 'Category',
              secondaryStatValue: player.bustCategory,
              showBadge: true,
              badgeText: title,
              badgeColor: gradientColors[0],
              onTap: () {
                Navigator.of(context).pushNamed(
                  '/fantasy/bust-evaluation',
                  arguments: player,
                );
              },
            ),
          ),
        ));
  }
}

class _ToolGrid extends StatelessWidget {
  static final List<Map<String, dynamic>> _tools = [
    {
      'icon': Icons.psychology,
      'title': 'Bust or Brilliant?',
      'subtitle': 'Draft pick evaluations',
      'route': '/fantasy/bust-evaluation',
    },
    {
      'icon': Icons.tune,
      'title': 'Custom Rankings',
      'subtitle': 'Build your own player rankings',
      'route': '/fantasy/custom-rankings',
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