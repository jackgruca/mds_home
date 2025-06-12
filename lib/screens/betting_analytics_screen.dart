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
  String? _nextCursor;
  int _currentPage = 0;
  final int _rowsPerPage = 25;
  List<String?> _pageCursors = [null];

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

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final callable = _functions.httpsCallable('getBettingData');
      final result = await callable.call<Map<String, dynamic>>({
        'limit': _rowsPerPage,
        'orderBy': _sortColumn,
        'orderDirection': _sortAscending ? 'asc' : 'desc',
        'cursor': _pageCursors[_currentPage],
        'filters': { for (var c in _queryConditions) c.field: c.value },
      });

      if (mounted) {
        setState(() {
          _rows = List<Map<String, dynamic>>.from(result.data['data'] ?? []);
          _totalRecords = result.data['totalRecords'] ?? 0;
          _nextCursor = result.data['nextCursor'];
          
          if (_rows.isNotEmpty && _headers.isEmpty) {
              _headers = _rows.first.keys.toList();
              _newQueryField = _headers.first;
          }

          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Error fetching data: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }
  
  void _applyFilters() {
    _currentPage = 0;
    _pageCursors = [null];
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
                      child: Text(field.replaceAll('_', ' ').toUpperCase()),
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
                        Color? cellColor;
                        if (percentiles.containsKey(field) && value is num) {
                          final p = percentiles[field]![value];
                          if (p != null) {
                            cellColor = Color.fromRGBO(100, 140, 240, 0.1 + (p * 0.85));
                          }
                        }
  
                        String displayValue;
                        if (value == null) {
                          displayValue = 'N/A';
                        } else if (value is num && (field.contains('line') || field.contains('moneyline'))) {
                            displayValue = value.toStringAsFixed(1);
                        } else if (value is num && (field.contains('covered') || field.contains('hit'))) {
                            displayValue = '${(value * 100).toStringAsFixed(0)}%';
                        } else if (value is int && (field == 'season')) {
                            displayValue = value.toString();
                        } else {
                            displayValue = value.toString();
                        }
  
                        return DataCell(
                          Container(
                            width: double.infinity,
                            height: double.infinity,
                            color: cellColor,
                            alignment: (value is num) ? Alignment.centerRight : Alignment.centerLeft,
                            padding: const EdgeInsets.symmetric(horizontal: 12.0),
                            child: (field == 'home_team' || field == 'away_team')
                                ? Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      TeamLogoUtils.buildNFLTeamLogo(value.toString(), size: 24.0),
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
        if (_rows.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: _currentPage > 0 ? () {
                    setState(() {
                      _currentPage--;
                      _fetchData();
                    });
                  } : null,
                  child: const Text('Previous'),
                ),
                const SizedBox(width: 16),
                Text('Page ${_currentPage + 1} of ${(_totalRecords / _rowsPerPage).ceil()}'),
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