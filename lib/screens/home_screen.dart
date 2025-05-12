import 'package:flutter/material.dart';
import 'package:mds_home/widgets/common/custom_app_bar.dart';
import 'package:provider/provider.dart';
import '../utils/theme_manager.dart';
import '../widgets/blog/blog_preview_card.dart';
import '../widgets/newsletter_signup.dart';
import '../widgets/auth/auth_dialog.dart';
import '../utils/constants.dart';
import '../widgets/common/responsive_layout_builder.dart';
import '../widgets/common/app_drawer.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Scaffold(
      appBar: CustomAppBar(
        title: 'StickToTheModel',
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
            _buildHeader(context, textTheme, isDarkMode),

            _buildTwitterBannerPlaceholder(context, textTheme),

            _buildFeatureColumns(context, textTheme),

            _buildBlogSection(context, textTheme),

            _buildFooterSignup(context, isDarkMode),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, TextTheme textTheme, bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDarkMode
              ? [Theme.of(context).colorScheme.surface.withOpacity(0.1), Theme.of(context).colorScheme.surface.withOpacity(0.05)]
              : [Colors.blue.shade50, Colors.blue.shade100],
        ),
      ),
      child: Column(
        children: [
          Text(
            'The Source for Your NFL Answers.',
            style: textTheme.displaySmall?.copyWith(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTwitterBannerPlaceholder(BuildContext context, TextTheme textTheme) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
      padding: const EdgeInsets.all(20),
      height: 150,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.5),
        borderRadius: BorderRadius.circular(AppConstants.kCardBorderRadius),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Center(
        child: Text(
          'Twitter Feed Placeholder: Customizable NFL Insights Coming Soon!',
          style: textTheme.titleMedium,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildFeatureColumns(BuildContext context, TextTheme textTheme) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: ResponsiveLayoutBuilder(
        mobile: (context) => Column(
          children: [
            _buildFeatureColumnItem(context, 'Draft Central', Icons.format_list_numbered, [
              _buildFeatureLink(context, 'Mock Draft Simulator', '/draft'),
              _buildFeatureLink(context, 'Draft Big Board', '/draft/big-board'),
              _buildFeatureLink(context, 'Team Needs Analysis', '/draft/team-needs'),
            ]),
            const SizedBox(height: 20),
            _buildFeatureColumnItem(context, 'Player Analytics', Icons.trending_up, [
              _buildFeatureLink(context, 'Player Projections', '/projections'),
              _buildFeatureLink(context, 'Performance Stats', '/projections/stats'),
              _buildFeatureLink(context, 'Fantasy Insights', '/projections/fantasy'),
            ]),
            const SizedBox(height: 20),
            _buildFeatureColumnItem(context, 'Betting Edge', Icons.paid, [
              _buildFeatureLink(context, 'Betting Analytics', '/betting'),
              _buildFeatureLink(context, 'Odds Comparison', '/betting/odds'),
              _buildFeatureLink(context, 'Historical ATS Data', '/data'),
            ]),
          ],
        ),
        desktop: (context) => Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _buildFeatureColumnItem(context, 'Draft Central', Icons.format_list_numbered, [
                _buildFeatureLink(context, 'Mock Draft Simulator', '/draft'),
                _buildFeatureLink(context, 'Draft Big Board', '/draft/big-board'),
                _buildFeatureLink(context, 'Team Needs Analysis', '/draft/team-needs'),
              ]),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: _buildFeatureColumnItem(context, 'Player Analytics', Icons.trending_up, [
                _buildFeatureLink(context, 'Player Projections', '/projections'),
                _buildFeatureLink(context, 'Performance Stats', '/projections/stats'),
                _buildFeatureLink(context, 'Fantasy Insights', '/projections/fantasy'),
              ]),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: _buildFeatureColumnItem(context, 'Betting Edge', Icons.paid, [
                _buildFeatureLink(context, 'Betting Analytics', '/betting'),
                _buildFeatureLink(context, 'Odds Comparison', '/betting/odds'),
                _buildFeatureLink(context, 'Historical ATS Data', '/data'),
              ]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureColumnItem(BuildContext context, String title, IconData icon, List<Widget> links) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 28, color: Theme.of(context).primaryColor),
                const SizedBox(width: 10),
                Text(title, style: Theme.of(context).textTheme.titleLarge),
              ],
            ),
            const Divider(height: 20, thickness: 1),
            ...links,
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureLink(BuildContext context, String text, String route) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: InkWell(
        onTap: () => Navigator.pushNamed(context, route),
        child: Row(
          children: [
            Icon(Icons.arrow_forward_ios, size: 14, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                text,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBlogSection(BuildContext context, TextTheme textTheme) {
    final blogPosts = [
      {
        'title': 'NFL Draft Surprises & Sleepers',
        'excerpt': 'Unpacking the most unexpected picks and hidden gems from the recent NFL draft...',
        'date': '2024-04-28',
        'imageUrl': 'assets/images/blog/draft_analysis_blog.jpg',
        'route': '/blog/draft-surprises'
      },
      {
        'title': 'Advanced Metrics for Betting Success',
        'excerpt': 'Leverage cutting-edge analytics to gain an edge in NFL betting markets this season...',
        'date': '2024-04-25',
        'imageUrl': 'assets/images/blog/betting_metrics_blog.jpg',
        'route': '/blog/betting-metrics'
      },
      {
        'title': 'Breakout Player Projections 2024',
        'excerpt': 'Identifying the players poised for a significant leap in performance in the upcoming season...',
        'date': '2024-04-22',
        'imageUrl': 'assets/images/blog/player_projections_blog.jpg',
        'route': '/blog/breakout-players'
      },
    ];

    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Latest Insights & Analysis', style: textTheme.headlineSmall),
          const SizedBox(height: 20),
          ResponsiveLayoutBuilder(
            mobile: (context) => ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: blogPosts.length,
              itemBuilder: (context, index) {
                final post = blogPosts[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: BlogPreviewCard(
                    title: post['title']!,
                    excerpt: post['excerpt']!,
                    date: post['date']!,
                    imageUrl: post['imageUrl']!,
                  ),
                );
              },
            ),
            desktop: (context) => GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 400,
                childAspectRatio: 1.25,
                crossAxisSpacing: 20,
                mainAxisSpacing: 20,
              ),
              itemCount: blogPosts.length,
              itemBuilder: (context, index) {
                final post = blogPosts[index];
                return BlogPreviewCard(
                  title: post['title']!,
                  excerpt: post['excerpt']!,
                  date: post['date']!,
                  imageUrl: post['imageUrl']!,
                );
              },
            ),
          ),
          const SizedBox(height: 20),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => Navigator.pushNamed(context, '/blog'),
              child: const Text('View All Blog Posts →'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooterSignup(BuildContext context, bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      color: isDarkMode ? Theme.of(context).colorScheme.surface.withOpacity(0.1) : Colors.blue.shade50,
      child: Column(
        children: [
          Text(
            'Want personalized NFL updates and insights?',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Theme.of(context).colorScheme.onSurface),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 15),
          Text(
            'Sign up for full access to all our tools and get the latest insights delivered to your inbox.',
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
            child: const Text('Get Started Now'),
          ),
        ],
      ),
    );
  }
} 