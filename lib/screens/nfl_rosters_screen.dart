import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../widgets/common/custom_app_bar.dart';
import '../widgets/common/app_drawer.dart';
import '../widgets/common/top_nav_bar.dart';
import '../widgets/auth/auth_dialog.dart';
import '../utils/team_logo_utils.dart';

class NflRostersScreen extends StatefulWidget {
  const NflRostersScreen({super.key});

  @override
  State<NflRostersScreen> createState() => _NflRostersScreenState();
}

class _NflRostersScreenState extends State<NflRostersScreen> {
  bool _isLoading = true;
  String? _error;
  List<Map<String, dynamic>> _rawRows = [];
  int _totalRecords = 0;

  // Pagination state
  int _currentPage = 0;
  static const int _rowsPerPage = 25;
  List<dynamic> _pageCursors = [null]; // Store cursors for each page
  dynamic _nextCursor; // Cursor for the next page

  // Sort state
  String _sortColumn = 'season';
  bool _sortAscending = false;

  // Season Filter - Default to current season
  String _selectedSeason = '2024';
  final List<String> _seasons = ['All', '2024', '2023', '2022', '2021', '2020', '2019', '2018', '2017', '2016', '2015', '2014'];

  // Team Filter
  String _selectedTeam = 'All';
  List<String> _teams = ['All'];

  // Position Filter
  String _selectedPosition = 'All';
  List<String> _positions = ['All'];

  List<String> _headers = [];

  // Search functionality
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // Firebase Functions
  FirebaseFunctions functions = FirebaseFunctions.instance;

  // All roster fields to display
  static const List<String> allRosterFields = [
    'full_name', 'team', 'position', 'jersey_number', 'height', 'weight', 
    'age_at_season', 'years_exp', 'season', 'status', 'college', 'rookie_year', 
    'is_rookie', 'is_veteran', 'is_active', 'is_practice_squad', 'is_injured_reserve'
  ];

  @override
  void initState() {
    super.initState();
    _fetchDataFromFirebase();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchDataFromFirebase() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    // Build filters object for cloud function
    Map<String, dynamic> filtersForFunction = {};
    
    // Add basic filters
    if (_selectedSeason != 'All') {
      filtersForFunction['season'] = _selectedSeason;
    }
    if (_selectedTeam != 'All') {
      filtersForFunction['team'] = _selectedTeam;
    }
    if (_selectedPosition != 'All') {
      filtersForFunction['position'] = _selectedPosition;
    }

    // Determine the cursor for the current page
    final dynamic currentCursor = _currentPage > 0 ? _pageCursors[_currentPage] : null;

    try {
      final HttpsCallable callable = functions.httpsCallable('getNflRosters');
      final result = await callable.call<Map<String, dynamic>>({
        'filters': filtersForFunction,
        'limit': _rowsPerPage,
        'orderBy': _sortColumn,
        'orderDirection': _sortAscending ? 'asc' : 'desc',
        'cursor': currentCursor,
      });

      if (mounted) {
        final data = result.data;
        List<Map<String, dynamic>> rows = List<Map<String, dynamic>>.from(data['data'] ?? []);
        
        // Apply client-side search filter
        if (_searchQuery.isNotEmpty) {
          final searchLower = _searchQuery.toLowerCase();
          rows = rows.where((row) {
            return allRosterFields.any((field) {
              final value = row[field]?.toString().toLowerCase() ?? '';
              return value.contains(searchLower);
            });
          }).toList();
        }

        // Update headers and filter options if this is the first load
        if (_headers.isEmpty && rows.isNotEmpty) {
          _headers = allRosterFields.where((field) => rows.first.containsKey(field)).toList();
          
          // Populate filter options from all data (not just current page)
          _populateFilterOptions();
        }

        // Update pagination cursors
        _nextCursor = data['nextCursor'];
        if (_nextCursor != null && _pageCursors.length <= _currentPage + 1) {
          _pageCursors.add(_nextCursor);
        }

        setState(() {
          _rawRows = rows;
          _totalRecords = data['totalRecords'] ?? 0;
          _isLoading = false;
        });

        // Show success message if provided
        if (data['message'] != null) {
          print('Success: ${data['message']}');
        }
      }
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
              'screenName': 'NflRostersScreen',
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
          _error = "An unexpected error occurred: ${e.message}";
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = 'Error fetching data: $e';
        });
      }
    }
  }

  Future<void> _populateFilterOptions() async {
    try {
      // Fetch a sample of data to populate filter options
      final callable = functions.httpsCallable('getNflRosters');
      final result = await callable.call<Map<String, dynamic>>({
        'filters': {},
        'limit': 1000, // Get more records to populate filters
        'orderBy': 'season',
        'orderDirection': 'desc',
      });

      final data = result.data;
      List<Map<String, dynamic>> allRows = List<Map<String, dynamic>>.from(data['data'] ?? []);
      
      if (allRows.isNotEmpty) {
        // Populate team options
        final teams = allRows.map((r) => r['team']?.toString() ?? '').where((t) => t.isNotEmpty).toSet().toList();
        teams.sort();
        _teams = ['All', ...teams];
        
        // Populate position options
        final positions = allRows.map((r) => r['position']?.toString() ?? '').where((p) => p.isNotEmpty).toSet().toList();
        positions.sort();
        _positions = ['All', ...positions];
        
        if (mounted) {
          setState(() {
            // Update the state with new filter options
          });
        }
      }
    } catch (e) {
      print('Error populating filter options: $e');
      // Continue with default options if this fails
    }
  }

  void _applyFiltersAndFetch() {
    _currentPage = 0; // Reset to first page
    _pageCursors = [null]; // Reset cursors
    _fetchDataFromFirebase();
  }

  String _formatHeaderName(String header) {
    const Map<String, String> headerDisplayNames = {
      'full_name': 'Name',
      'position': 'Pos',
      'jersey_number': '#',
      'team': 'Team',
      'season': 'Season',
      'height': 'Height',
      'weight': 'Weight',
      'age_at_season': 'Age',
      'years_exp': 'Exp',
      'is_rookie': 'Rookie',
      'is_veteran': 'Vet',
      'status': 'Status',
      'college': 'College',
      'rookie_year': 'Rookie Yr',
      'is_active': 'Active',
      'is_practice_squad': 'PS',
      'is_injured_reserve': 'IR',
    };
    return headerDisplayNames[header] ?? header;
  }

  Widget _formatCellValue(dynamic value, String header) {
    if (value == null) return const Text('');
    
    switch (header) {
      case 'team':
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            TeamLogoUtils.buildNFLTeamLogo(value.toString(), size: 24),
            const SizedBox(width: 8),
            Text(value.toString(), style: const TextStyle(fontSize: 14)),
          ],
        );
      case 'height':
        // Convert height to feet'inches" format
        if (value is num) {
          int totalInches = value.toInt();
          int feet = totalInches ~/ 12;
          int inches = totalInches % 12;
          return Text('$feet\'$inches"', style: const TextStyle(fontSize: 14));
        }
        return Text(value.toString(), style: const TextStyle(fontSize: 14));
      case 'weight':
        return Text('${value}lbs', style: const TextStyle(fontSize: 14));
      case 'is_rookie':
      case 'is_veteran':
      case 'is_active':
      case 'is_practice_squad':
      case 'is_injured_reserve':
        return value == 1 
            ? const Icon(Icons.check, color: Colors.green, size: 18)
            : const Text('');
      default:
        return Text(value.toString(), style: const TextStyle(fontSize: 14));
    }
  }

  Widget _buildFilterChip({
    required String label,
    required String value,
    required List<String> options,
    required ValueChanged<String?> onChanged,
  }) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: value != 'All' ? theme.colorScheme.primaryContainer : theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: value != 'All' ? theme.colorScheme.primary : theme.colorScheme.outline.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: DropdownButton<String>(
        value: value,
        underline: const SizedBox(),
        isDense: true,
        style: const TextStyle(
          color: Colors.black, // Changed to black for all dropdowns
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        icon: Icon(
          Icons.keyboard_arrow_down,
          size: 18,
          color: value != 'All' ? theme.colorScheme.onPrimaryContainer : theme.colorScheme.onSurface,
        ),
        items: options.map((option) {
          return DropdownMenuItem(
            value: option,
            child: Text(
              label == 'Season' ? option : (option == 'All' ? '$label: $option' : option), // Remove label prefix for team and position when not "All"
              style: const TextStyle(color: Colors.black), // Ensure dropdown items are also black
            ),
          );
        }).toList(),
        onChanged: onChanged,
      ),
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
          // Header with title and controls
          Container(
            padding: const EdgeInsets.all(24.0),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              border: Border(bottom: BorderSide(color: theme.dividerColor.withOpacity(0.1))),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title Section
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'NFL Rosters',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Explore comprehensive NFL roster data across seasons',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurface.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 24),
                
                // Filters and Search Row
                Row(
                  children: [
                    // Search Bar
                    Expanded(
                      flex: 2,
                      child: Container(
                        height: 44,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(color: theme.colorScheme.outline.withOpacity(0.2)),
                        ),
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'Search players, teams, positions...',
                            hintStyle: TextStyle(
                              color: theme.colorScheme.onSurface.withOpacity(0.5),
                              fontSize: 14,
                            ),
                            prefixIcon: Icon(
                              Icons.search,
                              color: theme.colorScheme.onSurface.withOpacity(0.5),
                              size: 20,
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                            isDense: true,
                          ),
                          style: const TextStyle(fontSize: 14),
                          onChanged: (value) {
                            setState(() {
                              _searchQuery = value;
                            });
                            _applyFiltersAndFetch();
                          },
                        ),
                      ),
                    ),
                    
                    const SizedBox(width: 16),
                    
                    // Filter Chips
                    Wrap(
                      spacing: 12,
                      children: [
                        _buildFilterChip(
                          label: 'Season',
                          value: _selectedSeason,
                          options: _seasons,
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                _selectedSeason = value;
                              });
                              _applyFiltersAndFetch();
                            }
                          },
                        ),
                        _buildFilterChip(
                          label: 'Team',
                          value: _selectedTeam,
                          options: _teams,
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                _selectedTeam = value;
                              });
                              _applyFiltersAndFetch();
                            }
                          },
                        ),
                        _buildFilterChip(
                          label: 'Position',
                          value: _selectedPosition,
                          options: _positions,
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                _selectedPosition = value;
                              });
                              _applyFiltersAndFetch();
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Results summary
          if (_totalRecords > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.2),
                border: Border(bottom: BorderSide(color: theme.dividerColor.withOpacity(0.1))),
              ),
              child: Row(
                children: [
                  Text(
                    'Showing ${_currentPage * _rowsPerPage + 1}-${_currentPage * _rowsPerPage + _rawRows.length} of $_totalRecords roster entries',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  if (_selectedSeason != 'All' || _selectedTeam != 'All' || _selectedPosition != 'All') ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.filter_list, size: 14, color: theme.colorScheme.onPrimaryContainer),
                          const SizedBox(width: 4),
                          Text(
                            'Filtered',
                            style: TextStyle(
                              fontSize: 12,
                              color: theme.colorScheme.onPrimaryContainer,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          
          // Data table
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error, size: 48, color: theme.colorScheme.error),
                            const SizedBox(height: 16),
                            Text(
                              'Error loading data',
                              style: theme.textTheme.headlineSmall,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _error!,
                              style: theme.textTheme.bodyMedium,
                              textAlign: TextAlign.center,
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
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.search_off, size: 48, color: theme.disabledColor),
                                const SizedBox(height: 16),
                                Text(
                                  'No roster data found',
                                  style: theme.textTheme.headlineSmall,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Try adjusting your filters or search query.',
                                  style: theme.textTheme.bodyMedium,
                                ),
                              ],
                            ),
                          )
                        : SingleChildScrollView(
                            scrollDirection: Axis.vertical,
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              padding: const EdgeInsets.all(16.0),
                              child: DataTable(
                                sortColumnIndex: _headers.contains(_sortColumn) ? _headers.indexOf(_sortColumn) : null,
                                sortAscending: _sortAscending,
                                headingRowColor: WidgetStateProperty.all(Colors.blue.shade700),
                                headingTextStyle: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                                dataRowHeight: 56,
                                showCheckboxColumn: false,
                                columnSpacing: 32,
                                decoration: BoxDecoration(
                                  border: Border.all(color: theme.dividerColor.withOpacity(0.2)),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                columns: _headers.map((header) {
                                  return DataColumn(
                                    label: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
                                      child: Text(_formatHeaderName(header)),
                                    ),
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
                                    color: WidgetStateProperty.resolveWith<Color?>(
                                      (Set<WidgetState> states) {
                                        if (states.contains(WidgetState.hovered)) {
                                          return theme.colorScheme.surfaceContainerHighest.withOpacity(0.5);
                                        }
                                        return null;
                                      },
                                    ),
                                    cells: _headers.map((header) {
                                      return DataCell(
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
                                          child: _formatCellValue(row[header], header),
                                        ),
                                      );
                                    }).toList(),
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
          ),
          
          // Pagination controls
          if (_totalRecords > _rowsPerPage)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                border: Border(top: BorderSide(color: theme.dividerColor.withOpacity(0.1))),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ElevatedButton.icon(
                    onPressed: _currentPage > 0 ? () {
                      setState(() {
                        _currentPage--;
                      });
                      _fetchDataFromFirebase();
                    } : null,
                    icon: const Icon(Icons.chevron_left),
                    label: const Text('Previous'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.surfaceContainerHighest,
                      foregroundColor: theme.colorScheme.onSurface,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Page ${_currentPage + 1} of ${(_totalRecords / _rowsPerPage).ceil()}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: (_currentPage + 1) * _rowsPerPage < _totalRecords ? () {
                      setState(() {
                        _currentPage++;
                      });
                      _fetchDataFromFirebase();
                    } : null,
                    icon: const Icon(Icons.chevron_right),
                    label: const Text('Next'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.surfaceContainerHighest,
                      foregroundColor: theme.colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
} 