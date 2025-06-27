import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Added for haptic feedback
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart'; // Added for animations
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../widgets/common/app_drawer.dart';
import '../../widgets/common/custom_app_bar.dart';
import '../../widgets/common/top_nav_bar.dart';
import '../../utils/team_logo_utils.dart';
import '../../utils/theme_config.dart'; // Added for theme colors
import '../../utils/theme_aware_colors.dart';

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
    case QueryOperator.equals: return '==';
    case QueryOperator.notEquals: return '!=';
    case QueryOperator.greaterThan: return '>';
    case QueryOperator.greaterThanOrEquals: return '>=';
    case QueryOperator.lessThan: return '<';
    case QueryOperator.lessThanOrEquals: return '<=';
    case QueryOperator.contains: return 'Contains';
    case QueryOperator.startsWith: return 'Starts With';
    case QueryOperator.endsWith: return 'Ends With';
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

class QBRankingsScreen extends StatefulWidget {
  const QBRankingsScreen({super.key});

  @override
  State<QBRankingsScreen> createState() => _QBRankingsScreenState();
}

class _QBRankingsScreenState extends State<QBRankingsScreen> {
  List<Map<String, dynamic>> _qbRankings = [];
  Map<String, Map<String, dynamic>> _teamQbTiers = {};
  bool _isLoading = true;
  String? _error;
  String _selectedSeason = '2024';
  String _selectedTier = 'All';
  
  // Sorting state
  String _sortColumn = 'rank_number';
  bool _sortAscending = true;
  
  // Query builder state
  final List<QueryCondition> _queryConditions = [];
  String? _newQueryField;
  QueryOperator? _newQueryOperator;
  final TextEditingController _newQueryValueController = TextEditingController();
  bool _isQueryBuilderExpanded = false;
  
  final List<String> _seasonOptions = ['All Seasons', '2024', '2023', '2022', '2021', '2020', '2019', '2018', '2017', '2016'];
  final List<String> _tierOptions = ['All', 'Tier 1', 'Tier 2', 'Tier 3', 'Tier 4', 'Tier 5', 'Tier 6', 'Tier 7', 'Tier 8'];
  
  // Fields that should have colored density cells (performance metrics) - CORRECTED FIELD NAMES
  final Set<String> _densityColoredFields = {
    'total_epa', 'avg_cpoe', 'yards_per_game', 'tds_per_game', 'ints_per_game', 'composite_rank_score'
  };
  
  // All available fields for query builder - CORRECTED FIELD NAMES
  final List<String> _allFields = [
    'player_name', 'team', 'season', 'games', 'pass_attempts', 'total_epa', 'avg_cpoe', 
    'yards_per_game', 'tds_per_game', 'ints_per_game', 'composite_rank_score', 
    'rank_number', 'qb_tier', 'team_qb_tier', 'team_rank_number'
  ];
  
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

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  @override
  void dispose() {
    _newQueryValueController.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Fetch both individual QB rankings and team QB tiers
      final futures = await Future.wait([
        FirebaseFirestore.instance.collection('qbRankings').get(),
        FirebaseFirestore.instance.collection('teamQbTiers').get(),
      ]);

      final qbSnapshot = futures[0];
      final teamSnapshot = futures[1];

      // Process individual QB rankings
      final qbRankings = qbSnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          ...data,
          'id': doc.id,
        };
      }).toList();

      // Process team QB tiers into a map for easy lookup
      final Map<String, Map<String, dynamic>> teamTiers = {};
      for (final doc in teamSnapshot.docs) {
        final data = doc.data();
        final key = '${data['team']}_${data['season']}';
        teamTiers[key] = data;
      }

      setState(() {
        _qbRankings = qbRankings;
        _teamQbTiers = teamTiers;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> get _filteredAndSortedData {
    List<Map<String, dynamic>> filtered = List.from(_qbRankings);

    // Apply season filter
    if (_selectedSeason != 'All Seasons') {
      final season = int.parse(_selectedSeason);
      filtered = filtered.where((qb) => qb['season'] == season).toList();
    }

    // Apply tier filter
    if (_selectedTier != 'All') {
      final tier = int.parse(_selectedTier.split(' ')[1]);
      filtered = filtered.where((qb) => qb['qb_tier'] == tier).toList();
    }

    // Apply query conditions
    for (final condition in _queryConditions) {
      filtered = filtered.where((qb) => _matchesCondition(qb, condition)).toList();
    }

    // Add team QB tier information
    for (final qb in filtered) {
      final teamKey = '${qb['team']}_${qb['season']}';
      final teamData = _teamQbTiers[teamKey];
      if (teamData != null) {
        qb['team_qb_tier'] = teamData['team_qb_tier'];
        qb['team_rank_number'] = teamData['team_rank_number'];
        qb['primary_qb'] = teamData['primary_qb'];
        qb['primary_qb_games'] = teamData['primary_qb_games'];
        qb['total_qbs_used'] = teamData['total_qbs_used'];
      }
    }

    // Sort data
    filtered.sort((a, b) {
      dynamic aValue = a[_sortColumn];
      dynamic bValue = b[_sortColumn];

      // Handle null values
      if (aValue == null && bValue == null) return 0;
      if (aValue == null) return _sortAscending ? 1 : -1;
      if (bValue == null) return _sortAscending ? -1 : 1;

      // Compare values
      int comparison;
      if (aValue is num && bValue is num) {
        comparison = aValue.compareTo(bValue);
      } else {
        comparison = aValue.toString().compareTo(bValue.toString());
      }

      return _sortAscending ? comparison : -comparison;
    });

    return filtered;
  }

  bool _matchesCondition(Map<String, dynamic> qb, QueryCondition condition) {
    dynamic actualValue = qb[condition.field];
    String conditionValue = condition.value.toLowerCase();

    if (actualValue == null) return false;

    try {
      switch (condition.operator) {
        case QueryOperator.equals:
          if (actualValue is num) {
            num? conditionNum = num.tryParse(condition.value);
            return conditionNum != null && actualValue == conditionNum;
          }
          return actualValue.toString().toLowerCase() == conditionValue;

        case QueryOperator.notEquals:
          if (actualValue is num) {
            num? conditionNum = num.tryParse(condition.value);
            return conditionNum == null || actualValue != conditionNum;
          }
          return actualValue.toString().toLowerCase() != conditionValue;

        case QueryOperator.greaterThan:
        case QueryOperator.greaterThanOrEquals:
        case QueryOperator.lessThan:
        case QueryOperator.lessThanOrEquals:
          if (actualValue is num) {
            double? conditionNum = double.tryParse(condition.value);
            if (conditionNum == null) return false;
            double actualNum = actualValue.toDouble();
            switch (condition.operator) {
              case QueryOperator.greaterThan: return actualNum > conditionNum;
              case QueryOperator.greaterThanOrEquals: return actualNum >= conditionNum;
              case QueryOperator.lessThan: return actualNum < conditionNum;
              case QueryOperator.lessThanOrEquals: return actualNum <= conditionNum;
              default: return false;
            }
          }
          return false;

        case QueryOperator.contains:
          return actualValue.toString().toLowerCase().contains(conditionValue);
        case QueryOperator.startsWith:
          return actualValue.toString().toLowerCase().startsWith(conditionValue);
        case QueryOperator.endsWith:
          return actualValue.toString().toLowerCase().endsWith(conditionValue);
      }
    } catch (e) {
      return false;
    }
    return false;
  }

  // Calculate percentile for colored density cells
  Map<String, double> _calculatePercentiles(List<Map<String, dynamic>> data, String field) {
    final values = data
        .where((item) => item[field] != null && item[field] is num)
        .map((item) => (item[field] as num).toDouble())
        .toList();
    
    if (values.isEmpty) return {};
    
    values.sort();
    
    Map<String, double> percentiles = {};
    for (final item in data) {
      if (item[field] != null && item[field] is num) {
        final value = (item[field] as num).toDouble();
        final rank = values.where((v) => v < value).length;
        final percentile = rank / values.length;
        percentiles['${item['player_name']}_${item['season']}'] = percentile;
      }
    }
    
    return percentiles;
  }

  // Get background color for density cells
  Color _getDensityColor(String field, String playerKey, Map<String, double> percentiles) {
    final percentile = percentiles[playerKey] ?? 0.0;
    
    // For negative stats (like interceptions), invert the color scale
    final bool isNegativeStat = field == 'ints_per_game';
    final adjustedPercentile = isNegativeStat ? (1.0 - percentile) : percentile;
    
    // Use blue color scheme for density cells
    return Colors.blue.shade700.withOpacity(0.1 + (adjustedPercentile * 0.6));
  }

  void _addQueryCondition() {
    if (_newQueryField != null && _newQueryOperator != null && _newQueryValueController.text.isNotEmpty) {
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

  String _formatFieldName(String field) {
    switch (field) {
      case 'player_name': return 'Player';
      case 'team': return 'Team';
      case 'season': return 'Season';
      case 'games': return 'Games';
      case 'pass_attempts': return 'Attempts';
      case 'total_epa': return 'EPA/Play';
      case 'avg_cpoe': return 'CPOE';
      case 'yards_per_game': return 'Yds/Game';
      case 'tds_per_game': return 'TD/Game';
      case 'ints_per_game': return 'INT/Game';
      case 'composite_rank_score': return 'QB Score';
      case 'rank_number': return 'Rank';
      case 'qb_tier': return 'QB Tier';
      case 'team_qb_tier': return 'Team Tier';
      case 'team_rank_number': return 'Team Rank';
      default: return field.replaceAll('_', ' ').split(' ').map((word) => 
          word.isEmpty ? '' : word[0].toUpperCase() + word.substring(1)).join(' ');
    }
  }

  String _formatCellValue(String field, dynamic value) {
    if (value == null) return '-';
    
    switch (field) {
      case 'total_epa':
      case 'avg_cpoe':
      case 'yards_per_game':
      case 'tds_per_game':
      case 'ints_per_game':
      case 'composite_rank_score':
        return value is num ? value.toStringAsFixed(2) : value.toString();
      default:
        return value.toString();
    }
  }

  Widget _buildTeamLogo(String team) {
    return SizedBox(
      width: 24,
      height: 24,
      child: TeamLogoUtils.buildNFLTeamLogo(team, size: 24),
    );
  }

  Color _getTierColor(int tier) {
    final colors = [
      Colors.green.shade700,    // Tier 1 - Elite
      Colors.green.shade500,    // Tier 2 - Excellent  
          ThemeConfig.darkNavy,     // Tier 3 - Very Good
    ThemeConfig.darkNavy.withOpacity(0.8),     // Tier 4 - Good
      Colors.orange.shade600,   // Tier 5 - Average
      Colors.orange.shade400,   // Tier 6 - Below Average
      Colors.red.shade400,      // Tier 7 - Poor
      Colors.red.shade700,      // Tier 8 - Backup
    ];
    return tier >= 1 && tier <= 8 ? colors[tier - 1] : Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    final currentRouteName = ModalRoute.of(context)?.settings.name;
    final filteredData = _filteredAndSortedData;
    
    final Map<String, Map<String, double>> fieldPercentiles = {};
    for (final field in _densityColoredFields) {
      fieldPercentiles[field] = _calculatePercentiles(filteredData, field);
    }

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
          Material(
            elevation: 2,
            borderRadius: BorderRadius.circular(20),
            shadowColor: ThemeConfig.gold.withOpacity(0.2),
            child: IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                HapticFeedback.lightImpact();
                _fetchData();
              },
              tooltip: 'Refresh Data',
              style: IconButton.styleFrom(
                backgroundColor: ThemeConfig.darkNavy,
                foregroundColor: ThemeConfig.gold,
                padding: const EdgeInsets.all(8),
              ),
            ),
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: AnimationConfiguration.synchronized(
        duration: const Duration(milliseconds: 400),
        child: Column(
          children: [
            // Filters and Controls
            SlideAnimation(
              verticalOffset: -50,
              child: FadeInAnimation(
                child: Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: ThemeAwareColors.getSurfaceColor(context),
                    border: Border(
                      bottom: BorderSide(
                        color: ThemeAwareColors.getDividerColor(context),
                        width: 1,
                      ),
                    ),
                  ),
                  child: Column(
                    children: [
                      // Season and Tier Filters
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              decoration: InputDecoration(
                                labelText: 'Season',
                                border: const OutlineInputBorder(),
                                fillColor: ThemeAwareColors.getInputFillColor(context),
                                filled: true,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              ),
                              value: _selectedSeason,
                              items: _seasonOptions.map((season) => DropdownMenuItem(
                                value: season,
                                child: Text(season),
                              )).toList(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedSeason = value!;
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              decoration: InputDecoration(
                                labelText: 'Tier Filter',
                                border: const OutlineInputBorder(),
                                fillColor: ThemeAwareColors.getInputFillColor(context),
                                filled: true,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              ),
                              value: _selectedTier,
                              items: _tierOptions.map((tier) => DropdownMenuItem(
                                value: tier,
                                child: Text(tier),
                              )).toList(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedTier = value!;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Query Builder Expander
                      ExpansionTile(
                        title: const Text('Query Builder'),
                        initiallyExpanded: _isQueryBuilderExpanded,
                        onExpansionChanged: (isExpanded) {
                          setState(() {
                            _isQueryBuilderExpanded = isExpanded;
                          });
                        },
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Column(
                              children: [
                                // Query conditions list
                                if (_queryConditions.isNotEmpty)
                                  Wrap(
                                    spacing: 8.0,
                                    runSpacing: 4.0,
                                    children: List.generate(_queryConditions.length, (index) {
                                      return Chip(
                                        label: Text(_queryConditions[index].toString()),
                                        deleteIcon: const Icon(Icons.close, size: 16),
                                        onDeleted: () => _removeQueryCondition(index),
                                        backgroundColor: ThemeConfig.gold.withOpacity(0.1),
                                      );
                                    }).toList(),
                                  ),
                                if (_queryConditions.isNotEmpty)
                                  const SizedBox(height: 8),
                                // Query input fields
                                Row(
                                  children: [
                                    Expanded(
                                      flex: 2,
                                      child: DropdownButtonFormField<String>(
                                        decoration: InputDecoration(
                                          labelText: 'Field', 
                                          border: const OutlineInputBorder(),
                                          fillColor: ThemeAwareColors.getInputFillColor(context),
                                          filled: true,
                                        ),
                                        items: _allFields.map((field) => DropdownMenuItem(value: field, child: Text(_formatFieldName(field)))).toList(),
                                        onChanged: (value) => setState(() => _newQueryField = value),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      flex: 2,
                                      child: DropdownButtonFormField<QueryOperator>(
                                        decoration: InputDecoration(
                                          labelText: 'Operator', 
                                          border: const OutlineInputBorder(),
                                          fillColor: ThemeAwareColors.getInputFillColor(context),
                                          filled: true,
                                        ),
                                        items: _allOperators.map((op) => DropdownMenuItem(value: op, child: Text(queryOperatorToString(op)))).toList(),
                                        onChanged: (value) => setState(() => _newQueryOperator = value),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      flex: 3,
                                      child: TextField(
                                        controller: _newQueryValueController,
                                        decoration: InputDecoration(
                                          labelText: 'Value', 
                                          border: const OutlineInputBorder(),
                                          fillColor: ThemeAwareColors.getInputFillColor(context),
                                          filled: true,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                // Action buttons for query
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    if (_queryConditions.isNotEmpty)
                                      TextButton(
                                        onPressed: _clearAllQueryConditions,
                                        child: const Text('Clear All'),
                                      ),
                                    const SizedBox(width: 8),
                                    ElevatedButton.icon(
                                      onPressed: _addQueryCondition,
                                      icon: const Icon(Icons.add),
                                      label: const Text('Add Condition'),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Data Table
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? Center(child: Text('Error: $_error'))
                      : filteredData.isEmpty
                          ? const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.search_off, size: 64, color: Colors.grey),
                                  SizedBox(height: 16),
                                  Text('No QBs match your current filters.'),
                                ],
                              ),
                            )
                          : SlideAnimation(
                              verticalOffset: 50,
                              child: FadeInAnimation(
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.vertical,
                                  child: SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    padding: const EdgeInsets.all(16.0),
                                    child: DataTable(
                                      sortColumnIndex: _getSortColumnIndex(),
                                      sortAscending: _sortAscending,
                                      headingRowColor: WidgetStateProperty.all(ThemeAwareColors.getTableHeaderColor(context)),
                                      headingTextStyle: TextStyle(
                                        color: ThemeAwareColors.getTableHeaderTextColor(context),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                      dataRowMinHeight: 44,
                                      dataRowMaxHeight: 44,
                                      showCheckboxColumn: false,
                                      border: TableBorder.all(
                                        color: ThemeAwareColors.getDividerColor(context),
                                        width: 0.5,
                                      ),
                                      columns: _buildDataColumns(),
                                      rows: _buildDataRows(filteredData, fieldPercentiles),
                                    ),
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

  int? _getSortColumnIndex() {
    final columns = _getColumnFields();
    final index = columns.indexOf(_sortColumn);
    return index >= 0 ? index : null;
  }

  // UPDATED COLUMN ORDER: Rank, Player, Team, QB Tier, Team Rank, Team Tier, then performance metrics
  List<String> _getColumnFields() {
    final List<String> columns = ['rank_number', 'player_name', 'team', 'qb_tier', 'team_rank_number', 'team_qb_tier'];
    
    // Add season column if showing all seasons
    if (_selectedSeason == 'All Seasons') {
      columns.add('season');
    }
    
    // Add performance metrics: Games, Attempts, EPA/Play, CPOE, Yds/Game, TD/Game, INT/Game, QB Score
    columns.addAll([
      'games', 'pass_attempts', 'total_epa', 'avg_cpoe', 'yards_per_game', 
      'tds_per_game', 'ints_per_game', 'composite_rank_score'
    ]);
    
    return columns;
  }

  List<DataColumn> _buildDataColumns() {
    final columns = _getColumnFields();
    
    return columns.map((field) {
      return DataColumn(
        label: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
          child: Text(_formatFieldName(field)),
        ),
        onSort: (columnIndex, ascending) {
          setState(() {
            _sortColumn = field;
            _sortAscending = ascending;
          });
        },
      );
    }).toList();
  }

  List<DataRow> _buildDataRows(List<Map<String, dynamic>> data, Map<String, Map<String, double>> fieldPercentiles) {
    return data.map((qb) {
      final playerKey = '${qb['player_name']}_${qb['season']}';
      final columns = _getColumnFields();
      
      return DataRow(
        cells: columns.map((field) {
          final value = qb[field];
          
          // Determine background color for density cells
          Color? backgroundColor;
          if (_densityColoredFields.contains(field) && fieldPercentiles[field] != null) {
            backgroundColor = _getDensityColor(field, playerKey, fieldPercentiles[field]!);
          }
          
          Widget cellContent;
          
          if (field == 'team') {
            cellContent = Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTeamLogo(value?.toString() ?? ''),
                const SizedBox(width: 4),
                Text(
                  value?.toString() ?? '-',
                  style: const TextStyle(fontSize: 13),
                ),
              ],
            );
          } else if (field == 'qb_tier' || field == 'team_qb_tier') {
            final tier = value as int?;
            cellContent = Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: tier != null ? _getTierColor(tier) : Colors.grey,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                tier?.toString() ?? '-',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            );
          } else {
            cellContent = Text(
              _formatCellValue(field, value),
              style: const TextStyle(fontSize: 13),
            );
          }
          
          return DataCell(
            Container(
              width: double.infinity,
              height: double.infinity,
              color: backgroundColor,
              alignment: (value is num && field != 'qb_tier' && field != 'team_qb_tier' && field != 'rank_number' && field != 'team_rank_number') 
                ? Alignment.centerRight 
                : Alignment.centerLeft,
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: cellContent,
            ),
          );
        }).toList(),
      );
    }).toList();
  }
} 