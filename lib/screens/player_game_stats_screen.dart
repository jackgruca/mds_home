import 'package:flutter/material.dart';
import 'package:mds_home/widgets/common/app_drawer.dart';
import 'package:mds_home/widgets/common/top_nav_bar.dart';
import 'package:mds_home/widgets/common/custom_app_bar.dart';
import 'package:mds_home/widgets/auth/auth_dialog.dart';
import 'package:mds_home/services/player_game_stats_service.dart';
import 'package:mds_home/widgets/design_system/mds_table.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:mds_home/services/player_data_service.dart';
import 'package:mds_home/models/player_info.dart';
import 'players/player_detail_screen.dart';

// Enum for Query Operators
enum QueryOperator {
  equals,
  notEquals,
  greaterThan,
  greaterThanOrEquals,
  lessThan,
  lessThanOrEquals,
  contains,
  startsWith,
  endsWith
}

// Helper to convert QueryOperator to a display string
String queryOperatorToString(QueryOperator op) {
  switch (op) {
    case QueryOperator.equals:
      return '==';
    case QueryOperator.notEquals:
      return '!=';
    case QueryOperator.greaterThan:
      return '>';
    case QueryOperator.greaterThanOrEquals:
      return '>=';
    case QueryOperator.lessThan:
      return '<';
    case QueryOperator.lessThanOrEquals:
      return '<=';
    case QueryOperator.contains:
      return 'Contains';
    case QueryOperator.startsWith:
      return 'Starts With';
    case QueryOperator.endsWith:
      return 'Ends With';
  }
}

// Class to represent a single query condition
class QueryCondition {
  final String field;
  final QueryOperator operator;
  final String value;

  QueryCondition(
      {required this.field, required this.operator, required this.value});

  @override
  String toString() {
    return '$field ${queryOperatorToString(operator)} "$value"';
  }
}

class PlayerGameStatsScreen extends StatefulWidget {
  const PlayerGameStatsScreen({super.key});

  @override
  State<PlayerGameStatsScreen> createState() =>
      _PlayerGameStatsScreenState();
}

class _PlayerGameStatsScreenState extends State<PlayerGameStatsScreen>
    with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  String? _error;
  List<PlayerGameStats> _allStats = [];
  List<Map<String, dynamic>> _rawRows = [];
  int _totalRecords = 0;
  
  final PlayerGameStatsService _service = PlayerGameStatsService();
  final PlayerDataService _playerDataService = PlayerDataService();
  bool _isPlayerDataLoading = true;
  List<PlayerInfo> _allPlayers = [];

  // Pagination state
  int _currentPage = 0;
  static const int _rowsPerPage = 25;
  

  // Sort state
  String _sortColumn = 'game_date';
  bool _sortAscending = false;

  // Position Filter
  String _selectedPosition = 'All';
  final List<String> _positions = ['All', 'QB', 'RB', 'WR', 'TE'];
  
  // Season Filter
  String _selectedSeason = 'All';
  List<String> _seasons = ['All'];
  
  // Team Filter
  String _selectedTeam = 'All';
  final List<String> _teams = [
    'All', 'ARI', 'ATL', 'BAL', 'BUF', 'CAR', 'CHI', 'CIN', 'CLE', 'DAL', 'DEN', 
    'DET', 'GB', 'HOU', 'IND', 'JAX', 'KC', 'LV', 'LAC', 'LAR', 'MIA', 'MIN', 
    'NE', 'NO', 'NYG', 'NYJ', 'PHI', 'PIT', 'SF', 'SEA', 'TB', 'TEN', 'WAS'
  ];
  
  // Week Filter
  String _selectedWeek = 'All';
  List<String> _weeks = ['All'];
  
  // Tab controller for Basic/Advanced/Visualizations
  late TabController _tabController;
  
  // Position-aware filtering state
  bool _showAllPositionsInTab = false;
  
  // Position helpers are unused in mock data view; removing to satisfy lints

  List<String> _headers = [];
  List<String> _selectedFields = [];

  // State for Query Builder
  final List<QueryCondition> _queryConditions = [];
  String? _newQueryField;
  QueryOperator? _newQueryOperator;
  final TextEditingController _newQueryValueController =
      TextEditingController();
  bool _isQueryBuilderExpanded = false;

  // Field groups for tabbed view - organized by position with Basic/Advanced/Visualizations structure
  static final Map<String, Map<String, List<String>>> _statCategoryFieldGroups = {
    'QB Games': {
      'Basic': ['player_name', 'team', 'opponent', 'week', 'completions', 'attempts', 'passing_yards', 'passing_tds', 'interceptions', 'sacks', 'carries', 'rushing_yards', 'rushing_tds', 'fantasy_points', 'fantasy_points_ppr'],
      'Advanced': ['player_name', 'team', 'week', 'completion_percentage', 'yards_per_attempt', 'passing_epa', 'avg_time_to_throw', 'avg_completed_air_yards', 'cpoe', 'aggressiveness', 'total_epa'],
      'Visualizations': ['player_name', 'team', 'week', 'passing_yards', 'passing_tds', 'rushing_yards', 'fantasy_points', 'completion_percentage', 'total_epa']
    },
    'RB Games': {
      'Basic': ['player_name', 'team', 'opponent', 'week', 'carries', 'rushing_yards', 'rushing_tds', 'yards_per_carry', 'targets', 'receptions', 'receiving_yards', 'receiving_tds', 'touches', 'fantasy_points', 'fantasy_points_ppr'],
      'Advanced': ['player_name', 'team', 'week', 'yards_per_carry', 'yards_per_touch', 'rushing_epa', 'receiving_epa', 'rush_efficiency', 'rush_yards_over_expected', 'avg_time_to_los', 'catch_rate', 'total_epa'],
      'Visualizations': ['player_name', 'team', 'week', 'rushing_yards', 'rushing_tds', 'receiving_yards', 'total_yards', 'fantasy_points', 'touches']
    },
    'WR/TE Games': {
      'Basic': ['player_name', 'position', 'team', 'opponent', 'week', 'targets', 'receptions', 'receiving_yards', 'receiving_tds', 'yards_per_reception', 'catch_rate', 'fantasy_points', 'fantasy_points_ppr'],
      'Advanced': ['player_name', 'position', 'team', 'week', 'catch_rate', 'yards_per_reception', 'receiving_epa', 'avg_separation', 'avg_cushion', 'avg_yac_above_expectation', 'catch_percentage', 'total_epa'],
      'Visualizations': ['player_name', 'position', 'team', 'week', 'receiving_yards', 'receiving_tds', 'targets', 'receptions', 'fantasy_points', 'yards_per_reception']
    },
    'Fantasy Focus': {
      'Basic': ['player_name', 'position', 'team', 'opponent', 'week', 'fantasy_points', 'fantasy_points_ppr', 'total_yards', 'total_tds', 'touches'],
      'Advanced': ['player_name', 'position', 'team', 'week', 'touches', 'yards_per_touch', 'total_epa', 'passing_epa', 'rushing_epa', 'receiving_epa'],
      'Visualizations': ['player_name', 'position', 'team', 'week', 'fantasy_points', 'fantasy_points_ppr', 'total_yards', 'total_tds', 'touches']
    },
    'Custom': {
      'Basic': [],
      'Advanced': [],
      'Visualizations': []
    }
  };
  
  String _selectedStatCategory = 'QB Games';
  String _selectedSubCategory = 'Basic';

  // All operators for query
  final List<QueryOperator> _allOperators = [
    QueryOperator.equals,
    QueryOperator.notEquals,
    QueryOperator.greaterThan,
    QueryOperator.greaterThanOrEquals,
    QueryOperator.lessThan,
    QueryOperator.lessThanOrEquals,
    QueryOperator.contains,
    QueryOperator.startsWith,
    QueryOperator.endsWith,
  ];

  // Field types for formatting
  final Set<String> doubleFields = {
    'passing_yards', 'rushing_yards', 'receiving_yards', 'total_yards',
    'completion_percentage', 'passer_rating', 'qbr', 'yards_per_carry',
    'yards_per_reception', 'catch_rate', 'target_share', 'snap_percentage',
    'air_yards', 'yards_after_catch', 'yards_before_contact', 'yards_after_contact',
    'time_to_throw', 'pressure_rate', 'average_separation', 'opportunity_share',
    'route_participation'
  };

  // Helper function to format header names
  String _formatHeaderName(String header) {
    final Map<String, String> headerMap = {
      // Basic info
      'player_id': 'ID',
      'player_name': 'Player',
      'team': 'Team',
      'opponent': 'Opp',
      'position': 'Pos',
      'position_group': 'Pos',
      'season': 'Year',
      'week': 'Wk',
      // Passing
      'completions': 'Cmp',
      'attempts': 'Att',
      'passing_yards': 'Pass Yds',
      'passing_tds': 'Pass TD',
      'interceptions': 'Int',
      'sacks': 'Sacks',
      'completion_percentage': 'Cmp%',
      'yards_per_attempt': 'Y/A',
      'passing_epa': 'Pass EPA',
      // Rushing
      'carries': 'Car',
      'rushing_yards': 'Rush Yds',
      'rushing_tds': 'Rush TD',
      'yards_per_carry': 'YPC',
      'rushing_epa': 'Rush EPA',
      // Receiving
      'targets': 'Tgt',
      'receptions': 'Rec',
      'receiving_yards': 'Rec Yds',
      'receiving_tds': 'Rec TD',
      'yards_per_reception': 'Y/R',
      'catch_rate': 'Catch%',
      'receiving_epa': 'Rec EPA',
      // Fantasy
      'fantasy_points': 'FP',
      'fantasy_points_ppr': 'FP PPR',
      'total_yards': 'Tot Yds',
      'total_tds': 'Tot TD',
      'touches': 'Touch',
      'yards_per_touch': 'Y/Touch',
      // EPA
      'total_epa': 'Tot EPA',
      // NGS Passing
      'avg_time_to_throw': 'TTT',
      'avg_completed_air_yards': 'CAY',
      'cpoe': 'CPOE',
      'aggressiveness': 'AGG%',
      // NGS Rushing
      'rush_efficiency': 'Eff',
      'rush_yards_over_expected': 'RYOE',
      'avg_time_to_los': 'TTLOS',
      // NGS Receiving
      'avg_separation': 'Sep',
      'avg_cushion': 'Cush',
      'avg_yac_above_expectation': 'YAC+',
      'catch_percentage': 'Catch%',
    };

    return headerMap[header] ?? header.split('_').map((word) => 
      word[0].toUpperCase() + word.substring(1)).join(' ');
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {
          _selectedSubCategory = ['Basic', 'Advanced', 'Visualizations'][_tabController.index];
          _updateSelectedFields();
        });
      }
    });
    
    // Load real data
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    
    try {
      // Load player data for navigation
      print('Loading player data for navigation...');
      await _playerDataService.loadPlayerData();
      _allPlayers = _playerDataService.getAllPlayers();
      print('Loaded ${_allPlayers.length} players for navigation');
      setState(() {
        _isPlayerDataLoading = false;
      });
      
      // Load available seasons and weeks
      final seasons = await _service.getAvailableSeasons();
      final weeks = await _service.getAvailableWeeks();
      
      setState(() {
        // Update seasons list - ensure no duplicates
        _seasons = seasons.toSet().toList();
        if (!_seasons.contains('All')) {
          _seasons.insert(0, 'All');
        }
        
        // Update weeks list - ensure no duplicates
        _weeks = ['All', ...weeks.where((w) => w != 'All').toSet().toList()];
      });
      
      // Load initial data
      await _fetchData();
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }
  
  Future<void> _fetchData() async {
    try {
      print('Fetching data with filters:');
      print('Season: ${_selectedSeason == 'All' ? null : _selectedSeason}');
      print('Week: ${_selectedWeek == 'All' ? null : _selectedWeek}');
      print('Position: ${_getEffectivePositionFilter() == 'All' ? null : _getEffectivePositionFilter()}');
      print('Team: ${_selectedTeam == 'All' ? null : _selectedTeam}');
      
      final stats = await _service.getPlayerGameStats(
        season: _selectedSeason == 'All' ? null : _selectedSeason,
        week: _selectedWeek == 'All' ? null : _selectedWeek,
        position: _getEffectivePositionFilter() == 'All' ? null : _getEffectivePositionFilter(),
        team: _selectedTeam == 'All' ? null : _selectedTeam,
      );
      
      print('Fetched ${stats.length} stats');
      
      // Store all stats but only convert what we need for display
      _allStats = stats;
      _totalRecords = stats.length;
      
      // Sort the stats first
      _sortStats();
      
      // Only convert the current page to maps for display
      final startIndex = _currentPage * _rowsPerPage;
      final endIndex = (startIndex + _rowsPerPage).clamp(0, _allStats.length);
      final pageStats = _allStats.sublist(startIndex, endIndex);
      
      _rawRows = pageStats.map((stat) => stat.toMap()).toList();
      
      // Update headers based on available fields
      if (_rawRows.isNotEmpty) {
        _headers = _rawRows.first.keys.toList();
      }
      
      _updateSelectedFields(refetch: false); // Don't refetch during data loading
      
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching data: $e');
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }
  
  String _getEffectivePositionFilter() {
    if (_showAllPositionsInTab) {
      return _selectedPosition;
    }
    
    switch (_selectedStatCategory) {
      case 'QB Games':
        return 'QB';
      case 'RB Games':
        return 'RB';
      case 'WR/TE Games':
        return _selectedPosition == 'All' ? 'All' : _selectedPosition;
      default:
        return _selectedPosition;
    }
  }

  void _updateSelectedFields({bool refetch = true}) {
    final fields = _statCategoryFieldGroups[_selectedStatCategory]?[_selectedSubCategory] ?? [];
    setState(() {
      _selectedFields = fields.isEmpty ? _headers.take(10).toList() : fields;
      
      // Auto-apply position filtering based on category tab
      if (!_showAllPositionsInTab) {
        switch (_selectedStatCategory) {
          case 'QB Games':
            _selectedPosition = 'QB';
            break;
          case 'RB Games':
            _selectedPosition = 'RB';
            break;
          case 'WR/TE Games':
            _selectedPosition = 'WR'; // Will be handled in filtering logic to include both WR and TE
            break;
          default:
            // For Fantasy Focus and Custom, keep current position filter
            break;
        }
      }
    });
    
    // Only refetch data when needed (not during initial load)
    if (refetch) {
      _currentPage = 0; // Reset to first page when filters change
      _fetchData();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _newQueryValueController.dispose();
    super.dispose();
  }

  void _addQueryCondition() {
    if (_newQueryField != null &&
        _newQueryOperator != null &&
        _newQueryValueController.text.isNotEmpty) {
      setState(() {
        _queryConditions.add(QueryCondition(
          field: _newQueryField!,
          operator: _newQueryOperator!,
          value: _newQueryValueController.text,
        ));
        _newQueryValueController.clear();
      });
    }
  }

  void _removeQueryCondition(int index) {
    setState(() {
      _queryConditions.removeAt(index);
    });
  }

  void _clearAllQueryConditions() {
    setState(() {
      _queryConditions.clear();
    });
  }

  void _applyFiltersAndFetch() {
    setState(() {
      _currentPage = 0;
      _isLoading = true;
    });
    _fetchData();
  }

  void _showCustomizeColumnsDialog() {
    List<String> tempSelected = List.from(_selectedFields);
    
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Customize Columns'),
              content: SizedBox(
                width: 400,
                height: 500,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: TextField(
                        decoration: const InputDecoration(
                          labelText: 'Search Fields',
                          prefixIcon: Icon(Icons.search),
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                        ),
                        onChanged: (value) {
                          setState(() {});
                        },
                      ),
                    ),
                    Expanded(
                      child: ListView(
                        children: _headers.map((header) {
                          return CheckboxListTile(
                            title: Text(_formatHeaderName(header)),
                            subtitle: Text(header, style: const TextStyle(fontSize: 12)),
                            value: tempSelected.contains(header),
                            onChanged: (checked) {
                              setState(() {
                                if (checked == true) {
                                  tempSelected.add(header);
                                } else {
                                  tempSelected.remove(header);
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      tempSelected = List.from(_headers);
                    });
                  },
                  child: const Text('Select All'),
                ),
                ElevatedButton(
                  onPressed: () {
                    this.setState(() {
                      _selectedFields = List.from(tempSelected);
                      _selectedStatCategory = 'Custom';
                      _statCategoryFieldGroups['Custom']![_selectedSubCategory] = _selectedFields;
                    });
                    Navigator.pop(context);
                  },
                  child: const Text('Apply'),
                ),
              ],
            );
          }
        );
      },
    );
  }

  Widget _buildVisualizationTab() {
    if (_allStats.isEmpty) {
      return const Center(child: Text('No data available for visualization'));
    }

    // Group data by player for trends
    Map<String, List<PlayerGameStats>> playerGroups = {};
    for (var stat in _allStats) {
      playerGroups.putIfAbsent(stat.playerName, () => []).add(stat);
    }
    
    // Take top 5 players by total fantasy points
    var topPlayers = playerGroups.entries.toList()
      ..sort((a, b) {
        var aTotal = a.value.fold(0.0, (sum, stat) => sum + stat.fantasyPointsPpr);
        var bTotal = b.value.fold(0.0, (sum, stat) => sum + stat.fantasyPointsPpr);
        return bTotal.compareTo(aTotal);
      });
    topPlayers = topPlayers.take(5).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          if (topPlayers.isNotEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Fantasy Points Trends (Top 5 Players)',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 300,
                      child: LineChart(
                        LineChartData(
                          gridData: FlGridData(show: true),
                          titlesData: FlTitlesData(
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: true),
                            ),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (value, meta) {
                                  return Text('W${value.toInt()}');
                                },
                              ),
                            ),
                          ),
                          borderData: FlBorderData(show: true),
                          lineBarsData: topPlayers.map((entry) {
                            var stats = entry.value..sort((a, b) => a.week.compareTo(b.week));
                            return LineChartBarData(
                              spots: stats.map((stat) => 
                                FlSpot(stat.week.toDouble(), stat.fantasyPointsPpr)
                              ).toList(),
                              isCurved: true,
                              barWidth: 2,
                              dotData: FlDotData(show: true, getDotPainter: (spot, percent, bar, index) {
                                return FlDotCirclePainter(
                                  radius: 3,
                                  color: bar.color ?? Colors.blue,
                                );
                              }),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      children: topPlayers.map((entry) => 
                        Padding(
                          padding: const EdgeInsets.only(right: 16),
                          child: Text(entry.key, style: const TextStyle(fontSize: 12)),
                        )
                      ).toList(),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Average Fantasy Points by Position',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 300,
                    child: BarChart(
                      BarChartData(
                        barGroups: _getPositionAverages(),
                        titlesData: FlTitlesData(
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: true),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                final positions = ['QB', 'RB', 'WR', 'TE'];
                                if (value.toInt() < positions.length) {
                                  return Text(positions[value.toInt()]);
                                }
                                return const Text('');
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  List<BarChartGroupData> _getPositionAverages() {
    if (_allStats.isEmpty) return [];
    
    Map<String, List<double>> positionStats = {
      'QB': [],
      'RB': [],
      'WR': [],
      'TE': [],
    };
    
    for (var stat in _allStats) {
      if (positionStats.containsKey(stat.positionGroup)) {
        positionStats[stat.positionGroup]!.add(stat.fantasyPointsPpr);
      }
    }
    
    List<BarChartGroupData> barGroups = [];
    int index = 0;
    
    for (var entry in positionStats.entries) {
      if (entry.value.isNotEmpty) {
        double average = entry.value.reduce((a, b) => a + b) / entry.value.length;
        barGroups.add(
          BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: average,
                color: Theme.of(context).primaryColor,
                width: 20,
              ),
            ],
          ),
        );
      }
      index++;
    }
    
    return barGroups;
  }

  @override
  Widget build(BuildContext context) {
    final currentRouteName = ModalRoute.of(context)?.settings.name;
    final theme = Theme.of(context);
    
    // _rawRows now already contains only the current page data
    final displayRows = _rawRows;

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
              onPressed: () =>
                  showDialog(context: context, builder: (_) => const AuthDialog()),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
              ),
              child: const Text('Sign In / Sign Up'),
            ),
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: Column(
        children: [
          // Query Builder Section
          Card(
            margin: const EdgeInsets.all(12),
            child: ExpansionTile(
              title: Row(
                children: [
                  Icon(Icons.tune, color: Theme.of(context).primaryColor),
                  const SizedBox(width: 8),
                  Text('Query Builder',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  const Spacer(),
                  Text(_isQueryBuilderExpanded ? 'Collapse' : 'Expand',
                      style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
              initiallyExpanded: _isQueryBuilderExpanded,
              onExpansionChanged: (expanded) {
                setState(() {
                  _isQueryBuilderExpanded = expanded;
                });
              },
              children: [
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Filter Row
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          // Season Dropdown
                          Expanded(
                            flex: 1,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Season',
                                    style: TextStyle(fontWeight: FontWeight.bold)),
                                const SizedBox(height: 4),
                                DropdownButtonFormField<String>(
                                  value: _selectedSeason,
                                  decoration: const InputDecoration(
                                    border: OutlineInputBorder(),
                                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  ),
                                  items: _seasons.map((season) {
                                    return DropdownMenuItem(
                                      value: season,
                                      child: Text(season),
                                    );
                                  }).toList(),
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedSeason = value!;
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Week Dropdown
                          Expanded(
                            flex: 1,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Week',
                                    style: TextStyle(fontWeight: FontWeight.bold)),
                                const SizedBox(height: 4),
                                DropdownButtonFormField<String>(
                                  value: _selectedWeek,
                                  decoration: const InputDecoration(
                                    border: OutlineInputBorder(),
                                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  ),
                                  items: _weeks.map((week) {
                                    return DropdownMenuItem(
                                      value: week,
                                      child: Text(week),
                                    );
                                  }).toList(),
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedWeek = value!;
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Position Dropdown
                          Expanded(
                            flex: 1,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Position',
                                    style: TextStyle(fontWeight: FontWeight.bold)),
                                const SizedBox(height: 4),
                                DropdownButtonFormField<String>(
                                  value: _selectedPosition,
                                  decoration: const InputDecoration(
                                    border: OutlineInputBorder(),
                                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  ),
                                  items: _positions.map((position) {
                                    return DropdownMenuItem(
                                      value: position,
                                      child: Text(position),
                                    );
                                  }).toList(),
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedPosition = value!;
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Team Dropdown
                          Expanded(
                            flex: 1,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Team',
                                    style: TextStyle(fontWeight: FontWeight.bold)),
                                const SizedBox(height: 4),
                                DropdownButtonFormField<String>(
                                  value: _selectedTeam,
                                  decoration: const InputDecoration(
                                    border: OutlineInputBorder(),
                                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  ),
                                  items: _teams.map((team) {
                                    return DropdownMenuItem(
                                      value: team,
                                      child: Text(team),
                                    );
                                  }).toList(),
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedTeam = value!;
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Apply Filters Button
                          ElevatedButton.icon(
                            onPressed: _applyFiltersAndFetch,
                            icon: const Icon(Icons.search),
                            label: const Text('Apply Filters'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Advanced Query Conditions
                      if (_queryConditions.isNotEmpty) ...[
                        const Divider(),
                        const SizedBox(height: 8),
                        const Text('Active Conditions:',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _queryConditions.asMap().entries.map((entry) {
                            final index = entry.key;
                            final condition = entry.value;
                            return Chip(
                              label: Text(condition.toString()),
                              onDeleted: () => _removeQueryCondition(index),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 8),
                      ],
                      // Add New Condition Row
                      const Divider(),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: DropdownButtonFormField<String>(
                              value: _newQueryField,
                              decoration: const InputDecoration(
                                labelText: 'Field',
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              ),
                              items: _headers.map((field) {
                                return DropdownMenuItem(
                                  value: field,
                                  child: Text(_formatHeaderName(field)),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  _newQueryField = value;
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 1,
                            child: DropdownButtonFormField<QueryOperator>(
                              value: _newQueryOperator,
                              decoration: const InputDecoration(
                                labelText: 'Operator',
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              ),
                              items: _allOperators.map((op) {
                                return DropdownMenuItem(
                                  value: op,
                                  child: Text(queryOperatorToString(op)),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  _newQueryOperator = value;
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 2,
                            child: TextField(
                              controller: _newQueryValueController,
                              decoration: const InputDecoration(
                                labelText: 'Value',
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            onPressed: _addQueryCondition,
                            icon: const Icon(Icons.add_circle),
                            color: Theme.of(context).primaryColor,
                          ),
                        ],
                      ),
                      if (_queryConditions.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton.icon(
                              onPressed: _clearAllQueryConditions,
                              icon: const Icon(Icons.clear_all),
                              label: const Text('Clear All Conditions'),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Data Categories Tabs
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _statCategoryFieldGroups.keys.map((category) {
                        final isSelected = category == _selectedStatCategory;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: ChoiceChip(
                            label: Text(category),
                            selected: isSelected,
                            onSelected: (selected) {
                              if (selected) {
                                setState(() {
                                  _selectedStatCategory = category;
                                  _updateSelectedFields();
                                });
                              }
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Position Toggle for position-specific tabs
                if (_selectedStatCategory != 'Fantasy Focus' && _selectedStatCategory != 'Custom')
                  Row(
                    children: [
                      const Text('Show All Positions: '),
                      Switch(
                        value: _showAllPositionsInTab,
                        onChanged: (value) {
                          setState(() {
                            _showAllPositionsInTab = value;
                          });
                        },
                      ),
                    ],
                  ),
                // Customize Columns Button
                TextButton.icon(
                  onPressed: _showCustomizeColumnsDialog,
                  icon: const Icon(Icons.view_column),
                  label: const Text('Customize Columns'),
                ),
              ],
            ),
          ),
          // Sub-category tabs (Basic/Advanced/Visualizations)
          Container(
            color: theme.primaryColor.withOpacity(0.1),
            child: TabBar(
              controller: _tabController,
              labelColor: theme.primaryColor,
              unselectedLabelColor: theme.textTheme.bodyMedium?.color,
              indicatorColor: theme.primaryColor,
              tabs: const [
                Tab(text: 'Basic'),
                Tab(text: 'Advanced'),
                Tab(text: 'Visualizations'),
              ],
            ),
          ),
          // Table/Visualization Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Basic Tab
                _buildTableWithPagination(displayRows),
                // Advanced Tab
                _buildTableWithPagination(displayRows),
                // Visualizations Tab
                _buildVisualizationTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableWithPagination(List<Map<String, dynamic>> displayRows) {
    return Column(
      children: [
        // Table with scrolling
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: _buildTableView(displayRows),
            ),
          ),
        ),
        // Pagination Controls
        _buildPaginationControls(),
      ],
    );
  }
  
  Widget _buildPaginationControls() {
    final totalPages = (_totalRecords / _rowsPerPage).ceil().clamp(1, 9999);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            _rawRows.isEmpty
                ? 'No records'
                : 'Showing ${_currentPage * _rowsPerPage + 1}-${((_currentPage + 1) * _rowsPerPage).clamp(1, _totalRecords)} of $_totalRecords records',
            style: TextStyle(fontSize: 13, color: Theme.of(context).textTheme.bodySmall?.color),
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.first_page),
                onPressed: _currentPage > 0
                    ? () {
                        setState(() {
                          _currentPage = 0;
                          _fetchData();
                        });
                      }
                    : null,
                tooltip: 'First page',
              ),
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: _currentPage > 0
                    ? () {
                        setState(() {
                          _currentPage--;
                          _fetchData();
                        });
                      }
                    : null,
                tooltip: 'Previous page',
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text('Page ${_currentPage + 1} of $totalPages'),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: _currentPage < totalPages - 1
                    ? () {
                        setState(() {
                          _currentPage++;
                          _fetchData();
                        });
                      }
                    : null,
                tooltip: 'Next page',
              ),
              IconButton(
                icon: const Icon(Icons.last_page),
                onPressed: _currentPage < totalPages - 1
                    ? () {
                        setState(() {
                          _currentPage = totalPages - 1;
                          _fetchData();
                        });
                      }
                    : null,
                tooltip: 'Last page',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTableView(List<Map<String, dynamic>> displayRows) {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading player game stats...'),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Theme.of(context).colorScheme.error),
            const SizedBox(height: 16),
            Text('Error: $_error', style: TextStyle(color: Theme.of(context).colorScheme.error)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _applyFiltersAndFetch,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (displayRows.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 48, color: Colors.grey),
            SizedBox(height: 16),
            Text('No data found matching your criteria', style: TextStyle(color: Colors.grey)),
            SizedBox(height: 16),
            Text('Debug Info:', style: TextStyle(fontWeight: FontWeight.bold)),
            Text('Total stats loaded: ${_allStats.length}'),
            Text('Raw rows: ${_rawRows.length}'),
            Text('Season: $_selectedSeason, Week: $_selectedWeek'),
            Text('Position: $_selectedPosition, Team: $_selectedTeam'),
          ],
        ),
      );
    }

    return MdsTable(
      style: MdsTableStyle.standard, // Use standard style for clean alternating rows
      density: MdsTableDensity.standard, // Use standard density (48px) like rankings
      columns: _selectedFields.map((field) {
        final bool isNumeric = _rawRows.isNotEmpty &&
            _rawRows.any((row) => row[field] is num);
        return MdsTableColumn(
          key: field,
          label: _formatHeaderName(field),
          sortable: true,
          width: _getColumnWidth(field),
          numeric: isNumeric,
          isDoubleField: doubleFields.contains(field),
          enablePercentileShading: false, // Disable percentile shading for cleaner look
        );
      }).toList(),
      rows: displayRows.asMap().entries.map((entry) {
        final int index = entry.key;
        final Map<String, dynamic> row = entry.value;
        return MdsTableRow(
          id: row['game_id']?.toString() ?? row['player_name']?.toString() ?? index.toString(),
          data: row,
          onTap: () => _navigateToPlayerDetail(row),
        );
      }).toList(),
      sortColumn: _sortColumn,
      sortAscending: _sortAscending,
      showBorder: true,
      onSort: (column, ascending) {
        setState(() {
          _sortColumn = column;
          _sortAscending = ascending;
          _sortData();
        });
      },
    );
  }

  void _sortStats() {
    // Sort the stats array directly before converting to maps
    _allStats.sort((a, b) {
      // Get the value for the sort column from each stat
      final aMap = a.toMap();
      final bMap = b.toMap();
      final aVal = aMap[_sortColumn];
      final bVal = bMap[_sortColumn];
      
      // Handle null values
      if (aVal == null && bVal == null) return 0;
      if (aVal == null) return _sortAscending ? -1 : 1;
      if (bVal == null) return _sortAscending ? 1 : -1;
      
      int result = 0;
      
      // Handle different data types
      if (aVal is num && bVal is num) {
        result = aVal.compareTo(bVal);
      } else if (aVal is String && bVal is String) {
        result = aVal.toLowerCase().compareTo(bVal.toLowerCase());
      } else {
        // Convert to string and compare
        result = aVal.toString().toLowerCase().compareTo(bVal.toString().toLowerCase());
      }
      
      return _sortAscending ? result : -result;
    });
  }
  
  void _sortData() {
    // This is called when headers are clicked - need to re-sort and re-paginate
    _sortStats();
    
    // Refresh the current page with sorted data
    final startIndex = _currentPage * _rowsPerPage;
    final endIndex = (startIndex + _rowsPerPage).clamp(0, _allStats.length);
    final pageStats = _allStats.sublist(startIndex, endIndex);
    
    _rawRows = pageStats.map((stat) => stat.toMap()).toList();
  }

  double _getColumnWidth(String field) {
    if (field == 'player_name') return 150;
    if (field == 'team' || field == 'opponent' || field == 'position') return 60;
    if (field == 'week') return 50;
    if (field == 'game_date') return 100;
    if (field.contains('percentage') || field.contains('rate')) return 80;
    return 100;
  }

  void _navigateToPlayerDetail(Map<String, dynamic> rowData) {
    if (_isPlayerDataLoading) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Player data still loading, please wait...')),
      );
      return;
    }

    // Extract player identification data
    String? playerName = rowData['player_name'] ?? 
                        rowData['fantasy_player_name'] ?? 
                        rowData['receiver_player_name'] ??
                        rowData['player_display_name'];
    String? team = rowData['team'] ?? rowData['posteam'] ?? rowData['recent_team'];
    String? position = rowData['position'];
    String? playerId = rowData['player_id'] ?? 
                       rowData['fantasy_player_id'] ?? 
                       rowData['receiver_player_id'] ??
                       rowData['gsis_id'];

    print('Looking for player: $playerName, Team: $team, Position: $position, ID: $playerId');
    
    PlayerInfo? matchedPlayer;
    String? matchReason;

    // Strategy 1: Player ID match (most precise)
    if (playerId != null && playerId.isNotEmpty) {
      matchedPlayer = _allPlayers.where((player) {
        return player.playerId == playerId;
      }).firstOrNull;
      if (matchedPlayer != null) {
        matchReason = 'ID match';
        print('✓ Found player by ID: ${matchedPlayer.fullName}');
      }
    }

    // Strategy 2: Name + position match (team-agnostic for historical data)
    if (matchedPlayer == null && playerName != null && position != null) {
      matchedPlayer = _allPlayers.where((player) {
        return player.fullName.toLowerCase() == playerName.toLowerCase() &&
               player.position.toLowerCase() == position.toLowerCase();
      }).firstOrNull;
      if (matchedPlayer != null) {
        matchReason = 'name + position match';
        print('✓ Found player by name + position: ${matchedPlayer.fullName}');
      }
    }

    // Strategy 3: Abbreviated name + position match (handle "J.Taylor" style names)
    if (matchedPlayer == null && playerName != null && position != null) {
      // Check if this looks like an abbreviated name (e.g., "J.Taylor")
      if (playerName.contains('.')) {
        final parts = playerName.split('.');
        if (parts.length >= 2) {
          final firstInitial = parts[0].toLowerCase();
          final lastName = parts.last.toLowerCase();
          
          matchedPlayer = _allPlayers.where((player) {
            final fullNameParts = player.fullName.toLowerCase().split(' ');
            return fullNameParts.isNotEmpty &&
                   fullNameParts.first.startsWith(firstInitial) &&
                   fullNameParts.last == lastName &&
                   player.position.toLowerCase() == position.toLowerCase();
          }).firstOrNull;
          if (matchedPlayer != null) {
            matchReason = 'abbreviated name + position match';
            print('✓ Found player by abbreviated name + position: ${matchedPlayer.fullName}');
          }
        }
      }
    }

    // Strategy 4: Abbreviated name without position (fallback)
    if (matchedPlayer == null && playerName != null && playerName.contains('.')) {
      final parts = playerName.split('.');
      if (parts.length >= 2) {
        final firstInitial = parts[0].toLowerCase();
        final lastName = parts.last.toLowerCase();
        
        final candidates = _allPlayers.where((player) {
          final fullNameParts = player.fullName.toLowerCase().split(' ');
          return fullNameParts.isNotEmpty &&
                 fullNameParts.first.startsWith(firstInitial) &&
                 fullNameParts.last == lastName;
        }).toList();
        
        if (candidates.length == 1) {
          matchedPlayer = candidates.first;
          matchReason = 'abbreviated name match';
          print('✓ Found player by abbreviated name: ${matchedPlayer.fullName}');
        } else if (candidates.length > 1) {
          print('⚠ Multiple players found for abbreviated name $playerName: ${candidates.map((p) => p.fullName).join(", ")}');
          // If we have team info, try to disambiguate
          if (team != null) {
            matchedPlayer = candidates.where((player) => 
              player.team.toLowerCase() == team.toLowerCase()).firstOrNull;
            if (matchedPlayer != null) {
              matchReason = 'abbreviated name + team disambiguation';
              print('✓ Disambiguated by team: ${matchedPlayer.fullName}');
            }
          }
        }
      }
    }

    // Strategy 5: Name contains + team match (for partial name matches)
    if (matchedPlayer == null && playerName != null && team != null) {
      final searchName = playerName.toLowerCase();
      matchedPlayer = _allPlayers.where((player) {
        return (player.fullName.toLowerCase().contains(searchName) ||
                searchName.contains(player.fullName.toLowerCase())) &&
               player.team.toLowerCase() == team.toLowerCase();
      }).firstOrNull;
      if (matchedPlayer != null) {
        matchReason = 'name contains + team match';
        print('✓ Found player by name contains + team: ${matchedPlayer.fullName}');
      }
    }

    // Strategy 6: Exact name match (last resort)
    if (matchedPlayer == null && playerName != null) {
      matchedPlayer = _allPlayers.where((player) {
        return player.fullName.toLowerCase() == playerName.toLowerCase();
      }).firstOrNull;
      if (matchedPlayer != null) {
        matchReason = 'exact name match';
        print('✓ Found player by exact name: ${matchedPlayer.fullName}');
      }
    }

    if (matchedPlayer != null) {
      print('Successfully matched player: ${matchedPlayer.fullName} ($matchReason)');
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PlayerDetailScreen(player: matchedPlayer!),
        ),
      );
    } else {
      print('❌ No player found for: $playerName');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Player details not available for "$playerName"'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  // Cell formatter no longer used; MdsTable handles value display
}