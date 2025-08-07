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

class DataCenterScreen extends StatefulWidget {
  const DataCenterScreen({super.key});

  @override
  State<DataCenterScreen> createState() => _DataCenterScreenState();
}

class _DataCenterScreenState extends State<DataCenterScreen> {
  @override
  void initState() {
    super.initState();
    
    // Update SEO for Data Center
    WidgetsBinding.instance.addPostFrameCallback((_) {
      SEOHelper.updateForDataExplorer();
      SEOHelper.updateToolStructuredData(
        toolName: 'NFL Data Center',
        description: 'Comprehensive NFL data tools including historical game data, player stats, and advanced analytics',
        url: 'https://sticktothemodel.com/data',
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
        ],
      ),
    );
  }

  Widget _buildHeroContent(BuildContext context, ThemeData theme, {required bool isMobile}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          'NFL Data Center',
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
          'Dive deep into NFL data with comprehensive player statistics, historical game data, and advanced analytics tools.',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: Colors.white.withOpacity(0.9),
            fontSize: isMobile ? 16 : 18,
            height: 1.5,
          ),
          textAlign: TextAlign.center,
        ),
      ],
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
              'Data Tools',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Access comprehensive NFL data and analytics.',
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
  static final List<Map<String, dynamic>> _dataTools = [
    {
      'icon': Icons.history,
      'title': 'Historical Game Data',
      'subtitle': 'Browse historical NFL game data and trends',
      'route': '/historical-game-data',
    },
    {
      'icon': Icons.person,
      'title': 'Player Season Stats',
      'subtitle': 'Detailed player statistics by season',
      'route': '/player-season-stats',
    },
    {
      'icon': Icons.groups,
      'title': 'Player Data',
      'subtitle': 'Comprehensive player information and stats',
      'route': '/players',
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
    return _buildSection(context, 'Data Tools', _dataTools, crossAxisCount: 1);
  }

  Widget _buildDesktopLayout(BuildContext context) {
    return _buildSection(context, 'Data Tools', _dataTools, crossAxisCount: 3);
  }

  Widget _buildSection(BuildContext context, String title, List<Map<String, dynamic>> tools, {required int crossAxisCount}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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