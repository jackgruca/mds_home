import 'package:flutter/material.dart';
import 'package:mds_home/widgets/common/app_drawer.dart';
import 'package:mds_home/widgets/common/top_nav_bar.dart';
import 'package:mds_home/widgets/common/custom_app_bar.dart';
import 'package:mds_home/widgets/auth/auth_dialog.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:mds_home/utils/team_logo_utils.dart';

// Enum for Query Operators (reusing from historical_data_screen.dart)
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

class _PlayerSeasonStatsScreenState extends State<PlayerSeasonStatsScreen> {
  bool _isLoading = true;
  String? _error;
  List<Map<String, dynamic>> _rawRows = [];
  int _totalRecords = 0;

  // Pagination state
  int _currentPage = 0;
  static const int _rowsPerPage = 25;
  List<dynamic> _pageCursors = [null]; // Stores cursors for each page
  dynamic _nextCursor; // Cursor for the next page, received from backend

  // For preloading next pages
  final Map<int, List<Map<String, dynamic>>> _preloadedPages = {};
  final Map<int, dynamic> _preloadedCursors = {};
  static const int _pagesToPreload = 2; // How many pages to preload ahead

  // Sort state
  String _sortColumn = 'season';
  bool _sortAscending = false;

  // Position Filter
  String _selectedPosition = 'All'; // Default position filter
  final List<String> _positions = ['All', 'QB', 'RB', 'WR', 'TE'];

  List<String> _headers = [];
  List<String> _selectedFields = []; // Initially empty, populated from data

  // State for Query Builder
  final List<QueryCondition> _queryConditions = [];
  String? _newQueryField;
  QueryOperator? _newQueryOperator;
  final TextEditingController _newQueryValueController =
      TextEditingController();

  FirebaseFunctions functions = FirebaseFunctions.instance;

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
    _fetchDataFromFirebase();
  }

  @override
  void dispose() {
    _newQueryValueController.dispose();
    super.dispose();
  }

  // Helper to determine field type for query input
  String getFieldType(String field) {
    const Set<String> doubleFields = {
      'passing_yards_per_attempt', 'passing_tds_per_attempt',
      'rushing_yards_per_attempt', 'rushing_tds_per_attempt',
      'yards_per_reception', 'receiving_tds_per_reception',
      'yards_per_touch', 'wopr'
    };
    const Set<String> intFields = {
      'season', 'games', 'completions', 'attempts', 'passing_yards', 'passing_tds',
      'interceptions', 'sacks', 'sack_yards', 'rushing_attempts', 'rushing_yards',
      'rushing_tds', 'receptions', 'targets', 'receiving_yards', 'receiving_tds',
      'fantasy_points', 'fantasy_points_ppr',
    };
    if (doubleFields.contains(field)) return 'double';
    if (intFields.contains(field)) return 'int';
    return 'string';
  }

  Future<void> _fetchDataFromFirebase() async {
    // Check if the requested page is already preloaded
    if (_preloadedPages.containsKey(_currentPage)) {
      print('[Preload] Using preloaded data for page $_currentPage');
      setState(() {
        _rawRows = _preloadedPages[_currentPage]!;
        _nextCursor = _preloadedCursors[_currentPage];
        _preloadedPages.remove(_currentPage);
        _preloadedCursors.remove(_currentPage);
        _isLoading = false;
      });
      _startPreloadingNextPages();
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    Map<String, dynamic> filtersForFunction = {};
    for (var condition in _queryConditions) {
      filtersForFunction[condition.field] = condition.value;
    }
    // Add position filter
    if (_selectedPosition != 'All') {
      filtersForFunction['position'] = _selectedPosition;
    }

    final dynamic currentCursor =
        _currentPage > 0 ? _pageCursors[_currentPage] : null;

    try {
      final HttpsCallable callable =
          functions.httpsCallable('getPlayerSeasonStats');
      final result = await callable.call<Map<String, dynamic>>({
        'filters': filtersForFunction,
        'limit': _rowsPerPage,
        'orderBy': _sortColumn,
        'orderDirection': _sortAscending ? 'asc' : 'desc',
        'cursor': currentCursor,
      });

      if (mounted) {
        setState(() {
          final List<dynamic> data = result.data['data'] ?? [];
          _rawRows =
              data.map((item) => Map<String, dynamic>.from(item)).toList();
          _totalRecords = result.data['totalRecords'] ?? 0;
          _nextCursor = result.data['nextCursor'];

          if (_rawRows.isNotEmpty) {
            _headers = _rawRows.first.keys.toList();
            if (!_headers.contains(_newQueryField) && _headers.isNotEmpty) {
              _newQueryField = _headers[0];
            }
            // Initialize selected fields on first load
            if (_selectedFields.isEmpty) {
              _selectedFields = _headers;
            }
          }
          _isLoading = false;
        });
      }
      _startPreloadingNextPages();
    } on FirebaseFunctionsException catch (e) {
      if (mounted) {
        setState(() {
          _error =
              "Error: ${e.message}\nThis may require a new index in Firebase. The request has been logged.";
          _isLoading = false;
        });
      }
    } catch (e, stack) {
      if (mounted) {
        setState(() {
          _error = 'An unexpected error occurred: $e\n$stack';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _startPreloadingNextPages() async {
    if (_nextCursor == null) return;

    Map<String, dynamic> filtersForFunction = {};
    for (var condition in _queryConditions) {
      filtersForFunction[condition.field] = condition.value;
    }
    if (_selectedPosition != 'All') {
      filtersForFunction['position'] = _selectedPosition;
    }


    dynamic currentPreloadCursor = _nextCursor;
    int preloadPageIndex = _currentPage + 1;

    for (int i = 0; i < _pagesToPreload; i++) {
      if (currentPreloadCursor == null) break;
      if (_preloadedPages.containsKey(preloadPageIndex)) {
        currentPreloadCursor = _preloadedCursors[preloadPageIndex];
        preloadPageIndex++;
        continue;
      }

      try {
        final HttpsCallable callable =
            functions.httpsCallable('getPlayerSeasonStats');
        final result = await callable.call<Map<String, dynamic>>({
          'filters': filtersForFunction,
          'limit': _rowsPerPage,
          'orderBy': _sortColumn,
          'orderDirection': _sortAscending ? 'asc' : 'desc',
          'cursor': currentPreloadCursor,
        });

        final List<dynamic> data = result.data['data'] ?? [];
        final dynamic receivedNextCursor = result.data['nextCursor'];

        if (data.isNotEmpty) {
          if (mounted) {
            _preloadedPages[preloadPageIndex] =
                data.map((item) => Map<String, dynamic>.from(item)).toList();
            _preloadedCursors[preloadPageIndex] = receivedNextCursor;
          }
        }
        currentPreloadCursor = receivedNextCursor;
        preloadPageIndex++;
      } catch (e) {
        print('[Preload] Error preloading page $preloadPageIndex: $e');
        currentPreloadCursor = null;
      }
    }
  }

  void _applyFiltersAndFetch() {
    _currentPage = 0;
    _pageCursors = [null];
    _nextCursor = null;
    _preloadedPages.clear();
    _preloadedCursors.clear();
    _fetchDataFromFirebase();
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
    _applyFiltersAndFetch();
  }

  @override
  Widget build(BuildContext context) {
    final currentRouteName = ModalRoute.of(context)?.settings.name;
    final theme = Theme.of(context);

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
          Card(
            margin: const EdgeInsets.all(12),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Build Query',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8.0),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // Position Dropdown
                      Expanded(
                        flex: 1,
                        child: DropdownButtonFormField<String>(
                          decoration:
                              const InputDecoration(labelText: 'Position'),
                          value: _selectedPosition,
                          items: _positions
                              .map((pos) => DropdownMenuItem(
                                    value: pos,
                                    child: Text(pos),
                                  ))
                              .toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                _selectedPosition = value;
                              });
                              _applyFiltersAndFetch();
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 8.0),
                      // Field Dropdown
                      Expanded(
                        flex: 2,
                        child: DropdownButtonFormField<String>(
                          decoration: const InputDecoration(labelText: 'Field'),
                          value: _headers.contains(_newQueryField)
                              ? _newQueryField
                              : null,
                          items: _headers
                              .map((header) => DropdownMenuItem(
                                    value: header,
                                    child: Text(header,
                                        overflow: TextOverflow.ellipsis),
                                  ))
                              .toList(),
                          onChanged: (value) {
                            setState(() {
                              _newQueryField = value;
                              _newQueryOperator = null;
                              _newQueryValueController.clear();
                            });
                          },
                          isExpanded: true,
                        ),
                      ),
                      const SizedBox(width: 8.0),
                      // Operator Dropdown
                      Expanded(
                        flex: 2,
                        child: DropdownButtonFormField<QueryOperator>(
                          decoration: const InputDecoration(labelText: 'Operator'),
                          value: _newQueryOperator,
                          items: _allOperators
                              .map((op) => DropdownMenuItem(
                                    value: op,
                                    child: Text(queryOperatorToString(op)),
                                  ))
                              .toList(),
                          onChanged: (value) {
                            setState(() => _newQueryOperator = value);
                          },
                          isExpanded: true,
                        ),
                      ),
                      const SizedBox(width: 8.0),
                      // Value Input
                      Expanded(
                        flex: 2,
                        child: TextField(
                          controller: _newQueryValueController,
                          decoration: const InputDecoration(labelText: 'Value'),
                          keyboardType: getFieldType(_newQueryField ?? '') == 'int' || getFieldType(_newQueryField ?? '') == 'double'
                              ? TextInputType.numberWithOptions(decimal: getFieldType(_newQueryField ?? '') == 'double')
                              : TextInputType.text,
                        ),
                      ),
                      const SizedBox(width: 8.0),
                      ElevatedButton(
                        onPressed: _addQueryCondition,
                        child: const Text('Add'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8.0),
                  if (_queryConditions.isNotEmpty) ...[
                    Text('Current Conditions:',
                        style: Theme.of(context).textTheme.bodySmall),
                    Wrap(
                      spacing: 6.0,
                      runSpacing: 2.0,
                      children: _queryConditions
                          .asMap()
                          .entries
                          .map((entry) => Chip(
                                label: Text(entry.value.toString()),
                                onDeleted: () =>
                                    _removeQueryCondition(entry.key),
                              ))
                          .toList(),
                    ),
                  ],
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: _clearAllQueryConditions,
                        child: const Text('Clear All'),
                      ),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.filter_alt_outlined),
                        label: const Text('Apply Queries'),
                        onPressed: _applyFiltersAndFetch,
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
                    ? Center(
                        child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(_error!,
                            style: const TextStyle(
                                color: Colors.red, fontSize: 16),
                            textAlign: TextAlign.center),
                      ))
                    : _buildDataTable(),
          ),
        ],
      ),
    );
  }

  Widget _buildDataTable() {
    if (_rawRows.isEmpty && !_isLoading && _error == null) {
      return const Center(
          child: Text('No data found. Try adjusting your filters.',
              style: TextStyle(fontSize: 16)));
    }

    final Set<String> doubleFields = {
      'passing_yards_per_attempt', 'passing_tds_per_attempt',
      'rushing_yards_per_attempt', 'rushing_tds_per_attempt',
      'yards_per_reception', 'receiving_tds_per_reception',
      'yards_per_touch', 'wopr'
    };

    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          sortColumnIndex:
              _headers.contains(_sortColumn) ? _headers.indexOf(_sortColumn) : null,
          sortAscending: _sortAscending,
          columns: _headers.map((header) {
            return DataColumn(
              label: Text(header),
              onSort: (columnIndex, ascending) {
                setState(() {
                  _sortColumn = _headers[columnIndex];
                  _sortAscending = ascending;
                  _applyFiltersAndFetch();
                });
              },
            );
          }).toList(),
          rows: _rawRows.map((row) {
            return DataRow(
              cells: _headers.map((header) {
                final value = row[header];
                String displayValue;

                if (value == null) {
                  displayValue = 'N/A';
                } else if (doubleFields.contains(header) && value is num) {
                  displayValue = value.toStringAsFixed(2);
                } else {
                  displayValue = value.toString();
                }

                return DataCell(
                  header == 'recent_team'
                      ? Row(
                          children: [
                            TeamLogoUtils.buildNFLTeamLogo(
                              value.toString(),
                              size: 24.0,
                            ),
                            const SizedBox(width: 8),
                            Text(displayValue),
                          ],
                        )
                      : Text(displayValue),
                );
              }).toList(),
            );
          }).toList(),
        ),
      ),
    );
  }
} 