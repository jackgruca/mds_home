import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../widgets/common/custom_app_bar.dart';
import '../widgets/common/top_nav_bar.dart';
import '../services/hybrid_data_service.dart';
import '../services/game_level_data_service.dart';
import '../widgets/rankings/filter_panel.dart';
import '../services/rankings/filter_service.dart';

class ComprehensiveQBAnalyticsScreen extends StatefulWidget {
  const ComprehensiveQBAnalyticsScreen({super.key});

  @override
  State<ComprehensiveQBAnalyticsScreen> createState() => _ComprehensiveQBAnalyticsScreenState();
}

class _ComprehensiveQBAnalyticsScreenState extends State<ComprehensiveQBAnalyticsScreen>
    with TickerProviderStateMixin {
  final HybridDataService _dataService = HybridDataService();
  final GameLevelDataService _gameDataService = GameLevelDataService();
  
  bool _isLoading = true;
  List<Map<String, dynamic>> _qbData = [];
  List<int> _availableSeasons = [];
  List<int> _selectedSeasons = [2024]; // Default to 2024
  
  // Sorting state
  String _sortColumn = 'passer_rating';
  bool _sortAscending = false;
  
  // Filter state
  bool _showFilterPanel = false;
  FilterQuery _currentFilter = const FilterQuery();
  bool _usingFilters = false;
  List<Map<String, dynamic>> _originalData = [];
  
  late TabController _tabController;

  // Define the 5 comprehensive QB data sections
  final List<Map<String, dynamic>> _dataSections = [
    {
      'id': 'core',
      'title': '🎯 Core Performance',
      'subtitle': 'Essential passing statistics',
      'color': Colors.blue,
      'icon': Icons.sports_football,
      'fields': [
        {'key': 'player_display_name', 'label': 'Player', 'type': 'string', 'width': 180.0},
        {'key': 'recent_team', 'label': 'Team', 'type': 'string', 'width': 60.0},
        {'key': 'games', 'label': 'G', 'type': 'int', 'width': 40.0},
        {'key': 'attempts', 'label': 'Att', 'type': 'int', 'width': 60.0},
        {'key': 'completions', 'label': 'Comp', 'type': 'int', 'width': 60.0},
        {'key': 'completion_percentage', 'label': 'Comp%', 'type': 'percentage', 'width': 70.0},
        {'key': 'passing_yards', 'label': 'Pass Yds', 'type': 'int', 'width': 80.0},
        {'key': 'passing_yards_per_attempt', 'label': 'YPA', 'type': 'decimal', 'width': 60.0},
        {'key': 'passing_tds', 'label': 'Pass TD', 'type': 'int', 'width': 70.0},
        {'key': 'interceptions', 'label': 'INT', 'type': 'int', 'width': 50.0},
        {'key': 'passer_rating', 'label': 'Rating', 'type': 'decimal', 'width': 70.0},
        {'key': 'sacks', 'label': 'Sacks', 'type': 'int', 'width': 60.0},
        {'key': 'sack_yards', 'label': 'Sack Yds', 'type': 'int', 'width': 70.0},
      ]
    },
    {
      'id': 'nextgen',
      'title': '⚡ NextGen Analytics',
      'subtitle': 'Advanced passing metrics',
      'color': Colors.purple,
      'icon': Icons.speed,
      'fields': [
        {'key': 'player_display_name', 'label': 'Player', 'type': 'string', 'width': 180.0},
        {'key': 'recent_team', 'label': 'Team', 'type': 'string', 'width': 60.0},
        {'key': 'completion_percentage_above_expectation', 'label': 'CPOE', 'type': 'decimal', 'width': 70.0},
        {'key': 'aggressiveness', 'label': 'Aggr%', 'type': 'percentage', 'width': 70.0},
        {'key': 'avg_time_to_throw', 'label': 'Time/Throw', 'type': 'decimal', 'width': 90.0},
        {'key': 'avg_intended_air_yards', 'label': 'Int Air Yds', 'type': 'decimal', 'width': 100.0},
        {'key': 'avg_completed_air_yards', 'label': 'Comp Air Yds', 'type': 'decimal', 'width': 110.0},
        {'key': 'avg_air_yards_differential', 'label': 'Air Yds Diff', 'type': 'decimal', 'width': 100.0},
        {'key': 'max_completed_air_distance', 'label': 'Max Air Dist', 'type': 'decimal', 'width': 100.0},
        {'key': 'avg_air_distance', 'label': 'Avg Air Dist', 'type': 'decimal', 'width': 100.0},
        {'key': 'air_yards_share', 'label': 'Air Yds%', 'type': 'percentage', 'width': 80.0},
      ]
    },
    {
      'id': 'dualthreat',
      'title': '🏃 Dual-Threat Metrics',
      'subtitle': 'Rushing & mobility stats',
      'color': Colors.green,
      'icon': Icons.directions_run,
      'fields': [
        {'key': 'player_display_name', 'label': 'Player', 'type': 'string', 'width': 180.0},
        {'key': 'recent_team', 'label': 'Team', 'type': 'string', 'width': 60.0},
        {'key': 'rushing_attempts', 'label': 'Rush Att', 'type': 'int', 'width': 80.0},
        {'key': 'rushing_yards', 'label': 'Rush Yds', 'type': 'int', 'width': 80.0},
        {'key': 'rushing_yards_per_attempt', 'label': 'Rush YPA', 'type': 'decimal', 'width': 80.0},
        {'key': 'rushing_tds', 'label': 'Rush TD', 'type': 'int', 'width': 70.0},
        {'key': 'rush_efficiency', 'label': 'Rush Eff', 'type': 'decimal', 'width': 80.0},
        {'key': 'rush_yards_over_expected', 'label': 'RYOE', 'type': 'decimal', 'width': 70.0},
        {'key': 'rush_pct_over_expected', 'label': 'RYOE%', 'type': 'percentage', 'width': 80.0},
        {'key': 'yards_per_carry', 'label': 'YPC', 'type': 'decimal', 'width': 60.0},
        {'key': 'yards_per_touch', 'label': 'YPT', 'type': 'decimal', 'width': 60.0},
      ]
    },
    {
      'id': 'situational',
      'title': '🎬 Situational Analytics',
      'subtitle': 'Context & situational metrics',
      'color': Colors.orange,
      'icon': Icons.analytics,
      'fields': [
        {'key': 'player_display_name', 'label': 'Player', 'type': 'string', 'width': 180.0},
        {'key': 'recent_team', 'label': 'Team', 'type': 'string', 'width': 60.0},
        {'key': 'avg_air_yards_to_sticks', 'label': 'Air/Sticks', 'type': 'decimal', 'width': 90.0},
        {'key': 'avg_depth_of_target', 'label': 'Avg DOT', 'type': 'decimal', 'width': 80.0},
        {'key': 'passing_tds_per_attempt', 'label': 'TD Rate', 'type': 'percentage', 'width': 80.0},
        {'key': 'sack_yards', 'label': 'Sack Yds', 'type': 'int', 'width': 80.0},
        {'key': 'wopr', 'label': 'WOPR', 'type': 'decimal', 'width': 70.0},
      ]
    },
    {
      'id': 'fantasy',
      'title': '🏆 Fantasy & Scoring',
      'subtitle': 'Fantasy football impact',
      'color': Colors.red,
      'icon': Icons.emoji_events,
      'fields': [
        {'key': 'player_display_name', 'label': 'Player', 'type': 'string', 'width': 180.0},
        {'key': 'recent_team', 'label': 'Team', 'type': 'string', 'width': 60.0},
        {'key': 'fantasy_points_ppr', 'label': 'PPR Pts', 'type': 'decimal', 'width': 80.0},
        {'key': 'fantasy_points_ppr_per_game', 'label': 'PPR/Game', 'type': 'decimal', 'width': 90.0},
        {'key': 'fantasy_points', 'label': 'Std Pts', 'type': 'decimal', 'width': 80.0},
        {'key': 'fantasy_points_per_game', 'label': 'Std/Game', 'type': 'decimal', 'width': 90.0},
        {'key': 'passing_tds', 'label': 'Pass TD', 'type': 'int', 'width': 70.0},
        {'key': 'rushing_tds', 'label': 'Rush TD', 'type': 'int', 'width': 70.0},
        {'key': 'interceptions', 'label': 'INT', 'type': 'int', 'width': 50.0},
        {'key': 'passing_yards', 'label': 'Pass Yds', 'type': 'int', 'width': 80.0},
        {'key': 'rushing_yards', 'label': 'Rush Yds', 'type': 'int', 'width': 80.0},
      ]
    },
    {
      'id': 'gamelogs',
      'title': '📋 Game Logs',
      'subtitle': 'Game-by-game performance tracking',
      'color': Colors.teal,
      'icon': Icons.timeline,
      'fields': [
        {'key': 'player_display_name', 'label': 'Player', 'type': 'string', 'width': 180.0},
        {'key': 'recent_team', 'label': 'Team', 'type': 'string', 'width': 60.0},
        {'key': 'games', 'label': 'Games', 'type': 'int', 'width': 60.0},
        {'key': 'last_5_avg_fantasy', 'label': 'L5 Avg', 'type': 'decimal', 'width': 80.0},
        {'key': 'best_game_fantasy', 'label': 'Best Game', 'type': 'decimal', 'width': 90.0},
        {'key': 'consistency_score', 'label': 'Consistency', 'type': 'decimal', 'width': 90.0},
        {'key': 'games_15_plus', 'label': '15+ Games', 'type': 'int', 'width': 80.0},
        {'key': 'games_20_plus', 'label': '20+ Games', 'type': 'int', 'width': 80.0},
        {'key': 'home_avg', 'label': 'Home Avg', 'type': 'decimal', 'width': 80.0},
        {'key': 'away_avg', 'label': 'Away Avg', 'type': 'decimal', 'width': 80.0},
      ]
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _dataSections.length, vsync: this);
    _loadQBData();
  }

  Future<void> _loadQBData() async {
    setState(() => _isLoading = true);
    
    try {
      // Load available seasons first
      _availableSeasons = await _dataService.getAvailableSeasons();
      
      // Load QB data with CSV performance for selected seasons
      final allQBs = await _dataService.getPlayerStats(
        position: 'QB',
        seasons: _selectedSeasons,
        orderBy: _sortColumn,
        descending: !_sortAscending,
      );
      
      // Filter for minimum attempts (50+ for current season, 200+ for multi-season)
      final minAttempts = _selectedSeasons.length == 1 ? 50 : 200;
      final filteredData = allQBs
          .where((qb) => (qb['attempts'] ?? 0) >= minAttempts)
          .toList();
      
      _originalData = List<Map<String, dynamic>>.from(filteredData);
      
      // Enhance with game log data for 2024 season only (to avoid performance issues)
      if (_selectedSeasons.contains(2024)) {
        await _enhanceWithGameLogData(filteredData);
      }
      
      // Apply filters if enabled
      _qbData = _usingFilters 
          ? FilterService.applyFilters(filteredData, _currentFilter)
          : filteredData;
      
      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint('Error loading QB data: $e');
    }
  }

  /// Enhance QB data with game log metrics
  Future<void> _enhanceWithGameLogData(List<Map<String, dynamic>> qbData) async {
    try {
      for (final qb in qbData) {
        final playerId = qb['player_id']?.toString();
        if (playerId == null) continue;
        
        // Clean player ID by removing suffix (e.g., "00-0033553_2024" -> "00-0033553")
        String cleanPlayerId = playerId;
        if (cleanPlayerId.contains('_')) {
          cleanPlayerId = cleanPlayerId.split('_').first;
        }
        
        // Get game logs for this player
        final gameLogs = await _gameDataService.getPlayerGameLogs(cleanPlayerId);
        
        if (gameLogs.isNotEmpty) {
          // Calculate game log metrics
          final fantasyPoints = gameLogs
              .map((game) => (game['fantasy_points_ppr'] as num?) ?? 0.0)
              .where((points) => points > 0)
              .toList();
          
          final homeGames = gameLogs.where((game) => game['home_away'] == 'Home').toList();
          final awayGames = gameLogs.where((game) => game['home_away'] == 'Away').toList();
          
          // Last 5 games average
          final last5Games = gameLogs.length > 5 ? fantasyPoints.take(5).toList() : fantasyPoints;
          final last5Avg = last5Games.isNotEmpty 
              ? last5Games.reduce((a, b) => a + b) / last5Games.length 
              : 0.0;
          
          // Best game
          final bestGame = fantasyPoints.isNotEmpty ? fantasyPoints.reduce((a, b) => a > b ? a : b) : 0.0;
          
          // Consistency (standard deviation)
          final mean = fantasyPoints.isNotEmpty ? fantasyPoints.reduce((a, b) => a + b) / fantasyPoints.length : 0.0;
          final variance = fantasyPoints.isNotEmpty 
              ? fantasyPoints.map((x) => (x - mean) * (x - mean)).reduce((a, b) => a + b) / fantasyPoints.length
              : 0.0;
          final consistency = mean > 0 ? (mean / (variance > 0 ? variance : 1)) * 10 : 0.0; // Scaled consistency score
          
          // High-scoring games
          final games15Plus = fantasyPoints.where((points) => points >= 15.0).length;
          final games20Plus = fantasyPoints.where((points) => points >= 20.0).length;
          
          // Home/Away averages
          final homePoints = homeGames.map((game) => (game['fantasy_points_ppr'] as num?) ?? 0.0).where((p) => p > 0);
          final awayPoints = awayGames.map((game) => (game['fantasy_points_ppr'] as num?) ?? 0.0).where((p) => p > 0);
          
          final homeAvg = homePoints.isNotEmpty ? homePoints.reduce((a, b) => a + b) / homePoints.length : 0.0;
          final awayAvg = awayPoints.isNotEmpty ? awayPoints.reduce((a, b) => a + b) / awayPoints.length : 0.0;
          
          // Add game log metrics to QB data
          qb['last_5_avg_fantasy'] = double.parse(last5Avg.toStringAsFixed(1));
          qb['best_game_fantasy'] = double.parse(bestGame.toStringAsFixed(1));
          qb['consistency_score'] = double.parse(consistency.toStringAsFixed(1));
          qb['games_15_plus'] = games15Plus;
          qb['games_20_plus'] = games20Plus;
          qb['home_avg'] = double.parse(homeAvg.toStringAsFixed(1));
          qb['away_avg'] = double.parse(awayAvg.toStringAsFixed(1));
        } else {
          // Set default values if no game logs found
          qb['last_5_avg_fantasy'] = 0.0;
          qb['best_game_fantasy'] = 0.0;
          qb['consistency_score'] = 0.0;
          qb['games_15_plus'] = 0;
          qb['games_20_plus'] = 0;
          qb['home_avg'] = 0.0;
          qb['away_avg'] = 0.0;
        }
      }
    } catch (e) {
      debugPrint('Error enhancing with game log data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        titleWidget: Text('🎯 Comprehensive QB Analytics'),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              const TopNavBarContent(),
              
              if (_isLoading)
                const Expanded(
                  child: Center(child: CircularProgressIndicator()),
                )
              else
                Expanded(
                  child: Column(
                    children: [
                      // Analytics header
                      _buildAnalyticsHeader(),
                      
                      // Tab bar for different sections
                      _buildSectionTabs(),
                      
                      // Data table content
                      Expanded(
                        child: TabBarView(
                          controller: _tabController,
                          children: _dataSections.map((section) => 
                            _buildDataTable(section)
                          ).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          // Filter panel overlay
          if (_showFilterPanel)
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: FilterPanel(
                currentQuery: _currentFilter,
                onFilterChanged: _onFilterChanged,
                onClose: _toggleFilterPanel,
                isVisible: _showFilterPanel,
                availableTeams: FilterService.getAvailableTeams(_originalData),
                availableSeasons: FilterService.getAvailableSeasons(_originalData),
                statFields: _getFilterableStatFields(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.blue.shade700,
            Colors.purple.shade600,
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.table_chart, size: 32, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Comprehensive QB Data Tables',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      '${_qbData.length} Qualified QBs • 61+ Statistical Fields',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Season selector and filter button row
          Row(
            children: [
              // Season dropdown
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white.withOpacity(0.3)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: null, // Always null to prevent dropdown value conflicts
                    hint: Text(
                      _selectedSeasons.length == 1 
                          ? _selectedSeasons.first.toString() 
                          : 'Multiple (${_selectedSeasons.length})',
                      style: const TextStyle(color: Colors.white),
                    ),
                    dropdownColor: Colors.blue.shade700,
                    style: const TextStyle(color: Colors.white),
                    iconEnabledColor: Colors.white,
                    items: [
                      ..._availableSeasons.map((season) => DropdownMenuItem<String>(
                        value: season.toString(),
                        child: StatefulBuilder(
                          builder: (context, setDropdownState) {
                            final isSelected = _selectedSeasons.contains(season);
                            return InkWell(
                              onTap: () {
                                setState(() {
                                  if (isSelected) {
                                    _selectedSeasons.remove(season);
                                    if (_selectedSeasons.isEmpty) {
                                      _selectedSeasons.add(2024);
                                    }
                                  } else {
                                    _selectedSeasons.add(season);
                                  }
                                });
                                _loadQBData();
                                // Don't close dropdown immediately
                                Navigator.of(context).pop();
                              },
                              child: Row(
                                children: [
                                  Checkbox(
                                    value: isSelected,
                                    onChanged: (bool? value) {
                                      setState(() {
                                        if (value == true) {
                                          _selectedSeasons.add(season);
                                        } else {
                                          _selectedSeasons.remove(season);
                                          if (_selectedSeasons.isEmpty) {
                                            _selectedSeasons.add(2024);
                                          }
                                        }
                                      });
                                      _loadQBData();
                                    },
                                    activeColor: Colors.white,
                                    checkColor: Colors.blue.shade700,
                                  ),
                                  Text(
                                    season.toString(),
                                    style: TextStyle(
                                      color: isSelected ? Colors.white : Colors.white.withOpacity(0.7),
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      )),
                      DropdownMenuItem<String>(
                        value: 'select_all',
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              _selectedSeasons = List.from(_availableSeasons);
                            });
                            _loadQBData();
                            Navigator.of(context).pop();
                          },
                          child: const Row(
                            children: [
                              Icon(Icons.select_all, color: Colors.white, size: 20),
                              SizedBox(width: 8),
                              Text('Select All', style: TextStyle(color: Colors.white)),
                            ],
                          ),
                        ),
                      ),
                    ],
                    onChanged: (String? value) {
                      // Handle selection logic in individual item taps
                    },
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Season display text
              Expanded(
                child: Text(
                  _selectedSeasons.length == 1 
                      ? 'Season: ${_selectedSeasons.first}'
                      : 'Seasons: ${_selectedSeasons.join(', ')}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 12),
              // Filter button
              ElevatedButton.icon(
                onPressed: _toggleFilterPanel,
                icon: Icon(
                  _showFilterPanel ? Icons.close : Icons.filter_list,
                  size: 20,
                ),
                label: Text(_showFilterPanel ? 'Close' : 'Filter'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _currentFilter.hasActiveFilters 
                      ? Colors.orange 
                      : Colors.white,
                  foregroundColor: _currentFilter.hasActiveFilters 
                      ? Colors.white 
                      : Colors.blue.shade700,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }


  Widget _buildSectionTabs() {
    return Container(
      color: Theme.of(context).cardColor,
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        tabs: _dataSections.map((section) => Tab(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(section['icon'], size: 16),
              const SizedBox(width: 8),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    section['title'],
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    section['subtitle'],
                    style: const TextStyle(fontSize: 10),
                  ),
                ],
              ),
            ],
          ),
        )).toList(),
      ),
    );
  }

  Widget _buildDataTable(Map<String, dynamic> section) {
    final fields = section['fields'] as List<Map<String, dynamic>>;
    final sectionColor = section['color'] as Color;
    
    return Padding(
      padding: const EdgeInsets.all(16),
      child: AnimationLimiter(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SingleChildScrollView(
              child: DataTable(
                      columnSpacing: 16,
                      sortColumnIndex: fields.indexWhere((f) => f['key'] == _sortColumn) != -1 
                          ? fields.indexWhere((f) => f['key'] == _sortColumn) 
                          : null,
                      sortAscending: _sortAscending,
                      columns: fields.map((field) => DataColumn(
                        label: SizedBox(
                          width: field['width'],
                          child: Text(
                            field['label'],
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        onSort: field['type'] != 'string' ? (columnIndex, ascending) {
                          _sortData(field['key'], ascending);
                        } : null,
                      )).toList(),
                      rows: _qbData.take(50).map((qb) { // Limit to top 50 for performance
                        return DataRow(
                          cells: fields.map((field) {
                            final value = qb[field['key']];
                            return DataCell(
                              Container(
                                width: field['width'],
                                child: field['key'] == 'player_display_name' && qb['player_id'] != null
                                  ? InkWell(
                                      onTap: () {
                                        // Clean player ID by removing suffix
                                        String cleanPlayerId = qb['player_id'].toString();
                                        if (cleanPlayerId.contains('_')) {
                                          cleanPlayerId = cleanPlayerId.split('_').first;
                                        }
                                        
                                        Navigator.pushNamed(
                                          context,
                                          '/player-profile',
                                          arguments: {
                                            'playerId': cleanPlayerId,
                                            'playerName': value?.toString() ?? '',
                                          },
                                        );
                                      },
                                      child: Text(
                                        _formatFieldValue(value, field['type']),
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.blue.shade600,
                                          decoration: TextDecoration.underline,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    )
                                  : Text(
                                      _formatFieldValue(value, field['type']),
                                      style: const TextStyle(fontSize: 11),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                              ),
                            );
                          }).toList(),
                        );
                      }).toList(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _sortData(String column, bool ascending) {
    setState(() {
      _sortColumn = column;
      _sortAscending = ascending;
      
      _qbData.sort((a, b) {
        final aVal = a[column];
        final bVal = b[column];
        
        if (aVal == null && bVal == null) return 0;
        if (aVal == null) return ascending ? -1 : 1;
        if (bVal == null) return ascending ? 1 : -1;
        
        if (aVal is num && bVal is num) {
          return ascending ? aVal.compareTo(bVal) : bVal.compareTo(aVal);
        }
        
        return ascending 
          ? aVal.toString().compareTo(bVal.toString())
          : bVal.toString().compareTo(aVal.toString());
      });
    });
  }

  String _formatFieldValue(dynamic value, String type) {
    if (value == null) return '-';
    
    switch (type) {
      case 'string':
        return value.toString();
      case 'int':
        return value.toString();
      case 'decimal':
        if (value is num) {
          return value.toStringAsFixed(1);
        }
        return value.toString();
      case 'percentage':
        if (value is num) {
          return '${value.toStringAsFixed(1)}%';
        }
        return value.toString();
      default:
        return value.toString();
    }
  }

  void _toggleFilterPanel() {
    setState(() {
      _showFilterPanel = !_showFilterPanel;
    });
  }

  void _onFilterChanged(FilterQuery newQuery) {
    setState(() {
      _currentFilter = newQuery;
      _usingFilters = newQuery.hasActiveFilters;
      
      // Apply filters to original data
      _qbData = _usingFilters 
          ? FilterService.applyFilters(_originalData, _currentFilter)
          : _originalData;
    });
  }

  Map<String, Map<String, dynamic>> _getFilterableStatFields() {
    final allFields = <String, Map<String, dynamic>>{};
    for (final section in _dataSections) {
      final fields = section['fields'] as List<Map<String, dynamic>>;
      for (final field in fields) {
        if (field['type'] != 'string') {
          allFields[field['key']] = {
            'name': field['label'],
            'format': field['type'],
          };
        }
      }
    }
    return allFields;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}