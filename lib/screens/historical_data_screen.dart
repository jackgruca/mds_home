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
import 'package:mds_home/utils/team_logo_utils.dart';

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
  List<NFLMatchup> _matchupsForViz = []; // For VisualizationTab (legacy, now unused)
  List<NFLMatchup> _allFilteredMatchups = []; // For VisualizationTab (all filtered data)
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
  bool _vizTruncated = false; // If true, visualization is truncated to 5000 rows
  bool _isVizLoading = false; // Track visualization loading state
  int _lastVizQueryHash = 0; // To avoid duplicate fetches
  List<NFLMatchup>? _vizCacheAll; // Cache for unfiltered visualization data
  bool _isVizCacheLoading = false; // Track cache loading state

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _headers = _defaultFields;
    if (_headers.isNotEmpty) _newQueryField = _headers[0];
    _tabController.addListener(_onTabChanged);
    _fetchDataFromFirebase();
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _newQueryValueController.dispose();
    super.dispose();
  }

  Future<void> _fetchDataFromFirebase() async {
    if (_preloadedPages.containsKey(_currentPage)) {
      print('[Preload] Using preloaded data for page $_currentPage');
      setState(() {
        _rawRows = _preloadedPages[_currentPage]!;
        _nextCursor = _preloadedCursors[_currentPage];
        // Clear this page from preloaded cache as it's now the current page
        // KEEPING FOR DEBUGGING: _preloadedPages.remove(_currentPage);
        // KEEPING FOR DEBUGGING: _preloadedCursors.remove(_currentPage);
        _isLoading = false;
      });
      // Start preloading the next set of pages after this one is displayed
      _startPreloadingNextPages();
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
      _vizTruncated = false;
    });

    Map<String, dynamic> filtersForFunction = {};
    for (var condition in _queryConditions) {
      filtersForFunction[condition.field] = condition.value;
    }

    // Determine the cursor for the current page
    final dynamic currentCursor = _currentPage > 0 ? _pageCursors[_currentPage] : null;
    debugPrint('Fetching page $_currentPage. Current cursor being sent: $currentCursor');

    try {
      final HttpsCallable callable = functions.httpsCallable('getHistoricalMatchups');
      final result = await callable.call<Map<String, dynamic>>({
        'filters': filtersForFunction,
        'limit': _rowsPerPage,
        'orderBy': _sortColumn,
        'orderDirection': _sortAscending ? 'asc' : 'desc',
        'cursor': currentCursor, // Pass the cursor for the current page
      });

      if (mounted) {
        setState(() {
          final List<dynamic> data = result.data['data'] ?? [];
          _rawRows = data.map((item) => Map<String, dynamic>.from(item)).toList();
          _matchupsForViz = _rawRows.map((row) => NFLMatchup.fromFirestoreMap(row)).toList();
          _totalRecords = result.data['totalRecords'] ?? 0;
          _nextCursor = result.data['nextCursor']; // Get the cursor for the next page
          debugPrint('Next cursor received from Firebase: $_nextCursor');

          // Store the next cursor for the following page in _pageCursors
          // Ensure _pageCursors has enough capacity
          while (_pageCursors.length <= _currentPage + 1) { // +1 because we are storing for the *next* page
            _pageCursors.add(null);
          }
          _pageCursors[_currentPage + 1] = _nextCursor;
          debugPrint('Updated _pageCursors: $_pageCursors');

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
      // Start preloading the next set of pages after this one is displayed
      _startPreloadingNextPages();
    } on FirebaseFunctionsException catch (e) {
      print('FirebaseFunctionsException caught in Flutter client:');
      print('Code: ${e.code}');
      print('Message: ${e.message}');
      print('Details: ${e.details}');
      if (mounted) {
        setState(() {
          String displayError = "We're working on adding this. Stay tuned.";

          if (e.code == 'failed-precondition' && e.details != null && e.details is Map) {
            final Map<String, dynamic> details = e.details as Map<String, dynamic>;
            final String? indexUrl = (details['originalError']?.toString() ?? '').contains('composite=')
                ? (details['originalError']?.toString() ?? '').split(' ').firstWhere((s) => s.contains('https://console.firebase.google.com/'), orElse: () => '')
                : null;
            
            // The backend now handles logging automatically. No client-side call needed.
            // if (indexUrl != null && indexUrl.isNotEmpty) {
            //   _logIndexRequestToFirestore(indexUrl, 'HistoricalDataScreen');
            // }

            // Always show the friendly message, never the URL or technical details
            displayError = "We're working on adding this. Stay tuned.";
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

  // Function to preload subsequent pages
  Future<void> _startPreloadingNextPages() async {
    if (_nextCursor == null) {
      // No more pages to preload from current position
      return;
    }

    Map<String, dynamic> filtersForFunction = {};
    for (var condition in _queryConditions) {
      filtersForFunction[condition.field] = condition.value;
    }

    dynamic currentPreloadCursor = _nextCursor; // Start preloading from the next page's cursor
    int preloadPageIndex = _currentPage + 1;

    for (int i = 0; i < _pagesToPreload; i++) {
      if (currentPreloadCursor == null) {
        break; // No more pages to preload
      }

      if (_preloadedPages.containsKey(preloadPageIndex)) {
        // Skip if this page is already preloaded
        currentPreloadCursor = _preloadedCursors[preloadPageIndex];
        preloadPageIndex++;
        continue;
      }

      debugPrint('[Preload] Attempting to preload page $preloadPageIndex with cursor: $currentPreloadCursor');

      try {
        final HttpsCallable callable = functions.httpsCallable('getHistoricalMatchups');
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
            _preloadedPages[preloadPageIndex] = data.map((item) => Map<String, dynamic>.from(item)).toList();
            _preloadedCursors[preloadPageIndex] = receivedNextCursor;
            debugPrint('[Preload] Preloaded page $preloadPageIndex. Next preload cursor: $receivedNextCursor');
          }
        }

        currentPreloadCursor = receivedNextCursor;
        preloadPageIndex++;
      } catch (e) {
        print('[Preload] Error preloading page $preloadPageIndex: $e');
        currentPreloadCursor = null; // Stop preloading on error for this path
      }
    }
  }

  // Fetch ALL data for visualizations (up to 5000 rows), with cache for unfiltered
  Future<void> _fetchVisualizationData() async {
    // If no filters, use cache if available
    final bool noFilters = _queryConditions.isEmpty;
    if (noFilters && _vizCacheAll != null) {
      print('[VizCache] Using cached unfiltered data.');
      setState(() {
        _allFilteredMatchups = _vizCacheAll!;
        _isVizLoading = false;
        _vizTruncated = _vizCacheAll!.length >= 5000;
        _lastVizQueryHash = _computeVizQueryHash();
      });
      return;
    }
    if (noFilters && _vizCacheAll == null) {
      print('[VizCache] Building cache for unfiltered data...');
    }
    setState(() {
      _isVizLoading = true;
      _vizTruncated = false;
      if (noFilters && _vizCacheAll == null) _isVizCacheLoading = true;
    });
    Map<String, dynamic> filtersForFunction = {};
    for (var condition in _queryConditions) {
      filtersForFunction[condition.field] = condition.value;
    }
    try {
      final HttpsCallable callable = functions.httpsCallable('getHistoricalMatchups');
      final vizResult = await callable.call<Map<String, dynamic>>({
        'filters': filtersForFunction,
        'limit': 5000, // Hardcoded max for visualizations
        'offset': 0,
        'orderBy': _sortColumn,
        'orderDirection': _sortAscending ? 'asc' : 'desc',
      });
      if (mounted) {
        setState(() {
          final List<dynamic> vizData = vizResult.data['data'] ?? [];
          final List<NFLMatchup> matchups = vizData.map((row) => NFLMatchup.fromFirestoreMap(Map<String, dynamic>.from(row))).toList();
          _allFilteredMatchups = matchups;
          final int vizTotal = vizResult.data['totalRecords'] ?? 0;
          _vizTruncated = vizData.length >= 5000 && vizTotal > 5000;
          _isVizLoading = false;
          _isVizCacheLoading = false;
          _lastVizQueryHash = _computeVizQueryHash();
          // Cache the unfiltered set for future instant loads
          if (noFilters) {
            _vizCacheAll = matchups;
          }
        });
      }
    } on FirebaseFunctionsException catch (e) {
      if (mounted) {
        setState(() {
          _isVizLoading = false;
          _isVizCacheLoading = false;
          _allFilteredMatchups = [];
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isVizLoading = false;
          _isVizCacheLoading = false;
          _allFilteredMatchups = [];
        });
      }
    }
  }

  // Helper: Compute a hash of the current viz query (filters, sort)
  int _computeVizQueryHash() {
    return Object.hashAll([
      ..._queryConditions.map((c) => '${c.field}:${c.operator}:${c.value}'),
      _sortColumn,
      _sortAscending,
    ]);
  }

  // Tab change listener: fetch viz data only when needed
  void _onTabChanged() {
    if (_tabController.index == 1) {
      // Visualization tab selected
      final int currentHash = _computeVizQueryHash();
      if (_allFilteredMatchups.isEmpty || _lastVizQueryHash != currentHash) {
        _fetchVisualizationData();
      }
    }
  }

  // When filters change, clear viz data so it reloads next time
  void _applyFiltersAndFetch() {
    _currentPage = 0;
    _pageCursors = [null]; // Reset cursors when filters change
    _nextCursor = null; // Clear next cursor
    _preloadedPages.clear(); // Clear preloaded data on filter change
    _preloadedCursors.clear(); // Clear preloaded cursors on filter change
    _allFilteredMatchups = [];
    _isVizLoading = false;
    _lastVizQueryHash = 0;
    // If filters are cleared, use cache next time
    if (_queryConditions.isEmpty && _vizCacheAll != null) {
      // No need to clear cache
    } else if (_queryConditions.isNotEmpty) {
      print('[VizCache] Invalidating cache due to filters.');
      // If filters are applied, do not use cache
      _vizCacheAll = null;
    }
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
    // Create a temporary list to hold selected fields until confirmed
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
                height: 500, // Set explicit height to make it scrollable
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
                          // Filter the displayed headers based on search input
                          setState(() {
                            // No need to change anything here, just trigger a rebuild
                          });
                        },
                      ),
                    ),
                    Expanded(
                      child: ListView(
                        children: _headers
                            .where((header) => header.toLowerCase().contains(''))
                            .map((header) {
                              return CheckboxListTile(
                                title: Text(header),
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
                    // Select all fields
                    setState(() {
                      tempSelected = List.from(_headers);
                    });
                  },
                  child: const Text('Select All'),
                ),
                ElevatedButton(
                  onPressed: () {
                    // Apply changes and close dialog
                    this.setState(() {
                      _selectedFields = List.from(tempSelected);
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
          if (_vizTruncated)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                'Warning: Visualization is limited to 5000 records. Refine your filters for more precise insights.',
                style: TextStyle(color: Colors.orange[800], fontWeight: FontWeight.bold),
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
                        (_isVizLoading || _isVizCacheLoading)
                          ? const Center(child: CircularProgressIndicator())
                          : VisualizationTab(
                              matchups: _allFilteredMatchups,
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
    
    // Define common field groupings with descriptive tab names
    final List<Map<String, dynamic>> fieldGroups = [
      {
        'name': 'Game Overview',
        'fields': ['Team', 'Date', 'Opponent', 'Final', 'VH', 'Season', 'Week', 'stadium', 'Outcome']
      },
      {
        'name': 'Betting',
        'fields': ['Team', 'Date', 'Opponent', 'Final', 'Closing_spread', 'Actual_spread', 'Spread_result', 'Closing_total', 'Actual_total', 'Points_result']
      },
      {
        'name': 'Team Stats',
        'fields': ['Team', 'Season', 'Week', 'Pass_yards', 'Rush_yards', 'Total_yards', 'Pass_att', 'Rush_att', 'TDs', 'Turnovers']
      },
      {
        'name': 'Weather & Conditions',
        'fields': ['Team', 'Date', 'Opponent', 'stadium', 'surface', 'temp', 'wind', 'setting', 'Season', 'Week']
      },
      {
        'name': 'Custom',
        'fields': _selectedFields
      },
    ];

    // Filter field groups to include only available fields
    for (var group in fieldGroups.where((g) => g['name'] != 'Custom')) {
      group['fields'] = (group['fields'] as List<String>).where((field) => _headers.contains(field)).toList();
    }
    
    // Calculate percentiles for numeric columns
    Map<String, Map<dynamic, double>> columnPercentiles = {};
    
    // Fields to exclude from shading (non-numeric or identifier fields)
    final List<String> excludedFields = [
      'Team', 'Opponent', 'Date', 'Season', 'Week', 'id', 'VH', 'stadium', 'surface', 'temp', 'setting'
    ];
    
    // Determine numeric columns dynamically
    List<String> numericShadingColumns = [];
    if (_rawRows.isNotEmpty) {
      for (String field in _selectedFields) {
        // Skip excluded fields
        if (excludedFields.contains(field)) continue;
        
        // Check if this field contains numeric values
        if (_rawRows.any((row) => row[field] != null && row[field] is num)) {
          numericShadingColumns.add(field);
        }
      }
    }
    
    // Function to calculate percentile rank
    double calculatePercentileRank(List<num> values, num value) {
      if (values.isEmpty) return 0.0;
      int below = values.where((v) => v < value).length;
      int equal = values.where((v) => v == value).length;
      // Handle case where all values are the same
      if (values.length == equal) return 0.5;
      // Percentile calculation
      return (below + 0.5 * equal) / values.length;
    }
    
    // Get active season filter if any
    String? seasonFilter;
    for (var condition in _queryConditions) {
      if (condition.field == 'Season') {
        seasonFilter = condition.value;
        break;
      }
    }
    
    // Calculate percentiles for each column to be shaded
    for (var column in numericShadingColumns) {
      List<num> columnValues = [];
      
      // Filter data by season if season filter is applied
      for (var row in _rawRows) {
        if (row[column] != null && row[column] is num) {
          // Only include rows matching season filter if it exists
          if (seasonFilter != null) {
            if (row['Season'].toString() == seasonFilter) {
              columnValues.add(row[column]);
            }
          } else {
            // No season filter, use all values
            columnValues.add(row[column]);
          }
        }
      }
      
      // Calculate percentile for each value
      Map<dynamic, double> valueToPercentile = {};
      for (var row in _rawRows) {
        if (row[column] != null && row[column] is num) {
          valueToPercentile[row[column]] = calculatePercentileRank(columnValues, row[column]);
        }
      }
      
      columnPercentiles[column] = valueToPercentile;
    }
    
    // Define colors for styling
    final Color headerColor = Colors.blue.shade700; // Darker blue for header
    final Color evenRowColor = Colors.grey.shade100; // Light gray for even rows
    const Color oddRowColor = Colors.white; // White for odd rows
    const TextStyle headerTextStyle = TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15);
    const TextStyle cellTextStyle = TextStyle(fontSize: 14);
    
    // Track the currently selected field group
    int selectedGroupIndex = fieldGroups.length - 1; // Default to 'Custom'
    
    return StatefulBuilder(
      builder: (context, setState) {
        // Get the current fields to display based on the selected group
        List<String> displayFields = selectedGroupIndex == fieldGroups.length - 1 
            ? _selectedFields 
            : List<String>.from(fieldGroups[selectedGroupIndex]['fields']);
        
        return Column(
          children: [
            // Field group tabs
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                children: fieldGroups.asMap().entries.map((entry) {
                  final int idx = entry.key;
                  final String name = entry.value['name'];
                  final bool isSelected = idx == selectedGroupIndex;
                  
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          selectedGroupIndex = idx;
                          // If not the custom tab, update the displayed fields
                          if (idx != fieldGroups.length - 1) {
                            // No need to update _selectedFields here, just changing the view
                          }
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.blue.shade700 : Colors.grey.shade200,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(8.0),
                            topRight: Radius.circular(8.0),
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          name,
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.black87,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                TextButton.icon(
                  icon: const Icon(Icons.edit, size: 16),
                  label: const Text('Customize Columns'),
                  onPressed: _showCustomizeColumnsDialog,
                ),
              ],
            ),
            
            Expanded(
              child: SingleChildScrollView(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Theme(
                    // Override default DataTable theme to remove cell spacing
                    data: Theme.of(context).copyWith(
                      dataTableTheme: const DataTableThemeData(
                        columnSpacing: 0, // Remove spacing between columns
                        horizontalMargin: 0, // Remove horizontal margin
                        dividerThickness: 0, // Remove divider
                      ),
                    ),
                    child: DataTable(
                      headingRowColor: WidgetStateProperty.resolveWith<Color?>((Set<WidgetState> states) => headerColor),
                      headingTextStyle: headerTextStyle,
                      dataRowHeight: 44, // Fixed height for all rows
                      showCheckboxColumn: false,
                      sortColumnIndex: displayFields.contains(_sortColumn) ? displayFields.indexOf(_sortColumn) : null,
                      sortAscending: _sortAscending,
                      border: TableBorder.all(
                        color: Colors.white,
                        width: 0.5,
                        style: BorderStyle.solid,
                      ),
                      columns: displayFields.map((header) {
                        return DataColumn(
                          label: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(header, style: const TextStyle(fontWeight: FontWeight.bold)),
                                if (_sortColumn == header)
                                  Icon(
                                    _sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
                                    size: 16,
                                    color: Colors.white,
                                  ),
                              ],
                            ),
                          ),
                          onSort: (columnIndex, ascending) {
                            this.setState(() {
                              _sortColumn = displayFields[columnIndex];
                              _sortAscending = ascending;
                              _applyFiltersAndFetch();
                            });
                          },
                          tooltip: 'Sort by $header',
                        );
                      }).toList(),
                      rows: _rawRows.isEmpty 
                        ? [] 
                        : _rawRows.asMap().entries.map((entry) {
                            final int rowIndex = entry.key;
                            final Map<String, dynamic> rowMap = entry.value;
                            return DataRow(
                              color: WidgetStateProperty.resolveWith<Color?>((Set<WidgetState> states) {
                                return rowIndex.isEven ? evenRowColor : oddRowColor;
                              }),
                              cells: displayFields.map((header) {
                                final value = rowMap[header];
                                String displayValue = 'N/A';
                                Color? cellBackgroundColor;
                                TextStyle cellStyle = cellTextStyle;
                                
                                if (value != null) {
                                  if (value is num && numericShadingColumns.contains(header)) {
                                    // Apply percentile-based shading for numeric fields
                                    double? percentile = columnPercentiles[header]?[value];
                                    if (percentile != null) {
                                      // Blue shade based on percentile (higher percentile = deeper blue)
                                      cellBackgroundColor = Color.fromRGBO(
                                        100,  // Red
                                        140,  // Green
                                        240,  // Blue
                                        0.1 + (percentile * 0.85)  // Alpha (10% to 95%)
                                      );
                                      
                                      // Make text bold for high percentiles
                                      if (percentile > 0.85) {
                                        cellStyle = cellTextStyle.copyWith(fontWeight: FontWeight.bold);
                                      }
                                    }
                                    
                                    // Format numeric value
                                    if (value is double) {
                                      displayValue = value.toStringAsFixed(1);
                                    } else {
                                      displayValue = value.toString();
                                    }
                                  } else if (value is String && (header == 'Date' || header.endsWith('_date'))) {
                                    try {
                                      displayValue = DateFormat('MM/dd/yyyy').format(DateTime.parse(value));
                                    } catch (e) {
                                      displayValue = value;
                                    }
                                  } else {
                                    displayValue = value.toString();
                                  }
                                }
                                
                                return DataCell(
                                  Container(
                                    // Fill the entire cell
                                    width: double.infinity,
                                    height: double.infinity,
                                    color: cellBackgroundColor,
                                    alignment: value is num ? Alignment.centerRight : Alignment.centerLeft,
                                    padding: const EdgeInsets.symmetric(horizontal: 12.0),
                                    child: (header == 'Team' || header == 'Opponent')
                                      ? Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            TeamLogoUtils.buildNFLTeamLogo(
                                              value.toString(),
                                              size: 24.0,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              value.toString(),
                                              style: cellStyle,
                                            ),
                                          ],
                                        )
                                      : Text(
                                          displayValue,
                                          style: cellStyle,
                                        ),
                                  ),
                                  // Allow sorting on this column
                                  onTap: () {
                                    if (displayFields.contains(header)) {
                                      this.setState(() {
                                        _sortColumn = header;
                                        _sortAscending = !_sortAscending;
                                        _applyFiltersAndFetch();
                                      });
                                    }
                                  },
                                );
                              }).toList(),
                            );
                          }).toList(),
                    ),
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
                          ? () => this.setState(() {
                              _currentPage--;
                              _fetchDataFromFirebase(); // Re-fetch for previous page
                            })
                          : null,
                      child: const Text('Previous'),
                    ),
                    const SizedBox(width: 16),
                    Text('Page ${(_currentPage) + 1} of ${(_totalRecords / _rowsPerPage).ceil().clamp(1,9999)}'),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: (_nextCursor != null || _preloadedPages.containsKey(_currentPage + 1))
                          ? () {
                              setState(() {
                                _currentPage++;
                                debugPrint('After Next button click, _currentPage incremented to: $_currentPage');
                                _fetchDataFromFirebase();
                              });
                            }
                          : null,
                      child: const Text('Next'),
                    ),
                  ],
                ),
              ),
          ],
        );
      }
    );
  }
} 