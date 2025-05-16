import 'package:flutter/material.dart';
import 'package:mds_home/widgets/common/app_drawer.dart';
import 'package:mds_home/models/wr_model_stat.dart';
import 'package:mds_home/widgets/common/top_nav_bar.dart';
import 'package:mds_home/widgets/common/custom_app_bar.dart';
import 'package:mds_home/widgets/auth/auth_dialog.dart';
import 'package:cloud_functions/cloud_functions.dart';

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

class WRModelScreen extends StatefulWidget {
  const WRModelScreen({super.key});

  @override
  State<WRModelScreen> createState() => _WRModelScreenState();
}

class _WRModelScreenState extends State<WRModelScreen> {
  bool _isLoading = true;
  String? _error;
  List<Map<String, dynamic>> _rawRows = [];
  int _totalRecords = 0;
  List<Map<String, dynamic>>? _wrCacheAll; // Cache for unfiltered WR data
  bool _isCacheLoading = false; // Track cache loading state
  
  // Pagination state
  int _currentPage = 0;
  static const int _rowsPerPage = 25;
  
  // Sort state
  String _sortColumn = 'points';
  bool _sortAscending = false;

  List<String> _headers = [];
  
  // Main fields to show by default
  static const List<String> _defaultFields = [
    'receiver_player_name', 'posteam', 'season', 'numGames', 'tgtShare', 
    'seasonYards', 'wr_rank', 'numTD', 'numRec', 'points'
  ];
  List<String> _selectedFields = List.from(_defaultFields);

  // State for Query Builder
  final List<QueryCondition> _queryConditions = [];
  String? _newQueryField;
  QueryOperator? _newQueryOperator;
  final TextEditingController _newQueryValueController = TextEditingController();

  FirebaseFunctions functions = FirebaseFunctions.instance;

  // Only allow the 'Equals' operator for WR Model Stats queries
  final List<QueryOperator> _allowedOperators = [QueryOperator.equals];

  @override
  void initState() {
    super.initState();
    _headers = _defaultFields;
    if (_headers.isNotEmpty) _newQueryField = _headers[0];
    
    _fetchDataFromFirebase();
  }

  @override
  void dispose() {
    _newQueryValueController.dispose();
    super.dispose();
  }

  Future<void> _fetchDataFromFirebase() async {
    // If no filters, use cache if available
    final bool noFilters = _queryConditions.isEmpty;
    if (noFilters && _wrCacheAll != null) {
      print('[WRCache] Using cached unfiltered data.');
      setState(() {
        _rawRows = List<Map<String, dynamic>>.from(_wrCacheAll!);
        _totalRecords = _wrCacheAll!.length;
        _isLoading = false;
      });
      return;
    }
    if (noFilters && _wrCacheAll == null) {
      print('[WRCache] Building cache for unfiltered data...');
    }
    setState(() {
      _isLoading = true;
      _error = null;
      if (noFilters && _wrCacheAll == null) _isCacheLoading = true;
    });
    Map<String, dynamic> filtersForFunction = {};
    for (var condition in _queryConditions) {
      filtersForFunction[condition.field] = condition.value;
    }
    try {
      final HttpsCallable callable = functions.httpsCallable('getWrModelStats');
      final result = await callable.call<Map<String, dynamic>>({
        'filters': filtersForFunction,
        'limit': _rowsPerPage,
        'offset': _currentPage * _rowsPerPage,
        'orderBy': _sortColumn,
        'orderDirection': _sortAscending ? 'asc' : 'desc',
      });
      // For unfiltered, also fetch and cache the full set (up to 5000 rows)
      if (noFilters && _wrCacheAll == null) {
        final fullResult = await callable.call<Map<String, dynamic>>({
          'filters': {},
          'limit': 5000,
          'offset': 0,
          'orderBy': _sortColumn,
          'orderDirection': _sortAscending ? 'asc' : 'desc',
        });
        final List<dynamic> fullData = fullResult.data['data'] ?? [];
        _wrCacheAll = fullData.map((item) => Map<String, dynamic>.from(item)).toList();
        _isCacheLoading = false;
      }
      if (mounted) {
        setState(() {
          final List<dynamic> data = result.data['data'] ?? [];
          _rawRows = data.map((item) => Map<String, dynamic>.from(item)).toList();
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
          _isCacheLoading = false;
        });
      }
    } on FirebaseFunctionsException catch (e) {
      print('FirebaseFunctionsException caught in Flutter client:');
      print('Code: \\${e.code}');
      print('Message: \\${e.message}');
      print('Details: \\${e.details}');
      if (mounted) {
        setState(() {
          String displayError = 'Error fetching data: \\nCode: \\${e.code}\nMessage: \\${e.message}\nDetails: \\${e.details}';
          if (e.code == 'failed-precondition') {
            displayError = 'Query Error: A required Firestore index is missing. Please check the Firebase Functions logs for a link to create it. Details: \\${e.message}';
          } else if (e.message != null && e.message!.toLowerCase().contains('index')){
            displayError = 'Query Error: There might be an issue with Firestore indexes. Please check Firebase Functions logs. Details: \\${e.message}';
          }
          _error = displayError;
          _isLoading = false;
          _isCacheLoading = false;
        });
      }
    } catch (e, stack) {
      print('Generic error in _fetchDataFromFirebase (client-side): $e');
      print(stack);
      if (mounted) {
        setState(() {
          _error = 'An unexpected error occurred on the client: $e\n$stack';
          _isLoading = false;
          _isCacheLoading = false;
        });
      }
    }
  }

  void _applyFiltersAndFetch() {
    _currentPage = 0;
    // If filters are cleared, use cache next time
    if (_queryConditions.isEmpty && _wrCacheAll != null) {
      // No need to clear cache
    } else if (_queryConditions.isNotEmpty) {
      print('[WRCache] Invalidating cache due to filters.');
      // If filters are applied, do not use cache
      _wrCacheAll = null;
    }
    _fetchDataFromFirebase();
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
      ),
      drawer: const AppDrawer(),
      body: Column(
        children: [
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
                          items: _allowedOperators.map((op) => DropdownMenuItem(
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
            child: (_isLoading || _isCacheLoading)
              ? const Center(child: CircularProgressIndicator())
              : _error != null
                  ? Center(child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 16), textAlign: TextAlign.center,)
                    ))
                  : _buildDataTable(),
          ),
        ],
      ),
    );
  }

  Widget _buildDataTable() {
    if (_rawRows.isEmpty && !_isLoading && _error == null) {
      return const Center(child: Text('No WR data found. Try adjusting your filters or check the database.', style: TextStyle(fontSize: 16)));
    }

    // Define common field groupings with descriptive tab names
    final List<Map<String, dynamic>> fieldGroups = [
      {
        'name': 'Overview',
        'fields': ['receiver_player_name', 'posteam', 'season', 'numGames', 'tgtShare', 'numRec', 'seasonYards', 'numTD', 'points', 'wr_rank']
      },
      {
        'name': 'Targets & Receptions',
        'fields': ['receiver_player_name', 'posteam', 'season', 'numGames', 'tgt', 'tgtShare', 'numRec', 'recYdsShare', 'rec_per_game', 'avg_depth', 'aDOT']
      },
      {
        'name': 'Production',  
        'fields': ['receiver_player_name', 'posteam', 'season', 'numGames', 'seasonYards', 'ydsPerRec', 'ydsPerTgt', 'yards_per_game', 'numTD', 'points']
      },
      {
        'name': 'Advanced',
        'fields': ['receiver_player_name', 'posteam', 'season', 'WOPR', 'RACR', 'aDOT', 'YPRR', 'aYPRR', 'aFP', 'points']
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

    // Calculate percentiles for numeric columns that need shading
    Map<String, Map<dynamic, double>> columnPercentiles = {};
    
    // Fields to exclude from shading (non-numeric or identifier fields)
    final List<String> excludedFields = [
      'receiver_player_name', 'posteam', 'season', 'id', 'name', 'team'
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
      if (condition.field == 'season') {
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
            if (row['season'].toString() == seasonFilter) {
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
          crossAxisAlignment: CrossAxisAlignment.stretch, // Stretch children to fill width
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
            
            // Row with action buttons
            Padding(
              padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 8.0, bottom: 4.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween, // Push items to ends
                children: [
                  Text(
                    _rawRows.isEmpty
                        ? '' // Show nothing if no data for pagination info
                        : 'Page ${(_currentPage) + 1} of ${(_totalRecords / _rowsPerPage).ceil().clamp(1, 9999)}. Total: $_totalRecords records.',
                    style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                  ),
                  Row(
                    children: [
                      TextButton.icon(
                        icon: const Icon(Icons.edit, size: 16),
                        label: const Text('Customize'),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          textStyle: const TextStyle(fontSize: 13),
                        ),
                        onPressed: () {
                          _showCustomizeColumnsDialog();
                        },
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Last Updated: ${DateTime.now().month}/${DateTime.now().day}/${DateTime.now().year}', 
                        style: TextStyle(color: Colors.grey.shade600, fontStyle: FontStyle.italic, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            Expanded(
              child: SingleChildScrollView(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.all(8.0), // Add padding around the DataTable
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
                                Text(header),
                                if (_sortColumn == header)
                                  Icon(
                                    _sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
                                    size: 16,
                                    color: Colors.white, // Sort icon color for header
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
                      rows: _rawRows.asMap().entries.map((entry) {
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
                                  // Use pure blue color with varying opacity
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
                                
                                // Smart numeric formatting
                                if (header.toLowerCase().contains('share') || header.toLowerCase().contains('pct') || header.toLowerCase().contains('%')) {
                                  displayValue = '${(value * 100).toStringAsFixed(1)}%';
                                } else if (value is double) {
                                   // Specific formatting for different metrics
                                  if (header.toLowerCase() == 'adot' || header.toLowerCase() == 'yprr' || header.toLowerCase().contains('epa')) {
                                      displayValue = value.toStringAsFixed(2);
                                  } else if (header.toLowerCase() == 'points'){
                                      displayValue = value.toStringAsFixed(1);
                                  } else {
                                      displayValue = value.toStringAsFixed(1);
                                  }
                                } else {
                                  displayValue = value.toString();
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
                                child: Text(
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
                          ? () => this.setState(() { _currentPage--; _fetchDataFromFirebase(); })
                          : null,
                      child: const Text('Previous'),
                    ),
                    const SizedBox(width: 16),
                    Text('Page ${(_currentPage) + 1} of ${(_totalRecords / _rowsPerPage).ceil().clamp(1,9999)}'),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: (_currentPage + 1) * _rowsPerPage < _totalRecords
                          ? () => this.setState(() { _currentPage++; _fetchDataFromFirebase(); })
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