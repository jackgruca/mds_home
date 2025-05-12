import 'package:flutter/material.dart';
import 'package:mds_home/widgets/common/app_drawer.dart';
import 'package:mds_home/models/nfl_matchup.dart';
import 'package:mds_home/services/historical_data_service.dart';
import 'package:intl/intl.dart';

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
  final String value; // Store value as String, parse when applying

  QueryCondition({required this.field, required this.operator, required this.value});

  @override
  String toString() {
    return '$field ${queryOperatorToString(operator)} "$value"';
  }
}

class HistoricalDataScreen extends StatefulWidget {
  const HistoricalDataScreen({super.key});

  @override
  State<HistoricalDataScreen> createState() => _HistoricalDataScreenState();
}

class _HistoricalDataScreenState extends State<HistoricalDataScreen> {
  bool _isLoading = true;
  String? _error;
  List<NFLMatchup> _matchups = [];
  
  // Pagination state
  int _currentPage = 0;
  static const int _rowsPerPage = 25;
  
  // Filter state
  DateTime? _startDate;
  DateTime? _endDate;
  String? _selectedTeam;
  String? _selectedOpponent;
  int? _selectedSeason;
  int? _selectedWeek;
  bool? _isHome;
  bool? _isWin;
  bool? _isSpreadWin;
  bool? _isOver;
  
  // Available filter options
  List<String> _teams = [];
  List<int> _seasons = [];
  List<int> _weeks = [];
  
  // Sort state
  String _sortColumn = 'date';
  bool _sortAscending = false;

  List<String> _headers = [];
  List<Map<String, String>> _rawRows = [];

  // Main fields to show by default
  static const List<String> _defaultFields = [
    'Team', 'Date', 'Opponent', 'Final', 'Closing_spread', 'Actual_total', 'Outcome', 'Spread_result', 'Points_result'
  ];
  List<String> _selectedFields = List.from(_defaultFields);

  // State for Query Builder
  final List<QueryCondition> _queryConditions = [];
  String? _newQueryField;
  QueryOperator? _newQueryOperator;
  final TextEditingController _newQueryValueController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadHistoricalData();
    _newQueryOperator = QueryOperator.equals; 
  }

  Future<void> _loadHistoricalData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      print('Initializing HistoricalDataService...');
      await HistoricalDataService.initialize();
      
      _teams = HistoricalDataService.getUniqueTeams();
      print('Loaded ${_teams.length} unique teams');
      
      _seasons = HistoricalDataService.getUniqueSeasons();
      print('Loaded ${_seasons.length} unique seasons');
      
      _weeks = HistoricalDataService.getUniqueWeeks();
      print('Loaded ${_weeks.length} unique weeks');
      
      _headers = HistoricalDataService.getHeaders();
      print('Loaded ${_headers.length} headers: $_headers');
      
      if (_headers.isNotEmpty && _newQueryField == null) {
        _newQueryField = _headers[0];
      }
      
      if (_selectedFields.any((f) => !_headers.contains(f))) {
        _selectedFields = List.from(_headers);
        print('Using all headers as selected fields');
      }
      
      _applyFilters(); // Initial data load with no filters or default queries

    } catch (e) {
      print('Error in _loadHistoricalData: $e');
      setState(() {
        _error = 'Failed to load historical data: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _applyFilters() {
    print("Applying filters with ${_queryConditions.length} conditions:");
    for (var condition in _queryConditions) {
      print(condition.toString());
    }
    
    setState(() {
      // Pass queryConditions to the service
      _matchups = HistoricalDataService.getMatchups(
        startDate: _startDate,
        endDate: _endDate,
        team: _selectedTeam,
        opponent: _selectedOpponent,
        season: _selectedSeason,
        week: _selectedWeek,
        isHome: _isHome,
        isWin: _isWin,
        isSpreadWin: _isSpreadWin,
        isOver: _isOver,
        queryConditions: _queryConditions, // Pass conditions
      );
      // getRawRows will use the filtered matchups internally if HistoricalDataService is updated accordingly
      // For now, ensure it can also accept queryConditions if it does its own filtering,
      // or rely on getMatchups being the primary source of filtered data.
      // Assuming getRawRows will be updated to use the filtered _matchups list or take queryConditions.
      _rawRows = HistoricalDataService.getRawRows(
         startDate: _startDate,
        endDate: _endDate,
        team: _selectedTeam,
        opponent: _selectedOpponent,
        season: _selectedSeason,
        week: _selectedWeek,
        isHome: _isHome,
        isWin: _isWin,
        isSpreadWin: _isSpreadWin,
        isOver: _isOver,
        queryConditions: _queryConditions, // Pass conditions
      );
      _currentPage = 0; 
    });
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Filter Matchups'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Date Range
                ListTile(
                  title: const Text('Date Range'),
                  subtitle: Text(
                    _startDate == null && _endDate == null
                        ? 'All dates'
                        : '${DateFormat('MM/dd/yyyy').format(_startDate ?? DateTime(2000))} - ${DateFormat('MM/dd/yyyy').format(_endDate ?? DateTime.now())}',
                  ),
                  onTap: () async {
                    final DateTimeRange? range = await showDateRangePicker(
                      context: context,
                      firstDate: DateTime(2000),
                      lastDate: DateTime.now(),
                      initialDateRange: _startDate != null && _endDate != null
                          ? DateTimeRange(start: _startDate!, end: _endDate!)
                          : null,
                    );
                    if (range != null) {
                      setState(() {
                        _startDate = range.start;
                        _endDate = range.end;
                      });
                    }
                  },
                ),
                
                // Team
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Team'),
                  value: _selectedTeam,
                  items: [
                    const DropdownMenuItem(value: null, child: Text('All Teams')),
                    ..._teams.map((team) => DropdownMenuItem(
                      value: team,
                      child: Text(team),
                    )),
                  ],
                  onChanged: (value) {
                    setState(() => _selectedTeam = value);
                  },
                ),
                
                // Opponent
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Opponent'),
                  value: _selectedOpponent,
                  items: [
                    const DropdownMenuItem(value: null, child: Text('All Opponents')),
                    ..._teams.map((team) => DropdownMenuItem(
                      value: team,
                      child: Text(team),
                    )),
                  ],
                  onChanged: (value) {
                    setState(() => _selectedOpponent = value);
                  },
                ),
                
                // Season
                DropdownButtonFormField<int>(
                  decoration: const InputDecoration(labelText: 'Season'),
                  value: _selectedSeason,
                  items: [
                    const DropdownMenuItem(value: null, child: Text('All Seasons')),
                    ..._seasons.map((season) => DropdownMenuItem(
                      value: season,
                      child: Text(season.toString()),
                    )),
                  ],
                  onChanged: (value) {
                    setState(() => _selectedSeason = value);
                  },
                ),
                
                // Week
                DropdownButtonFormField<int>(
                  decoration: const InputDecoration(labelText: 'Week'),
                  value: _selectedWeek,
                  items: [
                    const DropdownMenuItem(value: null, child: Text('All Weeks')),
                    ..._weeks.map((week) => DropdownMenuItem(
                      value: week,
                      child: Text(week.toString()),
                    )),
                  ],
                  onChanged: (value) {
                    setState(() => _selectedWeek = value);
                  },
                ),
                
                // Game Type
                DropdownButtonFormField<bool>(
                  decoration: const InputDecoration(labelText: 'Game Type'),
                  value: _isHome,
                  items: const [
                    DropdownMenuItem(value: null, child: Text('All Games')),
                    DropdownMenuItem(value: true, child: Text('Home Games')),
                    DropdownMenuItem(value: false, child: Text('Away Games')),
                  ],
                  onChanged: (value) {
                    setState(() => _isHome = value);
                  },
                ),
                
                // Result
                DropdownButtonFormField<bool>(
                  decoration: const InputDecoration(labelText: 'Result'),
                  value: _isWin,
                  items: const [
                    DropdownMenuItem(value: null, child: Text('All Results')),
                    DropdownMenuItem(value: true, child: Text('Wins')),
                    DropdownMenuItem(value: false, child: Text('Losses')),
                  ],
                  onChanged: (value) {
                    setState(() => _isWin = value);
                  },
                ),
                
                // Spread Result
                DropdownButtonFormField<bool>(
                  decoration: const InputDecoration(labelText: 'Spread Result'),
                  value: _isSpreadWin,
                  items: const [
                    DropdownMenuItem(value: null, child: Text('All Spread Results')),
                    DropdownMenuItem(value: true, child: Text('Covered')),
                    DropdownMenuItem(value: false, child: Text('Failed to Cover')),
                  ],
                  onChanged: (value) {
                    setState(() => _isSpreadWin = value);
                  },
                ),
                
                // Total Result
                DropdownButtonFormField<bool>(
                  decoration: const InputDecoration(labelText: 'Total Result'),
                  value: _isOver,
                  items: const [
                    DropdownMenuItem(value: null, child: Text('All Total Results')),
                    DropdownMenuItem(value: true, child: Text('Over')),
                    DropdownMenuItem(value: false, child: Text('Under')),
                  ],
                  onChanged: (value) {
                    setState(() => _isOver = value);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _applyFilters();
              },
              child: const Text('Apply'),
            ),
          ],
        ),
      ),
    );
  }

  void _showCustomizeColumnsDialog() {
    showDialog(
      context: context,
      builder: (context) {
        List<String> tempSelected = List.from(_selectedFields);
        return AlertDialog(
          title: const Text('Customize Columns'),
          content: SizedBox(
            width: 400,
            child: SingleChildScrollView(
              child: Column(
                children: _headers.map((header) {
                  return CheckboxListTile(
                    title: Text(header),
                    value: tempSelected.contains(header),
                    onChanged: (checked) {
                      if (checked == true) {
                        tempSelected.add(header);
                      } else {
                        tempSelected.remove(header);
                      }
                      setState(() {});
                    },
                  );
                }).toList(),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _selectedFields = List.from(tempSelected);
                });
                Navigator.pop(context);
              },
              child: const Text('Apply'),
            ),
          ],
        );
      },
    );
  }

  void _sort<T>(Comparable<T> Function(NFLMatchup m) getField, String column) {
    setState(() {
      if (_sortColumn == column) {
        _sortAscending = !_sortAscending;
      } else {
        _sortColumn = column;
        _sortAscending = true;
      }
      
      _matchups.sort((a, b) {
        final aValue = getField(a);
        final bValue = getField(b);
        return _sortAscending
            ? Comparable.compare(aValue, bValue)
            : Comparable.compare(bValue, aValue);
      });
    });
  }

  // Methods for Query Builder
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
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all parts of the query condition.')),
      );
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
    _applyFilters(); 
  }
  
  Widget _buildQueryBuilderSection() {
    if (_headers.isNotEmpty && _newQueryField == null) {
        _newQueryField = _headers[0];
    }
    return Card(
      margin: const EdgeInsets.all(8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Build Query', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16.0),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  flex: 2,
                  child: DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: 'Field'),
                    value: _newQueryField,
                    items: _headers.map((header) => DropdownMenuItem(
                      value: header,
                      child: Text(header, overflow: TextOverflow.ellipsis),
                    )).toList(),
                    onChanged: (value) {
                      setState(() {
                        _newQueryField = value;
                      });
                    },
                    isExpanded: true,
                  ),
                ),
                const SizedBox(width: 8.0),
                Expanded(
                  flex: 2,
                  child: DropdownButtonFormField<QueryOperator>(
                    decoration: const InputDecoration(labelText: 'Operator'),
                    value: _newQueryOperator,
                    items: QueryOperator.values.map((op) => DropdownMenuItem(
                      value: op,
                      child: Text(queryOperatorToString(op)),
                    )).toList(),
                    onChanged: (value) {
                      setState(() {
                        _newQueryOperator = value;
                      });
                    },
                    isExpanded: true,
                  ),
                ),
                const SizedBox(width: 8.0),
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _newQueryValueController,
                    decoration: const InputDecoration(labelText: 'Value'),
                  ),
                ),
                const SizedBox(width: 8.0),
                ElevatedButton(
                  onPressed: _addQueryCondition,
                  child: const Text('Add'),
                ),
              ],
            ),
            const SizedBox(height: 16.0),
            if (_queryConditions.isNotEmpty) ...[
              Text('Current Conditions:', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8.0),
              Wrap(
                spacing: 8.0,
                runSpacing: 4.0,
                children: _queryConditions.asMap().entries.map((entry) {
                  int idx = entry.key;
                  QueryCondition condition = entry.value;
                  return Chip(
                    label: Text(condition.toString()),
                    onDeleted: () => _removeQueryCondition(idx),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16.0),
            ],
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _clearAllQueryConditions,
                  child: const Text('Clear All'),
                ),
                const SizedBox(width: 8.0),
                ElevatedButton.icon(
                  icon: const Icon(Icons.filter_alt_outlined),
                  label: const Text('Apply Queries'),
                  onPressed: _applyFilters,
                ),
                const SizedBox(width: 8.0),
                ElevatedButton.icon(
                  icon: const Icon(Icons.view_column_outlined),
                  label: const Text("Columns"),
                  onPressed: _showCustomizeColumnsDialog,
                )
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_headers.isNotEmpty && _newQueryField == null) {
      _newQueryField = _headers[0]; // Ensure initialized before build
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Historical Data'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            tooltip: 'Quick Filters',
            onPressed: _showFilterDialog, 
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!, style: const TextStyle(color: Colors.red)))
              : Column(
                  children: [
                    _buildQueryBuilderSection(),
                    
                    // Statistics summary card - this can be part of a scrollable area if needed
                    // or kept fixed if it's small. For now, let it be as is.
                    if (_selectedTeam != null)
                      Card(
                        margin: const EdgeInsets.all(8.0),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '$_selectedTeam Statistics',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildStatColumn(
                                      'Overall',
                                      HistoricalDataService.getTeamStats(_selectedTeam!),
                                    ),
                                  ),
                                  Expanded(
                                    child: _buildStatColumn(
                                      'Home',
                                      HistoricalDataService.getTeamStats(_selectedTeam!),
                                      isHome: true,
                                    ),
                                  ),
                                  Expanded(
                                    child: _buildStatColumn(
                                      'Away',
                                      HistoricalDataService.getTeamStats(_selectedTeam!),
                                      isHome: false,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    
                    // Filter summary chips - similar to stats, can be part of overall scroll or fixed.
                    if (_selectedTeam != null ||
                        _selectedOpponent != null ||
                        _selectedSeason != null ||
                        _selectedWeek != null ||
                        _isHome != null ||
                        _isWin != null ||
                        _isSpreadWin != null ||
                        _isOver != null)
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Wrap(
                          spacing: 8.0,
                          children: [
                            if (_selectedTeam != null)
                              FilterChip(label: Text('Team: $_selectedTeam'),onDeleted: () => setState(() {_selectedTeam=null; _applyFilters();}), selected: true, onSelected: (s){ if(!s) setState(() {_selectedTeam=null; _applyFilters();});}),
                            if (_selectedOpponent != null)
                              FilterChip(label: Text('Opponent: $_selectedOpponent'),onDeleted: () => setState(() {_selectedOpponent=null; _applyFilters();}), selected: true, onSelected: (s){ if(!s) setState(() {_selectedOpponent=null; _applyFilters();});}),
                            if (_selectedSeason != null)
                              FilterChip(label: Text('Season: $_selectedSeason'),onDeleted: () => setState(() {_selectedSeason=null; _applyFilters();}), selected: true, onSelected: (s){ if(!s) setState(() {_selectedSeason=null; _applyFilters();});}),
                            if (_selectedWeek != null)
                              FilterChip(label: Text('Week: $_selectedWeek'),onDeleted: () => setState(() {_selectedWeek=null; _applyFilters();}), selected: true, onSelected: (s){ if(!s) setState(() {_selectedWeek=null; _applyFilters();});}),
                            if (_isHome != null)
                              FilterChip(label: Text(_isHome! ? 'Home' : 'Away'),onDeleted: () => setState(() {_isHome=null; _applyFilters();}), selected: true, onSelected: (s){ if(!s) setState(() {_isHome=null; _applyFilters();});}),
                            if (_isWin != null)
                              FilterChip(label: Text(_isWin! ? 'Win' : 'Loss'),onDeleted: () => setState(() {_isWin=null; _applyFilters();}), selected: true, onSelected: (s){ if(!s) setState(() {_isWin=null; _applyFilters();});}),
                            if (_isSpreadWin != null)
                              FilterChip(label: Text(_isSpreadWin! ? 'Cover' : 'No Cover'),onDeleted: () => setState(() {_isSpreadWin=null; _applyFilters();}), selected: true, onSelected: (s){ if(!s) setState(() {_isSpreadWin=null; _applyFilters();});}),
                            if (_isOver != null)
                              FilterChip(label: Text(_isOver! ? 'Over' : 'Under'),onDeleted: () => setState(() {_isOver=null; _applyFilters();}), selected: true, onSelected: (s){ if(!s) setState(() {_isOver=null; _applyFilters();});}),
                          ],
                        ),
                      ),

                    // Data table section
                    Expanded(
                      child: Column( // This Column will contain the table and its pagination
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                            child: Text(
                              _rawRows.isEmpty 
                                ? 'No data to display for the current filters.'
                                : 'Page ${_currentPage + 1} of ${(_rawRows.length / _rowsPerPage).ceil().clamp(1, 999)}. Total: ${_rawRows.length} records.',
                              style: TextStyle(color: Colors.grey.shade700),
                            ),
                          ),
                          Expanded( // This Expanded makes the DataTable's container scrollable
                            child: SingleChildScrollView( // Vertical scroll for DataTable rows
                              child: SingleChildScrollView( // Horizontal scroll for DataTable
                                scrollDirection: Axis.horizontal,
                                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                child: DataTable(
                                  showCheckboxColumn: false,
                                  columns: _selectedFields
                                      .map((header) => DataColumn(
                                            label: Text(header, style: const TextStyle(fontWeight: FontWeight.bold)),
                                          ))
                                      .toList(),
                                  rows: _rawRows.isEmpty 
                                      ? [] 
                                      : _rawRows
                                          .skip(_currentPage * _rowsPerPage)
                                          .take(_rowsPerPage)
                                          .toList() // Make a modifiable list for asMap
                                          .asMap() // For alternating row colors
                                          .map((index, row) => MapEntry(index, DataRow(
                                                color: WidgetStateProperty.resolveWith<Color?>(
                                                  (Set<WidgetState> states) {
                                                    if (index.isEven) return Colors.grey.withOpacity(0.08);
                                                    return null; 
                                                  },
                                                ),
                                                cells: _selectedFields
                                                    .map((header) => DataCell(
                                                          Text(row[header] ?? 'N/A', 
                                                            style: TextStyle(
                                                              color: row[header] == null ? Colors.grey.shade600 : null,
                                                            ),
                                                          ),
                                                        ))
                                                    .toList(),
                                              )))
                                          .values
                                          .toList(),
                                ),
                              ),
                            ),
                          ),
                          // Pagination controls
                          if (_rawRows.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  ElevatedButton(
                                    onPressed: _currentPage > 0
                                        ? () => setState(() => _currentPage--)
                                        : null,
                                    child: const Text('Previous'),
                                  ),
                                  const SizedBox(width: 16),
                                  Text('Page ${_currentPage + 1} of ${(_rawRows.length / _rowsPerPage).ceil().clamp(1, 999)}'),
                                  const SizedBox(width: 16),
                                  ElevatedButton(
                                    onPressed: (_currentPage + 1) * _rowsPerPage < _rawRows.length
                                        ? () => setState(() => _currentPage++)
                                        : null,
                                    child: const Text('Next'),
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

  Widget _buildStatColumn(String title, Map<String, dynamic> stats, {bool? isHome}) {
    Map<String, dynamic> filteredStats = {};
    if (isHome != null) {
      filteredStats = {
        'games': isHome ? stats['homeGames'] : stats['awayGames'],
        'wins': isHome ? stats['homeWins'] : stats['awayWins'],
        'winPct': (isHome ? stats['homeWinPercentage'] : stats['awayWinPercentage']) ?? 0.0,
      };
    } else {
      filteredStats = {
        'games': stats['totalGames'],
        'wins': stats['wins'],
        'winPct': stats['winPercentage'] ?? 0.0,
        'spreadWins': stats['spreadWins'],
        'spreadWinPct': stats['spreadWinPercentage'] ?? 0.0,
        'overs': stats['overs'],
        'overPct': stats['overPercentage'] ?? 0.0,
      };
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        _buildStatRow('Games', (filteredStats['games'] ?? 0).toString()),
        _buildStatRow('Wins', (filteredStats['wins'] ?? 0).toString()),
        _buildStatRow('Win %', '${((filteredStats['winPct'] as double) * 100).toStringAsFixed(1)}%'),
        if (isHome == null) ...[
          _buildStatRow('ATS Wins', (filteredStats['spreadWins'] ?? 0).toString()),
          _buildStatRow('ATS %', '${((filteredStats['spreadWinPct'] as double) * 100).toStringAsFixed(1)}%'),
          _buildStatRow('Overs', (filteredStats['overs'] ?? 0).toString()),
          _buildStatRow('Over %', '${((filteredStats['overPct'] as double) * 100).toStringAsFixed(1)}%'),
        ],
      ],
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
} 