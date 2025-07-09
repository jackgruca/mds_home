import 'package:flutter/material.dart';
import 'package:mds_home/widgets/common/app_drawer.dart';
import 'package:mds_home/widgets/common/top_nav_bar.dart';
import 'package:mds_home/widgets/common/custom_app_bar.dart';
import 'package:mds_home/widgets/auth/auth_dialog.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:mds_home/utils/team_logo_utils.dart';
import 'package:mds_home/utils/theme_config.dart';
import 'package:mds_home/utils/theme_aware_colors.dart';
import 'package:mds_home/widgets/design_system/mds_table.dart';

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

class _PlayerSeasonStatsScreenState extends State<PlayerSeasonStatsScreen>
    with SingleTickerProviderStateMixin {
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
  
  // Season Filter
  String _selectedSeason = 'All';
  final List<String> _seasons = ['All', '2024', '2023', '2022', '2021', '2020'];
  
  // Team Filter
  String _selectedTeam = 'All';
  final List<String> _teams = [
    'All', 'ARI', 'ATL', 'BAL', 'BUF', 'CAR', 'CHI', 'CIN', 'CLE', 'DAL', 'DEN', 
    'DET', 'GB', 'HOU', 'IND', 'JAX', 'KC', 'LV', 'LAC', 'LAR', 'MIA', 'MIN', 
    'NE', 'NO', 'NYG', 'NYJ', 'PHI', 'PIT', 'SF', 'SEA', 'TB', 'TEN', 'WAS'
  ];
  
  // Tab controller for Basic/Advanced/Visualizations
  late TabController _tabController;
  
  // New: Position-aware filtering state
  bool _showAllPositionsInTab = false; // Toggle to show all positions in position-specific tabs
  
  // Helper method to get the position filter for the current tab
  String _getEffectivePositionFilter() {
    if (_showAllPositionsInTab) {
      return _selectedPosition; // Use the dropdown filter when showing all positions
    }
    
    // Auto-filter by position based on the selected tab
    switch (_selectedStatCategory) {
      case 'QB Stats':
        return 'QB';
      case 'RB Stats':
        return 'RB';
      case 'WR/TE Stats':
        return 'WR'; // We'll handle TE separately in the filter logic
      default:
        return _selectedPosition; // For other tabs, use the dropdown filter
    }
  }
  
  // Helper method to determine if we should include TE in WR/TE Stats
  bool _shouldIncludeTE() {
    return _selectedStatCategory == 'WR/TE Stats' && !_showAllPositionsInTab;
  }

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

  // Field groups for tabbed view - organized by position with Basic/Advanced/Visualizations structure
  static final Map<String, Map<String, List<String>>> _statCategoryFieldGroups = {
    'QB Stats': {
      'Basic': ['player_name', 'recent_team', 'season', 'games', 'completions', 'attempts', 'passing_yards', 'passing_tds', 'interceptions', 'completion_percentage', 'passer_rating'],
      'Advanced': ['player_name', 'recent_team', 'season', 'avg_time_to_throw', 'avg_completed_air_yards', 'avg_intended_air_yards', 'avg_air_yards_differential', 'aggressiveness', 'completion_percentage_above_expectation', 'rushing_attempts', 'rushing_yards'],
      'Visualizations': ['player_name', 'recent_team', 'season', 'passing_yards', 'passing_tds', 'passer_rating', 'completion_percentage', 'fantasy_points', 'fantasy_points_ppr']
    },
    'RB Stats': {
      'Basic': ['player_name', 'recent_team', 'season', 'games', 'rushing_attempts', 'rushing_yards', 'rushing_tds', 'yards_per_carry', 'receptions', 'receiving_yards', 'fantasy_points', 'fantasy_points_ppr'],
      'Advanced': ['player_name', 'recent_team', 'season', 'rush_efficiency', 'avg_time_to_los', 'rush_yards_over_expected', 'rush_yards_over_expected_per_att', 'rush_pct_over_expected', 'target_share', 'yards_per_touch'],
      'Visualizations': ['player_name', 'recent_team', 'season', 'rushing_yards', 'rushing_tds', 'receiving_yards', 'fantasy_points', 'fantasy_points_ppr', 'yards_per_carry']
    },
    'WR/TE Stats': {
      'Basic': ['player_name', 'recent_team', 'position', 'season', 'games', 'targets', 'receptions', 'receiving_yards', 'receiving_tds', 'yards_per_reception', 'fantasy_points', 'fantasy_points_ppr'],
      'Advanced': ['player_name', 'recent_team', 'position', 'season', 'target_share', 'air_yards_share', 'wopr', 'avg_depth_of_target', 'avg_cushion', 'avg_separation', 'catch_percentage', 'racr'],
      'Visualizations': ['player_name', 'recent_team', 'position', 'season', 'receiving_yards', 'receiving_tds', 'targets', 'target_share', 'fantasy_points', 'fantasy_points_ppr']
    },
    'Fantasy Focus': {
      'Basic': ['player_name', 'recent_team', 'position', 'season', 'games', 'fantasy_points', 'fantasy_points_ppr', 'fantasy_points_per_game'],
      'Advanced': ['player_name', 'recent_team', 'position', 'season', 'targets', 'target_share', 'red_zone_targets', 'wopr', 'yards_per_touch'],
      'Visualizations': ['player_name', 'recent_team', 'position', 'season', 'fantasy_points', 'fantasy_points_ppr', 'targets', 'receiving_yards', 'rushing_yards']
    },
    'Custom': {
      'Basic': [],
      'Advanced': [],
      'Visualizations': []
    }
  };
  
  String _selectedStatCategory = 'QB Stats';
  String _selectedSubCategory = 'Basic'; // Basic, Advanced, Visualizations

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
    'passing_yards_per_attempt', 'passing_tds_per_attempt',
    'rushing_yards_per_attempt', 'rushing_tds_per_attempt', 
    'receiving_yards_per_reception', 'receiving_tds_per_reception',
    'completion_percentage', 'passer_rating', 'qbr', 'yards_per_carry', 'yards_per_reception',
    'target_share', 'air_yards_share', 'wopr', 'racr', 'avg_depth_of_target',
    'yards_per_touch', 'catch_percentage',
    // NextGen Passing Stats
    'avg_time_to_throw', 'avg_completed_air_yards', 'avg_intended_air_yards', 
    'avg_air_yards_differential', 'aggressiveness', 'max_completed_air_distance',
    'avg_air_distance', 'avg_air_yards_to_sticks', 'completion_percentage_above_expectation',
    // NextGen Rushing Stats
    'rush_efficiency', 'pct_attempts_vs_eight_plus', 'avg_time_to_los', 'rush_yards_over_expected',
    'rush_yards_over_expected_per_att', 'rush_pct_over_expected',
    // NextGen Receiving Stats
    'avg_cushion', 'avg_separation', 'rec_avg_intended_air_yards', 'percent_share_of_intended_air_yards'
  };

  // Helper function to format header names prettily with abbreviations
  String _formatHeaderName(String header) {
    // Define abbreviations and pretty names - expanded for new categories
    final Map<String, String> headerMap = {
      'player_name': 'Player',
      'recent_team': 'Team',
      'position': 'Pos',
      'season': 'Year',
      'games': 'G',
      'games_started': 'GS',
      // Passing Stats
      'completions': 'Cmp',
      'attempts': 'Att',
      'passing_yards': 'Pass Yds',
      'passing_tds': 'Pass TD',
      'interceptions': 'Int',
      'passing_yards_per_attempt': 'Y/A',
      'completion_percentage': 'Cmp%',
      'passer_rating': 'Rate',
      'qbr': 'QBR',
      // Rushing Stats
      'rushing_attempts': 'Rush Att',
      'rushing_yards': 'Rush Yds',
      'rushing_tds': 'Rush TD',
      'rushing_yards_per_attempt': 'Y/C',
      'yards_per_carry': 'Y/C',
      // Receiving Stats
      'targets': 'Tgt',
      'receptions': 'Rec',
      'receiving_yards': 'Rec Yds',
      'receiving_tds': 'Rec TD',
      'receiving_yards_per_reception': 'Y/R',
      'yards_per_reception': 'Y/R',
      'target_share': 'Tgt%',
      'air_yards_share': 'Air%',
      'wopr': 'WOPR',
      'racr': 'RACR',
      'avg_depth_of_target': 'aDOT',
      // Fantasy Stats
      'fantasy_points': 'Fpts',
      'fantasy_points_ppr': 'PPR Pts',
      'fantasy_points_per_game': 'Fpts/G',
      'red_zone_targets': 'RZ Tgt',
      'yards_per_touch': 'Y/Touch',
      // NextGen Passing
      'avg_time_to_throw': 'Avg TTT',
      'avg_completed_air_yards': 'CAY',
      'avg_intended_air_yards': 'IAY', 
      'avg_air_yards_differential': 'AYD',
      'aggressiveness': 'AGG%',
      'max_completed_air_distance': 'MCAD',
      'completion_percentage_above_expectation': 'CPOE',
      // NextGen Rushing
      'rush_efficiency': 'Rush Eff',
      'pct_attempts_vs_eight_plus': '8+ Box%',
      'avg_time_to_los': 'TLOS',
      'rush_yards_over_expected': 'RYOE',
      'rush_yards_over_expected_per_att': 'RYOE/Att',
      'rush_pct_over_expected': 'Rush%+',
      // NextGen Receiving
      'avg_cushion': 'Cushion',
      'avg_separation': 'Sep',
      'rec_avg_intended_air_yards': 'Rec IAY',
      'percent_share_of_intended_air_yards': 'IAY%',
      'catch_percentage': 'Catch%',
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
    // Basic Info
    'player_name': 'Player Name',
    'recent_team': 'Most Recent Team',
    'position': 'Position (QB, RB, WR, TE)',
    'season': 'NFL Season Year',
    'games': 'Games Played',
    
    // Passing Stats
    'completions': 'Pass Completions',
    'attempts': 'Pass Attempts',
    'passing_yards': 'Passing Yards',
    'passing_tds': 'Passing Touchdowns',
    'interceptions': 'Interceptions Thrown',
    'completion_percentage': 'Completion Percentage',
    'passer_rating': 'NFL Passer Rating (0-158.3)',
    'qbr': 'ESPN QBR (0-100)',
    'sacks': 'Times Sacked',
    'sack_yards': 'Yards Lost to Sacks',
    
    // Rushing Stats
    'rushing_attempts': 'Rushing Attempts',
    'rushing_yards': 'Rushing Yards',
    'rushing_tds': 'Rushing Touchdowns',
    'yards_per_carry': 'Yards Per Carry (Y/C)',
    
    // Receiving Stats
    'receptions': 'Receptions',
    'targets': 'Targets',
    'receiving_yards': 'Receiving Yards',
    'receiving_tds': 'Receiving Touchdowns',
    'yards_per_reception': 'Yards Per Reception',
    'target_share': 'Target Share (%)',
    'catch_rate': 'Catch Rate (%)',
    
    // Advanced Receiving
    'air_yards_share': 'Air Yards Share (%)',
    'avg_depth_of_target': 'Average Depth of Target',
    'racr': 'Receiver Air Conversion Ratio',
    'wopr': 'Weighted Opportunity Rating',
    
    // Fantasy Stats
    'fantasy_points': 'Fantasy Points (Standard)',
    'fantasy_points_ppr': 'Fantasy Points (PPR)',
    'fantasy_points_per_game': 'Fantasy Points Per Game',
    
    // NextGen Passing
    'avg_time_to_throw': 'Average Time to Throw (seconds)',
    'avg_completed_air_yards': 'Average Completed Air Yards',
    'avg_intended_air_yards': 'Average Intended Air Yards',
    'avg_air_yards_differential': 'Air Yards Differential',
    'aggressiveness': 'Aggressiveness (%)',
    'max_completed_air_distance': 'Max Completed Air Distance',
    'avg_air_distance': 'Average Air Distance',
    'avg_air_yards_to_sticks': 'Average Air Yards to Sticks',
    'completion_percentage_above_expectation': 'Completion % Above Expectation',
    
    // NextGen Rushing
    'rush_efficiency': 'Rushing Efficiency',
    'pct_attempts_vs_eight_plus': '8+ Defenders in Box (%)',
    'avg_time_to_los': 'Average Time to Line of Scrimmage',
    'rush_yards_over_expected': 'Rush Yards Over Expected',
    'rush_yards_over_expected_per_att': 'Rush Yards Over Expected Per Attempt',
    'rush_pct_over_expected': 'Rush % Over Expected',
    
    // NextGen Receiving
    'avg_cushion': 'Average Cushion (yards)',
    'avg_separation': 'Average Separation (yards)',
    'rec_avg_intended_air_yards': 'Average Intended Air Yards (Receiving)',
    'percent_share_of_intended_air_yards': 'Share of Intended Air Yards (%)',
    'catch_percentage': 'Catch Percentage (%)',
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this); // Basic, Advanced, Visualizations
    
    // Handle route parameters from data hub
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null && args['position'] != null) {
        final position = args['position'] as String;
        setState(() {
          // Set the appropriate stat category based on position
          switch (position) {
            case 'QB':
              _selectedStatCategory = 'QB Stats';
              _selectedPosition = 'QB';
              break;
            case 'RB':
              _selectedStatCategory = 'RB Stats';
              _selectedPosition = 'RB';
              break;
            case 'WR':
              _selectedStatCategory = 'WR/TE Stats';
              _selectedPosition = 'WR';
              break;
            case 'FANTASY':
              _selectedStatCategory = 'Fantasy Focus';
              _selectedPosition = 'All';
              break;
            default:
              _selectedPosition = position;
          }
        });
      }
      _fetchDataFromFirebase();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _newQueryValueController.dispose();
    super.dispose();
  }

  // Helper to determine field type for query input
  String getFieldType(String field) {
    const Set<String> doubleFields = {
      'passing_yards_per_attempt', 'passing_tds_per_attempt',
      'rushing_yards_per_attempt', 'rushing_tds_per_attempt',
      'yards_per_reception', 'receiving_tds_per_reception',
      'yards_per_touch', 'wopr',
      // NextGen Passing Stats
      'avg_time_to_throw', 'avg_completed_air_yards', 'avg_intended_air_yards', 
      'avg_air_yards_differential', 'aggressiveness', 'max_completed_air_distance',
      'avg_air_distance', 'avg_air_yards_to_sticks', 'completion_percentage_above_expectation',
      // NextGen Rushing Stats
      'rush_efficiency', 'pct_attempts_vs_eight_plus', 'avg_time_to_los', 'rush_yards_over_expected',
      'rush_yards_over_expected_per_att', 'rush_pct_over_expected',
      // NextGen Receiving Stats
      'avg_cushion', 'avg_separation', 'rec_avg_intended_air_yards', 'percent_share_of_intended_air_yards',
      'catch_percentage'
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
    // DEBUG LOGGING - Track data fetching state
    print('🔍 [DEBUG] _fetchDataFromFirebase called');
    print('🔍 [DEBUG] Current stat category: $_selectedStatCategory');
    print('🔍 [DEBUG] Show all positions in tab: $_showAllPositionsInTab');
    print('🔍 [DEBUG] Selected position: $_selectedPosition');
    
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
      filtersForFunction['season'] = _selectedSeason;
    }
    
    // Add team filter
    if (_selectedTeam != 'All') {
      filtersForFunction['recent_team'] = _selectedTeam;
    }
    
    // Intelligent position filtering
    String effectivePositionFilter = _getEffectivePositionFilter();
    bool shouldIncludeTE = _shouldIncludeTE();
    
    // DEBUG LOGGING - Track position filtering logic
    print('🔍 [DEBUG] Effective position filter: $effectivePositionFilter');
    print('🔍 [DEBUG] Should include TE: $shouldIncludeTE');
    
    if (effectivePositionFilter != 'All') {
      if (shouldIncludeTE) {
        // For WR/TE Stats tab, don't add position filter - we'll filter client-side
        // This avoids Firebase index issues with position_in arrays
        print('🔍 [DEBUG] WR/TE Stats: No position filter added, will filter client-side');
      } else {
        filtersForFunction['position'] = effectivePositionFilter;
        print('🔍 [DEBUG] Added position filter: $effectivePositionFilter');
      }
    }
    
    print('🔍 [DEBUG] Final filters for Firebase: $filtersForFunction');

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
          List<Map<String, dynamic>> allRows = data.map((item) => Map<String, dynamic>.from(item)).toList();
          
          // Client-side filtering for WR/TE Stats tab
          if (_shouldIncludeTE() && _selectedStatCategory == 'WR/TE Stats') {
            _rawRows = allRows.where((row) => 
              row['position'] == 'WR' || row['position'] == 'TE'
            ).toList();
            print('🔍 [DEBUG] Client-side filtered WR/TE: ${_rawRows.length} rows from ${allRows.length} total');
          } else {
            _rawRows = allRows;
          }
          
          _totalRecords = result.data['totalRecords'] ?? 0;
          _nextCursor = result.data['nextCursor'];

          // DEBUG LOGGING - Track Firebase response
          print('🔍 [DEBUG] Firebase response received');
          print('🔍 [DEBUG] Total records from Firebase: $_totalRecords');
          print('🔍 [DEBUG] All rows count: ${allRows.length}');
          print('🔍 [DEBUG] Final filtered rows count: ${_rawRows.length}');
          if (_rawRows.isNotEmpty) {
            print('🔍 [DEBUG] First row keys: ${_rawRows.first.keys.toList()}');
            print('🔍 [DEBUG] First row player: ${_rawRows.first['player_name']}');
            print('🔍 [DEBUG] First row position: ${_rawRows.first['position']}');
          } else {
            print('🔍 [DEBUG] No rows after filtering!');
            
            // DIAGNOSTIC: If we're looking for WR/TE and got no results, let's check what positions exist
            if (_selectedStatCategory == 'WR/TE Stats') {
              print('🔍 [DEBUG] DIAGNOSTIC: WR/TE query returned 0 results. Let\'s check what positions exist...');
              _runPositionDiagnostic();
            }
          }

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
              'screenName': 'PlayerSeasonStatsScreen',
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
      } else {
        // Handle other Firebase Functions errors (like 'internal' errors)
        if (mounted) {
          setState(() {
            _error = "An unexpected error occurred: ${e.message}";
            _isLoading = false;
          });
        }
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
    
    // Add season filter
    if (_selectedSeason != 'All') {
      filtersForFunction['season'] = _selectedSeason;
    }
    
    // Add team filter
    if (_selectedTeam != 'All') {
      filtersForFunction['recent_team'] = _selectedTeam;
    }
    
    // Use the same intelligent position filtering for preloading
    String effectivePositionFilter = _getEffectivePositionFilter();
    if (effectivePositionFilter != 'All') {
      if (_shouldIncludeTE()) {
        // For WR/TE Stats tab, don't add position filter - we'll filter client-side
        // This avoids Firebase index issues with position_in arrays
      } else {
        filtersForFunction['position'] = effectivePositionFilter;
      }
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
            List<Map<String, dynamic>> allRows = data.map((item) => Map<String, dynamic>.from(item)).toList();
            
            // Apply same client-side filtering for preloaded data
            if (_shouldIncludeTE() && _selectedStatCategory == 'WR/TE Stats') {
              allRows = allRows.where((row) => 
                row['position'] == 'WR' || row['position'] == 'TE'
              ).toList();
            }
            
            _preloadedPages[preloadPageIndex] = allRows;
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

  Future<void> _runPositionDiagnostic() async {
    try {
      print('🔍 [DEBUG] DIAGNOSTIC: Running position diagnostic...');
      final HttpsCallable callable = functions.httpsCallable('getPlayerSeasonStats');
      final result = await callable.call<Map<String, dynamic>>({
        'filters': {}, // No filters to get all positions
        'limit': 100, // Get a sample
        'orderBy': 'player_name',
        'orderDirection': 'asc',
      });

      final List<dynamic> data = result.data['data'] ?? [];
      if (data.isNotEmpty) {
        final positions = data.map((item) => item['position']).toSet().toList();
        print('🔍 [DEBUG] DIAGNOSTIC: Available positions in database: $positions');
        print('🔍 [DEBUG] DIAGNOSTIC: Total sample records: ${data.length}');
        print('🔍 [DEBUG] DIAGNOSTIC: Sample players: ${data.take(10).map((p) => '${p['player_name']} (${p['position']})').toList()}');
        
        // Check if WR/TE exist with different naming
        final wrLikePositions = positions.where((p) => p.toString().toLowerCase().contains('w')).toList();
        final teLikePositions = positions.where((p) => p.toString().toLowerCase().contains('t')).toList();
        print('🔍 [DEBUG] DIAGNOSTIC: WR-like positions: $wrLikePositions');
        print('🔍 [DEBUG] DIAGNOSTIC: TE-like positions: $teLikePositions');
      } else {
        print('🔍 [DEBUG] DIAGNOSTIC: No data returned even with no filters!');
      }
    } catch (e) {
      print('🔍 [DEBUG] DIAGNOSTIC: Error running diagnostic: $e');
    }
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
                      _selectedStatCategory = 'Custom';
                      // Update the Custom category fields
                      _statCategoryFieldGroups['Custom']!['Basic'] = _selectedFields;
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
          content: SingleChildScrollView(
            child: Column(
              children: _fieldDefinitions.entries.map((entry) {
                return ListTile(
                  title: Text(entry.key),
                  trailing: Text(entry.value),
                );
              }).toList(),
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

  Widget _buildCompactControlsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(bottom: BorderSide(color: Colors.grey.shade300, width: 0.5)),
      ),
      child: Column(
        children: [
          // Position/Category Selection Row
          Row(
            children: [
              // Position/Category buttons
              Expanded(
                flex: 3,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: (_statCategoryFieldGroups.keys).map((category) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: ChoiceChip(
                          label: Text(category),
                          selected: _selectedStatCategory == category,
                          onSelected: (selected) {
                            if (selected) {
                              setState(() {
                                _selectedStatCategory = category;
                                _showAllPositionsInTab = false;
                              });
                              _applyFiltersAndFetch();
                            }
                          },
                          selectedColor: _getPositionColor().withValues(alpha: 0.2),
                          labelStyle: TextStyle(
                            color: _selectedStatCategory == category 
                                ? _getPositionColor() 
                                : Colors.grey.shade700,
                            fontWeight: _selectedStatCategory == category 
                                ? FontWeight.bold 
                                : FontWeight.normal,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              
              // Season Filter
              SizedBox(
                width: 120,
                child: DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Season',
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    border: OutlineInputBorder(),
                  ),
                  value: _selectedSeason,
                  items: _seasons.map((season) => DropdownMenuItem(
                    value: season,
                    child: Text(season),
                  )).toList(),
                  onChanged: (value) {
                    setState(() => _selectedSeason = value!);
                    _applyFiltersAndFetch();
                  },
                ),
              ),
              
              const SizedBox(width: 12),
              
              // Team Filter
              SizedBox(
                width: 100,
                child: DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Team',
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    border: OutlineInputBorder(),
                  ),
                  value: _selectedTeam,
                  items: _teams.map((team) => DropdownMenuItem(
                    value: team,
                    child: Text(team),
                  )).toList(),
                  onChanged: (value) {
                    setState(() => _selectedTeam = value!);
                    _applyFiltersAndFetch();
                  },
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Sub-category tabs (Basic/Advanced/Visualizations) - more compact
          SizedBox(
            height: 40,
            child: TabBar(
              controller: _tabController,
              labelColor: _getPositionColor(),
              unselectedLabelColor: Colors.grey.shade600,
              indicatorColor: _getPositionColor(),
              indicatorSize: TabBarIndicatorSize.tab,
              tabs: const [
                Tab(text: 'Basic'),
                Tab(text: 'Advanced'),
                Tab(text: 'Visualizations'),
              ],
              onTap: (index) {
                setState(() {
                  _selectedSubCategory = ['Basic', 'Advanced', 'Visualizations'][index];
                });
              },
            ),
          ),
        ],
      ),
    );
  }


  Color _getPositionColor() {
    switch (_selectedStatCategory) {
      case 'QB Stats':
        return Colors.blue.shade600;
      case 'RB Stats':
        return Colors.green.shade600;
      case 'WR/TE Stats':
        return Colors.orange.shade600;
      case 'Fantasy Focus':
        return Colors.purple.shade600;
      default:
        return Colors.indigo.shade600;
    }
  }

  IconData _getPositionIcon() {
    switch (_selectedStatCategory) {
      case 'QB Stats':
        return Icons.sports_football;
      case 'RB Stats':
        return Icons.directions_run;
      case 'WR/TE Stats':
        return Icons.catching_pokemon;
      case 'Fantasy Focus':
        return Icons.star;
      default:
        return Icons.analytics;
    }
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
          // Compact Controls Section
          _buildCompactControlsSection(),
          
          // Compact Query Builder
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ExpansionTile(
              tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              title: Row(
                children: [
                  Icon(Icons.tune, color: Theme.of(context).primaryColor, size: 20),
                  const SizedBox(width: 8),
                  Text('Advanced Filters',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                  const Spacer(),
                  if (_queryConditions.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${_queryConditions.length}',
                        style: TextStyle(
                          color: Theme.of(context).primaryColor,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
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
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          // Position Dropdown
                          Expanded(
                            flex: 1,
                            child: DropdownButtonFormField<String>(
                              decoration: const InputDecoration(
                                labelText: 'Position',
                                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                border: OutlineInputBorder(),
                              ),
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
                              decoration: const InputDecoration(
                                labelText: 'Field',
                                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                border: OutlineInputBorder(),
                              ),
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
                              decoration: const InputDecoration(
                                labelText: 'Operator',
                                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                border: OutlineInputBorder(),
                              ),
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
                              decoration: const InputDecoration(
                                labelText: 'Value',
                                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                border: OutlineInputBorder(),
                              ),
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
                      const SizedBox(height: 12.0),
                      if (_queryConditions.isNotEmpty) ...[
                        Text('Active Filters:',
                            style: Theme.of(context).textTheme.bodySmall),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 6.0,
                          runSpacing: 4.0,
                          children: _queryConditions
                              .asMap()
                              .entries
                              .map((entry) => Chip(
                                    label: Text(entry.value.toString()),
                                    onDeleted: () =>
                                        _removeQueryCondition(entry.key),
                                    deleteIconColor: Colors.red.shade400,
                                  ))
                              .toList(),
                        ),
                        const SizedBox(height: 8),
                      ],
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (_queryConditions.isNotEmpty)
                            TextButton(
                              onPressed: _clearAllQueryConditions,
                              child: const Text('Clear All'),
                            ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.filter_alt_outlined, size: 16),
                            label: const Text('Apply Filters'),
                            onPressed: _applyFiltersAndFetch,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
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
                                                          style: TextStyle(
                                 color: ThemeAwareColors.getErrorColor(context), fontSize: 16),
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
      // DEBUG LOGGING - Track when "no data found" message is shown
      print('🔍 [DEBUG] Showing "No data found" message');
      print('🔍 [DEBUG] - _rawRows.isEmpty: ${_rawRows.isEmpty}');
      print('🔍 [DEBUG] - _isLoading: $_isLoading');
      print('🔍 [DEBUG] - _error: $_error');
      print('🔍 [DEBUG] - Current stat category: $_selectedStatCategory');
      
      return const Center(
          child: Text('No data found. Try adjusting your filters.',
              style: TextStyle(fontSize: 16)));
    }

    // MdsTable handles percentile calculations automatically

    List<String> getVisibleFieldsForCategory(String category, String position) {
      // DEBUG LOGGING - Track field category calculation
      print('🔍 [DEBUG] getVisibleFieldsForCategory called with:');
      print('🔍 [DEBUG] - category: $category');
      print('🔍 [DEBUG] - position: $position');
      
      List<String> fields;
      
      if (category == 'Custom') {
        // For Custom category, use the selected fields
        fields = _selectedFields;
        print('🔍 [DEBUG] Using custom fields: ${fields.length} fields');
      } else {
        // For predefined categories, use the fields from the category and subcategory
        fields = _statCategoryFieldGroups[category]?[_selectedSubCategory] ?? [];
        print('🔍 [DEBUG] Base fields from category: ${fields.length} fields');
        
        // Special handling for WR/TE Stats tab - always show WR/TE fields regardless of position filter
        if (category == 'WR/TE Stats') {
          final result = fields.where((f) => !['completions', 'attempts', 'passing_yards', 'passing_tds', 'interceptions', 'passing_yards_per_attempt', 'rushing_attempts', 'rushing_yards', 'rushing_tds'].contains(f) || ['player_name', 'season', 'games'].contains(f)).toList();
          print('🔍 [DEBUG] WR/TE Stats tab - filtered fields: ${result.length}');
          print('🔍 [DEBUG] WR/TE Stats tab - fields: $result');
          return result;
        }
        
        if (position == 'QB') {
          return fields.where((f) => !['rushing_attempts', 'rushing_yards', 'rushing_tds', 'receptions', 'targets', 'receiving_yards', 'receiving_tds', 'yards_per_reception', 'wopr'].contains(f) || ['player_name', 'season', 'games'].contains(f)).toList();
        }
        if (position == 'RB') {
           return fields.where((f) => !['completions', 'attempts', 'passing_yards', 'passing_tds', 'interceptions', 'passing_yards_per_attempt'].contains(f) || ['player_name', 'season', 'games'].contains(f)).toList();
        }
        if (position == 'WR' || position == 'TE') {
           return fields.where((f) => !['completions', 'attempts', 'passing_yards', 'passing_tds', 'interceptions', 'passing_yards_per_attempt', 'rushing_attempts', 'rushing_yards', 'rushing_tds'].contains(f) || ['player_name', 'season', 'games'].contains(f)).toList();
        }
      }
      
      // 'All' position shows all fields for the category
      return fields;
    }

    // Use effective position filter for determining visible fields
    final String effectivePosition = _showAllPositionsInTab ? _selectedPosition : _getEffectivePositionFilter();
    final List<String> displayFields = getVisibleFieldsForCategory(_selectedStatCategory, effectivePosition);
    
    // DEBUG LOGGING - Track column field calculation
    print('🔍 [DEBUG] Building table with:');
    print('🔍 [DEBUG] - Stat category: $_selectedStatCategory');
    print('🔍 [DEBUG] - Effective position: $effectivePosition');
    print('🔍 [DEBUG] - Display fields count: ${displayFields.length}');
    print('🔍 [DEBUG] - Display fields: $displayFields');
    print('🔍 [DEBUG] - Raw rows count: ${_rawRows.length}');

    return Column(
      children: [
        
        // Position-aware toggle for position-specific tabs
        if (_isPositionSpecificTab()) 
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              border: Border(bottom: BorderSide(color: Colors.grey.shade300, width: 0.5)),
            ),
            child: Row(
              children: [
                Icon(Icons.filter_list, size: 16, color: ThemeAwareColors.getSecondaryTextColor(context)),
                const SizedBox(width: 8),
                Text(
                  _showAllPositionsInTab 
                    ? 'Showing: ${_selectedPosition == 'All' ? 'All Positions' : '$_selectedPosition Only'}'
                    : 'Showing: ${_getPositionDisplayText()} Only',
                  style: TextStyle(fontSize: 13, color: ThemeAwareColors.getSecondaryTextColor(context)),
                ),
                const SizedBox(width: 12),
                Switch(
                  value: _showAllPositionsInTab,
                  onChanged: (value) {
                    setState(() {
                      _showAllPositionsInTab = value;
                    });
                    _applyFiltersAndFetch();
                  },
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                const SizedBox(width: 8),
                Text(
                  'Show All Positions',
                  style: TextStyle(fontSize: 13, color: ThemeAwareColors.getSecondaryTextColor(context)),
                ),
              ],
            ),
          ),
        
        // Add row with action buttons
        Padding(
          padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 8.0, bottom: 4.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween, // Push items to ends
            children: [
              Text(
                _rawRows.isEmpty
                    ? '' // Show nothing if no data for pagination info
                    : 'Page ${(_currentPage) + 1} of ${(_totalRecords / _rowsPerPage).ceil().clamp(1, 9999)}. Total: $_totalRecords records.',
                style: TextStyle(color: ThemeAwareColors.getSecondaryTextColor(context), fontSize: 13),
              ),
              Row(
                children: [
                  TextButton.icon(
                    onPressed: _showFieldDefinitions,
                    icon: const Icon(Icons.help_outline, size: 16),
                    label: const Text('Field Key'),
                    style: TextButton.styleFrom(
                      foregroundColor: ThemeConfig.darkNavy,
                    ),
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
          child: MdsTable(
            style: MdsTableStyle.premium,
            density: MdsTableDensity.comfortable,
            columns: displayFields.map((header) => MdsTableColumn(
              key: header,
              label: _formatHeaderName(header),
              numeric: _rawRows.isNotEmpty && _rawRows.any((row) => row[header] is num),
              enablePercentileShading: _rawRows.isNotEmpty && _rawRows.any((row) => row[header] is num) && header != 'season' && header != 'games',
              isDoubleField: doubleFields.contains(header),
              cellBuilder: header == 'recent_team' ? (value, rowIndex, percentile) {
                if (value == null) return const Text('N/A');
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TeamLogoUtils.buildNFLTeamLogo(
                      value.toString(),
                      size: 24.0,
                    ),
                    const SizedBox(width: 8),
                    Text(value.toString()),
                  ],
                );
              } : null,
            )).toList(),
            rows: _rawRows.asMap().entries.map((entry) => MdsTableRow(
              id: '${entry.key}',
              data: entry.value,
            )).toList(),
            sortColumn: _sortColumn,
            sortAscending: _sortAscending,
            onSort: (columnKey, ascending) {
              setState(() {
                _sortColumn = columnKey;
                _sortAscending = ascending;
                _applyFiltersAndFetch();
              });
            },
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

  // Helper method to determine if current tab is position-specific
  bool _isPositionSpecificTab() {
    return ['QB Stats', 'RB Stats', 'WR/TE Stats'].contains(_selectedStatCategory);
  }
  
  // Helper method to get display text for current position filter
  String _getPositionDisplayText() {
    switch (_selectedStatCategory) {
      case 'QB Stats':
        return 'QB';
      case 'RB Stats':
        return 'RB';
      case 'WR/TE Stats':
        return 'WR/TE';
      default:
        return _selectedPosition;
    }
  }
} 