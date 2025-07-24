import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:mds_home/widgets/common/custom_app_bar.dart';
import '../../widgets/auth/auth_dialog.dart';
import '../../widgets/common/app_drawer.dart';
import '../../widgets/common/top_nav_bar.dart';
import '../../utils/seo_helper.dart';

class DataExplorerScreen extends StatefulWidget {
  const DataExplorerScreen({super.key});

  @override
  _DataExplorerScreenState createState() => _DataExplorerScreenState();
}

class _DataExplorerScreenState extends State<DataExplorerScreen> {
  String _selectedSeason = '2023';
  bool _isLoading = true;
  Map<String, List<Map<String, dynamic>>> _topPerformers = {};
  
  final List<String> _availableSeasons = ['2024', '2023', '2022', '2021', '2020'];

  @override
  void initState() {
    super.initState();
    
    // Update SEO meta tags for Data Explorer page
    WidgetsBinding.instance.addPostFrameCallback((_) {
      SEOHelper.updateForDataExplorer();
    });
    
    _loadTopPerformers();
  }

  Future<void> _loadTopPerformers() async {
    setState(() => _isLoading = true);
    
    try {
      final functions = FirebaseFunctions.instance;
      
      // Load top performers for each category
      final futures = [
        _getTopPerformers('QB', 'passing_yards', 'Passing'),
        _getTopPerformers('RB', 'rushing_yards', 'Rushing'), 
        _getTopPerformers('WR', 'receiving_yards', 'Receiving'),
        _getTopPerformers('All', 'fantasy_points_ppr', 'Fantasy'),
      ];
      
      final results = await Future.wait(futures);
      
      setState(() {
        _topPerformers = {
          'Passing': results[0],
          'Rushing': results[1], 
          'Receiving': results[2],
          'Fantasy': results[3],
        };
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading top performers: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<List<Map<String, dynamic>>> _getTopPerformers(String position, String statField, String category) async {
    try {
      final callable = FirebaseFunctions.instance.httpsCallable('getTopPlayersByPosition');
      final result = await callable.call({
        'position': position,
        'season': int.parse(_selectedSeason),
        'limit': 5,
        'orderBy': statField,
      });
      
      return List<Map<String, dynamic>>.from(result.data['data'] ?? []);
    } catch (e) {
      print('Error getting top $category performers: $e');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
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
      body: _isLoading ? 
        const Center(child: CircularProgressIndicator()) :
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                theme.colorScheme.surface,
                theme.colorScheme.surface.withOpacity(0.8),
              ],
            ),
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeroSection(),
                _buildSeasonFilter(),
                _buildStatCategories(),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
    );
  }

  Widget _buildHeroSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(32, 40, 32, 32),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1E3A8A), // Deep blue
            Color(0xFF3B82F6), // Lighter blue
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.analytics,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'NFL Data Hub',
                      style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 32,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Comprehensive player statistics and performance analytics',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white.withOpacity(0.9),
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildQuickStats(),
        ],
      ),
    );
  }

  Widget _buildQuickStats() {
    return Row(
      children: [
        _buildQuickStatItem('5', 'Seasons', Icons.calendar_today),
        const SizedBox(width: 32),
        _buildQuickStatItem('1,000+', 'Players', Icons.person),
        const SizedBox(width: 32),
        _buildQuickStatItem('50+', 'Stats', Icons.bar_chart),
      ],
    );
  }

  Widget _buildQuickStatItem(String value, String label, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Colors.white.withOpacity(0.8), size: 20),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSeasonFilter() {
    return Container(
      margin: const EdgeInsets.all(32),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.calendar_today, 
              color: Theme.of(context).colorScheme.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Text(
            'Season:',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              border: Border.all(color: Theme.of(context).dividerColor),
              borderRadius: BorderRadius.circular(8),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedSeason,
                items: _availableSeasons.map((season) => DropdownMenuItem(
                  value: season,
                  child: Text(
                    season,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                )).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedSeason = value);
                    _loadTopPerformers();
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCategories() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Top Performers',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 28,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Leading players in each statistical category',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 32),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 24,
            crossAxisSpacing: 24,
            childAspectRatio: 1.3,
            children: [
              _buildModernStatCard(
                'Passing', 
                Icons.sports_football, 
                const Color(0xFF3B82F6), // Blue
                '/data/passing',
                'QB Stats'
              ),
              _buildModernStatCard(
                'Rushing', 
                Icons.directions_run, 
                const Color(0xFF10B981), // Green
                '/data/rushing',
                'RB Stats'
              ),
              _buildModernStatCard(
                'Receiving', 
                Icons.sports_baseball, 
                const Color(0xFFF59E0B), // Orange
                '/data/receiving',
                'WR/TE Stats'
              ),
              _buildModernStatCard(
                'Fantasy', 
                Icons.star, 
                const Color(0xFF8B5CF6), // Purple
                '/data/fantasy',
                'All Positions'
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildModernStatCard(String category, IconData icon, Color color, String route, String subtitle) {
    final performers = _topPerformers[category] ?? [];
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => Navigator.pushNamed(context, route),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with icon and title
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(icon, color: color, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            category,
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: color,
                            ),
                          ),
                          Text(
                            subtitle,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                
                // Top performers list
                Expanded(
                  child: performers.isEmpty 
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.hourglass_empty, color: color.withOpacity(0.5)),
                            const SizedBox(height: 8),
                            Text('Loading...', style: TextStyle(color: color.withOpacity(0.7))),
                          ],
                        ),
                      )
                    : Column(
                        children: performers.take(3).map((player) {
                          final index = performers.indexOf(player);
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              children: [
                                Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    color: color.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Center(
                                    child: Text(
                                      '${index + 1}',
                                      style: TextStyle(
                                        color: color,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        player['player_display_name'] ?? '',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        player['recent_team'] ?? '',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  _formatStatValue(player, category),
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: color,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                ),
                
                // View all button
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'View All',
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(Icons.arrow_forward, color: color, size: 16),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatStatValue(Map<String, dynamic> player, String category) {
    switch (category) {
      case 'Passing':
        final yards = player['passing_yards']?.toString() ?? '0';
        return '$yards YDS';
      case 'Rushing':
        final yards = player['rushing_yards']?.toString() ?? '0';
        return '$yards YDS';
      case 'Receiving':
        final yards = player['receiving_yards']?.toString() ?? '0';
        return '$yards YDS';
      case 'Fantasy':
        final points = player['fantasy_points_ppr']?.toString() ?? '0';
        return '$points PTS';
      default:
        return '';
    }
  }
} 