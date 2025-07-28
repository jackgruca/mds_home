// lib/screens/player_profile_screen.dart
import 'package:flutter/material.dart';
import '../models/nfl_player.dart';
import '../services/nfl_player_service.dart';
import '../services/instant_player_cache.dart';
import '../services/static_player_stats_2024.dart';
import '../services/player_profile_service.dart';
import '../services/game_level_data_service.dart';
import '../widgets/common/custom_app_bar.dart';
import '../widgets/common/top_nav_bar.dart';

class PlayerProfileScreen extends StatefulWidget {
  final String playerId;
  final String? playerName;

  const PlayerProfileScreen({
    super.key,
    required this.playerId,
    this.playerName,
  });

  @override
  State<PlayerProfileScreen> createState() => _PlayerProfileScreenState();
}

class _PlayerProfileScreenState extends State<PlayerProfileScreen> with SingleTickerProviderStateMixin {
  NFLPlayer? _basicPlayer; // For immediate display
  Map<String, dynamic>? _enhancedPlayerData; // New comprehensive data
  List<Map<String, dynamic>>? _gameLogs;
  bool _isLoadingBasic = true;
  bool _isLoadingEnhanced = false;
  String? _error;
  late TabController _tabController;
  
  final PlayerProfileService _profileService = PlayerProfileService();
  final GameLevelDataService _gameDataService = GameLevelDataService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadPlayerDataProgressive();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadPlayerDataProgressive() async {
    final decodedPlayerId = Uri.decodeComponent(widget.playerId);
    print('PlayerProfileScreen: Loading data for playerId: $decodedPlayerId');
    
    // Step 1: Try static 2024 stats first (INSTANT - 0ms)
    final staticStats = StaticPlayerStats2024.getPlayerStats(decodedPlayerId);
    if (staticStats != null && mounted) {
      // Create minimal player object from static data
      final staticPlayer = NFLPlayer(
        playerName: decodedPlayerId,
        position: staticStats['position'],
        team: staticStats['team'],
        currentSeasonStats: staticStats,
      );
      
      setState(() {
        _basicPlayer = staticPlayer;
        _isLoadingBasic = false;
      });
      
      // Load enhanced data in background
      _loadEnhancedData(decodedPlayerId);
      return;
    }
    
    // Step 2: Try instant cache
    final instantPlayer = InstantPlayerCache.getInstantPlayer(decodedPlayerId);
    if (instantPlayer != null && mounted) {
      setState(() {
        _basicPlayer = instantPlayer;
        _isLoadingBasic = false;
      });
      
      // Load enhanced data in background
      _loadEnhancedData(decodedPlayerId);
      return;
    }
    
    // Step 3: Try enhanced profile service first
    try {
      final enhancedData = await _profileService.getPlayerProfile(decodedPlayerId);
      if (enhancedData != null && mounted) {
        // Create basic player from enhanced data
        final basicPlayer = NFLPlayer(
          playerName: enhancedData['player_name'] ?? decodedPlayerId,
          position: enhancedData['position'],
          team: enhancedData['team'],
          currentSeasonStats: enhancedData['season_stats'],
        );
        
        setState(() {
          _basicPlayer = basicPlayer;
          _enhancedPlayerData = enhancedData;
          _gameLogs = enhancedData['game_logs'];
          _isLoadingBasic = false;
        });
        return;
      }
    } catch (e) {
      print('Enhanced data failed, falling back: $e');
    }
    
    // Step 4: ONLY if not in enhanced data - API call
    try {
      final player = await NFLPlayerService.getPlayerByName(
        decodedPlayerId, 
        includeHistoricalStats: false
      );
      
      if (player != null && mounted) {
        setState(() {
          _basicPlayer = player;
          _isLoadingBasic = false;
        });
        
        // Try to load enhanced data for this player
        _loadEnhancedData(decodedPlayerId);
      } else if (mounted) {
        setState(() {
          _error = 'Player not found';
          _isLoadingBasic = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load player data: $e';
          _isLoadingBasic = false;
        });
      }
    }
  }

  Future<void> _loadEnhancedData(String playerId) async {
    if (!mounted) return;
    
    setState(() {
      _isLoadingEnhanced = true;
    });

    try {
      final enhancedData = await _profileService.getPlayerProfile(playerId);
      final gameLogs = await _gameDataService.getPlayerGameLogs(playerId);
      
      if (mounted) {
        setState(() {
          _enhancedPlayerData = enhancedData;
          _gameLogs = gameLogs;
          _isLoadingEnhanced = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingEnhanced = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      appBar: CustomAppBar(
        titleWidget: _buildAppBarTitle(),
      ),
      body: Column(
        children: [
          const TopNavBarContent(),
          
          // Breadcrumb navigation
          _buildBreadcrumb(isDarkMode),
          
          Expanded(
            child: _buildBody(),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBarTitle() {
    if (_basicPlayer != null) {
      return Text(_basicPlayer!.displayName);
    }
    return Text(widget.playerName ?? 'Player Profile');
  }

  Widget _buildBreadcrumb(bool isDarkMode) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade100,
        border: Border(
          bottom: BorderSide(
            color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          InkWell(
            onTap: () => Navigator.pushNamedAndRemoveUntil(
              context, 
              '/enhanced-data-hub',
              (route) => false,
            ),
            child: Text(
              'Data Hub',
              style: TextStyle(
                color: Colors.blue.shade600,
                fontSize: 14,
              ),
            ),
          ),
          Icon(
            Icons.chevron_right,
            size: 16,
            color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
          ),
          InkWell(
            onTap: () => Navigator.pushNamed(context, '/player-season-stats'),
            child: Text(
              'Players',
              style: TextStyle(
                color: Colors.blue.shade600,
                fontSize: 14,
              ),
            ),
          ),
          Icon(
            Icons.chevron_right,
            size: 16,
            color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
          ),
          Text(
            _basicPlayer?.displayName ?? widget.playerName ?? 'Player',
            style: TextStyle(
              color: isDarkMode ? Colors.white : Colors.black87,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    // Show loading only if we have no basic player data
    if (_isLoadingBasic && _basicPlayer == null) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null && _basicPlayer == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadPlayerDataProgressive,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_basicPlayer == null) {
      return const Center(
        child: Text('Player not found'),
      );
    }

    return _buildPlayerProfile();
  }

  Widget _buildPlayerProfile() {
    final player = _basicPlayer!;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        // Player header
        Container(
          padding: const EdgeInsets.all(16),
          child: _buildEnhancedHeader(player, isDarkMode),
        ),
        
        // Tab bar
        Container(
          color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade100,
          child: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'Overview'),
              Tab(text: 'Game Log'),
              Tab(text: 'Career'),
            ],
            labelColor: isDarkMode ? Colors.white : Colors.black87,
            unselectedLabelColor: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
            indicatorColor: Colors.blue.shade600,
          ),
        ),
        
        // Tab content
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildOverviewTab(player, isDarkMode),
              _buildGameLogTab(isDarkMode),
              _buildCareerTab(player, isDarkMode),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEnhancedHeader(NFLPlayer player, bool isDarkMode) {
    final enhancedData = _enhancedPlayerData;
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.blue.shade700,
            Colors.blue.shade500,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      player.displayName,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        if (player.position != null) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              player.position!,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                        ],
                        if (player.team != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              player.team!,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              if (enhancedData != null && enhancedData['games_played'] != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '${enhancedData['games_played']}',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const Text(
                        'Games',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          
          if (enhancedData != null) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                if (enhancedData['height'] != null)
                  _buildInfoChip('Height', enhancedData['height'].toString()),
                const SizedBox(width: 12),
                if (enhancedData['weight'] != null)
                  _buildInfoChip('Weight', '${enhancedData['weight']} lbs'),
                const SizedBox(width: 12),
                if (enhancedData['years_exp'] != null)
                  _buildInfoChip('Exp', '${enhancedData['years_exp']} yrs'),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '$label: $value',
        style: const TextStyle(
          fontSize: 12,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildOverviewTab(NFLPlayer player, bool isDarkMode) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Season stats
          _buildSeasonStatsCard(player, isDarkMode),
          
          const SizedBox(height: 16),
          
          // Recent games (if available)
          if (_gameLogs != null && _gameLogs!.isNotEmpty)
            _buildRecentGamesCard(isDarkMode),
        ],
      ),
    );
  }

  Widget _buildGameLogTab(bool isDarkMode) {
    if (_gameLogs == null) {
      if (_isLoadingEnhanced) {
        return const Center(child: CircularProgressIndicator());
      }
      return const Center(
        child: Text('No game log data available'),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '2024 Game Log',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          
          // Game log table
          _buildGameLogTable(isDarkMode),
        ],
      ),
    );
  }

  Widget _buildCareerTab(NFLPlayer player, bool isDarkMode) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Career Statistics',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          
          // For now, show current season (can be expanded with historical data)
          _buildSeasonStatsCard(player, isDarkMode),
        ],
      ),
    );
  }

  Widget _buildSeasonStatsCard(NFLPlayer player, bool isDarkMode) {
    final stats = player.currentSeasonStats ?? {};
    final enhancedStats = _enhancedPlayerData?['season_stats'] ?? {};
    final position = player.position ?? '';
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey.shade800 : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade300, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '2024 Season Stats',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          
          if (position == 'QB') 
            _buildQBStats(enhancedStats.isNotEmpty ? enhancedStats : stats, isDarkMode)
          else if (position == 'RB') 
            _buildRBStats(enhancedStats.isNotEmpty ? enhancedStats : stats, isDarkMode)
          else if (position == 'WR' || position == 'TE') 
            _buildWRTEStats(enhancedStats.isNotEmpty ? enhancedStats : stats, isDarkMode)
          else
            Text(
              'No stats available for this position',
              style: TextStyle(
                color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRecentGamesCard(bool isDarkMode) {
    final recentGames = _gameLogs!.take(5).toList();
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey.shade800 : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade300, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recent Games',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          
          ...recentGames.map((game) => _buildGameSummaryRow(game, isDarkMode)),
        ],
      ),
    );
  }

  Widget _buildGameSummaryRow(Map<String, dynamic> game, bool isDarkMode) {
    final week = game['week']?.toString() ?? '?';
    final opponent = game['opponent']?.toString() ?? 'Unknown';
    final result = game['game_result']?.toString() ?? '?';
    final fantasyPoints = game['fantasy_points_ppr']?.toString() ?? '0';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: result == 'W' ? Colors.green : result == 'L' ? Colors.red : Colors.grey,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                result,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
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
                  'Week $week vs $opponent',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
                Text(
                  '$fantasyPoints fantasy points',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDarkMode ? Colors.grey.shade300 : Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGameLogTable(bool isDarkMode) {
    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey.shade800 : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade300, width: 1),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columnSpacing: 20,
          headingRowColor: WidgetStateProperty.all(
            isDarkMode ? Colors.grey.shade700 : Colors.grey.shade100,
          ),
          columns: const [
            DataColumn(label: Text('Week')),
            DataColumn(label: Text('Opponent')),
            DataColumn(label: Text('Result')),
            DataColumn(label: Text('Fantasy Pts')),
            DataColumn(label: Text('Key Stats')),
          ],
          rows: _gameLogs!.map((game) {
            final week = game['week']?.toString() ?? '?';
            final opponent = game['opponent']?.toString() ?? 'Unknown';
            final result = game['game_result']?.toString() ?? '?';
            final fantasyPoints = (game['fantasy_points_ppr'] as num?)?.toStringAsFixed(1) ?? '0.0';
            final keyStats = _getKeyStatsForGame(game);
            
            return DataRow(
              cells: [
                DataCell(Text(week)),
                DataCell(Text(opponent)),
                DataCell(
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: result == 'W' ? Colors.green : result == 'L' ? Colors.red : Colors.grey,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      result,
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                ),
                DataCell(Text(fantasyPoints)),
                DataCell(Text(keyStats)),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  String _getKeyStatsForGame(Map<String, dynamic> game) {
    final position = _basicPlayer?.position ?? '';
    
    if (position == 'QB') {
      final yards = game['passing_yards']?.toString() ?? '0';
      final tds = game['passing_tds']?.toString() ?? '0';
      return '$yards yds, $tds TD';
    } else if (position == 'RB') {
      final rushYds = game['rushing_yards']?.toString() ?? '0';
      final rushTds = game['rushing_tds']?.toString() ?? '0';
      return '$rushYds rush yds, $rushTds TD';
    } else if (position == 'WR' || position == 'TE') {
      final rec = game['receptions']?.toString() ?? '0';
      final yards = game['receiving_yards']?.toString() ?? '0';
      final tds = game['receiving_tds']?.toString() ?? '0';
      return '$rec rec, $yards yds, $tds TD';
    }
    
    return 'N/A';
  }

  
  Widget _buildQBStats(Map<String, dynamic> stats, bool isDarkMode) {
    return Wrap(
      spacing: 16,
      runSpacing: 12,
      children: [
        _buildStatItem('Pass Yards', stats['passing_yards']?.toString() ?? 'N/A', isDarkMode),
        _buildStatItem('Completions', stats['completions']?.toString() ?? 'N/A', isDarkMode),
        _buildStatItem('Attempts', stats['attempts']?.toString() ?? 'N/A', isDarkMode),
        _buildStatItem('Pass TDs', stats['passing_tds']?.toString() ?? 'N/A', isDarkMode),
      ],
    );
  }
  
  Widget _buildRBStats(Map<String, dynamic> stats, bool isDarkMode) {
    return Wrap(
      spacing: 16,
      runSpacing: 12,
      children: [
        _buildStatItem('Rush Att', stats['rush_att']?.toString() ?? 'N/A', isDarkMode),
        _buildStatItem('Rush Yards', stats['rushing_yards']?.toString() ?? 'N/A', isDarkMode),
        _buildStatItem('Rush TDs', stats['rushing_tds']?.toString() ?? 'N/A', isDarkMode),
      ],
    );
  }
  
  Widget _buildWRTEStats(Map<String, dynamic> stats, bool isDarkMode) {
    return Wrap(
      spacing: 16,
      runSpacing: 12,
      children: [
        _buildStatItem('Targets', stats['targets']?.toString() ?? 'N/A', isDarkMode),
        _buildStatItem('Receptions', stats['receptions']?.toString() ?? 'N/A', isDarkMode),
        _buildStatItem('Rec Yards', stats['receiving_yards']?.toString() ?? 'N/A', isDarkMode),
        _buildStatItem('Rec TDs', stats['receiving_tds']?.toString() ?? 'N/A', isDarkMode),
      ],
    );
  }
  
  Widget _buildStatItem(String label, String value, bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.black12 : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

}