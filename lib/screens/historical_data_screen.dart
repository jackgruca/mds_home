import 'package:flutter/material.dart';
import 'package:mds_home/widgets/common/app_drawer.dart';
import 'package:mds_home/models/nfl_matchup.dart'; // Import the centralized model
import 'package:intl/intl.dart';
import 'package:mds_home/widgets/analytics/visualization_tab.dart';
import 'package:mds_home/widgets/analytics/quick_start_templates.dart';
import '../../widgets/common/top_nav_bar.dart';
import '../../widgets/common/custom_app_bar.dart';
import '../../widgets/auth/auth_dialog.dart';
import 'package:cloud_functions/cloud_functions.dart';

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

class _HistoricalDataScreenState extends State<HistoricalDataScreen> with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  String? _error;
  List<Map<String, dynamic>> _rawRows = [];
  List<NFLMatchup> _matchupsForViz = []; // For VisualizationTab
  int _totalRecords = 0;
  
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
  final List<String> _teams = [];
  final List<int> _seasons = [];
  final List<int> _weeks = [];
  
  // Sort state
  String _sortColumn = 'Date';
  bool _sortAscending = false;

  List<String> _headers = [];
  
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

  // Add new state variables for sorting and filtering
  final Map<String, bool> _columnSortAscending = {};
  final Map<String, List<String>> _columnFilters = {};

  late TabController _tabController;
  FirebaseFunctions functions = FirebaseFunctions.instance;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _headers = _defaultFields;
    if (_headers.isNotEmpty) _newQueryField = _headers[0];
    
    _fetchDataFromFirebase();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _newQueryValueController.dispose();
    super.dispose();
  }

  Future<void> _fetchDataFromFirebase() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    Map<String, dynamic> filtersForFunction = {};
    for (var condition in _queryConditions) {
      filtersForFunction[condition.field] = condition.value;
    }

    try {
      final HttpsCallable callable = functions.httpsCallable('getHistoricalMatchups');
      final result = await callable.call<Map<String, dynamic>>({
        'filters': filtersForFunction,
        'limit': _rowsPerPage,
        'offset': _currentPage * _rowsPerPage,
        'orderBy': _sortColumn,
        'orderDirection': _sortAscending ? 'asc' : 'desc',
      });

      if (mounted) {
        setState(() {
          final List<dynamic> data = result.data['data'] ?? [];
          _rawRows = data.map((item) => Map<String, dynamic>.from(item)).toList();
          _matchupsForViz = _rawRows.map((row) => NFLMatchup.fromFirestoreMap(row)).toList();
          _totalRecords = result.data['totalRecords'] ?? 0;

          if (_rawRows.isNotEmpty) {
            _headers = _rawRows.first.keys.toList();
            if (!_headers.contains(_newQueryField) && _headers.isNotEmpty) {
              _newQueryField = _headers[0];
            }
            _selectedFields = _selectedFields.where((sf) => _headers.contains(sf)).toList();
            if (_selectedFields.isEmpty && _headers.isNotEmpty) {
              _selectedFields = _headers.take(5).toList();
            }
          }
          _isLoading = false;
        });
      }
    } on FirebaseFunctionsException catch (e) {
      print('FirebaseFunctionsException caught in Flutter client:');
      print('Code: ${e.code}');
      print('Message: ${e.message}');
      print('Details: ${e.details}');
      if (mounted) {
        setState(() {
          String displayError = 'Error fetching data: ${e.message}';
          if (e.code == 'failed-precondition') {
            displayError = 'Query Error: A required Firestore index is missing. Please check the Firebase Functions logs for a link to create it. Details: ${e.message}';
          } else if (e.message != null && e.message!.toLowerCase().contains('index')){
            displayError = 'Query Error: There might be an issue with Firestore indexes. Please check Firebase Functions logs. Details: ${e.message}';
          }
           _error = displayError;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Generic error in _fetchDataFromFirebase (client-side): $e');
      if (mounted) {
        setState(() {
          _error = 'An unexpected error occurred on the client: $e';
          _isLoading = false;
        });
      }
    }
  }

  void _applyFiltersAndFetch() {
    _currentPage = 0;
    _fetchDataFromFirebase();
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: const Text('Filter Matchups (Legacy)'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Team'),
                  value: _selectedTeam,
                  items: [
                    const DropdownMenuItem(value: null, child: Text('All Teams')),
                    ..._teams.map((team) => DropdownMenuItem(value: team, child: Text(team))),
                  ],
                  onChanged: (value) {
                    setStateDialog(() => _selectedTeam = value);
                  },
                ),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Opponent'),
                  value: _selectedOpponent,
                  items: [
                    const DropdownMenuItem(value: null, child: Text('All Opponents')),
                    ..._teams.map((team) => DropdownMenuItem(value: team, child: Text(team))),
                  ],
                  onChanged: (value) {
                    setStateDialog(() => _selectedOpponent = value);
                  },
                ),
                DropdownButtonFormField<int>(
                  decoration: const InputDecoration(labelText: 'Season'),
                  value: _selectedSeason,
                  items: [
                    const DropdownMenuItem(value: null, child: Text('All Seasons')),
                    ..._seasons.map((season) => DropdownMenuItem(value: season, child: Text(season.toString()))),
                  ],
                  onChanged: (value) {
                    setStateDialog(() => _selectedSeason = value);
                  },
                ),
                DropdownButtonFormField<int>(
                  decoration: const InputDecoration(labelText: 'Week'),
                  value: _selectedWeek,
                  items: [
                    const DropdownMenuItem(value: null, child: Text('All Weeks')),
                    ..._weeks.map((week) => DropdownMenuItem(value: week, child: Text(week.toString()))),
                  ],
                  onChanged: (value) {
                    setStateDialog(() => _selectedWeek = value);
                  },
                ),
                DropdownButtonFormField<bool>(
                  decoration: const InputDecoration(labelText: 'Game Type'),
                  value: _isHome,
                  items: const [
                    DropdownMenuItem(value: null, child: Text('All Games')),
                    DropdownMenuItem(value: true, child: Text('Home Games')),
                    DropdownMenuItem(value: false, child: Text('Away Games')),
                  ],
                  onChanged: (value) {
                    setStateDialog(() => _isHome = value);
                  },
                ),
                DropdownButtonFormField<bool>(
                  decoration: const InputDecoration(labelText: 'Result'),
                  value: _isWin,
                  items: const [
                    DropdownMenuItem(value: null, child: Text('All Results')),
                    DropdownMenuItem(value: true, child: Text('Wins')),
                    DropdownMenuItem(value: false, child: Text('Losses')),
                  ],
                  onChanged: (value) {
                    setStateDialog(() => _isWin = value);
                  },
                ),
                DropdownButtonFormField<bool>(
                  decoration: const InputDecoration(labelText: 'Spread Result'),
                  value: _isSpreadWin,
                  items: const [
                    DropdownMenuItem(value: null, child: Text('All Spread Results')),
                    DropdownMenuItem(value: true, child: Text('Covered')),
                    DropdownMenuItem(value: false, child: Text('Failed to Cover')),
                  ],
                  onChanged: (value) {
                    setStateDialog(() => _isSpreadWin = value);
                  },
                ),
                DropdownButtonFormField<bool>(
                  decoration: const InputDecoration(labelText: 'Total Result'),
                  value: _isOver,
                  items: const [
                    DropdownMenuItem(value: null, child: Text('All Total Results')),
                    DropdownMenuItem(value: true, child: Text('Over')),
                    DropdownMenuItem(value: false, child: Text('Under')),
                  ],
                  onChanged: (value) {
                    setStateDialog(() => _isOver = value);
                  },
                ),
                const Text("Note: Apply these via 'Build Query' for now for Firebase integration.", style: TextStyle(color: Colors.orange)),
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
                Navigator.pop(context);
                _applyFiltersAndFetch();
              },
              child: const Text('Apply (Legacy)'),
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
        List<String> currentAvailableHeaders = List.from(_headers);

        return AlertDialog(
          title: const Text('Customize Columns'),
          content: SizedBox(
            width: 400,
            child: SingleChildScrollView(
              child: Column(
                children: currentAvailableHeaders.map((header) {
                  return CheckboxListTile(
                    title: Text(header),
                    value: tempSelected.contains(header),
                    onChanged: (checked) {
                      if (checked == true) {
                        tempSelected.add(header);
                      } else {
                        tempSelected.remove(header);
                      }
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
    _applyFiltersAndFetch();
  }
  
  @override
  Widget build(BuildContext context) {
    final currentRouteName = ModalRoute.of(context)?.settings.name;
    final theme = Theme.of(context);

    final PreferredSizeWidget tabBarBottom = PreferredSize(
      preferredSize: const Size.fromHeight(kTextTabBarHeight),
      child: TabBar(
        controller: _tabController,
        tabs: const [
          Tab(text: 'Data Table'),
          Tab(text: 'Visualizations'),
        ],
      ),
    );

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
          IconButton(
            icon: const Icon(Icons.filter_list),
            tooltip: 'Quick Filters (Legacy)',
            onPressed: _showFilterDialog,
          ),
           Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ElevatedButton(
              onPressed: () => showDialog(context: context, builder: (_) => const AuthDialog()),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                textStyle: const TextStyle(fontSize: 14),
              ),
              child: const Text('Sign In / Sign Up'),
            ),
          ),
        ],
        bottom: tabBarBottom,
      ),
      drawer: const AppDrawer(),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.yellow[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.amber.shade200, width: 1),
            ),
            child: ExpansionTile(
              leading: const Icon(Icons.lightbulb_outline, color: Colors.amber, size: 26),
              title: Text(
                'Quick Ideas (Tap to Expand)',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold, fontSize: 16, color: Colors.amber[900],
                ),
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: QuickStartTemplates.templates.map((template) => Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4.0),
                        child: ActionChip(
                          label: Text(template.name),
                          tooltip: template.description,
                          onPressed: () {
                            setState(() {
                              _queryConditions.clear();
                              _queryConditions.addAll(template.conditions);
                              _applyFiltersAndFetch();
                            });
                          },
                        ),
                      )).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Build Query', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, fontSize: 18)),
                      TextButton(
                        onPressed: _showCustomizeColumnsDialog,
                        child: const Text('Customize Columns', style: TextStyle(fontSize: 15)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8.0),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        flex: 2,
                        child: DropdownButtonFormField<String>(
                          decoration: const InputDecoration(labelText: 'Field', contentPadding: EdgeInsets.symmetric(vertical: 6, horizontal: 8), isDense: true, labelStyle: TextStyle(fontSize: 17)),
                          value: _headers.contains(_newQueryField) ? _newQueryField : null,
                          items: _headers.map((header) => DropdownMenuItem(
                            value: header,
                            child: Text(header, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 17)),
                          )).toList(),
                          onChanged: (value) {
                            setState(() => _newQueryField = value);
                          },
                          isExpanded: true,
                        ),
                      ),
                      const SizedBox(width: 6.0),
                      Expanded(
                        flex: 2,
                        child: DropdownButtonFormField<QueryOperator>(
                          decoration: const InputDecoration(labelText: 'Operator', contentPadding: EdgeInsets.symmetric(vertical: 6, horizontal: 8), isDense: true, labelStyle: TextStyle(fontSize: 17)),
                          value: _newQueryOperator,
                          items: QueryOperator.values.map((op) => DropdownMenuItem(
                            value: op,
                            child: Text(queryOperatorToString(op), style: const TextStyle(fontSize: 17)),
                          )).toList(),
                          onChanged: (value) {
                            setState(() => _newQueryOperator = value);
                          },
                          isExpanded: true,
                        ),
                      ),
                      const SizedBox(width: 6.0),
                      Expanded(
                        flex: 2,
                        child: TextField(
                          controller: _newQueryValueController,
                          style: const TextStyle(fontSize: 17),
                          decoration: const InputDecoration(labelText: 'Value', contentPadding: EdgeInsets.symmetric(vertical: 6, horizontal: 8), isDense: true, labelStyle: TextStyle(fontSize: 17)),
                        ),
                      ),
                      const SizedBox(width: 6.0),
                      SizedBox(
                        height: 36,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 0), textStyle: const TextStyle(fontSize: 16)),
                          onPressed: _addQueryCondition,
                          child: const Text('Add'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8.0),
                  if (_queryConditions.isNotEmpty) ...[
                    Text('Current Conditions:', style: Theme.of(context).textTheme.bodySmall),
                    const SizedBox(height: 4.0),
                    Wrap(
                      spacing: 6.0,
                      runSpacing: 2.0,
                      children: _queryConditions.asMap().entries.map((entry) {
                        int idx = entry.key;
                        QueryCondition condition = entry.value;
                        return Chip(
                          label: Text(condition.toString(), style: const TextStyle(fontSize: 12)),
                          onDeleted: () => _removeQueryCondition(idx),
                          visualDensity: VisualDensity.compact,
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 8.0),
                  ],
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        style: TextButton.styleFrom(minimumSize: const Size(36, 32), padding: const EdgeInsets.symmetric(horizontal: 8)),
                        onPressed: _clearAllQueryConditions,
                        child: const Text('Clear All', style: TextStyle(fontSize: 13)),
                      ),
                      const SizedBox(width: 6.0),
                      SizedBox(
                        height: 32,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0), textStyle: const TextStyle(fontSize: 13)),
                          icon: const Icon(Icons.filter_alt_outlined, size: 16),
                          label: const Text('Apply Queries'),
                          onPressed: _applyFiltersAndFetch,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
                  ? Center(child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 16), textAlign: TextAlign.center,)
                    ))
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _buildDataTableTab(),
                        VisualizationTab(
                          matchups: _matchupsForViz,
                          selectedTeam: _selectedTeam,
                          currentFilters: _queryConditions,
                          onApplyFilter: (conditions) {
                            setState(() {
                              _queryConditions.clear();
                              _queryConditions.addAll(conditions);
                              _applyFiltersAndFetch();
                            });
                          },
                        ),
                      ],
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataTableTab() {
    if (_rawRows.isEmpty && !_isLoading && _error == null) {
      return const Center(child: Text('No data to display. Try adjusting your filters.'));
    }
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
          child: Text(
            _rawRows.isEmpty
                ? 'No data to display for the current filters.'
                : 'Page ${(_currentPage) + 1} of ${(_totalRecords / _rowsPerPage).ceil().clamp(1, 9999)}. Total: $_totalRecords records.',
            style: TextStyle(color: Colors.grey.shade700),
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: DataTable(
                showCheckboxColumn: false,
                sortColumnIndex: _headers.indexOf(_sortColumn).clamp(0, _headers.isNotEmpty ? _headers.length -1 : 0),
                sortAscending: _sortAscending,
                columns: _selectedFields.map((header) {
                  return DataColumn(
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(header, style: const TextStyle(fontWeight: FontWeight.bold)),
                        if (_sortColumn == header)
                          Icon(
                            _sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
                            size: 16,
                          ),
                      ],
                    ),
                    onSort: (columnIndex, ascending) {
                      setState(() {
                        _sortColumn = _selectedFields[columnIndex];
                        _sortAscending = ascending;
                        _applyFiltersAndFetch();
                      });
                    },
                    tooltip: 'Sort by $header',
                  );
                }).toList(),
                rows: _rawRows.isEmpty 
                  ? [] 
                  : _rawRows
                      .map((rowMap) => DataRow(
                            cells: _selectedFields.map((header) {
                              final value = rowMap[header];
                              String displayValue = 'N/A';
                              if (value != null) {
                                if (value is String && (header == 'Date' || header.endsWith('_date'))) {
                                  try {
                                    displayValue = DateFormat('MM/dd/yyyy').format(DateTime.parse(value));
                                  } catch (e) {
                                    displayValue = value;
                                  }
                                } else {
                                  displayValue = value.toString();
                                }
                              }
                              return DataCell(Text(
                                displayValue,
                                style: TextStyle(
                                  color: displayValue == 'N/A' ? Colors.grey.shade600 : null,
                                ),
                              ));
                            }).toList(),
                          ))
                      .toList(),
              ),
            ),
          ),
        ),
        if (_rawRows.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: _currentPage > 0
                      ? () => setState(() { _currentPage--; _fetchDataFromFirebase(); })
                      : null,
                  child: const Text('Previous'),
                ),
                const SizedBox(width: 16),
                Text('Page ${(_currentPage) + 1} of ${(_totalRecords / _rowsPerPage).ceil().clamp(1,9999)}'),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: (_currentPage + 1) * _rowsPerPage < _totalRecords
                      ? () => setState(() { _currentPage++; _fetchDataFromFirebase(); })
                      : null,
                  child: const Text('Next'),
                ),
              ],
            ),
          ),
      ],
    );
  }
} 