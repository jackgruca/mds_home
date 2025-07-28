import 'package:flutter/material.dart';
import 'package:mds_home/widgets/common/app_drawer.dart';
import 'package:mds_home/widgets/common/top_nav_bar.dart';
import 'package:mds_home/widgets/common/custom_app_bar.dart';
import 'package:mds_home/widgets/auth/auth_dialog.dart';
import 'package:mds_home/utils/team_logo_utils.dart';
import 'package:mds_home/utils/theme_config.dart';
import 'package:mds_home/utils/theme_aware_colors.dart';
import 'package:mds_home/widgets/design_system/mds_table.dart';
import '../services/hybrid_data_service.dart';

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

class PlayerSeasonStatsScreen extends StatefulWidget {
  const PlayerSeasonStatsScreen({super.key});

  @override
  State<PlayerSeasonStatsScreen> createState() =>
      _PlayerSeasonStatsScreenState();
}

class _PlayerSeasonStatsScreenState extends State<PlayerSeasonStatsScreen>
    with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  String? _error;
  List<Map<String, dynamic>> _rawRows = [];
  List<Map<String, dynamic>> _filteredRows = [];
  int _totalRecords = 0;

  // CSV Data Service
  final HybridDataService _dataService = HybridDataService();

  // Pagination state  
  int _currentPage = 0;
  static const int _rowsPerPage = 25;

  // Sort state
  String _sortColumn = 'season';
  bool _sortAscending = false;

  // Position Filter
  String _selectedPosition = 'All';
  final List<String> _positions = ['All', 'QB', 'RB', 'WR', 'TE'];
  
  // Season Filter
  String _selectedSeason = 'All';
  final List<String> _seasons = ['All', '2024', '2023', '2022', '2021', '2020'];

  // Query conditions for advanced filtering
  List<QueryCondition> _queryConditions = [];
  final TextEditingController _fieldController = TextEditingController();
  final TextEditingController _valueController = TextEditingController();
  QueryOperator _selectedOperator = QueryOperator.equals;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      print('🚀 Loading player stats from CSV...');
      final startTime = DateTime.now();
      
      // Load all data from CSV (super fast!)
      final allData = await _dataService.getPlayerStats();
      
      final loadTime = DateTime.now().difference(startTime).inMilliseconds;
      print('✅ Loaded ${allData.length} records in ${loadTime}ms');

      // Apply filters
      _rawRows = allData;
      _applyFilters();
      
      setState(() {
        _isLoading = false;
        _totalRecords = _filteredRows.length;
      });

    } catch (e) {
      print('❌ Error loading data: $e');
      setState(() {
        _error = 'Failed to load player stats: $e';
        _isLoading = false;
      });
    }
  }

  void _applyFilters() {
    var filtered = List<Map<String, dynamic>>.from(_rawRows);

    // Apply position filter
    if (_selectedPosition != 'All') {
      filtered = filtered.where((row) => row['position'] == _selectedPosition).toList();
    }

    // Apply season filter
    if (_selectedSeason != 'All') {
      final season = int.tryParse(_selectedSeason);
      if (season != null) {
        filtered = filtered.where((row) => row['season'] == season).toList();
      }
    }

    // Apply custom query conditions
    for (final condition in _queryConditions) {
      filtered = filtered.where((row) {
        final fieldValue = row[condition.field];
        if (fieldValue == null) return false;

        final fieldStr = fieldValue.toString().toLowerCase();
        final conditionValue = condition.value.toLowerCase();

        switch (condition.operator) {
          case QueryOperator.equals:
            return fieldStr == conditionValue;
          case QueryOperator.notEquals:
            return fieldStr != conditionValue;
          case QueryOperator.contains:
            return fieldStr.contains(conditionValue);
          case QueryOperator.startsWith:
            return fieldStr.startsWith(conditionValue);
          case QueryOperator.endsWith:
            return fieldStr.endsWith(conditionValue);
          case QueryOperator.greaterThan:
          case QueryOperator.greaterThanOrEquals:
          case QueryOperator.lessThan:
          case QueryOperator.lessThanOrEquals:
            final numValue = num.tryParse(condition.value);
            final fieldNum = num.tryParse(fieldStr);
            if (numValue != null && fieldNum != null) {
              switch (condition.operator) {
                case QueryOperator.greaterThan:
                  return fieldNum > numValue;
                case QueryOperator.greaterThanOrEquals:
                  return fieldNum >= numValue;
                case QueryOperator.lessThan:
                  return fieldNum < numValue;
                case QueryOperator.lessThanOrEquals:
                  return fieldNum <= numValue;
                default:
                  return false;
              }
            }
            return false;
        }
      }).toList();
    }

    // Apply sorting
    filtered.sort((a, b) {
      final aValue = a[_sortColumn] ?? '';
      final bValue = b[_sortColumn] ?? '';
      
      int result;
      if (aValue is num && bValue is num) {
        result = aValue.compareTo(bValue);
      } else {
        result = aValue.toString().compareTo(bValue.toString());
      }
      
      return _sortAscending ? result : -result;
    });

    _filteredRows = filtered;
    _currentPage = 0; // Reset to first page
  }

  List<Map<String, dynamic>> get _currentPageData {
    final startIndex = _currentPage * _rowsPerPage;
    final endIndex = (startIndex + _rowsPerPage).clamp(0, _filteredRows.length);
    return _filteredRows.sublist(startIndex, endIndex);
  }

  void _onSort(String column, bool ascending) {
    setState(() {
      _sortColumn = column;
      _sortAscending = ascending;
      _applyFilters(); // Re-apply all filters including sort
    });
  }

  void _onFilterChange() {
    setState(() {
      _applyFilters();
    });
  }

  void _addQueryCondition() {
    if (_fieldController.text.isNotEmpty && _valueController.text.isNotEmpty) {
      setState(() {
        _queryConditions.add(QueryCondition(
          field: _fieldController.text.trim(),
          operator: _selectedOperator,
          value: _valueController.text.trim(),
        ));
        _fieldController.clear();
        _valueController.clear();
        _applyFilters();
      });
    }
  }

  void _removeQueryCondition(int index) {
    setState(() {
      _queryConditions.removeAt(index);
      _applyFilters();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isWideScreen = screenWidth > 1200;

    return Scaffold(
      appBar: CustomAppBar(
        titleWidget: const Text('Player Season Stats'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Refresh Data',
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: Column(
        children: [
          const TopNavBarContent(),
          
          // Filters Section
          Container(
            padding: const EdgeInsets.all(16),
            color: isDarkMode ? Colors.grey[850] : Colors.grey[100],
            child: Column(
              children: [
                // Position and Season filters
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedPosition,
                        decoration: const InputDecoration(
                          labelText: 'Position',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        items: _positions.map((position) {
                          return DropdownMenuItem<String>(
                            value: position,
                            child: Text(position),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedPosition = value!;
                            _onFilterChange();
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedSeason,
                        decoration: const InputDecoration(
                          labelText: 'Season',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        items: _seasons.map((season) {
                          return DropdownMenuItem<String>(
                            value: season,
                            child: Text(season),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedSeason = value!;
                            _onFilterChange();
                          });
                        },
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Advanced Query Builder
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Advanced Filters',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        
                        // Query condition input
                        Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: TextField(
                                controller: _fieldController,
                                decoration: const InputDecoration(
                                  labelText: 'Field',
                                  hintText: 'e.g., passing_yards',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: DropdownButtonFormField<QueryOperator>(
                                value: _selectedOperator,
                                decoration: const InputDecoration(
                                  labelText: 'Operator',
                                  border: OutlineInputBorder(),
                                ),
                                items: QueryOperator.values.map((op) {
                                  return DropdownMenuItem<QueryOperator>(
                                    value: op,
                                    child: Text(queryOperatorToString(op)),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  setState(() {
                                    _selectedOperator = value!;
                                  });
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              flex: 2,
                              child: TextField(
                                controller: _valueController,
                                decoration: const InputDecoration(
                                  labelText: 'Value',
                                  hintText: 'e.g., 3000',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: _addQueryCondition,
                              child: const Text('Add'),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 8),
                        
                        // Active query conditions
                        if (_queryConditions.isNotEmpty)
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
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Results Section
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error_outline, size: 64, color: Colors.red),
                            const SizedBox(height: 16),
                            Text(_error!),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _loadData,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : Column(
                        children: [
                          // Results summary
                          Container(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Text(
                                  'Showing ${_currentPageData.length} of ${_filteredRows.length} players',
                                  style: Theme.of(context).textTheme.titleMedium,
                                ),
                                const Spacer(),
                                Text(
                                  'Page ${_currentPage + 1} of ${((_filteredRows.length - 1) ~/ _rowsPerPage) + 1}',
                                ),
                              ],
                            ),
                          ),
                          
                          // Data table
                          Expanded(
                            child: _buildDataTable(),
                          ),
                          
                          // Pagination
                          if (_filteredRows.length > _rowsPerPage)
                            Container(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  IconButton(
                                    onPressed: _currentPage > 0
                                        ? () => setState(() => _currentPage--)
                                        : null,
                                    icon: const Icon(Icons.chevron_left),
                                  ),
                                  Text('${_currentPage + 1}'),
                                  IconButton(
                                    onPressed: (_currentPage + 1) * _rowsPerPage < _filteredRows.length
                                        ? () => setState(() => _currentPage++)
                                        : null,
                                    icon: const Icon(Icons.chevron_right),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataTable() {
    if (_currentPageData.isEmpty) {
      return const Center(
        child: Text('No data matches your filters'),
      );
    }

    // Get column names from first row
    final columns = _currentPageData.first.keys.toList();
    
    // Priority columns to show first
    final priorityColumns = [
      'player_display_name',
      'position', 
      'recent_team',
      'season',
      'games',
      'passing_yards',
      'passing_tds',
      'rushing_yards',
      'rushing_tds',
      'receiving_yards',
      'receiving_tds',
      'fantasy_points_ppr'
    ];
    
    // Reorder columns
    final orderedColumns = <String>[];
    for (final col in priorityColumns) {
      if (columns.contains(col)) {
        orderedColumns.add(col);
      }
    }
    // Add remaining columns
    for (final col in columns) {
      if (!orderedColumns.contains(col)) {
        orderedColumns.add(col);
      }
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        sortColumnIndex: orderedColumns.indexOf(_sortColumn),
        sortAscending: _sortAscending,
        columns: orderedColumns.map((column) {
          return DataColumn(
            label: Text(
              column.replaceAll('_', ' ').toUpperCase(),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            onSort: (columnIndex, ascending) {
              _onSort(column, ascending);
            },
          );
        }).toList(),
        rows: _currentPageData.map((row) {
          return DataRow(
            cells: orderedColumns.map((column) {
              final value = row[column];
              String displayValue;
              
              if (value == null) {
                displayValue = '-';
              } else if (value is num) {
                displayValue = value.toString();
              } else {
                displayValue = value.toString();
              }
              
              // Make player names clickable
              if (column == 'player_display_name' && row['player_id'] != null) {
                return DataCell(
                  InkWell(
                    onTap: () {
                      // Clean player ID by removing suffix (e.g., "00-0033553_2024" -> "00-0033553")
                      String cleanPlayerId = row['player_id'].toString();
                      if (cleanPlayerId.contains('_')) {
                        cleanPlayerId = cleanPlayerId.split('_').first;
                      }
                      
                      Navigator.pushNamed(
                        context,
                        '/player-profile',
                        arguments: {
                          'playerId': cleanPlayerId,
                          'playerName': displayValue,
                        },
                      );
                    },
                    child: Text(
                      displayValue,
                      style: TextStyle(
                        color: Colors.blue.shade600,
                        decoration: TextDecoration.underline,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                );
              }
              
              return DataCell(Text(displayValue));
            }).toList(),
          );
        }).toList(),
      ),
    );
  }

  @override
  void dispose() {
    _fieldController.dispose();
    _valueController.dispose();
    super.dispose();
  }
}