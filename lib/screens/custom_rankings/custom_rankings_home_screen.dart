import 'package:flutter/material.dart';
import 'package:mds_home/widgets/common/custom_app_bar.dart';
import 'package:mds_home/widgets/common/responsive_layout_builder.dart';
import 'package:mds_home/utils/theme_config.dart';
import 'package:mds_home/widgets/design_system/mds_button.dart';
import 'package:mds_home/widgets/design_system/mds_card.dart';
import 'questionnaire_wizard_screen.dart';
import '../../screens/fantasy/my_rankings_screen.dart';

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
      child: Column(
        children: [
          _buildHeroSection(context),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHowItWorksSection(context),
                const SizedBox(height: 24),
                _buildFeaturesSection(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildHeroSection(context),
          Padding(
            padding: const EdgeInsets.all(32.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: _buildHowItWorksSection(context),
                ),
                const SizedBox(width: 32),
                Expanded(
                  flex: 2,
                  child: _buildFeaturesSection(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroSection(BuildContext context) {
    final theme = Theme.of(context);
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Container(
      padding: EdgeInsets.all(isMobile ? 24 : 48),
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            ThemeConfig.darkNavy.withOpacity(0.9),
            ThemeConfig.darkNavy,
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Create Your Custom Player Rankings',
            style: theme.textTheme.displayMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Build personalized fantasy football rankings based on the stats that matter most to you. Weight attributes like target share, yards per game, and previous season performance to create your perfect player rankings.',
            style: theme.textTheme.titleLarge?.copyWith(
              color: Colors.white.withOpacity(0.9),
            ),
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _startQuestionnaire(context),
                  icon: const Icon(Icons.rocket_launch, size: 18, color: Colors.white),
                  label: const Text(
                    'Start Building Your Rankings',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ThemeConfig.successGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 2,
                    shadowColor: Colors.black.withOpacity(0.2),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _viewSavedRankings(context),
                  icon: const Icon(Icons.folder_outlined, size: 18, color: Colors.white),
                  label: const Text(
                    'Manage Saved Rankings',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ThemeConfig.darkNavy,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 2,
                    shadowColor: Colors.black.withOpacity(0.2),
                  ),
                ),
              ),
            ],
          ),
        ],
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
          style: theme.textTheme.headlineLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: ThemeConfig.darkNavy,
          ),
        ),
        const SizedBox(height: 24),
        _buildStep(
            context,
            1,
            'Choose Position',
            'Select QB, RB, WR, or TE to begin. Each position has a curated list of relevant stats.',
            Icons.sports_football),
        const SizedBox(height: 20),
        _buildStep(
            context,
            2,
            'Select Attributes',
            'Pick the stats you value most, like yards per game, target share, or fantasy points per game.',
            Icons.checklist),
        const SizedBox(height: 20),
        _buildStep(
            context,
            3,
            'Set Weights',
            'Assign a weight to each attribute to control its impact on the final player score.',
            Icons.balance),
        const SizedBox(height: 20),
        _buildStep(
            context,
            4,
            'View & Adjust',
            'Analyze your custom rankings and fine-tune the weights to get them just right.',
            Icons.tune),
      ],
    );
  }

  Widget _buildStep(BuildContext context, int stepNumber, String title,
      String description, IconData icon) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 20,
          backgroundColor: ThemeConfig.gold,
          child: Icon(icon, size: 22, color: Colors.white),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Step $stepNumber: $title',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: theme.textTheme.bodyLarge,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFeaturesSection(BuildContext context) {
    final theme = Theme.of(context);
    
    return MdsCard(
      type: MdsCardType.outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Key Features',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: ThemeConfig.darkNavy,
            ),
          ),
          const SizedBox(height: 16),
          _buildFeatureItem(context, Icons.analytics, 'Advanced Stats',
              'Go beyond the basics with metrics like target share, air yards, and snap percentage.'),
          const Divider(height: 24),
          _buildFeatureItem(context, Icons.speed, 'Real-Time Updates',
              'Instantly see how your rankings change as you adjust attribute weights.'),
          const Divider(height: 24),
          _buildFeatureItem(context, Icons.save, 'Save & Export',
              'Create and save multiple ranking systems, then export them for your draft prep.'),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(
      BuildContext context, IconData icon, String title, String description) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 28, color: ThemeConfig.gold),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
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
    );
  }

  void _startQuestionnaire(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const QuestionnaireWizardScreen(),
      ),
    );
  }

  void _viewSavedRankings(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const MyRankingsScreen(),
      ),
    );
  }
}