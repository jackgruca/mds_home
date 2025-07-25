// lib/screens/player_profile_screen.dart
import 'package:flutter/material.dart';
import '../models/nfl_player.dart';
import '../services/nfl_player_service.dart';
import '../services/instant_player_cache.dart';
import '../services/static_player_stats_2024.dart';
import '../widgets/common/custom_app_bar.dart';
import '../widgets/common/top_nav_bar.dart';

class PlayerProfileScreen extends StatefulWidget {
  final String playerId;

  const PlayerProfileScreen({
    super.key,
    required this.playerId,
  });

  @override
  State<PlayerProfileScreen> createState() => _PlayerProfileScreenState();
}

class _PlayerProfileScreenState extends State<PlayerProfileScreen> {
  NFLPlayer? _basicPlayer; // For immediate display
  bool _isLoadingBasic = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPlayerDataProgressive();
  }

  Future<void> _loadPlayerDataProgressive() async {
    final decodedPlayerId = Uri.decodeComponent(widget.playerId);
    
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
      return; // DONE - no API call needed
    }
    
    // Step 2: Try instant cache
    final instantPlayer = InstantPlayerCache.getInstantPlayer(decodedPlayerId);
    if (instantPlayer != null && mounted) {
      setState(() {
        _basicPlayer = instantPlayer;
        _isLoadingBasic = false;
      });
      return; // DONE
    }
    
    // Step 3: ONLY if not in static cache - API call
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        titleWidget: Text('Player Profile'),
      ),
      body: Column(
        children: [
          const TopNavBarContent(),
          Expanded(
            child: _buildBody(),
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

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Simple player header
          _buildSimpleHeader(player, isDarkMode),
          
          const SizedBox(height: 24),
          
          // Just 2024 stats - NOTHING ELSE
          _buildSimple2024Stats(player, isDarkMode),
        ],
      ),
    );
  }

  Widget _buildSimpleHeader(NFLPlayer player, bool isDarkMode) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey.shade800 : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade300, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            player.displayName,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              if (player.position != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade600,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    player.position!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              if (player.team != null)
                Text(
                  player.team!,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDarkMode ? Colors.grey.shade300 : Colors.grey.shade700,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSimple2024Stats(NFLPlayer player, bool isDarkMode) {
    final stats = player.currentSeasonStats ?? {};
    final position = player.position ?? '';
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey.shade800 : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade300, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '2024 Stats',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          
          if (position == 'QB') 
            _buildQBStats(stats, isDarkMode)
          else if (position == 'RB') 
            _buildRBStats(stats, isDarkMode)
          else if (position == 'WR' || position == 'TE') 
            _buildWRTEStats(stats, isDarkMode)
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