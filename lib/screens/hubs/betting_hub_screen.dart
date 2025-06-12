import 'package:flutter/material.dart';
import 'package:mds_home/widgets/common/custom_app_bar.dart';
import 'package:mds_home/widgets/common/responsive_layout_builder.dart';
import '../../widgets/auth/auth_dialog.dart';
import '../../widgets/common/app_drawer.dart';
import '../../widgets/common/top_nav_bar.dart';
import '../../widgets/home/home_slideshow.dart';
import '../../widgets/home/stacked_tool_links.dart';
import 'package:collection/collection.dart'; // For firstWhereOrNull
import 'package:cloud_functions/cloud_functions.dart';
import 'package:mds_home/utils/team_logo_utils.dart';

// Helper function (can be extracted later)
Map<String, dynamic>? _findAndFormatTool(NavItem? hub, String route, {String? desc, IconData? icon}) {
  if (hub?.subItems == null) return null;
  final item = hub!.subItems!.firstWhereOrNull((i) => i.route == route);
  if (item == null) return null;
  return {
    'icon': icon ?? item.icon ?? Icons.build_circle_outlined,
    'title': item.title,
    'desc': desc ?? 'Access the ${item.title} tool.',
    'route': item.route,
    'isPlaceholder': item.isPlaceholder,
  };
}

// Find the Betting Hub NavItem
final NavItem? _bettingHubNavItem = topNavItems.firstWhereOrNull((item) => item.route == '/betting');

// Define the curated list of tools for Betting Hub preview
final List<Map<String, dynamic>> _previewTools = [
  _findAndFormatTool(_bettingHubNavItem, '/betting', desc: 'Odds, trends, and historical ATS data.', icon: Icons.paid), // Betting Analytics
  _findAndFormatTool(_bettingHubNavItem, '/betting/lines', desc: 'Track real-time line movements.', icon: Icons.show_chart), // Line Movement Tracker*
  _findAndFormatTool(_bettingHubNavItem, '/betting/angles', desc: 'Discover profitable betting angles.', icon: Icons.explore), // Betting Angles Dashboard*
  _findAndFormatTool(_bettingHubNavItem, '/betting/matchups', desc: 'Analyze historical matchup data for edges.', icon: Icons.history_edu), // Historical Matchup Analysis*
  _findAndFormatTool(_bettingHubNavItem, '/betting/money', desc: 'See where the public and sharp money is going.', icon: Icons.attach_money), // Public vs. Sharp Money*
  _findAndFormatTool(_bettingHubNavItem, '/betting/performance', desc: 'Track your betting performance and ROI.', icon: Icons.assessment), // Performance Tracker*
].whereNotNull().toList();

// Reusing Query Enums and helpers from wr_model_screen
enum QueryOperator {
  equals,
  notEquals,
  greaterThan,
  greaterThanOrEquals,
  lessThan,
  lessThanOrEquals,
}

String queryOperatorToString(QueryOperator op) {
  switch (op) {
    case QueryOperator.equals: return '==';
    case QueryOperator.notEquals: return '!=';
    case QueryOperator.greaterThan: return '>';
    case QueryOperator.greaterThanOrEquals: return '>=';
    case QueryOperator.lessThan: return '<';
    case QueryOperator.lessThanOrEquals: return '<=';
  }
}

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

class BettingHubScreen extends StatefulWidget {
  const BettingHubScreen({super.key});

  @override
  State<BettingHubScreen> createState() => _BettingHubScreenState();
}

class _BettingHubScreenState extends State<BettingHubScreen> {
  bool _isLoading = true;
  String? _error;
  List<Map<String, dynamic>> _rawRows = [];
  int _totalRecords = 0;
  
  // Pagination state
  int _currentPage = 0;
  static const int _rowsPerPage = 25;
  List<String?> _pageCursors = [null]; // Using document IDs (strings) as cursors
  String? _nextCursor;
  
  // Sort state
  String _sortColumn = 'game_id';
  bool _sortAscending = false;

  List<String> _headers = [];
  
  // Main fields to show by default
  static const List<String> _defaultFields = [
    'season', 'week', 'gameday', 'home_team', 'away_team', 'spread_line', 'total_line', 'result', 'home_score', 'away_score'
  ];
  List<String> _selectedFields = List.from(_defaultFields);

  // State for Query Builder
  final List<QueryCondition> _queryConditions = [];
  String? _newQueryField;
  QueryOperator? _newQueryOperator;
  final TextEditingController _newQueryValueController = TextEditingController();

  FirebaseFunctions functions = FirebaseFunctions.instance;

  // Field groups for the Betting Hub
  static const List<Map<String, dynamic>> fieldGroups = [
    {
      'name': 'Game Info',
      'fields': [
        'season', 'week', 'game_type', 'gameday', 'kickoff_time', 'home_team', 'away_team', 'result', 'total', 'home_score', 'away_score'
      ]
    },
    {
      'name': 'Betting Info',
      'fields': [
        'season', 'home_team', 'away_team', 'spread_line', 'total_line', 'favorite_team', 'underdog_team', 'home_moneyline', 'away_moneyline'
      ]
    },
    {
      'name': 'Venue & Weather',
      'fields': [
        'season', 'home_team', 'away_team', 'location', 'stadium', 'roof', 'surface', 'temp', 'wind'
      ]
    },
    {
      'name': 'Custom',
      'fields': []
    }
  ];

  // Map for short, clear header display names
  static const Map<String, String> headerDisplayNames = {
    'game_id': 'Game ID',
    'season': 'Season',
    'game_type': 'Type',
    'week': 'Week',
    'gameday': 'Date',
    'kickoff_time': 'Time',
    'away_team': 'Away',
    'home_team': 'Home',
    'away_score': 'Away Score',
    'home_score': 'Home Score',
    'result': 'Result',
    'total': 'Total',
    'spread_line': 'Spread',
    'total_line': 'O/U',
    'away_moneyline': 'Away ML',
    'home_moneyline': 'Home ML',
    'favorite_team': 'Favorite',
    'underdog_team': 'Underdog',
    'location': 'Location',
    'stadium': 'Stadium',
    'roof': 'Roof',
    'surface': 'Surface',
    'temp': 'Temp (°F)',
    'wind': 'Wind (mph)',
  };

  // Helper to determine field type for query input
  String getFieldType(String field) {
    const Set<String> doubleFields = {'spread_line', 'total_line'};
    const Set<String> intFields = {'season', 'week', 'result', 'total', 'away_score', 'home_score', 'away_moneyline', 'home_moneyline', 'temp', 'wind'};
    if (field == 'gameday') return 'date';
    if (doubleFields.contains(field)) return 'double';
    if (intFields.contains(field)) return 'int';
    return 'string';
  }

  // All operators for query
  final List<QueryOperator> _allOperators = [
    QueryOperator.equals,
    QueryOperator.notEquals,
    QueryOperator.greaterThan,
    QueryOperator.greaterThanOrEquals,
    QueryOperator.lessThan,
    QueryOperator.lessThanOrEquals,
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

  Future<void> _fetchDataFromFirebase() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    Map<String, dynamic> filtersForFunction = {};
    for (var condition in _queryConditions) {
      filtersForFunction[condition.field] = {
        'operator': queryOperatorToString(condition.operator),
        'value': _parseValue(condition.value, getFieldType(condition.field)),
      };
    }

    final String? currentCursor = _currentPage > 0 && _pageCursors.length > _currentPage ? _pageCursors[_currentPage] : null;

    try {
      final HttpsCallable callable = functions.httpsCallable('getBettingData');
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
          _rawRows = data.map((item) => Map<String, dynamic>.from(item)).toList();
          _totalRecords = result.data['totalRecords'] ?? 0;
          _nextCursor = result.data['nextCursor'];

          if (_rawRows.isNotEmpty && _headers.isEmpty) {
            final allKeys = _rawRows
                .expand((row) => row.keys)
                .toSet()
                .toList();
            _headers = allKeys;
            _newQueryField ??= _headers[0];
          }
          _isLoading = false;
        });
      }
    } on FirebaseFunctionsException catch (e) {
      if (mounted) {
        setState(() {
          _error = "Error: ${e.message}";
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'An unexpected error occurred: $e';
          _isLoading = false;
        });
      }
    }
  }
  
  dynamic _parseValue(String value, String type) {
    if (type == 'int') return int.tryParse(value);
    if (type == 'double') return double.tryParse(value);
    return value;
  }

  void _applyFiltersAndFetch() {
    _currentPage = 0;
    _pageCursors = [null];
    _nextCursor = null;
    _fetchDataFromFirebase();
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
                height: 500,
                child: ListView(
                  children: _headers.map((header) {
                    return CheckboxListTile(
                      title: Text(headerDisplayNames[header] ?? header),
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
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                TextButton(
                  onPressed: () => setState(() => tempSelected = List.from(_headers)),
                  child: const Text('Select All'),
                ),
                ElevatedButton(
                  onPressed: () {
                    this.setState(() => _selectedFields = List.from(tempSelected));
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
    setState(() => _queryConditions.removeAt(index));
  }

  void _clearAllQueryConditions() {
    setState(() => _queryConditions.clear());
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
              ),
              child: const Text('Sign In / Sign Up'),
            ),
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: Column(
        children: [
          // Query Builder Card
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Build Query', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8.0),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // Field Dropdown
                      Expanded(
                        flex: 2,
                        child: DropdownButtonFormField<String>(
                          decoration: const InputDecoration(labelText: 'Field', isDense: true),
                          value: _headers.contains(_newQueryField) ? _newQueryField : null,
                          items: _headers.map((h) => DropdownMenuItem(value: h, child: Text(headerDisplayNames[h] ?? h, overflow: TextOverflow.ellipsis))).toList(),
                          onChanged: (v) => setState(() => _newQueryField = v),
                           isExpanded: true,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Operator Dropdown
                      Expanded(
                        flex: 2,
                        child: DropdownButtonFormField<QueryOperator>(
                          decoration: const InputDecoration(labelText: 'Operator', isDense: true),
                          value: _newQueryOperator,
                          items: _allOperators.map((op) => DropdownMenuItem(value: op, child: Text(queryOperatorToString(op)))).toList(),
                          onChanged: (v) => setState(() => _newQueryOperator = v),
                           isExpanded: true,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Value Input
                      Expanded(
                        flex: 2,
                        child: TextField(
                          controller: _newQueryValueController,
                          decoration: const InputDecoration(labelText: 'Value', isDense: true),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(onPressed: _addQueryCondition, child: const Text('Add')),
                    ],
                  ),
                  if (_queryConditions.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6.0,
                      runSpacing: 2.0,
                      children: _queryConditions.asMap().entries.map((entry) {
                        return Chip(
                          label: Text(entry.value.toString()),
                          onDeleted: () => _removeQueryCondition(entry.key),
                        );
                      }).toList(),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(onPressed: _clearAllQueryConditions, child: const Text('Clear All')),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.filter_alt, size: 16),
                        label: const Text('Apply Queries'),
                        onPressed: _applyFiltersAndFetch,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          // Data Table
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 16), textAlign: TextAlign.center,)
                      ))
                    : _rawRows.isEmpty 
                        ? const Center(child: Text('No data found for your query.'))
                        : _buildDataTable(),
          ),
        ],
      ),
    );
  }

  Widget _buildDataTable() {
    int selectedGroupIndex = fieldGroups.indexWhere((g) => g['name'] == 'Custom');

    return StatefulBuilder(
      builder: (context, setState) {
        List<String> displayFields = selectedGroupIndex == fieldGroups.length - 1 
            ? _selectedFields 
            : List<String>.from(fieldGroups[selectedGroupIndex]['fields']);
        
        displayFields.retainWhere((f) => _headers.contains(f));

        return Column(
          children: [
            // Field group tabs
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
              child: Row(
                children: List.generate(fieldGroups.length, (index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: ChoiceChip(
                      label: Text(fieldGroups[index]['name']),
                      selected: selectedGroupIndex == index,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            selectedGroupIndex = index;
                            if (index < fieldGroups.length - 1) { // Not custom
                              _selectedFields = List<String>.from(fieldGroups[index]['fields']);
                            }
                          });
                        }
                      },
                    ),
                  );
                }),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                   Text(
                     _totalRecords > 0 
                       ? 'Page ${(_currentPage) + 1} of ${(_totalRecords / _rowsPerPage).ceil().clamp(1, 9999)}. Total: $_totalRecords records.'
                       : 'Page ${(_currentPage) + 1}',
                     style: TextStyle(color: Colors.grey.shade700, fontSize: 13)
                   ),
                  TextButton.icon(
                    icon: const Icon(Icons.edit, size: 16),
                    label: const Text('Customize'),
                    onPressed: _showCustomizeColumnsDialog,
                  )
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.all(8.0),
                  child: DataTable(
                    sortColumnIndex: displayFields.contains(_sortColumn) ? displayFields.indexOf(_sortColumn) : null,
                    sortAscending: _sortAscending,
                    columns: displayFields.map((header) {
                      return DataColumn(
                        label: Text(headerDisplayNames[header] ?? header, style: const TextStyle(fontWeight: FontWeight.bold)),
                        onSort: (columnIndex, ascending) {
                          this.setState(() {
                            _sortColumn = displayFields[columnIndex];
                            _sortAscending = ascending;
                            _applyFiltersAndFetch();
                          });
                        },
                      );
                    }).toList(),
                    rows: _rawRows.map((row) {
                      return DataRow(
                        cells: displayFields.map((header) {
                          final value = row[header];
                          String displayValue = value?.toString() ?? 'N/A';

                          if (value != null) {
                            if (header == 'spread_line') {
                              displayValue = value > 0 ? '+$value' : value.toString();
                            } else if (header == 'gameday' && value is String) {
                               DateTime? date = DateTime.tryParse(value);
                               if (date != null) {
                                 displayValue = '${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}/${date.year}';
                               }
                            } else if (value is double) {
                              displayValue = value.toStringAsFixed(2);
                            }
                          }

                          return DataCell(
                            (header == 'home_team' || header == 'away_team' || header == 'favorite_team' || header == 'underdog_team')
                              ? Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (value != null) TeamLogoUtils.buildNFLTeamLogo(value.toString(), size: 24),
                                    const SizedBox(width: 8),
                                    Text(displayValue),
                                  ],
                                )
                              : Text(displayValue)
                          );
                        }).toList(),
                      );
                    }).toList(),
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
                          ? () => this.setState(() {
                              _currentPage--;
                              _fetchDataFromFirebase();
                            })
                          : null,
                      child: const Text('Previous'),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      _totalRecords > 0
                        ? 'Page ${(_currentPage) + 1} of ${(_totalRecords / _rowsPerPage).ceil().clamp(1, 9999)}'
                        : 'Page ${(_currentPage) + 1}',
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: _nextCursor != null
                          ? () {
                              this.setState(() {
                                if (_pageCursors.length <= _currentPage + 1) {
                                  _pageCursors.add(_nextCursor);
                                } else {
                                  _pageCursors[_currentPage + 1] = _nextCursor;
                                }
                                _currentPage++;
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
      },
    );
  }
} 