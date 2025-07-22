import 'package:flutter/material.dart';
import '../../widgets/common/custom_app_bar.dart';
import '../../utils/theme_config.dart';
import '../../utils/team_logo_utils.dart';
import '../../models/vorp/custom_position_ranking.dart';
import '../../services/vorp/custom_vorp_ranking_service.dart';

class CustomBigBoardScreen extends StatefulWidget {
  final CustomBigBoard bigBoard;

  const CustomBigBoardScreen({
    super.key,
    required this.bigBoard,
  });

  @override
  State<CustomBigBoardScreen> createState() => _CustomBigBoardScreenState();
}

class _CustomBigBoardScreenState extends State<CustomBigBoardScreen> {
  final CustomVorpRankingService _rankingService = CustomVorpRankingService();
  
  // Filter state
  String _selectedPosition = 'All';
  String _selectedTier = 'All';
  bool _showVORPTiers = true;
  bool _showProjectedPoints = true;
  
  // Sorting state
  String _sortBy = 'vorp'; // vorp, projectedPoints, alphabetical
  bool _sortAscending = false; // VORP should default to descending (highest first)
  
  // Filtered and sorted players
  List<CustomPlayerRank> _filteredPlayers = [];
  List<String> _availablePositions = [];
  Map<String, Color> _positionColors = {};

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  void _initializeData() {
    // Get available positions
    _availablePositions = ['All'];
    _availablePositions.addAll(
      widget.bigBoard.aggregatedPlayers
          .map((player) => _getPositionFromPlayerId(player.playerId))
          .toSet()
          .where((pos) => pos.isNotEmpty)
          .toList()
        ..sort()
    );
    
    // Set up position colors
    _positionColors = {
      'QB': Colors.blue.shade600,
      'RB': Colors.green.shade600, 
      'WR': Colors.orange.shade600,
      'TE': Colors.purple.shade600,
    };
    
    _applyFilters();
  }

  String _getPositionFromPlayerId(String playerId) {
    // Look through position rankings to find this player's position
    for (final entry in widget.bigBoard.positionRankings.entries) {
      final positionRanking = entry.value;
      if (positionRanking.playerRanks.any((p) => p.playerId == playerId)) {
        return entry.key.toUpperCase();
      }
    }
    return '';
  }

  void _applyFilters() {
    var players = List<CustomPlayerRank>.from(widget.bigBoard.aggregatedPlayers);
    
    // Position filter
    if (_selectedPosition != 'All') {
      players = players.where((player) {
        final position = _getPositionFromPlayerId(player.playerId);
        return position == _selectedPosition;
      }).toList();
    }
    
    // Sort players
    switch (_sortBy) {
      case 'vorp':
        players.sort((a, b) => _sortAscending 
            ? a.vorp.compareTo(b.vorp)
            : b.vorp.compareTo(a.vorp));
        break;
      case 'projectedPoints':
        players.sort((a, b) => _sortAscending 
            ? a.projectedPoints.compareTo(b.projectedPoints)
            : b.projectedPoints.compareTo(a.projectedPoints));
        break;
      case 'alphabetical':
        players.sort((a, b) => _sortAscending
            ? a.playerName.compareTo(b.playerName)
            : b.playerName.compareTo(a.playerName));
        break;
    }
    
    setState(() {
      _filteredPlayers = players;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        titleWidget: Text(widget.bigBoard.name),
        actions: [
          // Export button
          PopupMenuButton<String>(
            icon: const Icon(Icons.download),
            onSelected: _exportBigBoard,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'csv',
                child: Row(
                  children: [
                    Icon(Icons.table_chart),
                    SizedBox(width: 8),
                    Text('Export to CSV'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'json',
                child: Row(
                  children: [
                    Icon(Icons.code),
                    SizedBox(width: 8),
                    Text('Export to JSON'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterBar(),
          _buildStatsHeader(),
          Expanded(child: _buildBigBoardList()),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          // Position filter
          Expanded(
            child: DropdownButtonFormField<String>(
              value: _selectedPosition,
              decoration: const InputDecoration(
                labelText: 'Position',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: _availablePositions.map((position) {
                return DropdownMenuItem(
                  value: position,
                  child: Text(position),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedPosition = value ?? 'All';
                });
                _applyFilters();
              },
            ),
          ),
          const SizedBox(width: 16),
          
          // Sort dropdown
          Expanded(
            child: DropdownButtonFormField<String>(
              value: _sortBy,
              decoration: const InputDecoration(
                labelText: 'Sort By',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: const [
                DropdownMenuItem(value: 'vorp', child: Text('VORP')),
                DropdownMenuItem(value: 'projectedPoints', child: Text('Projected Points')),
                DropdownMenuItem(value: 'alphabetical', child: Text('Name')),
              ],
              onChanged: (value) {
                setState(() {
                  _sortBy = value ?? 'vorp';
                  // Auto-set logical sort direction
                  if (value == 'alphabetical') {
                    _sortAscending = true;
                  } else {
                    _sortAscending = false; // VORP and Points should be highest first
                  }
                });
                _applyFilters();
              },
            ),
          ),
          const SizedBox(width: 16),
          
          // Sort direction toggle
          IconButton(
            onPressed: () {
              setState(() {
                _sortAscending = !_sortAscending;
              });
              _applyFilters();
            },
            icon: Icon(
              _sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
              color: ThemeConfig.darkNavy,
            ),
            tooltip: _sortAscending ? 'Ascending' : 'Descending',
          ),
          
          // Display options
          PopupMenuButton<String>(
            icon: const Icon(Icons.settings),
            onSelected: _handleDisplayOption,
            itemBuilder: (context) => [
              CheckedPopupMenuItem(
                value: 'showVORPTiers',
                checked: _showVORPTiers,
                child: const Text('Show VORP Tiers'),
              ),
              CheckedPopupMenuItem(
                value: 'showProjectedPoints',
                checked: _showProjectedPoints,
                child: const Text('Show Projected Points'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsHeader() {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            ThemeConfig.darkNavy.withValues(alpha: 0.1),
            ThemeConfig.gold.withValues(alpha: 0.1),
          ],
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.dashboard,
            size: 32,
            color: ThemeConfig.darkNavy,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Custom Big Board',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${_filteredPlayers.length} players • ${_availablePositions.length - 1} positions • Created ${_formatDate(widget.bigBoard.createdAt)}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          // VORP stats
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Top VORP: ${_getTopVORP()}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: ThemeConfig.successGreen,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Avg VORP: ${_getAverageVORP()}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBigBoardList() {
    if (_filteredPlayers.isEmpty) {
      return const Center(
        child: Text(
          'No players match the selected filters.',
          style: TextStyle(fontSize: 16),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredPlayers.length,
      itemBuilder: (context, index) => _buildPlayerCard(index, _filteredPlayers[index]),
    );
  }

  Widget _buildPlayerCard(int index, CustomPlayerRank player) {
    final theme = Theme.of(context);
    final position = _getPositionFromPlayerId(player.playerId);
    final positionColor = _positionColors[position] ?? Colors.grey.shade600;
    final vorpTier = _getVORPTier(player.vorp);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Rank
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      positionColor,
                      positionColor.withValues(alpha: 0.7),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              
              // Player info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        TeamLogoUtils.buildNFLTeamLogo(player.team, size: 24),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            player.playerName,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: positionColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            position,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        if (_showProjectedPoints) ...[
                          Icon(Icons.sports_football, size: 16, color: Colors.grey.shade600),
                          const SizedBox(width: 4),
                          Text(
                            '${player.projectedPoints.toStringAsFixed(1)} pts',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.grey.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 16),
                        ],
                        Icon(Icons.trending_up, size: 16, color: Colors.grey.shade600),
                        const SizedBox(width: 4),
                        Text(
                          'VORP: ${player.vorp >= 0 ? '+' : ''}${player.vorp.toStringAsFixed(1)}',
                          style: TextStyle(
                            color: player.vorp >= 0 ? ThemeConfig.successGreen : Colors.red.shade600,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (_showVORPTiers) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: _getVORPTierColor(vorpTier),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              vorpTier,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getVORPTier(double vorp) {
    if (vorp >= 15.0) return 'Elite';
    if (vorp >= 10.0) return 'High';
    if (vorp >= 5.0) return 'Good';
    if (vorp >= 0.0) return 'Above Avg';
    if (vorp >= -5.0) return 'Below Avg';
    return 'Poor';
  }

  Color _getVORPTierColor(String tier) {
    switch (tier) {
      case 'Elite': return Colors.purple.shade600;
      case 'High': return Colors.green.shade600;
      case 'Good': return Colors.blue.shade600;
      case 'Above Avg': return Colors.orange.shade600;
      case 'Below Avg': return Colors.red.shade400;
      case 'Poor': return Colors.grey.shade600;
      default: return Colors.grey.shade600;
    }
  }

  String _getTopVORP() {
    if (_filteredPlayers.isEmpty) return '0.0';
    final topVORP = _filteredPlayers.map((p) => p.vorp).reduce((a, b) => a > b ? a : b);
    return topVORP >= 0 ? '+${topVORP.toStringAsFixed(1)}' : topVORP.toStringAsFixed(1);
  }

  String _getAverageVORP() {
    if (_filteredPlayers.isEmpty) return '0.0';
    final avgVORP = _filteredPlayers.map((p) => p.vorp).reduce((a, b) => a + b) / _filteredPlayers.length;
    return avgVORP >= 0 ? '+${avgVORP.toStringAsFixed(1)}' : avgVORP.toStringAsFixed(1);
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }

  void _handleDisplayOption(String option) {
    setState(() {
      switch (option) {
        case 'showVORPTiers':
          _showVORPTiers = !_showVORPTiers;
          break;
        case 'showProjectedPoints':
          _showProjectedPoints = !_showProjectedPoints;
          break;
      }
    });
  }

  Future<void> _exportBigBoard(String format) async {
    try {
      // Create export data
      final exportData = _filteredPlayers.asMap().entries.map((entry) {
        final index = entry.key;
        final player = entry.value;
        final position = _getPositionFromPlayerId(player.playerId);
        
        return {
          'rank': index + 1,
          'player_name': player.playerName,
          'team': player.team,
          'position': position,
          'projected_points': player.projectedPoints,
          'vorp': player.vorp,
          'vorp_tier': _getVORPTier(player.vorp),
        };
      }).toList();

      switch (format) {
        case 'csv':
          final csvContent = _generateCSV(exportData);
          // TODO: Implement actual file download
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('CSV export ready (download feature in development)'),
              backgroundColor: Colors.green,
            ),
          );
          break;
          
        case 'json':
          // TODO: Implement JSON export
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('JSON export ready (download feature in development)'),
              backgroundColor: Colors.green,
            ),
          );
          break;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _generateCSV(List<Map<String, dynamic>> data) {
    if (data.isEmpty) return '';
    
    // Header
    final headers = data.first.keys.join(',');
    
    // Rows
    final rows = data.map((row) {
      return row.values.map((value) => '"$value"').join(',');
    }).join('\n');
    
    return '$headers\n$rows';
  }
}