import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:mds_home/models/bust_evaluation.dart';
import 'package:mds_home/services/bust_evaluation_service.dart';
import 'package:mds_home/utils/team_logo_utils.dart';
import 'package:mds_home/utils/theme_config.dart';
import '../../utils/seo_helper.dart';
import '../../widgets/common/custom_app_bar.dart';
import '../../widgets/common/app_drawer.dart';
import '../../widgets/common/top_nav_bar.dart';
import '../../widgets/common/responsive_layout_builder.dart';
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
    
    // Update SEO for Fantasy Hub
    WidgetsBinding.instance.addPostFrameCallback((_) {
      SEOHelper.updateForFantasyHub();
      SEOHelper.updateToolStructuredData(
        toolName: 'Fantasy Football Hub',
        description: 'Complete fantasy football toolkit with VORP big board, custom rankings, player comparison tools, and advanced analytics',
        url: 'https://sticktothemodel.com/fantasy',
      );
    });
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
            SliverToBoxAdapter(
              child: AnimationConfiguration.staggeredList(
                position: 0,
                duration: const Duration(milliseconds: 800),
                child: SlideAnimation(
                  verticalOffset: 50.0,
                  child: FadeInAnimation(
                    child: _buildHeroSection(),
                  ),
                ),
              ),
            ),
            _Header(),
            _ToolGrid(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroSection() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            ThemeConfig.darkNavy,
            ThemeConfig.darkNavy.withOpacity(0.9),
            const Color(0xFF2A2A3E),
          ],
        ),
      ),
      child: ResponsiveLayoutBuilder(
        mobile: (context) => _buildMobileHero(context),
        desktop: (context) => _buildDesktopHero(context),
      ),
    );
  }

  Widget _buildMobileHero(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 48),
      child: Column(
        children: [
          Column(
            children: [
              _buildHeroContent(context, theme, isMobile: true),
              const SizedBox(height: 32),
              _buildFlowDiagram(context, theme, isMobile: true),
            ],
          ),
          const SizedBox(height: 24),
          _buildTrustSignal(context, theme),
        ],
      ),
    );
  }

  Widget _buildDesktopHero(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 64),
      child: Column(
        children: [
          _buildHeroContent(context, theme, isMobile: false),
          const SizedBox(height: 48),
          Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 800),
              child: _buildFlowDiagram(context, theme, isMobile: false),
            ),
          ),
          const SizedBox(height: 32),
          _buildTrustSignal(context, theme),
        ],
      ),
    );
  }

  Widget _buildHeroContent(BuildContext context, ThemeData theme, {required bool isMobile}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          'Build Smarter Fantasy Lineups with Data-Driven Tools',
          style: theme.textTheme.displayLarge?.copyWith(
            color: Colors.white,
            fontSize: isMobile ? 28 : 36,
            fontWeight: FontWeight.bold,
            height: 1.2,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Text(
          'Master your fantasy season with our 4-step data-driven approach: analyze expert rankings, customize player projections, build your personalized big board, and practice with realistic mock drafts.',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: Colors.white.withOpacity(0.9),
            fontSize: isMobile ? 16 : 18,
            height: 1.5,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        AnimationConfiguration.synchronized(
          duration: const Duration(milliseconds: 600),
          child: SlideAnimation(
            verticalOffset: 20.0,
            child: FadeInAnimation(
              child: Material(
                elevation: 8,
                borderRadius: BorderRadius.circular(32),
                shadowColor: ThemeConfig.gold.withOpacity(0.4),
                child: ElevatedButton(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    Navigator.pushNamed(context, '/consensus');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ThemeConfig.gold,
                    foregroundColor: ThemeConfig.darkNavy,
                    padding: EdgeInsets.symmetric(
                      horizontal: isMobile ? 24 : 32,
                      vertical: isMobile ? 16 : 20,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(32),
                    ),
                    textStyle: TextStyle(
                      fontSize: isMobile ? 16 : 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Start Building Your 2025 Strategy'),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.arrow_forward_rounded,
                        size: isMobile ? 20 : 24,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFlowDiagram(BuildContext context, ThemeData theme, {required bool isMobile}) {
    final steps = [
      {'icon': Icons.leaderboard, 'title': 'Rankings', 'desc': 'Analyze expert consensus'},
      {'icon': Icons.trending_up, 'title': 'Projections', 'desc': 'Customize player stats'},
      {'icon': Icons.dashboard, 'title': 'Big Board', 'desc': 'Build your board'},
      {'icon': Icons.sports, 'title': 'Mock Draft', 'desc': 'Practice & perfect'},
      {'icon': Icons.analytics, 'title': 'Tools', 'desc': 'Compare & analyze'},
    ];

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Text(
            'Your Path to Fantasy Success',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: ThemeConfig.gold,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          if (isMobile)
            _buildMobileFlowSteps(steps, theme)
          else
            _buildDesktopFlowSteps(steps, theme),
        ],
      ),
    );
  }

  Widget _buildMobileFlowSteps(List<Map<String, dynamic>> steps, ThemeData theme) {
    return Column(
      children: steps.asMap().entries.map((entry) {
        final index = entry.key;
        final step = entry.value;
        final isLast = index == steps.length - 1;
        
        return Column(
          children: [
            _buildFlowStep(step, theme, index + 1),
            if (!isLast) ...[
              const SizedBox(height: 8),
              Icon(
                Icons.keyboard_arrow_down,
                color: ThemeConfig.gold,
                size: 20,
              ),
              const SizedBox(height: 8),
            ],
          ],
        );
      }).toList(),
    );
  }

  Widget _buildDesktopFlowSteps(List<Map<String, dynamic>> steps, ThemeData theme) {
    return Row(
      children: steps.asMap().entries.map((entry) {
        final index = entry.key;
        final step = entry.value;
        final isLast = index == steps.length - 1;
        
        return Expanded(
          child: Row(
            children: [
              Expanded(child: _buildFlowStep(step, theme, index + 1)),
              if (!isLast) ...[
                const SizedBox(width: 8),
                Icon(
                  Icons.arrow_forward,
                  color: ThemeConfig.gold,
                  size: 20,
                ),
                const SizedBox(width: 8),
              ],
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildFlowStep(Map<String, dynamic> step, ThemeData theme, int stepNumber) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: ThemeConfig.gold.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              step['icon'] as IconData,
              color: ThemeConfig.gold,
              size: 24,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            step['title'] as String,
            style: theme.textTheme.titleMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            step['desc'] as String,
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.white.withOpacity(0.8),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTrustSignal(BuildContext context, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.people_outline,
            color: ThemeConfig.gold,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            'Join the 10,000+ fantasy managers, using data tools',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.white.withOpacity(0.9),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
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
  static final List<Map<String, dynamic>> _preseasonTools = [
    {
      'icon': Icons.leaderboard,
      'title': 'Big Board',
      'subtitle': 'Fantasy player rankings & tiers',
      'route': '/fantasy/big-board',
    },
    {
      'icon': Icons.star_border,
      'title': 'Draft Big Board',
      'subtitle': '2026 NFL Draft prospect rankings',
      'route': '/fantasy/draft-big-board',
    },
    {
      'icon': Icons.tune,
      'title': 'Custom Rankings',
      'subtitle': 'Build your own player rankings',
      'route': '/fantasy/custom-rankings',
    },
    {
      'icon': Icons.analytics_outlined,
      'title': 'Stat Predictor',
      'subtitle': 'Predict & customize next year stats',
      'route': '/projections/stat-predictor',
    },
    {
      'icon': Icons.sports_football,
      'title': 'Mock Draft',
      'subtitle': 'Fantasy draft simulator',
      'route': '/mock-draft-sim',
    },
  ];

  static final List<Map<String, dynamic>> _inSeasonTools = [
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
  ];

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      sliver: SliverToBoxAdapter(
        child: ResponsiveLayoutBuilder(
          mobile: (context) => _buildMobileLayout(context),
          desktop: (context) => _buildDesktopLayout(context),
        ),
      ),
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSection(context, 'Preseason Tools', _preseasonTools, crossAxisCount: 2),
        const SizedBox(height: 32),
        _buildSection(context, 'In-Season Tools', _inSeasonTools, crossAxisCount: 2),
      ],
    );
  }

  Widget _buildDesktopLayout(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSection(context, 'Preseason Tools', _preseasonTools, crossAxisCount: 4),
        const SizedBox(height: 32),
        _buildSection(context, 'In-Season Tools', _inSeasonTools, crossAxisCount: 4),
      ],
    );
  }

  Widget _buildSection(BuildContext context, String title, List<Map<String, dynamic>> tools, {required int crossAxisCount}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: 16.0,
            crossAxisSpacing: 16.0,
            childAspectRatio: 1.1,
          ),
          itemCount: tools.length,
          itemBuilder: (context, index) {
            final tool = tools[index];
            return AnimationConfiguration.staggeredGrid(
              position: index,
              duration: const Duration(milliseconds: 375),
              columnCount: crossAxisCount,
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
    );
  }
} 