// lib/screens/betting_analytics_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:mds_home/models/query_condition.dart';
import 'package:mds_home/utils/team_logo_utils.dart';
import 'package:mds_home/widgets/auth/auth_dialog.dart';
import 'package:mds_home/widgets/common/custom_app_bar.dart';
import 'package:mds_home/widgets/common/top_nav_bar.dart';
import 'package:mds_home/widgets/common/app_drawer.dart';

class BettingAnalyticsScreen extends StatefulWidget {
  const BettingAnalyticsScreen({super.key});

  @override
  State<BettingAnalyticsScreen> createState() => _BettingAnalyticsScreenState();
}

class _BettingAnalyticsScreenState extends State<BettingAnalyticsScreen> {
  bool _isLoading = true;
  String? _error;
  List<Map<String, dynamic>> _rows = [];
  int _totalRecords = 0;
  
  // Pagination state
  int _currentPage = 0;
  static const int _rowsPerPage = 25;
  List<dynamic> _pageCursors = [null]; // Stores cursors for each page
  dynamic _nextCursor; // Cursor for the next page, received from backend

  // For preloading next pages - ADDED FROM PLAYER SEASON STATS
  final Map<int, List<Map<String, dynamic>>> _preloadedPages = {};
  final Map<int, dynamic> _preloadedCursors = {};
  static const int _pagesToPreload = 2; // How many pages to preload ahead

  String _sortColumn = 'gameday';
  bool _sortAscending = false;

  final List<QueryCondition> _queryConditions = [];
  String? _newQueryField;
  QueryOperator? _newQueryOperator;
  final TextEditingController _newQueryValueController = TextEditingController();

  final FirebaseFunctions _functions = FirebaseFunctions.instance;
  
  String _selectedStatCategory = 'Game Lines';

  static const Map<String, List<String>> _fieldGroups = {
    'Game Lines': ['gameday', 'home_team', 'away_team', 'spread_line', 'total_line', 'home_moneyline', 'away_moneyline'],
    'Results': ['gameday', 'home_team', 'home_score', 'away_team', 'away_score', 'result', 'total_actual'],
    'Coverage': ['gameday', 'home_team', 'spread_line', 'result', 'home_team_covered', 'away_team_covered'],
    'Over/Under': ['gameday', 'home_team', 'away_team', 'total_line', 'total_actual', 'over_hit', 'under_hit'],
  };
  
  List<String> _headers = [];

  // Field types for formatting
  final Set<String> doubleFields = {
    'spread_line', 'total_line', 'home_score', 'away_score', 'point_differential',
    'win_probability', 'win_probability_vegas', 'over_probability',
    'home_win_pct', 'away_win_pct', 'home_cover_pct', 'away_cover_pct',
    'over_pct', 'under_pct', 'total_actual'
  };
  
  // For percentile-based shading
  List<String> numericShadingColumns = [];
  Map<String, Map<num, double>> columnPercentiles = {};

  // Helper function to format header names prettily with abbreviations
  String _formatHeaderName(String header) {
    // Define abbreviations and pretty names for betting data
    final Map<String, String> headerMap = {
      'gameday': 'Date',
      'home_team': 'Home',
      'away_team': 'Away',
      'spread_line': 'Spread',
      'total_line': 'Total',
      'home_moneyline': 'Home ML',
      'away_moneyline': 'Away ML',
      'home_score': 'Home Pts',
      'away_score': 'Away Pts',
      'total_actual': 'Final Total',
      'point_differential': 'Diff',
      'home_team_covered': 'Home Cover',
      'away_team_covered': 'Away Cover',
      'over_hit': 'Over',
      'under_hit': 'Under',
      'win_probability': 'Win Prob',
      'win_probability_vegas': 'Vegas Prob',
      'over_probability': 'Over Prob',
      'home_win_pct': 'Home Win%',
      'away_win_pct': 'Away Win%',
      'home_cover_pct': 'Home Cover%',
      'away_cover_pct': 'Away Cover%',
      'over_pct': 'Over%',
      'under_pct': 'Under%',
    };

    // Return mapped name if exists, otherwise format the original
    if (headerMap.containsKey(header)) {
      return headerMap[header]!;
    }
    
    // For unmapped headers, convert snake_case to Title Case
    return header
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) => word.isEmpty ? '' : word[0].toUpperCase() + word.substring(1).toLowerCase())
        .join(' ');
  }

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    // Check if the requested page is already preloaded
    if (_preloadedPages.containsKey(_currentPage)) {
      print('[Preload] Using preloaded data for page $_currentPage');
      setState(() {
        _rows = _preloadedPages[_currentPage]!;
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

    // Get cursor for current page - ensure it's properly formatted
    dynamic currentCursor;
    if (_currentPage > 0 && _pageCursors.length > _currentPage && _pageCursors[_currentPage] != null) {
      currentCursor = _pageCursors[_currentPage];
      // Ensure cursor is in proper array format
      if (currentCursor is List) {
        // Already in correct format
        print('[BettingAnalytics] Using array cursor: $currentCursor');
      } else {
        // Convert to null if not proper format
        print('[BettingAnalytics] Invalid cursor format, setting to null');
        currentCursor = null;
      }
    } else {
      currentCursor = null;
      print('[BettingAnalytics] No cursor for page $_currentPage');
    }

    try {
      final callable = _functions.httpsCallable('getBettingData');
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
          _rows = data.map((item) => Map<String, dynamic>.from(item)).toList();
          _totalRecords = result.data['totalRecords'] ?? 0;
          
          // Handle nextCursor properly - ensure it's stored as received from Firebase
          final rawNextCursor = result.data['nextCursor'];
          if (rawNextCursor != null && rawNextCursor is List && rawNextCursor.length == 2) {
            _nextCursor = rawNextCursor;
            print('[BettingAnalytics] NextCursor received: $rawNextCursor');
          } else {
            _nextCursor = null;
            print('[BettingAnalytics] No valid nextCursor received');
          }

          if (_rows.isNotEmpty) {
            _headers = _rows.first.keys.toList();
            if (!_headers.contains(_newQueryField) && _headers.isNotEmpty) {
              _newQueryField = _headers[0];
            }
            
            // Determine numeric columns for shading
            numericShadingColumns = [];
            for (final field in _headers) {
              if (field != 'id' && field != 'home_team' && field != 'away_team' && field != 'gameday' && field != 'result' &&
                  _rows.any((row) => row[field] != null && row[field] is num)) {
                numericShadingColumns.add(field);
              }
            }
            
            // Calculate percentiles for numeric columns
            columnPercentiles = {};
            for (final column in numericShadingColumns) {
              final List<num> values = _rows
                  .map((row) => row[column])
                  .whereType<num>()
                  .toList();
              
              if (values.isNotEmpty) {
                values.sort();
                columnPercentiles[column] = {};
                for (final row in _rows) {
                  final value = row[column];
                  if (value is num && columnPercentiles[column]![value] == null) {
                    final rank = values.where((v) => v < value).length;
                    final count = values.where((v) => v == value).length;
                    columnPercentiles[column]![value] = (rank + 0.5 * count) / values.length;
                  }
                }
              }
            }
          }
          _isLoading = false;
        });
      }
      _startPreloadingNextPages();
    } on FirebaseFunctionsException catch (e) {
      print('FirebaseFunctionsException: ${e.message}');
      if (e.message != null && e.message!.contains('The query requires an index')) {
        final indexUrlMatch = RegExp(r'https://console\.firebase\.google\.com/v1/r/project/[^\s]+').firstMatch(e.message!);        
        if (indexUrlMatch != null) {
          final missingIndexUrl = indexUrlMatch.group(0);
          print('Missing index URL found: $missingIndexUrl');
          
          try {
            final result = await _functions.httpsCallable('logMissingIndex').call({
              'url': missingIndexUrl,
              'timestamp': DateTime.now().toIso8601String(),
              'screenName': 'BettingAnalyticsScreen',
              'queryDetails': {
                'filters': filtersForFunction,
                'orderBy': _sortColumn,
                'orderDirection': _sortAscending ? 'asc' : 'desc',
              },
              'errorMessage': e.message,
            });
            print('logMissingIndex function call succeeded: ${result.data}');
          } catch (functionError) {
            print('Error calling logMissingIndex function: $functionError');
          }
        }
        if (mounted) {
          setState(() {
            _error = "We're working to expand our data. Please check back later or contact support if the issue persists.";
            _isLoading = false;
          });
        }
      } else if (mounted) {
        setState(() {
          _error = "An unexpected error occurred: ${e.message}";
          _isLoading = false;
        });
      }
    } catch (e, stack) {
      print('Error in _fetchData: $e');
      print('Stack trace: $stack');
      if (mounted) {
        setState(() {
          _error = 'An unexpected error occurred: $e';
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
        final HttpsCallable callable = _functions.httpsCallable('getBettingData');
        final result = await callable.call<Map<String, dynamic>>({
          'filters': filtersForFunction,
          'limit': _rowsPerPage,
          'orderBy': _sortColumn,
          'orderDirection': _sortAscending ? 'asc' : 'desc',
          'cursor': currentPreloadCursor,
        });

        final List<dynamic> data = result.data['data'] ?? [];
        final preloadedRows = data.map((item) => Map<String, dynamic>.from(item)).toList();
        
        // Handle nextCursor properly for preloading
        final rawNextCursor = result.data['nextCursor'];
        dynamic nextPreloadCursor;
        if (rawNextCursor != null && rawNextCursor is List && rawNextCursor.length == 2) {
          nextPreloadCursor = rawNextCursor;
        } else {
          nextPreloadCursor = null;
        }

        if (preloadedRows.isNotEmpty) {
          _preloadedPages[preloadPageIndex] = preloadedRows;
          _preloadedCursors[preloadPageIndex] = nextPreloadCursor;
          print('[Preload] Preloaded page $preloadPageIndex with ${preloadedRows.length} rows');
        }

        currentPreloadCursor = nextPreloadCursor;
        preloadPageIndex++;
      } catch (e) {
        print('[Preload] Error preloading page $preloadPageIndex: $e');
        break;
      }
    }
  }
  
  void _applyFilters() {
    _currentPage = 0;
    _pageCursors = [null];
    _nextCursor = null;
    _preloadedPages.clear();
    _preloadedCursors.clear();
    _fetchData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        titleWidget: Row(
          children: [
            const Text('StickToTheModel', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(width: 20),
            Expanded(child: TopNavBarContent(currentRoute: ModalRoute.of(context)?.settings.name)),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ElevatedButton(
              onPressed: () => showDialog(context: context, builder: (_) => const AuthDialog()),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                textStyle: const TextStyle(fontSize: 14),
              ),
              child: const Text('Sign In / Sign Up'),
            ),
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : _buildDataTable(),
    );
  }

  Widget _buildDataTable() {
    final List<String> displayFields = _fieldGroups[_selectedStatCategory] ?? _headers;

    final Set<String> numericColumns = _rows.isNotEmpty
      ? _rows.first.keys.where((key) {
          return _rows.any((row) => row[key] is num);
        }).toSet()
      : {};

    final Map<String, Map<num, double>> percentiles = {};
    for (var col in numericColumns) {
      if (col == 'season' || col == 'week' || col.contains('_id')) continue;
      final values = _rows.map((row) => row[col]).whereType<num>().toList();
      if (values.isNotEmpty) {
        values.sort();
        percentiles[col] = {};
        for (var v in values) {
          if (!percentiles[col]!.containsKey(v)) {
            final rank = values.where((e) => e < v).length;
            final count = values.where((e) => e == v).length;
            percentiles[col]![v] = (rank + 0.5 * count) / values.length;
          }
        }
      }
    }

    return Column(
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
          child: Row(
            children: _fieldGroups.keys.map((category) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: ChoiceChip(
                  label: Text(category),
                  selected: _selectedStatCategory == category,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _selectedStatCategory = category;
                      });
                    }
                  },
                ),
              );
            }).toList(),
          ),
        ),
        
        // Add row with pagination info
        if (_rows.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 8.0, bottom: 4.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Page ${_currentPage + 1} of ${(_totalRecords / _rowsPerPage).ceil().clamp(1, 9999)}. Total: $_totalRecords records.',
                  style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                ),
                const SizedBox(), // Empty space to balance the row
              ],
            ),
          ),
        
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.all(8.0),
              child: Theme(
                data: Theme.of(context).copyWith(
                  dataTableTheme: const DataTableThemeData(
                    columnSpacing: 0,
                    horizontalMargin: 0,
                    dividerThickness: 0,
                  ),
                ),
                child: DataTable(
                  sortColumnIndex: displayFields.contains(_sortColumn) ? displayFields.indexOf(_sortColumn) : null,
                  sortAscending: _sortAscending,
                  headingRowColor: WidgetStateProperty.all(Colors.blue.shade700),
                  headingTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                  dataRowHeight: 44,
                  showCheckboxColumn: false,
                  border: TableBorder.all(
                    color: Colors.grey.shade300,
                    width: 0.5,
                  ),
                  columns: displayFields.map((field) => DataColumn(
                    label: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                      child: Text(_formatHeaderName(field)),
                    ),
                    onSort: (i, asc) {
                      setState(() {
                        _sortColumn = field;
                        _sortAscending = asc;
                        _applyFilters();
                      });
                    },
                  )).toList(),
                  rows: _rows.asMap().entries.map((entry) {
                    final int rowIndex = entry.key;
                    final Map<String, dynamic> row = entry.value;
                    return DataRow(
                      color: WidgetStateProperty.resolveWith<Color?>((states) => rowIndex.isEven ? Colors.grey.shade100 : Colors.white),
                      cells: displayFields.map((field) {
                        final value = row[field];
                        String displayValue;
                        Color? cellBackgroundColor;
                        
                        if (value == null) {
                          displayValue = 'N/A';
                        } else if (value is num && numericShadingColumns.contains(field)) {
                          final percentile = columnPercentiles[field]?[value];
                          if (percentile != null) {
                            cellBackgroundColor = Color.fromRGBO(
                              100, 140, 240, 0.1 + (percentile * 0.85)
                            );
                          }
                          if (doubleFields.contains(field)) {
                            displayValue = value.toStringAsFixed(2);
                          } else {
                            displayValue = value.toInt().toString();
                          }
                        } else {
                          displayValue = value.toString();
                        }
                        
                        return DataCell(
                          Container(
                            width: double.infinity,
                            height: double.infinity,
                            color: cellBackgroundColor,
                            alignment: (value is num) ? Alignment.centerRight : Alignment.centerLeft,
                            padding: const EdgeInsets.symmetric(horizontal: 12.0),
                            child: (field == 'home_team' || field == 'away_team')
                              ? Row(
                                  mainAxisSize: MainAxisSize.min,
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
        // Pagination Controls
        if (_rows.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: _currentPage > 0 ? () => setState(() {
                    _currentPage--;
                    _fetchData();
                  }) : null,
                  child: const Text('Previous'),
                ),
                const SizedBox(width: 16),
                Text('Page ${_currentPage + 1} of ${(_totalRecords / _rowsPerPage).ceil().clamp(1, 9999)}'),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: _nextCursor != null ? () {
                    setState(() {
                      _currentPage++;
                      if (_pageCursors.length <= _currentPage) {
                        _pageCursors.add(_nextCursor);
                      }
                      _fetchData();
                    });
                  } : null,
                  child: const Text('Next'),
                ),
              ],
            ),
          ),
      ],
    );
  }
}