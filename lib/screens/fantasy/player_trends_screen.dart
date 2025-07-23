import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mds_home/utils/team_logo_utils.dart';
import 'dart:math';

import '../../widgets/common/custom_app_bar.dart';
import '../../widgets/common/app_drawer.dart';
import '../../widgets/common/top_nav_bar.dart';
import '../../widgets/auth/auth_dialog.dart';
import '../../utils/theme_config.dart';
import '../../widgets/design_system/mds_table.dart';
import '../../services/rankings/filter_service.dart';
import '../../widgets/rankings/filter_panel.dart';

// Enum for Query Operators
enum QueryOperator {
  equals,
  notEquals,
  greaterThan,
  greaterThanOrEquals,
  lessThan,
  lessThanOrEquals,
  contains,
}

// Helper to convert QueryOperator to a display string
String queryOperatorToString(QueryOperator op) {
  switch (op) {
    case QueryOperator.equals: return '==';
    case QueryOperator.notEquals: return '!=';
    case QueryOperator.greaterThan: return '>';
    case QueryOperator.greaterThanOrEquals: return '>=';
    case QueryOperator.lessThan: return '<';
    case QueryOperator.lessThanOrEquals: return '<=';
    case QueryOperator.contains: return 'Contains';
  }
}

// Class to represent a single query condition
class QueryCondition {
  final String field;
  final QueryOperator operator;
  final String value;

  QueryCondition({required this.field, required this.operator, required this.value});

  @override
  String toString() {
    return '$field ${queryOperatorToString(operator)} "$value"';
  }
}

class PlayerTrendsScreen extends StatefulWidget {
  const PlayerTrendsScreen({super.key});

  @override
  _PlayerTrendsScreenState createState() => _PlayerTrendsScreenState();
}

class _PlayerTrendsScreenState extends State<PlayerTrendsScreen> {
  String _selectedPosition = 'RB';
  double _selectedWeeks = 4;
  String _selectedYear = '2024'; // Add year selection
  List<Map<String, dynamic>> _playerData = [];
  bool _isLoading = true;
  String _sortColumn = 'recent_avg_fantasy_points_ppr';
  bool _sortAscending = false;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ScrollController _horizontalScrollController = ScrollController();
  final ScrollController _verticalScrollController = ScrollController();
  final ScrollController _frozenColumnScrollController = ScrollController();
  
  // Available years for selection (past 5 years)
  final List<String> _availableYears = ['2024', '2023', '2022', '2021', '2020'];

  // Query builder state
  bool _isQueryBuilderExpanded = false;
  final List<QueryCondition> _queryConditions = [];
  String? _newQueryField;
  QueryOperator? _newQueryOperator;
  final TextEditingController _newQueryValueController = TextEditingController();
  
  // Filter panel state
  bool _showFilterPanel = false;
  bool _usingFilters = false;
  late FilterQuery _currentFilter;
  
  // Available fields for querying based on position
  List<String> get _availableQueryFields {
    final baseFields = ['playerName', 'team'];
    const recentPrefix = 'recent_';
    const fullPrefix = 'full_';
    
    if (_selectedPosition == 'RB') {
      return baseFields + [
        '${recentPrefix}avg_fantasy_points_ppr', '${fullPrefix}avg_fantasy_points_ppr',
        '${recentPrefix}avg_carries', '${fullPrefix}avg_carries',
        '${recentPrefix}avg_rushing_yards', '${fullPrefix}avg_rushing_yards',
        '${recentPrefix}avg_targets', '${fullPrefix}avg_targets',
        '${recentPrefix}avg_receptions', '${fullPrefix}avg_receptions',
        '${recentPrefix}avg_total_td', '${fullPrefix}avg_total_td',
      ];
    } else if (_selectedPosition == 'WR' || _selectedPosition == 'TE') {
      return baseFields + [
        '${recentPrefix}avg_fantasy_points_ppr', '${fullPrefix}avg_fantasy_points_ppr',
        '${recentPrefix}avg_targets', '${fullPrefix}avg_targets',
        '${recentPrefix}avg_receptions', '${fullPrefix}avg_receptions',
        '${recentPrefix}avg_receiving_yards', '${fullPrefix}avg_receiving_yards',
        '${recentPrefix}avg_total_td', '${fullPrefix}avg_total_td',
      ];
    } else { // QB
      return baseFields + [
        '${recentPrefix}avg_fantasy_points_ppr', '${fullPrefix}avg_fantasy_points_ppr',
        '${recentPrefix}avg_passing_attempts', '${fullPrefix}avg_passing_attempts',
        '${recentPrefix}avg_passing_yards', '${fullPrefix}avg_passing_yards',
        '${recentPrefix}avg_passing_tds', '${fullPrefix}avg_passing_tds',
        '${recentPrefix}avg_rushing_yards_qb', '${fullPrefix}avg_rushing_yards_qb',
      ];
    }
  }

  @override
  void initState() {
    super.initState();
    _currentFilter = const FilterQuery();
    _setupScrollSynchronization();
    _fetchAndProcessPlayerTrends();
  }

  void _setupScrollSynchronization() {
    // Bidirectional vertical scroll synchronization
    _verticalScrollController.addListener(() {
      if (_frozenColumnScrollController.hasClients && 
          _frozenColumnScrollController.offset != _verticalScrollController.offset) {
        _frozenColumnScrollController.jumpTo(_verticalScrollController.offset);
      }
    });
    
    _frozenColumnScrollController.addListener(() {
      if (_verticalScrollController.hasClients && 
          _verticalScrollController.offset != _frozenColumnScrollController.offset) {
        _verticalScrollController.jumpTo(_frozenColumnScrollController.offset);
      }
    });
  }

  @override
  void dispose() {
    _newQueryValueController.dispose();
    _horizontalScrollController.dispose();
    _verticalScrollController.dispose();
    _frozenColumnScrollController.dispose();
    super.dispose();
  }

  void _toggleFilterPanel() {
    setState(() {
      _showFilterPanel = !_showFilterPanel;
      if (_showFilterPanel) {
        _isQueryBuilderExpanded = false; // Close query builder when opening filter panel
      }
    });
  }

  void _onFilterChanged(FilterQuery newFilter) {
    setState(() {
      _currentFilter = newFilter;
      _usingFilters = newFilter.hasActiveFilters;
    });
    _fetchAndProcessPlayerTrends();
  }

  Map<String, Map<String, dynamic>> _getFilterableStats() {
    // Return available stats for filtering based on current position
    final stats = <String, Map<String, dynamic>>{};
    
    // Common stats for all positions
    stats['playerName'] = {'label': 'Player Name', 'type': 'text'};
    stats['team'] = {'label': 'Team', 'type': 'text'};
    
    if (_selectedPosition == 'RB') {
      stats['recent_avg_fantasy_points_ppr'] = {'label': 'Recent Fantasy Points (PPR)', 'type': 'number'};
      stats['full_avg_fantasy_points_ppr'] = {'label': 'Season Fantasy Points (PPR)', 'type': 'number'};
      stats['recent_avg_carries'] = {'label': 'Recent Carries', 'type': 'number'};
      stats['full_avg_carries'] = {'label': 'Season Carries', 'type': 'number'};
      stats['recent_avg_rushing_yards'] = {'label': 'Recent Rushing Yards', 'type': 'number'};
      stats['full_avg_rushing_yards'] = {'label': 'Season Rushing Yards', 'type': 'number'};
      stats['recent_avg_targets'] = {'label': 'Recent Targets', 'type': 'number'};
      stats['full_avg_targets'] = {'label': 'Season Targets', 'type': 'number'};
      stats['recent_avg_receptions'] = {'label': 'Recent Receptions', 'type': 'number'};
      stats['full_avg_receptions'] = {'label': 'Season Receptions', 'type': 'number'};
      stats['recent_avg_total_td'] = {'label': 'Recent TDs', 'type': 'number'};
      stats['full_avg_total_td'] = {'label': 'Season TDs', 'type': 'number'};
    } else if (_selectedPosition == 'WR' || _selectedPosition == 'TE') {
      stats['recent_avg_fantasy_points_ppr'] = {'label': 'Recent Fantasy Points (PPR)', 'type': 'number'};
      stats['full_avg_fantasy_points_ppr'] = {'label': 'Season Fantasy Points (PPR)', 'type': 'number'};
      stats['recent_avg_targets'] = {'label': 'Recent Targets', 'type': 'number'};
      stats['full_avg_targets'] = {'label': 'Season Targets', 'type': 'number'};
      stats['recent_avg_receptions'] = {'label': 'Recent Receptions', 'type': 'number'};
      stats['full_avg_receptions'] = {'label': 'Season Receptions', 'type': 'number'};
      stats['recent_avg_receiving_yards'] = {'label': 'Recent Receiving Yards', 'type': 'number'};
      stats['full_avg_receiving_yards'] = {'label': 'Season Receiving Yards', 'type': 'number'};
      stats['recent_avg_receiving_td'] = {'label': 'Recent Receiving TDs', 'type': 'number'};
      stats['full_avg_receiving_td'] = {'label': 'Season Receiving TDs', 'type': 'number'};
    } else if (_selectedPosition == 'QB') {
      stats['recent_avg_fantasy_points_ppr'] = {'label': 'Recent Fantasy Points', 'type': 'number'};
      stats['full_avg_fantasy_points_ppr'] = {'label': 'Season Fantasy Points', 'type': 'number'};
      stats['recent_avg_passing_yards'] = {'label': 'Recent Passing Yards', 'type': 'number'};
      stats['full_avg_passing_yards'] = {'label': 'Season Passing Yards', 'type': 'number'};
      stats['recent_avg_passing_td'] = {'label': 'Recent Passing TDs', 'type': 'number'};
      stats['full_avg_passing_td'] = {'label': 'Season Passing TDs', 'type': 'number'};
      stats['recent_avg_interceptions'] = {'label': 'Recent Interceptions', 'type': 'number'};
      stats['full_avg_interceptions'] = {'label': 'Season Interceptions', 'type': 'number'};
      stats['recent_avg_rushing_yards'] = {'label': 'Recent Rushing Yards', 'type': 'number'};
      stats['full_avg_rushing_yards'] = {'label': 'Season Rushing Yards', 'type': 'number'};
      stats['recent_avg_rushing_td'] = {'label': 'Recent Rushing TDs', 'type': 'number'};
      stats['full_avg_rushing_td'] = {'label': 'Season Rushing TDs', 'type': 'number'};
    }
    
    return stats;
  }

  void _addQueryCondition() {
    if (_newQueryField != null && _newQueryOperator != null && _newQueryValueController.text.isNotEmpty) {
      setState(() {
        _queryConditions.add(QueryCondition(
          field: _newQueryField!,
          operator: _newQueryOperator!,
          value: _newQueryValueController.text,
        ));
        _newQueryField = null;
        _newQueryOperator = null;
        _newQueryValueController.clear();
      });
      _applyQueryFilters();
    }
  }

  void _removeQueryCondition(int index) {
    setState(() {
      _queryConditions.removeAt(index);
    });
    _applyQueryFilters();
  }

  void _clearAllQueryConditions() {
    setState(() {
      _queryConditions.clear();
    });
    _applyQueryFilters();
  }

  void _applyQueryFilters() {
    // This will be called after data is fetched to apply client-side filtering
    _sortData();
  }

  List<Map<String, dynamic>> _getFilteredData() {
    List<Map<String, dynamic>> filteredData = _playerData;
    
    // Apply filter panel filters first
    if (_currentFilter.hasActiveFilters) {
      filteredData = FilterService.applyFilters(filteredData, _currentFilter);
    }
    
    // Apply legacy query conditions
    if (_queryConditions.isNotEmpty) {
      filteredData = filteredData.where((player) {
        return _queryConditions.every((condition) {
          final value = player[condition.field];
          final queryValue = condition.value.toLowerCase();
          
          switch (condition.operator) {
            case QueryOperator.equals:
              if (value is num) {
                return value == double.tryParse(condition.value);
              }
              return value.toString().toLowerCase() == queryValue;
            case QueryOperator.notEquals:
              if (value is num) {
                return value != double.tryParse(condition.value);
              }
              return value.toString().toLowerCase() != queryValue;
            case QueryOperator.greaterThan:
              if (value is num) {
                final numValue = double.tryParse(condition.value);
                return numValue != null && value > numValue;
              }
              return false;
            case QueryOperator.greaterThanOrEquals:
              if (value is num) {
                final numValue = double.tryParse(condition.value);
                return numValue != null && value >= numValue;
              }
              return false;
            case QueryOperator.lessThan:
              if (value is num) {
                final numValue = double.tryParse(condition.value);
                return numValue != null && value < numValue;
              }
              return false;
            case QueryOperator.lessThanOrEquals:
              if (value is num) {
                final numValue = double.tryParse(condition.value);
                return numValue != null && value <= numValue;
              }
              return false;
            case QueryOperator.contains:
              return value.toString().toLowerCase().contains(queryValue);
          }
        });
      }).toList();
    }
    
    return filteredData;
  }
  
  double _getMedian(List<double> arr) {
    if (arr.isEmpty) return 0;
    final sorted = [...arr]..sort((a, b) => a.compareTo(b));
    final mid = (sorted.length / 2).floor();
    if (sorted.length % 2 == 0) {
      return (sorted[mid - 1] + sorted[mid]) / 2;
    }
    return sorted[mid].toDouble();
  }

  // Helper to calculate stats for a list of game logs
  Map<String, double> _calculateStatsForLogs(List<Map<String, dynamic>> logs) {
    if (logs.isEmpty) return {};

    final games = logs.length.toDouble();
    
    // Generic stats for all positions
    final pprPoints = logs.map((l) => (l['fantasy_points_ppr'] as num? ?? 0).toDouble()).toList();
    
    // Position-specific stats
    List<double> targets = [], receptions = [], receivingYards = [], receivingTds = [];
    List<double> carries = [], rushingYards = [], rushingTds = [];
    List<double> passAttempts = [], passYards = [], passTds = [];
    
    for (var log in logs) {
        targets.add((log['targets'] as num? ?? 0).toDouble());
        receptions.add((log['receptions'] as num? ?? 0).toDouble());
        receivingYards.add((log['receiving_yards'] as num? ?? 0).toDouble());
        receivingTds.add((log['receiving_tds'] as num? ?? 0).toDouble());
        carries.add((log['carries'] as num? ?? 0).toDouble());
        rushingYards.add((log['rushing_yards'] as num? ?? 0).toDouble());
        rushingTds.add((log['rushing_tds'] as num? ?? 0).toDouble());
        passAttempts.add((log['attempts'] as num? ?? 0).toDouble());
        passYards.add((log['passing_yards'] as num? ?? 0).toDouble());
        passTds.add((log['passing_tds'] as num? ?? 0).toDouble());
    }

    final totalPPR = pprPoints.fold(0.0, (a, b) => a + b);

    // Combine rushing and receiving TDs for RBs and WRs/TEs
    final totalCombinedTds = List.generate(logs.length, (i) => receivingTds[i] + rushingTds[i]).fold(0.0, (a,b) => a+b);

    return {
      'games': games,
      'avg_fantasy_points_ppr': totalPPR / games,
      'median_fantasy_points_ppr': _getMedian(pprPoints),
      
      // WR/TE
      'avg_targets': targets.fold(0.0, (a,b) => a+b) / games,
      'avg_receptions': receptions.fold(0.0, (a,b) => a+b) / games,
      'avg_receiving_yards': receivingYards.fold(0.0, (a,b) => a+b) / games,
      
      // RB
      'avg_carries': carries.fold(0.0, (a,b) => a+b) / games,
      'avg_rushing_yards': rushingYards.fold(0.0, (a,b) => a+b) / games,
      'avg_total_td': totalCombinedTds / games,

      // QB
      'avg_passing_attempts': passAttempts.fold(0.0, (a,b) => a+b) / games,
      'avg_passing_yards': passYards.fold(0.0, (a,b) => a+b) / games,
      'avg_passing_tds': passTds.fold(0.0, (a,b) => a+b) / games,
      'avg_rushing_attempts_qb': carries.fold(0.0, (a,b) => a+b) / games,
      'avg_rushing_yards_qb': rushingYards.fold(0.0, (a,b) => a+b) / games,
      'avg_rushing_tds_qb': rushingTds.fold(0.0, (a,b) => a+b) / games,
    };
  }

  Future<void> _fetchAndProcessPlayerTrends() async {
    setState(() { _isLoading = true; });

    try {
      final querySnapshot = await _firestore
          .collection('playerGameLogs')
          .where('season', isEqualTo: int.parse(_selectedYear))
          .where('position', isEqualTo: _selectedPosition)
          .get();

      if (querySnapshot.docs.isEmpty) {
        setState(() { _playerData = []; _isLoading = false; });
        return;
      }
      
      final playersData = <String, dynamic>{};
      for (var doc in querySnapshot.docs) {
        final log = doc.data();
        final playerId = log['player_id'];
        if (playerId == null) continue;

        if (!playersData.containsKey(playerId)) {
          playersData[playerId] = {
            'player_name': log['player_name'],
            'position': log['position'],
            'team': log['team'],
            'logs': <Map<String, dynamic>>[]
          };
        }
        playersData[playerId]['logs'].add(log);
      }

      final List<Map<String, dynamic>> results = [];
      playersData.forEach((playerId, player) {
        final allLogs = (player['logs'] as List<Map<String, dynamic>>)..sort((a,b) => (b['week'] as int).compareTo(a['week'] as int));
        if (allLogs.isEmpty) return;
        
        final maxWeek = allLogs.first['week'] as int;
        final startWeek = max(1, maxWeek - _selectedWeeks.toInt() + 1);
        final recentLogs = allLogs.where((log) => (log['week'] as int) >= startWeek).toList();

        final fullSeasonStats = _calculateStatsForLogs(allLogs);
        final recentStats = _calculateStatsForLogs(recentLogs);
        
        // --- Calculate Trend Flags ---
        final Map<String, dynamic> trends = {};
        if (fullSeasonStats.isNotEmpty && recentStats.isNotEmpty) {
            // Define key metrics for trend calculation
            double fullUsage = 0, recentUsage = 0;
            final fullResult = fullSeasonStats['avg_fantasy_points_ppr'] ?? 0;
            final recentResult = recentStats['avg_fantasy_points_ppr'] ?? 0;

            if (_selectedPosition == 'RB') {
                fullUsage = (fullSeasonStats['avg_carries'] ?? 0) + (fullSeasonStats['avg_targets'] ?? 0);
                recentUsage = (recentStats['avg_carries'] ?? 0) + (recentStats['avg_targets'] ?? 0);
            } else if (_selectedPosition == 'WR' || _selectedPosition == 'TE') {
                fullUsage = fullSeasonStats['avg_targets'] ?? 0;
                recentUsage = recentStats['avg_targets'] ?? 0;
            } else if (_selectedPosition == 'QB') {
                fullUsage = fullSeasonStats['avg_passing_attempts'] ?? 0;
                recentUsage = recentStats['avg_passing_attempts'] ?? 0;
            }

            // Calculate percentage change and set flags
            if (fullUsage > 0) {
                final usageChange = (recentUsage - fullUsage) / fullUsage;
                trends['usage_value'] = usageChange;
            }
            if (fullResult > 0) {
                final resultChange = (recentResult - fullResult) / fullResult;
                trends['result_value'] = resultChange;
            }
        }
        
        final combinedData = <String, dynamic>{
          'playerName': player['player_name'],
          'team': player['team'],
          ...trends,
        };

        fullSeasonStats.forEach((key, value) {
          combinedData['full_$key'] = value;
        });
        recentStats.forEach((key, value) {
          combinedData['recent_$key'] = value;
        });

        results.add(combinedData);
      });
      
      setState(() {
        _playerData = results;
        _sortData();
        _isLoading = false;
      });

    } catch (e) {
      debugPrint("Error processing player trends: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error processing data: ${e.toString()}')),
        );
      }
      setState(() { _playerData = []; _isLoading = false; });
    }
  }
  


  void _sortData() {
    _playerData.sort((a, b) {
      final aValue = a[_sortColumn] as num?;
      final bValue = b[_sortColumn] as num?;
      
      if (aValue == null && bValue == null) return 0;
      if (aValue == null) return _sortAscending ? -1 : 1;
      if (bValue == null) return _sortAscending ? 1 : -1;

      final comparison = aValue.compareTo(bValue);
      return _sortAscending ? comparison : -comparison;
    });
  }

  @override
  Widget build(BuildContext context) {
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
            child: Material(
              elevation: 2,
              borderRadius: BorderRadius.circular(24),
              shadowColor: ThemeConfig.gold.withOpacity(0.3),
              child: ElevatedButton(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  showDialog(context: context, builder: (_) => const AuthDialog());
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: ThemeConfig.darkNavy,
                  foregroundColor: ThemeConfig.gold,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                child: const Text('Sign In / Sign Up'),
              ),
            ),
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Card(
              elevation: 2,
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  _buildControls(),
                  Expanded(
                    child: _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : _getFilteredData().isEmpty 
                            ? const Center(child: Text('No data available for the selected filters.'))
                            : _buildDataTable(),
                  ),
                ],
              ),
            ),
          ),
          if (_showFilterPanel)
            Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              child: FilterPanel(
                currentQuery: _currentFilter,
                onFilterChanged: _onFilterChanged,
                onClose: _toggleFilterPanel,
                isVisible: _showFilterPanel,
                availableTeams: FilterService.getAvailableTeams(_playerData),
                availableSeasons: FilterService.getAvailableSeasons(_playerData),
                statFields: _getFilterableStats(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildControls() {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark 
                    ? Theme.of(context).colorScheme.surfaceContainerHighest 
                    : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Position: ', style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).brightness == Brightness.dark 
                        ? Colors.white 
                        : Colors.black87,
                    )),
                    DropdownButton<String>(
                      value: _selectedPosition,
                      underline: const SizedBox(),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setState(() {
                            _selectedPosition = newValue;
                            _fetchAndProcessPlayerTrends();
                          });
                        }
                      },
                      items: <String>['RB', 'WR', 'TE', 'QB'].map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value, style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).brightness == Brightness.dark 
                              ? Colors.white 
                              : Colors.black87,
                          )),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.calendar_today, size: 16, color: Colors.blue.shade700),
                    const SizedBox(width: 6),
                    const Text('Year: ', style: TextStyle(fontWeight: FontWeight.w600)),
                    DropdownButton<String>(
                      value: _selectedYear,
                      underline: const SizedBox(),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setState(() {
                            _selectedYear = newValue;
                            _fetchAndProcessPlayerTrends();
                          });
                        }
                      },
                      items: _availableYears.map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue.shade700)),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              // Filter button
              Container(
                margin: const EdgeInsets.only(right: 8),
                child: ElevatedButton.icon(
                  onPressed: _toggleFilterPanel,
                  icon: Icon(
                    _showFilterPanel ? Icons.close : Icons.filter_list,
                    size: 16,
                  ),
                  label: Text(_showFilterPanel ? 'Close' : 'Filter'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _usingFilters ? Colors.blue.shade600 : ThemeConfig.darkNavy,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
              ),
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _fetchAndProcessPlayerTrends,
                icon: _isLoading ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.refresh),
                label: Text(_isLoading ? 'Loading...' : 'Reload Data'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade600,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _buildSlider('Compare Recent Weeks:', _selectedWeeks, 1, 17, (val) => setState(() => _selectedWeeks = val)),
        ],
      ),
    );
  }

  Widget _buildCollapsibleQuerySection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        onExpansionChanged: (expanded) {
          setState(() {
            _isQueryBuilderExpanded = expanded;
            if (expanded) {
              _showFilterPanel = false; // Close filter panel when opening query builder
            }
          });
        },
        title: Row(
          children: [
            Icon(Icons.filter_alt_outlined, color: Theme.of(context).primaryColor, size: 20),
            const SizedBox(width: 8),
            Text('Advanced Filters',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
            const Spacer(),
            if (_queryConditions.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_queryConditions.length}',
                  style: TextStyle(
                    color: Theme.of(context).primaryColor,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Query conditions
                if (_queryConditions.isNotEmpty) ...[
                  Wrap(
                    spacing: 8.0,
                    runSpacing: 4.0,
                    children: _queryConditions.asMap().entries.map((entry) {
                      final index = entry.key;
                      final condition = entry.value;
                      return Chip(
                        label: Text(condition.toString(), style: const TextStyle(fontSize: 12)),
                        deleteIcon: const Icon(Icons.close, size: 16),
                        onDeleted: () => _removeQueryCondition(index),
                        backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),
                ],
                // Query input fields
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          labelText: 'Field',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          isDense: true,
                        ),
                        value: _availableQueryFields.contains(_newQueryField) ? _newQueryField : null,
                        items: _availableQueryFields.map((field) {
                          String displayName = field;
                          if (field.startsWith('recent_')) {
                            displayName = '${field.substring(7)} (Recent)';
                          } else if (field.startsWith('full_')) {
                            displayName = '${field.substring(5)} (Season)';
                          }
                          return DropdownMenuItem(
                            value: field,
                            child: Text(displayName, style: const TextStyle(fontSize: 13)),
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
                      flex: 2,
                      child: DropdownButtonFormField<QueryOperator>(
                        decoration: const InputDecoration(
                          labelText: 'Operator',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          isDense: true,
                        ),
                        value: _newQueryOperator,
                        items: QueryOperator.values.map((op) => DropdownMenuItem(
                          value: op,
                          child: Text(queryOperatorToString(op), style: const TextStyle(fontSize: 13)),
                        )).toList(),
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
                          isDense: true,
                        ),
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: _addQueryCondition,
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Add', style: TextStyle(fontSize: 12)),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    ),
                  ],
                ),
                if (_queryConditions.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: _clearAllQueryConditions,
                        child: const Text('Clear All', style: TextStyle(fontSize: 12)),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSlider(String label, double value, double min, double max, ValueChanged<double> onChanged) {
    return Row(
      children: [
        Text(label),
        Expanded(
          child: Slider(
            value: value,
            min: min,
            max: max,
            divisions: (max - min).toInt(),
            label: 'Last ${value.round()} weeks',
            onChanged: onChanged,
            onChangeEnd: (value) => _fetchAndProcessPlayerTrends(),
          ),
        ),
      ],
    );
  }

  Widget _buildDataTable() {
    if (_playerData.isEmpty && !_isLoading) {
      return const Center(
        child: Text('No data found. Try adjusting your filters.',
            style: TextStyle(fontSize: 16)),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.surface,
            Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: ThemeConfig.gold.withOpacity(0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: ThemeConfig.darkNavy.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Row(
          children: [
            // FROZEN FIRST COLUMN (Player names + header)
            Container(
              width: 150,
              child: Column(
                children: [
                  // Player header (always visible)
                  _buildFrozenColumnHeader(),
                  // Player data (scrolls vertically)
                  Expanded(
                    child: ListView.builder(
                      controller: _frozenColumnScrollController,
                      physics: const ClampingScrollPhysics(),
                      itemCount: _getFilteredData().length,
                      itemBuilder: (context, index) {
                        final filteredData = _getFilteredData();
                        final player = filteredData[index];
                        return _buildFrozenPlayerCell(player, index);
                      },
                    ),
                  ),
                ],
              ),
            ),
            // SCROLLABLE DATA AREA (headers + data move together)
            Expanded(
              child: NotificationListener<ScrollNotification>(
                onNotification: (ScrollNotification notification) {
                  // Let scroll notifications propagate to synchronize both ListViews
                  return false;
                },
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  controller: _horizontalScrollController,
                  child: SizedBox(
                    width: _getScrollableTableWidth(),
                    child: Column(
                      children: [
                        // STICKY HEADERS (move horizontally with data, stay at top)
                        _buildScrollableHeaders(),
                        // DATA (scrolls both ways)
                        Expanded(
                          child: ListView.builder(
                            controller: _verticalScrollController,
                            physics: const ClampingScrollPhysics(),
                            itemCount: _getFilteredData().length,
                            itemBuilder: (context, index) {
                              final filteredData = _getFilteredData();
                              final player = filteredData[index];
                              return _buildScrollableDataCells(player, index);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }


  Map<String, int> _calculateColumnSpans() {
    final columns = _getMdsColumns();
    int seasonToDateCount = 0;
    int recentCount = 0;
    int trendsCount = 0;
    
    for (final column in columns) {
      if (column.key == 'playerName') {
        // Skip player column, it's separate
        continue;
      } else if (column.key.startsWith('full_')) {
        seasonToDateCount++;
      } else if (column.key.startsWith('recent_')) {
        recentCount++;
      } else if (column.key.endsWith('_value') || column.key == 'usage_flag' || column.key == 'result_flag') {
        trendsCount++;
      }
    }
    
    return {
      'seasonToDate': seasonToDateCount,
      'recent': recentCount,
      'trends': trendsCount,
    };
  }


  double _getScrollableTableWidth() {
    final columns = _getMdsColumns();
    double totalWidth = 0;
    for (final column in columns) {
      if (column.key != 'playerName') {
        totalWidth += 100;
      }
    }
    return totalWidth;
  }

  
  List<MdsTableColumn> _getMdsColumns() {
    List<MdsTableColumn> columns = [
      MdsTableColumn(
        key: 'playerName',
        label: 'Player',
        numeric: false,
        cellBuilder: (value, rowIndex, percentile) {
          final filteredData = _getFilteredData();
          final player = filteredData[rowIndex];
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (player['team'] != null && (player['team'] as String).isNotEmpty)
                TeamLogoUtils.buildNFLTeamLogo(player['team'], size: 24),
              const SizedBox(width: 8),
              Text(player['playerName'] as String? ?? 'N/A'),
            ],
          );
        },
      ),
    ];

    // --- TO-DATE STATS ---
    columns.addAll([
      const MdsTableColumn(key: 'full_games', label: 'G', numeric: true, enablePercentileShading: true),
      const MdsTableColumn(key: 'full_avg_fantasy_points_ppr', label: 'PPR', numeric: true, enablePercentileShading: true, isDoubleField: true),
    ]);

    if (_selectedPosition == 'WR' || _selectedPosition == 'TE') {
      columns.addAll([
        const MdsTableColumn(key: 'full_avg_targets', label: 'Tgt', numeric: true, enablePercentileShading: true, isDoubleField: true),
        const MdsTableColumn(key: 'full_avg_receptions', label: 'Rec', numeric: true, enablePercentileShading: true, isDoubleField: true),
        const MdsTableColumn(key: 'full_avg_receiving_yards', label: 'Yds', numeric: true, enablePercentileShading: true, isDoubleField: true),
        const MdsTableColumn(key: 'full_avg_total_td', label: 'TD', numeric: true, enablePercentileShading: true, isDoubleField: true),
      ]);
    } else if (_selectedPosition == 'RB') {
      columns.addAll([
        const MdsTableColumn(key: 'full_avg_carries', label: 'Car', numeric: true, enablePercentileShading: true, isDoubleField: true),
        const MdsTableColumn(key: 'full_avg_rushing_yards', label: 'RuYd', numeric: true, enablePercentileShading: true, isDoubleField: true),
        const MdsTableColumn(key: 'full_avg_targets', label: 'Tgt', numeric: true, enablePercentileShading: true, isDoubleField: true),
        const MdsTableColumn(key: 'full_avg_receiving_yards', label: 'ReYd', numeric: true, enablePercentileShading: true, isDoubleField: true),
        const MdsTableColumn(key: 'full_avg_total_td', label: 'TD', numeric: true, enablePercentileShading: true, isDoubleField: true),
      ]);
    } else if (_selectedPosition == 'QB') {
      columns.addAll([
        const MdsTableColumn(key: 'full_avg_passing_attempts', label: 'Att', numeric: true, enablePercentileShading: true, isDoubleField: true),
        const MdsTableColumn(key: 'full_avg_passing_yards', label: 'PaYd', numeric: true, enablePercentileShading: true, isDoubleField: true),
        const MdsTableColumn(key: 'full_avg_passing_tds', label: 'PaTD', numeric: true, enablePercentileShading: true, isDoubleField: true),
        const MdsTableColumn(key: 'full_avg_rushing_attempts_qb', label: 'RAtt', numeric: true, enablePercentileShading: true, isDoubleField: true),
        const MdsTableColumn(key: 'full_avg_rushing_yards_qb', label: 'RuYd', numeric: true, enablePercentileShading: true, isDoubleField: true),
        const MdsTableColumn(key: 'full_avg_rushing_tds_qb', label: 'RuTD', numeric: true, enablePercentileShading: true, isDoubleField: true),
      ]);
    }

    // --- RECENT STATS ---
    columns.addAll([
      const MdsTableColumn(key: 'recent_games', label: 'G', numeric: true, enablePercentileShading: true),
      const MdsTableColumn(key: 'recent_avg_fantasy_points_ppr', label: 'PPR', numeric: true, enablePercentileShading: true, isDoubleField: true),
      const MdsTableColumn(key: 'recent_median_fantasy_points_ppr', label: 'Med', numeric: true, enablePercentileShading: true, isDoubleField: true),
    ]);

    if (_selectedPosition == 'WR' || _selectedPosition == 'TE') {
      columns.addAll([
        const MdsTableColumn(key: 'recent_avg_targets', label: 'Tgt', numeric: true, enablePercentileShading: true, isDoubleField: true),
        const MdsTableColumn(key: 'recent_avg_receptions', label: 'Rec', numeric: true, enablePercentileShading: true, isDoubleField: true),
        const MdsTableColumn(key: 'recent_avg_receiving_yards', label: 'Yds', numeric: true, enablePercentileShading: true, isDoubleField: true),
        const MdsTableColumn(key: 'recent_avg_total_td', label: 'TD', numeric: true, enablePercentileShading: true, isDoubleField: true),
      ]);
    } else if (_selectedPosition == 'RB') {
      columns.addAll([
        const MdsTableColumn(key: 'recent_avg_carries', label: 'Car', numeric: true, enablePercentileShading: true, isDoubleField: true),
        const MdsTableColumn(key: 'recent_avg_rushing_yards', label: 'RuYd', numeric: true, enablePercentileShading: true, isDoubleField: true),
        const MdsTableColumn(key: 'recent_avg_targets', label: 'Tgt', numeric: true, enablePercentileShading: true, isDoubleField: true),
        const MdsTableColumn(key: 'recent_avg_receiving_yards', label: 'ReYd', numeric: true, enablePercentileShading: true, isDoubleField: true),
        const MdsTableColumn(key: 'recent_avg_total_td', label: 'TD', numeric: true, enablePercentileShading: true, isDoubleField: true),
      ]);
    } else if (_selectedPosition == 'QB') {
      columns.addAll([
        const MdsTableColumn(key: 'recent_avg_passing_attempts', label: 'Att', numeric: true, enablePercentileShading: true, isDoubleField: true),
        const MdsTableColumn(key: 'recent_avg_passing_yards', label: 'PaYd', numeric: true, enablePercentileShading: true, isDoubleField: true),
        const MdsTableColumn(key: 'recent_avg_passing_tds', label: 'PaTD', numeric: true, enablePercentileShading: true, isDoubleField: true),
        const MdsTableColumn(key: 'recent_avg_rushing_attempts_qb', label: 'RAtt', numeric: true, enablePercentileShading: true, isDoubleField: true),
        const MdsTableColumn(key: 'recent_avg_rushing_yards_qb', label: 'RuYd', numeric: true, enablePercentileShading: true, isDoubleField: true),
        const MdsTableColumn(key: 'recent_avg_rushing_tds_qb', label: 'RuTD', numeric: true, enablePercentileShading: true, isDoubleField: true),
      ]);
    }

    // --- TRENDS ---
    columns.addAll([
      MdsTableColumn(
        key: 'usage_value', 
        label: 'Usage', 
        numeric: true,
        cellBuilder: (value, rowIndex, percentile) => _buildTrendCellContent(value),
      ),
      MdsTableColumn(
        key: 'result_value', 
        label: 'Result', 
        numeric: true,
        cellBuilder: (value, rowIndex, percentile) => _buildTrendCellContent(value),
      ),
    ]);

    return columns;
  }




  Widget _buildTrendCellContent(dynamic value) {
    if (value == null) {
      return const Text('-');
    }

    final doubleValue = (value is num) ? value.toDouble() : null;
    if (doubleValue == null) {
      return const Text('-');
    }

    final color = _getColorForPercentage(doubleValue);
    final textColor = color.computeLuminance() > 0.5 ? Colors.black : Colors.white;
    final text = '${(doubleValue * 100).toStringAsFixed(1)}%';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
        textAlign: TextAlign.center,
      ),
    );
  }

  Color _getColorForPercentage(double? value) {
    if (value == null) return Colors.transparent;

    // Clamp the value to a range of -30% to +30% for color scaling
    final clampedValue = value.clamp(-0.3, 0.3);

    // Red -> Yellow -> Green gradient
    if (clampedValue < 0) {
      // Interpolate between Yellow and Red
      return Color.lerp(Colors.yellow.shade600, Colors.red.shade500, clampedValue.abs() / 0.3)!;
    } else {
      // Interpolate between Yellow and Green
      return Color.lerp(Colors.yellow.shade600, Colors.green.shade500, clampedValue / 0.3)!;
    }
  }

  Widget _buildFrozenColumnHeader() {
    return Container(
      color: ThemeConfig.darkNavy,
      child: Column(
        children: [
          // Top level: Empty space for group headers
          Container(
            width: 150,
            height: 40,
            alignment: Alignment.center,
            child: const Text(
              '',
              style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
          // Bottom level: Player column header
          Container(
            width: 150,
            height: 40,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white24, width: 0.5),
              color: ThemeConfig.darkNavy,
            ),
            child: const Center(
              child: Text(
                'Player',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildScrollableHeaders() {
    final columns = _getMdsColumns().where((col) => col.key != 'playerName').toList();
    final columnSpans = _calculateColumnSpans();
    
    return Container(
      color: ThemeConfig.darkNavy,
      child: Column(
        children: [
          // Top level: Group headers
          Row(
              children: [
                // Season To-Date group
                Container(
                  width: columnSpans['seasonToDate']! * 100.0,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    border: Border(
                      left: BorderSide(color: Colors.white24, width: 1),
                      right: BorderSide(color: Colors.white24, width: 1),
                    ),
                  ),
                  child: Text(
                    'Season To-Date ($_selectedYear)',
                    style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                ),
                // Recent group
                Container(
                  width: columnSpans['recent']! * 100.0,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    border: Border(right: BorderSide(color: Colors.white24, width: 1)),
                  ),
                  child: Text(
                    'Recent ${_selectedWeeks.round()} Weeks ($_selectedYear)',
                    style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                ),
                // Trends group
                Container(
                  width: columnSpans['trends']! * 100.0,
                  height: 40,
                  alignment: Alignment.center,
                  child: const Text(
                    'Trends',
                    style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          // Bottom level: Individual column headers
          Row(
              children: columns.map((column) {
                return GestureDetector(
                  onTap: column.numeric ? () {
                    setState(() {
                      if (_sortColumn == column.key) {
                        _sortAscending = !_sortAscending;
                      } else {
                        _sortColumn = column.key;
                        _sortAscending = false;
                      }
                      _sortData();
                    });
                  } : null,
                  child: Container(
                    width: 100,
                    height: 40,
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white24, width: 0.5),
                      color: ThemeConfig.darkNavy,
                    ),
                    child: Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              column.label,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                color: Colors.white,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (column.numeric && _sortColumn == column.key) ...[
                            const SizedBox(width: 2),
                            Icon(
                              _sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
                              size: 12,
                              color: Colors.white,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildFrozenPlayerCell(Map<String, dynamic> player, int index) {
    final isEven = index % 2 == 0;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final rowColor = isDark 
      ? (isEven ? Colors.grey.shade100 : Colors.grey.shade200)
      : (isEven ? Colors.white : Colors.grey.shade50);
    
    return Container(
      width: 150,
      height: 52,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: rowColor,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200, width: 1),
          right: BorderSide(color: Colors.grey.shade200, width: 0.5),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (player['team'] != null && (player['team'] as String).isNotEmpty)
            TeamLogoUtils.buildNFLTeamLogo(player['team'], size: 20),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              player['playerName'] as String? ?? 'N/A',
              style: const TextStyle(
                fontSize: 12, 
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScrollableDataCells(Map<String, dynamic> player, int index) {
    final columns = _getMdsColumns().where((col) => col.key != 'playerName').toList();
    final isEven = index % 2 == 0;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final rowColor = isDark 
      ? (isEven ? Colors.grey.shade100 : Colors.grey.shade200)
      : (isEven ? Colors.white : Colors.grey.shade50);
    
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: rowColor,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200, width: 1),
        ),
      ),
      child: Row(
        children: columns.map((column) {
          final value = player[column.key];
          return Container(
            width: 100,
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade200, width: 0.5),
            ),
            child: Center(
              child: _buildCellContent(column, value, index, player),
            ),
          );
        }).toList(),
      ),
    );
  }



  Widget _buildCellContent(MdsTableColumn column, dynamic value, int index, Map<String, dynamic> player) {
    // Handle custom cell builders
    if (column.cellBuilder != null) {
      return column.cellBuilder!(value, index, null);
    }
    
    // Handle player name column with team logo
    if (column.key == 'playerName') {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (player['team'] != null && (player['team'] as String).isNotEmpty)
            TeamLogoUtils.buildNFLTeamLogo(player['team'], size: 20),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              player['playerName'] as String? ?? 'N/A',
              style: const TextStyle(
                fontSize: 12, 
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      );
    }
    
    // Handle numeric values
    if (column.numeric && value is num) {
      final displayValue = column.isDoubleField ? value.toStringAsFixed(1) : value.round().toString();
      return Text(
        displayValue,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: Colors.black87,
        ),
        textAlign: TextAlign.center,
      );
    }
    
    return Text(
      value?.toString() ?? '-',
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: Colors.black87,
      ),
      textAlign: TextAlign.center,
    );
  }
}

 