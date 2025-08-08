import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../../utils/seo_helper.dart';
import '../../widgets/common/custom_app_bar.dart';
import '../../widgets/common/app_drawer.dart';
import '../../widgets/common/top_nav_bar.dart';
import '../../widgets/common/responsive_layout_builder.dart';
import '../../widgets/auth/auth_dialog.dart';
import '../../widgets/design_system/index.dart';
import '../../utils/theme_config.dart';

class RankingsHubScreen extends StatefulWidget {
  const RankingsHubScreen({super.key});

  @override
  State<RankingsHubScreen> createState() => _RankingsHubScreenState();
}

class _RankingsHubScreenState extends State<RankingsHubScreen> {
  @override
  void initState() {
    super.initState();
    
    // Update SEO for Rankings Hub
    WidgetsBinding.instance.addPostFrameCallback((_) {
      SEOHelper.updateForRankings();
      SEOHelper.updateToolStructuredData(
        toolName: 'NFL Player Rankings Hub',
        description: 'Comprehensive data-driven NFL player rankings by position with customizable statistical weighting and advanced analytics',
        url: 'https://sticktothemodel.com/rankings',
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
          _buildHeroContent(context, theme, isMobile: true),
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
          'Data-Driven NFL Player Rankings',
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
          'Comprehensive statistical rankings by position. Built on advanced analytics, not bias.',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: Colors.white.withOpacity(0.9),
            fontSize: isMobile ? 16 : 18,
            height: 1.5,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Text(
          'See rankings across the years, and customize based on your own attribute weights',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: Colors.white.withOpacity(0.7),
            fontSize: isMobile ? 14 : 16,
            height: 1.4,
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
                    Navigator.pushNamed(context, '/rankings/qb');
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
                      const Text('Explore QB Rankings'),
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
            Icons.analytics_outlined,
            color: ThemeConfig.gold,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            'Updated weekly with latest statistical data',
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
              'Position Rankings',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Statistical rankings with customizable attribute weighting.',
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
  static final List<Map<String, dynamic>> _skillPositions = [
    {
      'icon': Icons.sports_football,
      'title': 'QB Rankings',
      'subtitle': 'Quarterback rankings and analysis',
      'route': '/rankings/qb',
    },
    {
      'icon': Icons.directions_run,
      'title': 'RB Rankings', 
      'subtitle': 'Running back rankings and metrics',
      'route': '/rankings/rb',
    },
    {
      'icon': Icons.sports_handball,
      'title': 'WR Rankings',
      'subtitle': 'Wide receiver rankings and projections',
      'route': '/rankings/wr',
    },
    {
      'icon': Icons.sports,
      'title': 'TE Rankings',
      'subtitle': 'Tight end rankings and analysis',
      'route': '/rankings/te',
    },
  ];

  static final List<Map<String, dynamic>> _defensivePositions = [
    {
      'icon': Icons.shield,
      'title': 'EDGE Rankings',
      'subtitle': 'Edge rusher rankings and pass rush metrics',
      'route': '/rankings/edge',
    },
    {
      'icon': Icons.security,
      'title': 'IDL Rankings',
      'subtitle': 'Interior defensive line rankings',
      'route': '/rankings/idl',
    },
  ];

  static final List<Map<String, dynamic>> _teamUnits = [
    {
      'icon': Icons.airline_seat_recline_extra,
      'title': 'Pass Offense',
      'subtitle': 'Team passing attack rankings',
      'route': '/rankings/pass-offense',
    },
    {
      'icon': Icons.fitness_center,
      'title': 'Run Offense',
      'subtitle': 'Team rushing attack rankings',
      'route': '/rankings/run-offense',
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
        _buildSection(context, 'Skill Positions', _skillPositions, crossAxisCount: 2),
        const SizedBox(height: 32),
        _buildSection(context, 'Defensive Positions', _defensivePositions, crossAxisCount: 2),
        const SizedBox(height: 32),
        _buildSection(context, 'Team Units', _teamUnits, crossAxisCount: 2),
      ],
    );
  }

  Widget _buildDesktopLayout(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSection(context, 'Skill Positions', _skillPositions, crossAxisCount: 4),
        const SizedBox(height: 32),
        _buildSection(context, 'Defensive Positions', _defensivePositions, crossAxisCount: 4),
        const SizedBox(height: 32),
        _buildSection(context, 'Team Units', _teamUnits, crossAxisCount: 4),
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