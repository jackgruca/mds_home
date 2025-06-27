import 'package:flutter/material.dart';
import 'package:mds_home/widgets/common/app_drawer.dart';
import 'package:mds_home/widgets/common/top_nav_bar.dart';
import 'package:mds_home/widgets/common/custom_app_bar.dart';
import 'package:mds_home/widgets/auth/auth_dialog.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:mds_home/utils/team_logo_utils.dart';
import 'package:mds_home/utils/theme_config.dart';
import 'package:mds_home/utils/theme_aware_colors.dart';

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

class HistoricalGameDataScreen extends StatefulWidget {
  const HistoricalGameDataScreen({super.key});

  @override
  State<HistoricalGameDataScreen> createState() =>
      _HistoricalGameDataScreenState();
}

class _HistoricalGameDataScreenState extends State<HistoricalGameDataScreen> {
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
  String _sortColumn = 'game_date';
  bool _sortAscending = false;

  // Season Filter
  String _selectedSeason = 'All'; // Default season filter
  final List<String> _seasons = ['All', '2024', '2023', '2022', '2021', '2020'];

  List<String> _headers = [];
  List<String> _selectedFields = []; // Initially empty, populated from data

  // State for Query Builder
  final List<QueryCondition> _queryConditions = [];
  String? _newQueryField;
  QueryOperator? _newQueryOperator;
  final TextEditingController _newQueryValueController =
      TextEditingController();
  bool _isQueryBuilderExpanded = false; // Initially collapsed

  FirebaseFunctions functions = FirebaseFunctions.instance;

  // Field groups for tabbed view - game data categories
  static final Map<String, List<String>> _gameDataCategoryFieldGroups = {
    'Game Basics': ['home_team', 'away_team', 'season', 'week', 'game_id', 'game_date', 'weekday', 'away_score', 'home_score', 'total_points', 'point_differential', 'result', 'overtime'],
    'Fantasy Edge': ['home_team', 'away_team', 'season', 'week', 'away_qb_name', 'home_qb_name', 'temp', 'wind', 'dome_game', 'outdoor_game', 'away_rest', 'home_rest', 'rest_advantage', 'high_scoring', 'low_scoring', 'blowout', 'close_game'],
    'Betting Angles': ['home_team', 'away_team', 'season', 'week', 'prime_time', 'playoff_game', 'div_game', 'away_rest', 'home_rest', 'rest_advantage', 'referee', 'cold_weather', 'hot_weather', 'windy_conditions', 'surface', 'roof'],
    'Game Context': ['home_team', 'away_team', 'season', 'week', 'prime_time', 'playoff_game', 'div_game', 'blowout', 'close_game', 'high_scoring', 'low_scoring', 'early_season', 'mid_season', 'late_season'],
    'Environment': ['home_team', 'away_team', 'season', 'week', 'stadium', 'roof', 'surface', 'temp', 'wind', 'cold_weather', 'hot_weather', 'windy_conditions', 'dome_game', 'outdoor_game'],
    'Personnel': ['home_team', 'away_team', 'season', 'week', 'away_qb_name', 'home_qb_name', 'away_coach', 'home_coach', 'referee'],
    'Custom': ['home_team', 'away_team', 'season', 'week'], // User-defined category with basic identifiers
  };
  
  String _selectedGameDataCategory = 'Game Basics';

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
    'temp', 'wind'
  };

  // Helper function to format header names prettily with abbreviations
  String _formatHeaderName(String header) {
    // Define abbreviations and pretty names for game data
    final Map<String, String> headerMap = {
      'game_id': 'Game ID',
      'season': 'Season',
      'week': 'Week',
      'game_type': 'Type',
      'game_date': 'Date',
      'weekday': 'Day',
      'gametime': 'Time',
      'prime_time': 'Prime',
      'away_team': 'Away',
      'away_score': 'Away Pts',
      'home_team': 'Home',
      'home_score': 'Home Pts',
      'total_points': 'Total',
      'point_differential': 'Diff',
      'result': 'Result',
      'overtime': 'OT',
      'blowout': 'Blowout',
      'close_game': 'Close',
      'high_scoring': 'High Scr',
      'low_scoring': 'Low Scr',
      'div_game': 'Div',
      'playoff_game': 'Playoff',
      'early_season': 'Early',
      'mid_season': 'Mid',
      'late_season': 'Late',
      'stadium': 'Stadium',
      'stadium_id': 'Venue ID',
      'roof': 'Roof',
      'surface': 'Surface',
      'temp': 'Temp',
      'wind': 'Wind',
      'cold_weather': 'Cold',
      'hot_weather': 'Hot',
      'windy_conditions': 'Windy',
      'dome_game': 'Dome',
      'outdoor_game': 'Outdoor',
      'away_rest': 'Away Rest',
      'home_rest': 'Home Rest',
      'rest_advantage': 'Rest Adv',
      'away_rest_advantage': 'Away Rest+',
      'home_rest_advantage': 'Home Rest+',
      'away_qb_name': 'Away QB',
      'home_qb_name': 'Home QB',
      'away_coach': 'Away Coach',
      'home_coach': 'Home Coach',
      'referee': 'Referee',
      'old_game_id': 'Old ID',
      'espn': 'ESPN ID',
      'pfr': 'PFR ID',
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

  // Field definitions for the key/legend
  static final Map<String, String> _fieldDefinitions = {
    // Game Basics
    'home_team': 'Home Team',
    'away_team': 'Away Team',
    'season': 'NFL Season Year',
    'week': 'Week Number',
    'game_id': 'Unique Game Identifier',
    'game_date': 'Date of Game',
    'weekday': 'Day of Week',
    'away_score': 'Away Team Final Score',
    'home_score': 'Home Team Final Score',
    'total_points': 'Combined Score',
    'point_differential': 'Margin of Victory',
    'result': 'Game Result (W/L)',
    'overtime': 'Overtime Game (1=Yes, 0=No)',
    
    // Fantasy Edge
    'away_qb_name': 'Away Team Starting QB',
    'home_qb_name': 'Home Team Starting QB',
    'temp': 'Temperature (°F)',
    'wind': 'Wind Speed (mph)',
    'dome_game': 'Indoor/Dome Game (1=Yes, 0=No)',
    'outdoor_game': 'Outdoor Game (1=Yes, 0=No)',
    'away_rest': 'Away Team Days of Rest',
    'home_rest': 'Home Team Days of Rest',
    'rest_advantage': 'Rest Advantage (Home - Away)',
    'high_scoring': 'High Scoring Game (1=Yes, 0=No)',
    'low_scoring': 'Low Scoring Game (1=Yes, 0=No)',
    'blowout': 'Blowout Game (1=Yes, 0=No)',
    'close_game': 'Close Game (1=Yes, 0=No)',
    
    // Game Context
    'prime_time': 'Prime Time Game (1=Yes, 0=No)',
    'playoff_game': 'Playoff Game (1=Yes, 0=No)',
    'div_game': 'Division Game (1=Yes, 0=No)',
    'roof': 'Stadium Roof Type',
    'surface': 'Playing Surface',
    'stadium': 'Stadium Name',
    'neutral_site': 'Neutral Site Game (1=Yes, 0=No)',
    
    // Environment
    'cold_weather': 'Cold Weather Game (1=Yes, 0=No)',
    'hot_weather': 'Hot Weather Game (1=Yes, 0=No)',
    'windy_conditions': 'Windy Conditions (1=Yes, 0=No)',
    'precipitation': 'Precipitation Present (1=Yes, 0=No)',
    
    // Personnel
    'referee': 'Head Referee',
    'away_coach': 'Away Team Head Coach',
    'home_coach': 'Home Team Head Coach',
  };

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
      'temp', 'wind'
    };
    const Set<String> intFields = {
      'season', 'week', 'away_score', 'home_score', 'total_points', 'point_differential',
      'result', 'away_rest', 'home_rest', 'rest_advantage', 'prime_time',
      'overtime', 'blowout', 'close_game', 'high_scoring', 'low_scoring', 'div_game',
      'playoff_game', 'cold_weather', 'hot_weather', 'windy_conditions', 'dome_game', 'outdoor_game'
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
    // Add season filter
    if (_selectedSeason != 'All') {
      filtersForFunction['season'] = int.parse(_selectedSeason);
    }

    final dynamic currentCursor =
        _currentPage > 0 ? _pageCursors[_currentPage] : null;

    try {
      final HttpsCallable callable =
          functions.httpsCallable('getHistoricalGameData');
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
      print('FirebaseFunctionsException: ${e.message}'); // Log the full error for debugging
      if (e.message != null && e.message!.contains('The query requires an index')) {
        // Extract the URL and log it to a new Firebase function
        final indexUrlMatch = RegExp(r'https://console\.firebase\.google\.com/v1/r/project/[^\s]+').firstMatch(e.message!);        
        if (indexUrlMatch != null) {
          final missingIndexUrl = indexUrlMatch.group(0);
          print('Missing index URL found: $missingIndexUrl');
          
          // Call a new Cloud Function to log this URL
          print('Attempting to call logMissingIndex Cloud Function...');
          try {
            final result = await functions.httpsCallable('logMissingIndex').call({
              'url': missingIndexUrl,
              'timestamp': DateTime.now().toIso8601String(),
              'screenName': 'HistoricalGameDataScreen',
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
            // This error is caught here to prevent it from affecting the UI
          }
        } else {
          print('No index URL found in error message: ${e.message}');
        }
        if (mounted) {
          setState(() {
            _error = "We're working to expand our data. Please check back later or contact support if the issue persists.";
            _isLoading = false;
          });
        }
      } else if (mounted) {
        setState(() {
          _error =
              "An unexpected error occurred: ${e.message}"; // For other types of errors
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
    if (_selectedSeason != 'All') {
      filtersForFunction['season'] = int.parse(_selectedSeason);
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
            functions.httpsCallable('getHistoricalGameData');
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
                      // Switch to Custom category when customizing fields
                      _selectedGameDataCategory = 'Custom';
                      // Update the Custom category fields
                      _gameDataCategoryFieldGroups['Custom'] = _selectedFields;
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

  void _showFieldDefinitions() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Field Definitions'),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: _fieldDefinitions.entries.map((entry) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 120,
                          child: Text(
                            entry.key,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(entry.value),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
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
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          // Season Dropdown
                          Expanded(
                            flex: 1,
                            child: DropdownButtonFormField<String>(
                              decoration:
                                  const InputDecoration(labelText: 'Season'),
                              value: _selectedSeason,
                              items: _seasons
                                  .map((season) => DropdownMenuItem(
                                        value: season,
                                        child: Text(season),
                                      ))
                                  .toList(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedSeason = value!;
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Field Dropdown
                          Expanded(
                            flex: 2,
                            child: DropdownButtonFormField<String>(
                              decoration:
                                  const InputDecoration(labelText: 'Field'),
                              value: _newQueryField,
                              items: _headers
                                  .map((field) => DropdownMenuItem(
                                        value: field,
                                        child: Text(field),
                                      ))
                                  .toList(),
                              onChanged: (value) {
                                setState(() {
                                  _newQueryField = value;
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Operator Dropdown
                          Expanded(
                            flex: 1,
                            child: DropdownButtonFormField<QueryOperator>(
                              decoration:
                                  const InputDecoration(labelText: 'Operator'),
                              value: _newQueryOperator,
                              items: _allOperators
                                  .map((op) => DropdownMenuItem(
                                        value: op,
                                        child: Text(queryOperatorToString(op)),
                                      ))
                                  .toList(),
                              onChanged: (value) {
                                setState(() {
                                  _newQueryOperator = value;
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Value TextField
                          Expanded(
                            flex: 2,
                            child: TextField(
                              controller: _newQueryValueController,
                              decoration: const InputDecoration(labelText: 'Value'),
                              keyboardType: _newQueryField != null
                                  ? (getFieldType(_newQueryField!) == 'int' ||
                                          getFieldType(_newQueryField!) == 'double')
                                      ? TextInputType.number
                                      : TextInputType.text
                                  : TextInputType.text,
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Add Condition Button
                          ElevatedButton(
                            onPressed: _addQueryCondition,
                            child: const Text('Add'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12.0),
                      // Display current query conditions
                      if (_queryConditions.isNotEmpty) ...[
                        const Text('Current Conditions:',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4.0),
                        Wrap(
                          spacing: 8.0,
                          runSpacing: 4.0,
                          children: _queryConditions.asMap().entries.map((entry) {
                            final index = entry.key;
                            final condition = entry.value;
                            return Chip(
                              label: Text(condition.toString()),
                              deleteIcon: const Icon(Icons.close, size: 18),
                              onDeleted: () => _removeQueryCondition(index),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 8.0),
                        Row(
                          children: [
                            ElevatedButton(
                              onPressed: _applyFiltersAndFetch,
                              child: const Text('Apply Filters'),
                            ),
                            const SizedBox(width: 8.0),
                            TextButton(
                              onPressed: _clearAllQueryConditions,
                              child: const Text('Clear All'),
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
          // Category Selection Tabs
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 12),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text('Data Categories',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold)),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: _showCustomizeColumnsDialog,
                        icon: const Icon(Icons.tune),
                        label: const Text('Customize'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8.0),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _gameDataCategoryFieldGroups.keys.map((category) {
                        final isSelected = _selectedGameDataCategory == category;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: FilterChip(
                            label: Text(category),
                            selected: isSelected,
                            onSelected: (selected) {
                              if (selected) {
                                setState(() {
                                  _selectedGameDataCategory = category;
                                  _selectedFields = List.from(_gameDataCategoryFieldGroups[category]!);
                                });
                              }
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Data Table
          Expanded(
            child: Card(
              margin: const EdgeInsets.all(12),
              child: Column(
                children: [
                  // Summary header
                  Container(
                    padding: const EdgeInsets.all(12.0),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                    ),
                    child: Row(
                      children: [
                        Text(
                          'Historical Game Data',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        if (!_isLoading)
                          Text(
                            'Showing ${_rawRows.length} of $_totalRecords games',
                            style: theme.textTheme.bodyMedium,
                          ),
                      ],
                    ),
                  ),
                  // Table content
                  Expanded(
                    child: _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : _error != null
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.error_outline,
                                      size: 64,
                                      color: theme.colorScheme.error,
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'Error loading data',
                                      style: theme.textTheme.titleLarge,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      _error!,
                                      textAlign: TextAlign.center,
                                      style: theme.textTheme.bodyMedium,
                                    ),
                                    const SizedBox(height: 16),
                                    ElevatedButton(
                                      onPressed: _fetchDataFromFirebase,
                                      child: const Text('Retry'),
                                    ),
                                  ],
                                ),
                              )
                            : _rawRows.isEmpty
                                ? const Center(
                                    child: Text('No data available'),
                                  )
                                : _buildStyledDataTable(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStyledDataTable() {
    if (_rawRows.isEmpty && !_isLoading && _error == null) {
      return const Center(
          child: Text('No data found. Try adjusting your filters.',
              style: TextStyle(fontSize: 16)));
    }

    // Determine numeric columns for shading dynamically based on visible data
    final List<String> numericShadingColumns = [];
    if (_rawRows.isNotEmpty) {
      for (final field in _rawRows.first.keys) {
        // Exclude text fields and identifiers from shading
        if (field != 'game_id' && field != 'home_team' && field != 'away_team' && 
            field != 'season' && field != 'week' && field != 'game_type' &&
            field != 'game_date' && field != 'stadium' && field != 'surface' &&
            field != 'roof' && field != 'weather_description' && field != 'div_game' &&
            field != 'playoff' && field != 'neutral_site' &&
            _rawRows.any((row) => row[field] != null && row[field] is num)) {
          numericShadingColumns.add(field);
        }
      }
    }
    
    // Calculate percentiles for numeric columns
    final Map<String, Map<num, double>> columnPercentiles = {};
    for (final column in numericShadingColumns) {
      final List<num> values = _rawRows
          .map((row) => row[column])
          .whereType<num>()
          .toList();
      
      if (values.isNotEmpty) {
        values.sort();
        columnPercentiles[column] = {};
        for (final row in _rawRows) {
          final value = row[column];
          if (value is num && columnPercentiles[column]![value] == null) {
            final rank = values.where((v) => v < value).length;
            final count = values.where((v) => v == value).length;
            columnPercentiles[column]![value] = (rank + 0.5 * count) / values.length;
          }
        }
      }
    }

    final List<String> displayFields = _selectedFields
        .where((field) => _headers.contains(field))
        .toList();

    // Ensure we always have at least one column to prevent DataTable assertion error
    if (displayFields.isEmpty && _headers.isNotEmpty) {
      displayFields.add(_headers.first);
    }

    return Column(
      children: [
        // Category Tabs (already implemented above)
        
        // Add row with action buttons and pagination info
        Padding(
          padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 8.0, bottom: 4.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _rawRows.isEmpty
                    ? ''
                    : 'Page ${(_currentPage) + 1} of ${(_totalRecords / _rowsPerPage).ceil().clamp(1, 9999)}. Total: $_totalRecords games.',
                style: TextStyle(color: ThemeAwareColors.getSecondaryTextColor(context), fontSize: 13),
              ),
              Row(
                children: [
                  TextButton.icon(
                    icon: const Icon(Icons.help_outline, size: 16),
                    label: const Text('Field Key'),
                    style: TextButton.styleFrom(
                      foregroundColor: ThemeConfig.darkNavy,
                    ),
                    onPressed: _showFieldDefinitions,
                  ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    icon: const Icon(Icons.edit, size: 16),
                    label: const Text('Customize Columns'),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      textStyle: const TextStyle(fontSize: 13),
                    ),
                    onPressed: _showCustomizeColumnsDialog,
                  ),
                ],
              ),
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
                    dataTableTheme: DataTableThemeData(
                                       headingRowColor: WidgetStatePropertyAll(ThemeAwareColors.getTableHeaderColor(context)),
                    headingTextStyle: TextStyle(
                     color: ThemeAwareColors.getTableHeaderTextColor(context),
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    columnSpacing: 8,
                    horizontalMargin: 8,
                  ),
                ),
                child: DataTable(
                  sortColumnIndex:
                      displayFields.contains(_sortColumn) ? displayFields.indexOf(_sortColumn) : null,
                  sortAscending: _sortAscending,
                  headingRowColor: WidgetStateProperty.all(ThemeAwareColors.getTableHeaderColor(context)),
                  headingTextStyle: TextStyle(color: ThemeAwareColors.getTableHeaderTextColor(context), fontWeight: FontWeight.bold, fontSize: 15),
                  dataRowMinHeight: 44,
                  dataRowMaxHeight: 44,
                  showCheckboxColumn: false,
                  border: TableBorder.all(
                    color: ThemeAwareColors.getDividerColor(context),
                    width: 0.5,
                  ),
                  columns: displayFields.map((header) {
                    return DataColumn(
                      label: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                        child: Text(_formatHeaderName(header))
                      ),
                      onSort: (columnIndex, ascending) {
                        setState(() {
                          _sortColumn = displayFields[columnIndex];
                          _sortAscending = ascending;
                          _applyFiltersAndFetch();
                        });
                      },
                    );
                  }).toList(),
                  rows: _rawRows.asMap().entries.map((entry) {
                    final int rowIndex = entry.key;
                    final Map<String, dynamic> row = entry.value;
                    return DataRow(
                      color: WidgetStateProperty.resolveWith<Color?>((states) => ThemeAwareColors.getTableRowColor(context, rowIndex)),
                      cells: displayFields.map((header) {
                        final value = row[header];
                        String displayValue;
                        Color? cellBackgroundColor;
  
                        if (value == null) {
                          displayValue = 'N/A';
                        } else if (value is num && numericShadingColumns.contains(header)) {
                          final percentile = columnPercentiles[header]?[value];
                          if (percentile != null) {
                            cellBackgroundColor = Color.fromRGBO(
                              100, 140, 240, 0.1 + (percentile * 0.85)
                            );
                          }
                          if (doubleFields.contains(header)) {
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
                            child: (header == 'home_team' || header == 'away_team')
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
        if (_rawRows.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: _currentPage > 0 ? () => setState(() {
                    _currentPage--;
                    _fetchDataFromFirebase();
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
                      _fetchDataFromFirebase();
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