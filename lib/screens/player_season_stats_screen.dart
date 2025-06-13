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

  // -- DYNAMICALLY GENERATED --
  Map<String, List<String>> _statCategoryFieldGroups = {};
  Set<String> _doubleFields = {};
  // -- END DYNAMIC --

  // New, static field groups as per user request
  static final Map<String, List<String>> _fieldGroups = {
      'Info': [
          'player_name', 'recent_team', 'position', 'season', 'age', 'draft_number',
          'height', 'weight', 'college', 'forty_yd', 'vertical', 'cone', 'shuttle', 'broad_jump'
      ],
      'Basic Stats': [ // This will be dynamically adjusted based on position
          'player_name', 'recent_team', 'season', 'games',
          // Placeholder, will be replaced
      ],
      'Advanced Stats': [
          'player_name', 'recent_team', 'season',
          'total_epa', 'wopr', 'racr', 'target_share', 'air_yards_share', 'adot', 'pacr',
          'passing_yards_after_catch', 'avg_yac', 'avg_cushion', 'avg_separation'
      ],
      'Custom': [] // Will be populated by user selection
  };

  static const Map<String, List<String>> _positionalBasicStats = {
      'QB': ['completions', 'attempts', 'passing_yards', 'passing_tds', 'interceptions', 'sacks'],
      'RB': ['carries', 'rushing_yards', 'rushing_tds', 'receptions', 'targets', 'receiving_yards', 'receiving_tds'],
      'WR': ['receptions', 'targets', 'receiving_yards', 'receiving_tds', 'carries', 'rushing_yards', 'rushing_tds'],
      'TE': ['receptions', 'targets', 'receiving_yards', 'receiving_tds'],
  };
  
  String _selectedStatCategory = 'Info';

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

  void _buildDynamicCategories(List<Map<String, dynamic>> data) {
    if (data.isEmpty) return;

    final allFields = data.first.keys.toSet();
    final Map<String, List<String>> newGroups = {
      for (var category in _fieldGroups.keys) category: []
    };
    newGroups['Other'] = [];

    for (final field in allFields) {
      String? assignedCategory;
      for (final entry in _fieldGroups.entries) {
        if (entry.value.any((keyword) => field.toLowerCase().contains(keyword))) {
          assignedCategory = entry.key;
          break;
        }
      }
      newGroups[assignedCategory ?? 'Other']!.add(field);
    }

    // Ensure player_name and season are always in Info
    if (newGroups['Info'] != null) {
        if (!newGroups['Info']!.contains('player_name')) newGroups['Info']!.insert(0, 'player_name');
        if (!newGroups['Info']!.contains('season')) newGroups['Info']!.insert(1, 'season');
    }
    
    // Remove empty categories
    newGroups.removeWhere((key, value) => value.isEmpty);

    // Identify double fields dynamically
    final Set<String> newDoubleFields = {};
    final firstRow = data.first;
    for (final field in allFields) {
      if (firstRow[field] is double) {
        newDoubleFields.add(field);
      }
    }
    
    setState(() {
      _statCategoryFieldGroups = newGroups;
      _doubleFields = newDoubleFields;
      // If the previously selected category no longer exists, default to the first one
      if (!_statCategoryFieldGroups.containsKey(_selectedStatCategory)) {
        _selectedStatCategory = _statCategoryFieldGroups.keys.first;
      }
    });
  }

  // Helper to determine field type for query input
  String getFieldType(String field) {
    const Set<String> doubleFields = {
      'passing_yards_per_attempt', 'passing_tds_per_attempt',
      'rushing_yards_per_attempt', 'rushing_tds_per_attempt',
      'yards_per_reception', 'receiving_tds_per_reception',
      'yards_per_touch', 'wopr', 'target_share', 'rush_share',
      'completion_percentage_above_expectation', 'avg_yac_above_expectation', 'aggressiveness', 'avg_intended_air_yards', 'avg_cushion', 'avg_separation',
      'forty_yd', 'vertical_jump', 'broad_jump', 'cone', 'shuttle'
    };
    const Set<String> intFields = {
      'season', 'games', 'completions', 'attempts', 'passing_yards', 'passing_tds',
      'interceptions', 'sacks', 'sack_yards', 'rushing_attempts', 'rushing_yards',
      'rushing_tds', 'receptions', 'targets', 'receiving_yards', 'receiving_tds',
      'fantasy_points', 'fantasy_points_ppr', 'years_experience', 'height', 'weight', 'draft_number',
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
        final List<dynamic> data = result.data['data'] ?? [];
        final newRows = data.map((item) => Map<String, dynamic>.from(item)).toList();
        
        setState(() {
          _rawRows = newRows;
          _totalRecords = result.data['totalRecords'] ?? 0;
          _nextCursor = result.data['nextCursor'];

          if (_rawRows.isNotEmpty) {
            _headers = _rawRows.first.keys.toList();
            if (!_headers.contains(_newQueryField) && _headers.isNotEmpty) {
              _newQueryField = _headers[0];
            }
            if (_selectedFields.isEmpty) {
              _selectedFields = List.from(_fieldGroups['Info'] ?? []);
            }
          }
          _isLoading = false;
        });
      }
      _startPreloadingNextPages();
    } on FirebaseFunctionsException catch (e) {
      print('FirebaseFunctionsException caught in Flutter client:');
      print('Code: ${e.code}');
      print('Message: ${e.message}');
      print('Details: ${e.details}');
      if (mounted) {
        setState(() {
          // IMPORTANT: Always set the error to the friendly, non-technical message.
          _error = "We're working on adding this. Stay tuned.";
          _isLoading = false;
        });
      }
    } catch (e, stack) {
      print('Generic error in _fetchDataFromFirebase (client-side): $e');
      print(stack);
      if (mounted) {
        setState(() {
          _error = 'An unexpected error occurred on the client: $e\n$stack';
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
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: TextField(
                        decoration: const InputDecoration(
                          labelText: 'Search Fields',
                          prefixIcon: Icon(Icons.search),
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                              vertical: 8, horizontal: 16),
                        ),
                        onChanged: (value) {
                          setState(() {
                            // Re-render to apply search filter
                          });
                        },
                      ),
                    ),
                    Expanded(
                      child: ListView(
                        children: _headers.where((header) {
                          // Filtering logic here if needed
                          return true;
                        }).map((header) {
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
                    this.setState(() {
                       _selectedFields = List.from(tempSelected);
                       _selectedStatCategory = 'Custom';
                    });
                    Navigator.pop(context);
                  },
                  child: const Text('Apply'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  String _toTitleCase(String text) {
    if (text.isEmpty) return '';
    return text.replaceAll('_', ' ').split(' ').map((word) {
      if (word.isEmpty) return '';
      if (word.toUpperCase() == word) return word; // Keep acronyms like 'QB'
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
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
          _buildQueryBuilder(),
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

  Widget _buildQueryBuilder() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Build Query',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold)),
                TextButton.icon(
                  icon: const Icon(Icons.edit, size: 16),
                  label: const Text('Customize Columns'),
                  onPressed: _showCustomizeColumnsDialog,
                ),
              ],
            ),
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
                          // When position changes, reset category to standard
                          _selectedStatCategory = 'Info';
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
                  style: TextButton.styleFrom(
                      minimumSize: const Size(36, 32),
                      padding: const EdgeInsets.symmetric(horizontal: 8)),
                  onPressed: _clearAllQueryConditions,
                  child:
                      const Text('Clear All', style: TextStyle(fontSize: 13)),
                ),
                const SizedBox(width: 6.0),
                SizedBox(
                  height: 32,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 0),
                        textStyle: const TextStyle(fontSize: 13)),
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
    );
  }

  Widget _buildDataTable() {
    if (_rawRows.isEmpty && !_isLoading && _error == null) {
      return const Center(
          child: Text('No player data found. Try adjusting your filters.',
              style: TextStyle(fontSize: 16)));
    }

    // Determine the fields to display based on the selected category
    List<String> displayFields = [];
    final currentCategory = _selectedStatCategory;
    
    if (currentCategory == 'Custom') {
        displayFields = _selectedFields;
    } else if (currentCategory == 'Basic Stats') {
        // Start with the base fields
        List<String> basicFields = List.from(_fieldGroups['Basic Stats'] ?? []);
        // Add position-specific fields
        List<String> positionalFields = _positionalBasicStats[_selectedPosition] ?? _positionalBasicStats['WR']!; // Default to WR
        // Combine, ensuring no duplicates and maintaining order
        displayFields = [...basicFields, ...positionalFields.where((f) => !basicFields.contains(f))]
                        .where((field) => _headers.contains(field)).toList();
    }
    else {
        displayFields = _fieldGroups[currentCategory]
                            ?.where((field) => _headers.contains(field))
                            .toList() ?? [];
    }
    
    // Ensure 'player_name' is always first if it exists
    if (displayFields.contains('player_name') && displayFields.first != 'player_name') {
        displayFields.remove('player_name');
        displayFields.insert(0, 'player_name');
    }

    // Calculate percentiles for numeric columns
    Map<String, Map<dynamic, double>> columnPercentiles = {};

    // Determine numeric columns dynamically from headers
    List<String> numericShadingColumns = [];
    if (_rawRows.isNotEmpty) {
      for (final field in _rawRows.first.keys) {
        if (field != 'player_id' && field != 'player_name' && field != 'position' && field != 'recent_team' && field != 'season' &&
            _rawRows.any((row) => row[field] != null && row[field] is num)) {
          numericShadingColumns.add(field);
        }
      }
    }
    
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

    final Set<String> doubleFields = _doubleFields;

    // Define colors for styling
    final Color headerColor = Colors.blue.shade700;
    final Color evenRowColor = Colors.grey.shade100;
    const Color oddRowColor = Colors.white;
    const TextStyle headerTextStyle =
        TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15);
    const TextStyle cellTextStyle = TextStyle(fontSize: 14);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Field group tabs (ChoiceChip style)
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
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
                        if (category == 'Custom' && _selectedFields.isEmpty) {
                            _selectedFields = _fieldGroups['Info'] ?? [];
                        }
                      });
                    }
                  },
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 8),

        // Row with action buttons and info
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
                  sortColumnIndex:
                      displayFields.contains(_sortColumn) ? displayFields.indexOf(_sortColumn) : null,
                  sortAscending: _sortAscending,
                  headingRowColor: WidgetStateProperty.all(Colors.blue.shade700),
                  headingTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                  dataRowHeight: 44,
                  showCheckboxColumn: false,
                  border: TableBorder.all(
                    color: Colors.grey.shade300,
                    width: 0.5,
                  ),
                  columns: displayFields.map((header) {
                    return DataColumn(
                      label: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                        child: Text(_toTitleCase(header))
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
                      color: WidgetStateProperty.resolveWith<Color?>((states) => rowIndex.isEven ? Colors.grey.shade100 : Colors.white),
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
                            child: header == 'recent_team'
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