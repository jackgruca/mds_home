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

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentSlide = 0;
  final List<Map<String, String>> _slides = [
    {
      'title': 'Run a Mock Draft',
      'desc': 'Simulate the NFL draft with real-time analytics.',
      'image': 'assets/images/blog/draft_analysis_blog.jpg',
      'route': '/draft',
    },
    {
      'title': 'Fantasy Football Mock Drafts',
      'desc': 'Practice your fantasy draft strategy.',
      'image': 'assets/images/blog/player_projections_blog.jpg',
      'route': '/draft/fantasy',
    },
    {
      'title': 'Player Big Boards',
      'desc': 'View and customize player rankings.',
      'image': 'assets/images/blog/betting_metrics_blog.jpg',
      'route': '/draft/big-board',
    },
    {
      'title': 'Games This Week',
      'desc': 'See matchups, odds, and projections for this week.',
      'image': 'assets/images/blog/draft_analysis_blog.jpg',
      'route': '/data',
    },
  ];
  final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

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
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              child: ResponsiveLayoutBuilder(
                mobile: (context) => Column(
                  children: [
                    _buildSlideshow(context, isMobile: true),
                    const SizedBox(height: 24),
                    _buildStackedToolLinks(context),
                  ],
                ),
                desktop: (context) => Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 2, child: _buildSlideshow(context)),
                    const SizedBox(width: 32),
                    Expanded(flex: 1, child: _buildStackedToolLinks(context)),
                  ],
                ),
              ),
            ),
            _buildBlogSection(context, textTheme),
            _buildFooterSignup(context, isDarkMode),
          ],
        ),
      ),
    );
  }

  Widget _buildSlideshow(BuildContext context, {bool isMobile = false}) {
    final slideHeight = isMobile ? 220.0 : 340.0;
    return Column(
      children: [
        SizedBox(
          height: slideHeight,
          child: PageView.builder(
            controller: _pageController,
            itemCount: _slides.length,
            onPageChanged: (i) => setState(() => _currentSlide = i),
            itemBuilder: (context, i) {
              final slide = _slides[i];
              return GestureDetector(
                onTap: () => Navigator.pushNamed(context, slide['route']!),
                child: Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  clipBehavior: Clip.antiAlias,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.asset(
                        slide['image']!,
                        fit: BoxFit.cover,
                        color: Colors.black.withOpacity(0.25),
                        colorBlendMode: BlendMode.darken,
                      ),
                      Padding(
                        padding: const EdgeInsets.all(28.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(slide['title']!, style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 12),
                            Text(slide['desc']!, style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white70)),
                            const SizedBox(height: 18),
                            ElevatedButton(
                              onPressed: () => Navigator.pushNamed(context, slide['route']!),
                              style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.primary),
                              child: const Text('Explore'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_slides.length, (i) => GestureDetector(
            onTap: () {
              _pageController.animateToPage(i, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
            },
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: 48,
              height: 36,
              decoration: BoxDecoration(
                border: Border.all(color: i == _currentSlide ? Theme.of(context).colorScheme.primary : Colors.grey.shade400, width: 2),
                borderRadius: BorderRadius.circular(8),
                image: DecorationImage(
                  image: AssetImage(_slides[i]['image']!),
                  fit: BoxFit.cover,
                  colorFilter: i == _currentSlide ? null : ColorFilter.mode(Colors.black.withOpacity(0.5), BlendMode.darken),
                ),
              ),
            ),
          )),
        ),
      ],
    );
  }

  Widget _buildStackedToolLinks(BuildContext context) {
    final List<Map<String, dynamic>> tools = [
      {
        'icon': Icons.format_list_numbered,
        'title': 'Mock Draft Simulator',
        'desc': 'Simulate the NFL draft with real-time analytics.',
        'route': '/draft',
      },
      {
        'icon': Icons.sports_football,
        'title': 'Fantasy Football Mock Drafts',
        'desc': 'Practice your fantasy draft strategy.',
        'route': '/draft/fantasy',
      },
      {
        'icon': Icons.leaderboard,
        'title': 'Player Big Boards',
        'desc': 'View and customize player rankings.',
        'route': '/draft/big-board',
      },
      {
        'icon': Icons.calendar_today,
        'title': 'Games This Week',
        'desc': 'See matchups, odds, and projections for this week.',
        'route': '/data',
      },
      {
        'icon': Icons.trending_up,
        'title': 'Player Analytics',
        'desc': 'Projections, stats, and fantasy insights.',
        'route': '/projections',
      },
      {
        'icon': Icons.paid,
        'title': 'Betting Analytics',
        'desc': 'Odds, trends, and historical ATS data.',
        'route': '/betting',
      },
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: tools.map((tool) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Card(
          elevation: 2,
          child: ListTile(
            leading: Icon(tool['icon'], size: 32, color: Theme.of(context).colorScheme.primary),
            title: Text(tool['title'], style: Theme.of(context).textTheme.titleLarge),
            subtitle: Text(tool['desc']),
            onTap: () => Navigator.pushNamed(context, tool['route']),
            trailing: const Icon(Icons.arrow_forward_ios, size: 18),
          ),
        ),
      )).toList(),
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