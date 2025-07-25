import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../widgets/common/custom_app_bar.dart';
import '../widgets/common/top_nav_bar.dart';
import '../services/hybrid_data_service.dart';

class ModernDataHubScreen extends StatefulWidget {
  const ModernDataHubScreen({super.key});

  @override
  State<ModernDataHubScreen> createState() => _ModernDataHubScreenState();
}

class _ModernDataHubScreenState extends State<ModernDataHubScreen>
    with TickerProviderStateMixin {
  final HybridDataService _dataService = HybridDataService();
  final TextEditingController _searchController = TextEditingController();
  
  bool _isLoading = true;
  List<Map<String, dynamic>> _allPlayers = [];
  List<Map<String, dynamic>> _searchResults = [];
  List<Map<String, dynamic>> _weeklyLeaders = [];
  List<Map<String, dynamic>> _trendingPlayers = [];
  List<Map<String, dynamic>> _breakoutCandidates = [];

  late AnimationController _heroAnimationController;
  late AnimationController _cardsAnimationController;

  @override
  void initState() {
    super.initState();
    _heroAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _cardsAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      // Load all player data
      _allPlayers = await _dataService.getPlayerStats();
      
      // Generate insights
      _generateInsights();
      
      // Start animations
      _heroAnimationController.forward();
      Future.delayed(const Duration(milliseconds: 300), () {
        _cardsAnimationController.forward();
      });
      
      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _generateInsights() {
    if (_allPlayers.isEmpty) return;

    // Get current season players
    final currentPlayers = _allPlayers
        .where((p) => p['season'] == 2024)
        .toList();

    // Weekly Leaders (fantasy points per game)
    _weeklyLeaders = currentPlayers
        .where((p) => p['fantasy_points_ppr_per_game'] != null)
        .toList()
      ..sort((a, b) => (b['fantasy_points_ppr_per_game'] ?? 0)
          .compareTo(a['fantasy_points_ppr_per_game'] ?? 0))
      ..take(6).toList();

    // Trending Players (high target share + games played)
    _trendingPlayers = currentPlayers
        .where((p) => 
            p['target_share'] != null && 
            p['target_share'] > 20 &&
            p['games'] != null && 
            p['games'] >= 5)
        .toList()
      ..sort((a, b) => (b['target_share'] ?? 0).compareTo(a['target_share'] ?? 0))
      ..take(6).toList();

    // Breakout Candidates (high efficiency metrics)
    _breakoutCandidates = currentPlayers
        .where((p) => 
            p['yards_per_reception'] != null &&
            p['yards_per_reception'] > 12 &&
            p['receptions'] != null &&
            p['receptions'] >= 20)
        .toList()
      ..sort((a, b) => (b['yards_per_reception'] ?? 0)
          .compareTo(a['yards_per_reception'] ?? 0))
      ..take(6).toList();
  }

  void _performSearch(String query) {
    if (query.isEmpty) {
      setState(() => _searchResults = []);
      return;
    }

    final results = _allPlayers
        .where((player) {
          final name = player['player_display_name']?.toString().toLowerCase() ?? '';
          final searchLower = query.toLowerCase();
          return name.contains(searchLower);
        })
        .take(5)
        .toList();

    setState(() => _searchResults = results);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      appBar: const CustomAppBar(
        titleWidget: Text('🏟️ NFL Analytics Hub'),
      ),
      body: Column(
        children: [
          const TopNavBarContent(),
          
          if (_isLoading)
            const Expanded(
              child: Center(child: CircularProgressIndicator()),
            )
          else
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Hero Section
                    _buildHeroSection(isDark),
                    
                    const SizedBox(height: 32),
                    
                    // Quick Search
                    _buildQuickSearch(),
                    
                    const SizedBox(height: 32),
                    
                    // Live Dashboard
                    _buildLiveDashboard(isDark),
                    
                    const SizedBox(height: 32),
                    
                    // Analytics Categories
                    _buildAnalyticsCategories(isDark),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHeroSection(bool isDark) {
    return AnimatedBuilder(
      animation: _heroAnimationController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 50 * (1 - _heroAnimationController.value)),
          child: Opacity(
            opacity: _heroAnimationController.value,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.blue.shade700,
                    Colors.purple.shade600,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.analytics,
                        size: 48,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Advanced NFL Analytics',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Lightning-fast insights powered by NextGen Stats',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white.withOpacity(0.9),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Stats preview
                  Row(
                    children: [
                      _buildStatChip('2,855', 'Players'),
                      const SizedBox(width: 16),
                      _buildStatChip('59', 'Metrics'),
                      const SizedBox(width: 16),
                      _buildStatChip('<50ms', 'Response'),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatChip(String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickSearch() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '🔍 Quick Player Search',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        
        TextField(
          controller: _searchController,
          onChanged: _performSearch,
          decoration: InputDecoration(
            hintText: 'Search players (e.g., "Mahomes", "Jefferson")',
            prefixIcon: const Icon(Icons.search),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: Theme.of(context).cardColor,
          ),
        ),
        
        if (_searchResults.isNotEmpty) ...[
          const SizedBox(height: 8),
          Container(
            constraints: const BoxConstraints(maxHeight: 200),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.withOpacity(0.3)),
            ),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _searchResults.length,
              itemBuilder: (context, index) {
                final player = _searchResults[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: _getPositionColor(player['position']),
                    child: Text(
                      player['position'] ?? '?',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(player['player_display_name'] ?? 'Unknown'),
                  subtitle: Text(
                    '${player['recent_team'] ?? 'UNK'} • ${player['fantasy_points_ppr']?.toStringAsFixed(1) ?? '0'} PPR Pts',
                  ),
                  onTap: () {
                    // Navigate to player detail
                    Navigator.pushNamed(
                      context, 
                      '/player/${player['player_id']}',
                    );
                  },
                );
              },
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildLiveDashboard(bool isDark) {
    return AnimationLimiter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '📈 Live Performance Dashboard',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 0.8,
            children: [
              _buildDashboardCard(
                '🔥 Weekly Leaders',
                _weeklyLeaders,
                Colors.red,
                'PPR/Game',
                'fantasy_points_ppr_per_game',
              ),
              _buildDashboardCard(
                '📈 Trending',
                _trendingPlayers,
                Colors.green,
                'Target %',
                'target_share',
              ),
              _buildDashboardCard(
                '⭐ Breakouts',
                _breakoutCandidates,
                Colors.purple,
                'YAC',
                'yards_per_reception',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardCard(
    String title,
    List<Map<String, dynamic>> players,
    Color color,
    String metricLabel,
    String metricField,
  ) {
    return AnimationConfiguration.staggeredGrid(
      position: 0,
      duration: const Duration(milliseconds: 600),
      columnCount: 3,
      child: SlideAnimation(
        verticalOffset: 50.0,
        child: FadeInAnimation(
          child: Card(
            elevation: 8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  colors: [
                    color.withOpacity(0.1),
                    color.withOpacity(0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  Expanded(
                    child: ListView.builder(
                      itemCount: players.take(3).length,
                      itemBuilder: (context, index) {
                        final player = players[index];
                        final metricValue = player[metricField]?.toStringAsFixed(1) ?? '0';
                        
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 12,
                                backgroundColor: color.withOpacity(0.2),
                                child: Text(
                                  '${index + 1}',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: color,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      player['player_display_name'] ?? 'Unknown',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      '$metricValue $metricLabel',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnalyticsCategories(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '📊 Analytics Categories',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.0,
          children: [
            _buildCategoryCard(
              '🎯 Quarterback Analytics',
              'Pocket presence, deep ball mastery, pressure stats',
              Icons.sports_football,
              Colors.blue,
              '/data/passing',
            ),
            _buildCategoryCard(
              '🏃 Running Back Analytics',
              'Rushing efficiency, dual-threat metrics, opportunity',
              Icons.fitness_center,
              Colors.orange,
              '/data/rushing',
            ),
            _buildCategoryCard(
              '🎯 Wide Receiver Analytics', 
              'Route running, separation, target efficiency, air yards',
              Icons.directions_run,
              Colors.green,
              '/data/receiving',
            ),
            _buildCategoryCard(
              '🏈 Tight End Analytics',
              'Target quality, receiving versatility, multi-dimensional usage',
              Icons.sports_handball,
              Colors.purple,
              '/data/advanced',
            ),
            _buildCategoryCard(
              '📈 Historical Trends',
              'Multi-season player analysis, career progression tracking',
              Icons.trending_up,
              Colors.indigo,
              '/data/trends',
            ),
            _buildCategoryCard(
              '🏆 Fantasy Intelligence',
              'Projections, opportunity metrics, waiver alerts',
              Icons.emoji_events,
              Colors.red,
              '/fantasy',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCategoryCard(
    String title,
    String description,
    IconData icon,
    Color color,
    String route,
  ) {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () => Navigator.pushNamed(context, route),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [
                color.withOpacity(0.1),
                color.withOpacity(0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                icon,
                size: 32,
                color: color,
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                description,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getPositionColor(String? position) {
    switch (position) {
      case 'QB': return Colors.blue;
      case 'RB': return Colors.green;
      case 'WR': return Colors.orange;
      case 'TE': return Colors.purple;
      default: return Colors.grey;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _heroAnimationController.dispose();
    _cardsAnimationController.dispose();
    super.dispose();
  }
}