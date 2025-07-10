import 'package:flutter/material.dart';
import 'package:mds_home/widgets/common/custom_app_bar.dart';
import 'package:mds_home/widgets/common/responsive_layout_builder.dart';
import 'package:mds_home/utils/theme_config.dart';
import 'questionnaire_wizard_screen.dart';

class CustomRankingsHomeScreen extends StatelessWidget {
  const CustomRankingsHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        titleWidget: Text('Custom Player Rankings'),
      ),
      body: ResponsiveLayoutBuilder(
        mobile: (context) => _buildMobileLayout(context),
        desktop: (context) => _buildDesktopLayout(context),
      ),
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeroSection(context),
          const SizedBox(height: 24),
          _buildGetStartedCard(context),
          const SizedBox(height: 24),
          _buildFeaturesGrid(context),
          const SizedBox(height: 24),
          _buildHowItWorksSection(context),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeroSection(context),
          const SizedBox(height: 32),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: _buildGetStartedCard(context),
              ),
              const SizedBox(width: 24),
              Expanded(
                flex: 3,
                child: _buildFeaturesGrid(context),
              ),
            ],
          ),
          const SizedBox(height: 32),
          _buildHowItWorksSection(context),
        ],
      ),
    );
  }

  Widget _buildHeroSection(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            ThemeConfig.darkNavy.withValues(alpha: 0.1),
            ThemeConfig.gold.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.tune,
            size: 48,
            color: ThemeConfig.darkNavy,
          ),
          const SizedBox(height: 16),
          Text(
            'Create Your Custom Rankings',
            style: theme.textTheme.displayMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: ThemeConfig.darkNavy,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Build personalized fantasy football rankings based on the stats that matter most to you. Weight attributes like target share, yards per game, and previous season performance to create your perfect player rankings.',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: ThemeConfig.darkGray,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGetStartedCard(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(
              Icons.rocket_launch,
              size: 48,
              color: ThemeConfig.gold,
            ),
            const SizedBox(height: 16),
            Text(
              'Get Started',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Create your first custom ranking system in just a few steps. Choose your position, select attributes, and set weights.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _startQuestionnaire(context),
              icon: const Icon(Icons.play_arrow),
              label: const Text('Start Building'),
              style: ElevatedButton.styleFrom(
                backgroundColor: ThemeConfig.darkNavy,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturesGrid(BuildContext context) {
    final features = [
      {
        'icon': Icons.sports_football,
        'title': 'All Positions',
        'description': 'Create rankings for QB, RB, WR, and TE with position-specific attributes',
      },
      {
        'icon': Icons.speed,
        'title': 'Real-Time Updates',
        'description': 'Adjust weights and see rankings update instantly',
      },
      {
        'icon': Icons.analytics,
        'title': 'Advanced Stats',
        'description': 'Use target share, air yards, snap percentage, and more',
      },
      {
        'icon': Icons.save,
        'title': 'Save & Export',
        'description': 'Save multiple ranking systems and export for sharing',
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.2,
      ),
      itemCount: features.length,
      itemBuilder: (context, index) {
        final feature = features[index];
        return _buildFeatureCard(context, feature);
      },
    );
  }

  Widget _buildFeatureCard(BuildContext context, Map<String, dynamic> feature) {
    final theme = Theme.of(context);
    
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              feature['icon'] as IconData,
              size: 32,
              color: ThemeConfig.brightRed,
            ),
            const SizedBox(height: 12),
            Text(
              feature['title'] as String,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              feature['description'] as String,
              style: theme.textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHowItWorksSection(BuildContext context) {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'How It Works',
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        _buildStep(context, 1, 'Choose Position', 'Select QB, RB, WR, or TE to rank', Icons.sports_football),
        _buildStep(context, 2, 'Select Attributes', 'Pick stats like yards per game, target share, etc.', Icons.checklist),
        _buildStep(context, 3, 'Set Weights', 'Decide how important each stat is to your rankings', Icons.tune),
        _buildStep(context, 4, 'View Rankings', 'See your personalized rankings and make adjustments', Icons.leaderboard),
      ],
    );
  }

  Widget _buildStep(BuildContext context, int step, String title, String description, IconData icon) {
    final theme = Theme.of(context);
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: ThemeConfig.darkNavy,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(
                step.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, size: 20, color: ThemeConfig.brightRed),
                    const SizedBox(width: 8),
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _startQuestionnaire(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const QuestionnaireWizardScreen(),
      ),
    );
  }
}