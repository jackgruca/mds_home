// lib/screens/player_profile_screen.dart
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/nfl_player.dart';
import '../services/nfl_player_service.dart';
import '../widgets/common/custom_app_bar.dart';
import '../widgets/common/top_nav_bar.dart';
import '../utils/team_logo_utils.dart';

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
  NFLPlayer? _player;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPlayerData();
  }

  Future<void> _loadPlayerData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Try to get player by ID first, fallback to name
      NFLPlayer? player = await NFLPlayerService.getPlayerById(widget.playerId);
      
      // If no result and playerId looks like a name, try by name
      if (player == null && widget.playerId.contains(' ')) {
        player = await NFLPlayerService.getPlayerByName(widget.playerId);
      }

      if (mounted) {
        setState(() {
          _player = player;
          _isLoading = false;
          if (player == null) {
            _error = 'Player not found';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load player data: $e';
          _isLoading = false;
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
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
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
              onPressed: _loadPlayerData,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_player == null) {
      return const Center(
        child: Text('Player not found'),
      );
    }

    return _buildPlayerProfile();
  }

  Widget _buildPlayerProfile() {
    final player = _player!;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Player header card
          _buildPlayerHeader(player, isDarkMode),
          
          const SizedBox(height: 24),
          
          // Player info sections
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left column - Bio info
              Expanded(
                flex: 1,
                child: _buildBioSection(player, isDarkMode),
              ),
              
              const SizedBox(width: 16),
              
              // Right column - Stats and other info
              Expanded(
                flex: 2,
                child: _buildStatsSection(player, isDarkMode),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerHeader(NFLPlayer player, bool isDarkMode) {
    final headerColor = _getPositionColor(player.position ?? '');
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            headerColor.withValues(alpha: isDarkMode ? 0.8 : 0.3),
            headerColor.withValues(alpha: isDarkMode ? 0.4 : 0.1),
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
      child: Row(
        children: [
          // Player headshot
          _buildPlayerImage(player, isDarkMode),
          
          const SizedBox(width: 24),
          
          // Player info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  player.displayName,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    if (player.position != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: headerColor,
                          borderRadius: BorderRadius.circular(20),
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
                    if (player.team != null) ...[
                      Text(
                        player.team!,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: isDarkMode ? Colors.grey.shade300 : Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ],
                ),
                if (player.experienceText.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    player.experienceText,
                    style: TextStyle(
                      fontSize: 14,
                      color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerImage(NFLPlayer player, bool isDarkMode) {
    if (player.headshotUrl != null && player.headshotUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: CachedNetworkImage(
          imageUrl: player.headshotUrl!,
          width: 100,
          height: 100,
          fit: BoxFit.cover,
          placeholder: (context, url) => Container(
            width: 100,
            height: 100,
            color: isDarkMode ? Colors.black12 : Colors.grey.shade200,
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          ),
          errorWidget: (context, url, error) => _buildFallbackImage(player, isDarkMode),
        ),
      );
    }
    
    return _buildFallbackImage(player, isDarkMode);
  }

  Widget _buildFallbackImage(NFLPlayer player, bool isDarkMode) {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.black12 : Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.person,
            size: 48,
            color: isDarkMode ? Colors.grey.shade600 : Colors.grey.shade400,
          ),
          if (player.team != null && player.team!.isNotEmpty)
            TeamLogoUtils.buildNFLTeamLogo(
              player.team!,
              size: 24,
            ),
        ],
      ),
    );
  }

  Widget _buildBioSection(NFLPlayer player, bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey.shade800 : Colors.white,
        borderRadius: BorderRadius.circular(12),
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
            'Player Info',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          
          _buildInfoRow('Height', player.formattedHeight, isDarkMode),
          _buildInfoRow('Weight', player.formattedWeight, isDarkMode),
          if (player.age != null)
            _buildInfoRow('Age', '${player.age}', isDarkMode),
          if (player.college != null)
            _buildInfoRow('College', player.college!, isDarkMode),
          if (player.draftInfo != 'Draft info unavailable')
            _buildInfoRow('Draft', player.draftInfo, isDarkMode),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                color: isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection(NFLPlayer player, bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey.shade800 : Colors.white,
        borderRadius: BorderRadius.circular(12),
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
            'Career Statistics',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          
          if (player.historicalStats != null && player.historicalStats!.isNotEmpty)
            _buildHistoricalStatsSection(player.historicalStats!, isDarkMode)
          else if (player.currentSeasonStats != null && player.currentSeasonStats!.isNotEmpty)
            _buildStatsGrid(player.currentSeasonStats!, isDarkMode)
          else
            Text(
              'No statistics available',
              style: TextStyle(
                fontSize: 14,
                color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHistoricalStatsSection(Map<int, Map<String, dynamic>> historicalStats, bool isDarkMode) {
    final sortedSeasons = historicalStats.keys.toList()..sort((a, b) => b.compareTo(a)); // Most recent first
    
    return Column(
      children: [
        // Season tabs or list
        SizedBox(
          height: 40,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: sortedSeasons.length,
            itemBuilder: (context, index) {
              final season = sortedSeasons[index];
              final isSelected = index == 0; // Default to most recent season
              
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected 
                        ? Colors.blue.shade600 
                        : (isDarkMode ? Colors.grey.shade700 : Colors.grey.shade200),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$season',
                    style: TextStyle(
                      color: isSelected 
                          ? Colors.white 
                          : (isDarkMode ? Colors.white : Colors.black87),
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Stats for most recent season
        _buildStatsGrid(historicalStats[sortedSeasons.first]!, isDarkMode),
        
        const SizedBox(height: 24),
        
        // Career progression table
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDarkMode ? Colors.black12 : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Career Progression',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              _buildCareerProgressionTable(historicalStats, isDarkMode),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCareerProgressionTable(Map<int, Map<String, dynamic>> historicalStats, bool isDarkMode) {
    final sortedSeasons = historicalStats.keys.toList()..sort((a, b) => b.compareTo(a));
    
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: [
          DataColumn(
            label: Text(
              'Season',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
          ),
          DataColumn(
            label: Text(
              'Games',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
          ),
          // Add key stat columns based on first season data
          ...historicalStats[sortedSeasons.first]!.entries
              .where((entry) => entry.key != 'season' && entry.key != 'games_played')
              .take(4) // Show only top 4 stats to keep table manageable
              .map((entry) => DataColumn(
                    label: Text(
                      entry.key.replaceAll('_', '\n').toUpperCase(),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                        color: isDarkMode ? Colors.white : Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  )),
        ],
        rows: sortedSeasons.map((season) {
          final stats = historicalStats[season]!;
          return DataRow(
            cells: [
              DataCell(Text(
                '$season',
                style: TextStyle(
                  color: isDarkMode ? Colors.grey.shade300 : Colors.black87,
                ),
              )),
              DataCell(Text(
                '${stats['games_played'] ?? 'N/A'}',
                style: TextStyle(
                  color: isDarkMode ? Colors.grey.shade300 : Colors.black87,
                ),
              )),
              ...stats.entries
                  .where((entry) => entry.key != 'season' && entry.key != 'games_played')
                  .take(4)
                  .map((entry) => DataCell(Text(
                        '${entry.value}',
                        style: TextStyle(
                          color: isDarkMode ? Colors.grey.shade300 : Colors.black87,
                        ),
                      ))),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildStatsGrid(Map<String, dynamic> stats, bool isDarkMode) {
    // Define key stats to display first, organized by position
    final position = _player?.position ?? '';
    final keyStats = _getKeyStatsForPosition(position, stats);
    final otherStats = stats.entries
        .where((entry) => !keyStats.any((key) => key.key == entry.key))
        .where((entry) => entry.value != null)
        .toList();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (keyStats.isNotEmpty) ...[
          Text(
            'Key Statistics',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: keyStats.map((entry) => _buildStatCard(entry, isDarkMode, isKey: true)).toList(),
          ),
          const SizedBox(height: 24),
        ],
        
        if (otherStats.isNotEmpty) ...[
          Text(
            'Additional Statistics',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: otherStats.map((entry) => _buildStatCard(entry, isDarkMode)).toList(),
          ),
        ],
      ],
    );
  }
  
  List<MapEntry<String, dynamic>> _getKeyStatsForPosition(String position, Map<String, dynamic> stats) {
    List<String> keyStatNames = [];
    
    switch (position) {
      case 'QB':
        keyStatNames = ['passing_yards', 'passing_tds', 'interceptions', 'completion_percentage', 'passer_rating'];
        break;
      case 'RB':
        keyStatNames = ['rushing_yards', 'rushing_tds', 'yards_per_carry', 'receptions', 'receiving_yards'];
        break;
      case 'WR':
      case 'TE':
        keyStatNames = ['receiving_yards', 'receiving_tds', 'receptions', 'yards_per_reception', 'targets'];
        break;
      default:
        keyStatNames = ['fantasy_points_ppr', 'fantasy_points', 'games'];
    }
    
    return keyStatNames
        .map((name) => stats.entries.firstWhere(
            (entry) => entry.key == name,
            orElse: () => const MapEntry('', null)))
        .where((entry) => entry.key.isNotEmpty && entry.value != null)
        .toList();
  }
  
  Widget _buildStatCard(MapEntry<String, dynamic> entry, bool isDarkMode, {bool isKey = false}) {
    return Container(
      width: isKey ? 120 : 100,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isKey 
            ? (isDarkMode ? Colors.blue.shade900.withValues(alpha: 0.3) : Colors.blue.shade50)
            : (isDarkMode ? Colors.black12 : Colors.grey.shade50),
        borderRadius: BorderRadius.circular(8),
        border: isKey ? Border.all(color: Colors.blue.shade300, width: 1) : null,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _formatStatName(entry.key),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            _formatStatValue(entry.key, entry.value),
            style: TextStyle(
              fontSize: isKey ? 18 : 16,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
  
  String _formatStatName(String key) {
    // Custom formatting for stat names
    switch (key) {
      case 'passing_yards': return 'Pass Yds';
      case 'passing_tds': return 'Pass TDs';
      case 'interceptions': return 'INTs';
      case 'completion_percentage': return 'Comp %';
      case 'passer_rating': return 'Rating';
      case 'rushing_yards': return 'Rush Yds';
      case 'rushing_tds': return 'Rush TDs';
      case 'yards_per_carry': return 'Y/C';
      case 'receiving_yards': return 'Rec Yds';
      case 'receiving_tds': return 'Rec TDs';
      case 'yards_per_reception': return 'Y/R';
      case 'fantasy_points_ppr': return 'PPR Pts';
      case 'fantasy_points': return 'Std Pts';
      default: return key.replaceAll('_', ' ').toUpperCase();
    }
  }
  
  String _formatStatValue(String key, dynamic value) {
    if (value == null) return 'N/A';
    
    // Format percentages
    if (key.contains('percentage') || key.contains('completion')) {
      return '${(value as num).toStringAsFixed(1)}%';
    }
    
    // Format decimals for certain stats
    if (['yards_per_carry', 'yards_per_reception', 'passer_rating'].contains(key)) {
      return (value as num).toStringAsFixed(1);
    }
    
    // Format integers
    if (value is num) {
      return value.round().toString();
    }
    
    return value.toString();
  }

  Color _getPositionColor(String position) {
    // Different colors for different position groups
    if (['QB'].contains(position)) {
      return Colors.blue.shade700;
    } else if (['RB', 'FB'].contains(position)) {
      return Colors.green.shade700;
    } else if (['WR', 'TE'].contains(position)) {
      return Colors.purple.shade700;
    } else if (['OT', 'IOL', 'OL', 'G', 'C'].contains(position)) {
      return Colors.orange.shade700;
    } else if (['EDGE', 'DL', 'IDL', 'DT', 'DE'].contains(position)) {
      return Colors.red.shade700;
    } else if (['LB', 'ILB', 'OLB'].contains(position)) {
      return Colors.teal.shade700;
    } else if (['CB', 'S', 'FS', 'SS'].contains(position)) {
      return Colors.indigo.shade700;
    }
    return Colors.grey.shade700;
  }
}