import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:html' as html;
import 'dart:js' as js;
import 'dart:convert';
import '../../widgets/common/custom_app_bar.dart';
import '../../widgets/common/app_drawer.dart';
import '../../widgets/common/top_nav_bar.dart';
import '../../widgets/auth/auth_dialog.dart';
import '../../utils/theme_config.dart';
import '../../utils/team_logo_utils.dart';
import '../../services/draft/historical_draft_service.dart';
import '../../models/draft/historical_draft_pick.dart';

class HistoricalDraftsScreen extends StatefulWidget {
  const HistoricalDraftsScreen({super.key});

  @override
  _HistoricalDraftsScreenState createState() => _HistoricalDraftsScreenState();
}

class _HistoricalDraftsScreenState extends State<HistoricalDraftsScreen> {
  // Data and loading state
  List<HistoricalDraftPick> _draftPicks = [];
  bool _isLoading = true;
  int _totalCount = 0;
  int _currentPage = 0;
  static const int _pageSize = 50;

  // Filter state
  int? _selectedYear; // Will be set to most recent year from Firebase
  String? _selectedTeam; // Default to all teams
  String? _selectedPosition; // New position filter
  String? _selectedSchool; // New school filter
  int? _selectedRound; // Default to All Rounds
  List<int> _availableYears = [];
  List<String> _availableTeams = [];
  List<String> _availablePositions = [];
  List<String> _availableSchools = [];

  // Search state
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode(); // Added focus node
  String _searchQuery = '';

  // Summary stats state
  Map<String, dynamic>? _summaryStats;
  bool _showSummaryStats = false;

  // Filter panel state  
  bool _showFilterPanel = false;

  // Scroll controllers
  final ScrollController _horizontalScrollController = ScrollController();
  final ScrollController _verticalScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _initializeData();
    _initializeFromUrl();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose(); // Dispose focus node
    _horizontalScrollController.dispose();
    _verticalScrollController.dispose();
    super.dispose();
  }

  Future<void> _initializeData() async {
    setState(() => _isLoading = true);
    
    try {
      // Load available years, teams, positions, and schools
      final years = await HistoricalDraftService.getAvailableYears();
      final teams = await HistoricalDraftService.getAvailableTeams();
      final positions = await HistoricalDraftService.getAvailablePositions();
      final schools = await HistoricalDraftService.getAvailableSchools();
      
      debugPrint('📋 Available data loaded:');
      debugPrint('  Years: ${years.length} years: $years');
      debugPrint('  Teams: ${teams.length} teams: ${teams.take(10)}...');
      debugPrint('  Positions: ${positions.length} positions: $positions');
      debugPrint('  Schools: ${schools.length} schools: ${schools.take(10)}...');
      
      setState(() {
        _availableYears = years;
        _availableTeams = ['All Teams', ...teams];
        _availablePositions = ['All Positions', ...positions];
        _availableSchools = ['All Schools', ...schools];
        _selectedTeam = 'All Teams';
        _selectedPosition = 'All Positions';
        _selectedSchool = 'All Schools';
        
        // Set to most recent year from Firebase data
        if (years.isNotEmpty) {
          _selectedYear = years.first; // Most recent year (years are sorted desc)
          debugPrint('🎯 Set default year to most recent: $_selectedYear');
        }
      });

      debugPrint('🎯 Initial filter values set:');
      debugPrint('  Year: $_selectedYear');
      debugPrint('  Team: $_selectedTeam');
      debugPrint('  Position: $_selectedPosition');
      debugPrint('  School: $_selectedSchool');

      // Load initial data
      await _loadDraftPicks();
    } catch (e) {
      debugPrint('Error initializing data: $e');
      _showErrorSnackBar('Failed to load draft data');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadDraftPicks() async {
    setState(() => _isLoading = true);

    try {
      debugPrint('🔍 Loading draft picks with filters:');
      debugPrint('  Year: $_selectedYear');
      debugPrint('  Team: $_selectedTeam');
      debugPrint('  Position: $_selectedPosition');
      debugPrint('  School: $_selectedSchool');
      debugPrint('  Page: $_currentPage, Size: $_pageSize');

      final picks = await HistoricalDraftService.getDraftPicks(
        year: _selectedYear,
        team: _selectedTeam == 'All Teams' ? null : _selectedTeam,
        position: _selectedPosition == 'All Positions' ? null : _selectedPosition,
        school: _selectedSchool == 'All Schools' ? null : _selectedSchool,
        round: _selectedRound,
        page: _currentPage,
        pageSize: _pageSize,
      );

      final totalCount = await HistoricalDraftService.getDraftPicksCount(
        year: _selectedYear,
        team: _selectedTeam == 'All Teams' ? null : _selectedTeam,
        position: _selectedPosition == 'All Positions' ? null : _selectedPosition,
        school: _selectedSchool == 'All Schools' ? null : _selectedSchool,
        round: _selectedRound,
      );

      // Load summary statistics
      final summary = await HistoricalDraftService.getDraftSummary(year: _selectedYear);

      debugPrint('📊 Loaded ${picks.length} picks, total count: $totalCount');

      setState(() {
        _draftPicks = picks;
        _totalCount = totalCount;
        _summaryStats = summary;
      });
    } catch (e) {
      debugPrint('❌ Error loading draft picks: $e');
      _showErrorSnackBar('Failed to load draft picks');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _onFilterChanged() {
    setState(() {
      _currentPage = 0; // Reset to first page when filters change
    });
    _updateUrlFromFilters();
    _loadDraftPicks();
  }

  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
    });
    _loadDraftPicks();
  }

  void _performSearch() {
    if (_searchQuery.trim().isEmpty) {
      _loadDraftPicks();
      return;
    }

    setState(() => _isLoading = true);

    HistoricalDraftService.searchDraftPicks(
      playerName: _searchQuery,
      year: _selectedYear,
      team: _selectedTeam == 'All Teams' ? null : _selectedTeam,
      position: _selectedPosition == 'All Positions' ? null : _selectedPosition,
      school: _selectedSchool == 'All Schools' ? null : _selectedSchool,
    ).then((picks) {
      setState(() {
        _draftPicks = picks;
        _totalCount = picks.length;
        _currentPage = 0;
        _isLoading = false;
      });
    }).catchError((e) {
      debugPrint('Error searching draft picks: $e');
      _showErrorSnackBar('Search failed');
      setState(() => _isLoading = false);
    });
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  void _initializeFromUrl() {
    final uri = Uri.parse(html.window.location.href);
    final params = uri.queryParameters;
    
    if (params.containsKey('year')) {
      final year = int.tryParse(params['year']!);
      if (year != null) _selectedYear = year;
    }
    
    if (params.containsKey('team')) {
      _selectedTeam = params['team'];
    }
    
    if (params.containsKey('position')) {
      _selectedPosition = params['position'];
    }
    
    if (params.containsKey('school')) {
      _selectedSchool = params['school'];
    }
    
    if (params.containsKey('round')) {
      final round = int.tryParse(params['round']!);
      if (round != null) _selectedRound = round;
    }
  }

  void _updateUrlFromFilters() {
    final uri = Uri.parse(html.window.location.href);
    final newParams = <String, String>{};
    
    if (_selectedYear != null) newParams['year'] = _selectedYear.toString();
    if (_selectedTeam != null && _selectedTeam != 'All Teams') {
      newParams['team'] = _selectedTeam!;
    }
    if (_selectedPosition != null && _selectedPosition != 'All Positions') {
      newParams['position'] = _selectedPosition!;
    }
    if (_selectedSchool != null && _selectedSchool != 'All Schools') {
      newParams['school'] = _selectedSchool!;
    }
    if (_selectedRound != null) {
      newParams['round'] = _selectedRound.toString();
    }
    
    final newUri = uri.replace(queryParameters: newParams.isEmpty ? null : newParams);
    html.window.history.replaceState(null, '', newUri.toString());
    
    _updateSEOMetaTags();
  }

  void _updateSEOMetaTags() {
    try {
      final yearParam = _selectedYear?.toString() ?? '';
      final teamParam = (_selectedTeam != null && _selectedTeam != 'All Teams') ? _selectedTeam! : '';
      final description = _getPageDescription();
      
      js.context.callMethod('updateDraftPageSEO', [yearParam, teamParam, description]);
    } catch (e) {
      debugPrint('Error updating SEO meta tags: $e');
    }
  }

  String _getPageTitle() {
    String title = 'NFL Draft History';
    if (_selectedYear != null) {
      title = '$_selectedYear NFL Draft';
      if (_selectedTeam != null && _selectedTeam != 'All Teams') {
        title = '$_selectedTeam $_selectedYear Draft Picks';
      }
    }
    return title;
  }

  String _getSemanticTitle() {
    if (_selectedYear != null && _selectedTeam != null && _selectedTeam != 'All Teams') {
      return '$_selectedYear $_selectedTeam Draft Results';
    } else if (_selectedYear != null) {
      return '$_selectedYear NFL Draft History';
    }
    return 'Complete NFL Draft History Database';
  }

  String _getPageDescription() {
    if (_selectedYear != null && _selectedTeam != null && _selectedTeam != 'All Teams') {
      return 'Complete $_selectedTeam draft history for $_selectedYear including all rounds, picks, players, positions, and schools.';
    } else if (_selectedYear != null) {
      return 'All NFL teams\' draft picks for $_selectedYear with detailed player information and statistics.';
    }
    return 'Search and analyze complete NFL draft history database with filtering, statistics, and export capabilities.';
  }

  void _toggleFilterPanel() {
    setState(() {
      _showFilterPanel = !_showFilterPanel;
    });
  }

  bool get _hasActiveFilters {
    return _selectedYear != null ||
           (_selectedTeam != null && _selectedTeam != 'All Teams') ||
           (_selectedPosition != null && _selectedPosition != 'All Positions') ||
           (_selectedSchool != null && _selectedSchool != 'All Schools') ||
           (_selectedRound != null) ||
           _searchQuery.isNotEmpty;
  }

  void _showExportDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Export Draft Data'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Export ${_draftPicks.length} draft picks to:',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      _exportToCSV();
                    },
                    icon: const Icon(Icons.table_chart),
                    label: const Text('CSV'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ThemeConfig.darkNavy,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      _exportToExcel();
                    },
                    icon: const Icon(Icons.grid_on),
                    label: const Text('Excel'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ThemeConfig.gold,
                      foregroundColor: ThemeConfig.darkNavy,
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _exportToCSV() async {
    try {
      // Get all data for export (not just current page)
      final allPicks = await HistoricalDraftService.getDraftPicks(
        year: _selectedYear,
        team: _selectedTeam == 'All Teams' ? null : _selectedTeam,
        position: _selectedPosition == 'All Positions' ? null : _selectedPosition,
        school: _selectedSchool == 'All Schools' ? null : _selectedSchool,
        round: _selectedRound,
        page: 0,
        pageSize: 10000, // Get all results
      );

      final csv = _generateCSV(allPicks);
      final fileName = _generateFileName('csv');
      
      _downloadFile(csv, fileName, 'text/csv');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Exported ${allPicks.length} draft picks to $fileName'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error exporting to CSV: $e');
      _showErrorSnackBar('Failed to export CSV file');
    }
  }

  Future<void> _exportToExcel() async {
    try {
      // Get all data for export (not just current page)
      final allPicks = await HistoricalDraftService.getDraftPicks(
        year: _selectedYear,
        team: _selectedTeam == 'All Teams' ? null : _selectedTeam,
        position: _selectedPosition == 'All Positions' ? null : _selectedPosition,
        school: _selectedSchool == 'All Schools' ? null : _selectedSchool,
        round: _selectedRound,
        page: 0,
        pageSize: 10000, // Get all results
      );

      final html = _generateHTML(allPicks);
      final fileName = _generateFileName('xls');
      
      _downloadFile(html, fileName, 'application/vnd.ms-excel');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Exported ${allPicks.length} draft picks to $fileName'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error exporting to Excel: $e');
      _showErrorSnackBar('Failed to export Excel file');
    }
  }

  String _generateCSV(List<HistoricalDraftPick> picks) {
    final buffer = StringBuffer();
    
    // Headers
    buffer.writeln('Year,Round,Pick,Player,Position,School,Team');
    
    // Data rows
    for (var pick in picks) {
      buffer.writeln(
        '"${pick.year}",'
        '"${pick.round}",'
        '"${pick.pick}",'
        '"${pick.displayName}",'
        '"${pick.displayPosition}",'
        '"${pick.displaySchool}",'
        '"${pick.displayTeam}"'
      );
    }
    
    return buffer.toString();
  }

  String _generateHTML(List<HistoricalDraftPick> picks) {
    final buffer = StringBuffer();
    
    buffer.writeln('''
    <html>
    <head>
      <meta charset="utf-8">
      <title>NFL Draft History Export</title>
      <style>
        table { border-collapse: collapse; width: 100%; }
        th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
        th { background-color: #f2f2f2; font-weight: bold; }
        tr:nth-child(even) { background-color: #f9f9f9; }
      </style>
    </head>
    <body>
      <h1>NFL Draft History Export</h1>
      <p>Exported on: ${DateTime.now().toLocal().toString().split('.')[0]}</p>
      <p>Total picks: ${picks.length}</p>
      
      <table>
        <thead>
          <tr>
            <th>Year</th>
            <th>Round</th>
            <th>Pick</th>
            <th>Player</th>
            <th>Position</th>
            <th>School</th>
            <th>Team</th>
          </tr>
        </thead>
        <tbody>
    ''');
    
    for (var pick in picks) {
      buffer.writeln('''
          <tr>
            <td>${pick.year}</td>
            <td>${pick.round}</td>
            <td>${pick.pick}</td>
            <td>${pick.displayName}</td>
            <td>${pick.displayPosition}</td>
            <td>${pick.displaySchool}</td>
            <td>${pick.displayTeam}</td>
          </tr>
      ''');
    }
    
    buffer.writeln('''
        </tbody>
      </table>
    </body>
    </html>
    ''');
    
    return buffer.toString();
  }

  String _generateFileName(String extension) {
    final now = DateTime.now();
    final dateStr = '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
    
    String seoName = 'nfl-draft-history';
    if (_selectedYear != null && _selectedTeam != null && _selectedTeam != 'All Teams') {
      seoName = '${_selectedTeam!.toLowerCase().replaceAll(' ', '-')}-${_selectedYear}-draft-picks';
    } else if (_selectedYear != null) {
      seoName = '${_selectedYear}-nfl-draft-results';
    } else if (_selectedTeam != null && _selectedTeam != 'All Teams') {
      seoName = '${_selectedTeam!.toLowerCase().replaceAll(' ', '-')}-draft-history';
    }
    
    if (_selectedPosition != null && _selectedPosition != 'All Positions') {
      seoName += '-${_selectedPosition!.toLowerCase()}';
    }
    
    return '$seoName-$dateStr.$extension';
  }

  void _downloadFile(String content, String fileName, String mimeType) {
    final bytes = utf8.encode(content);
    final blob = html.Blob([bytes], mimeType);
    final url = html.Url.createObjectUrlFromBlob(blob);
    
    final anchor = html.AnchorElement(href: url)
      ..download = fileName
      ..style.display = 'none';
    
    html.document.body?.children.add(anchor);
    anchor.click();
    html.document.body?.children.remove(anchor);
    html.Url.revokeObjectUrl(url);
  }

  bool _handleKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent) {
      // Search shortcut: Ctrl/Cmd + F
      if ((event.logicalKey == LogicalKeyboardKey.keyF) && 
          (event.logicalKey == LogicalKeyboardKey.controlLeft || 
           event.logicalKey == LogicalKeyboardKey.metaLeft)) {
        _searchFocusNode.requestFocus(); // Use focus node
        return true;
      }
      
      // Export shortcut: Ctrl/Cmd + E
      if ((event.logicalKey == LogicalKeyboardKey.keyE) && 
          (event.logicalKey == LogicalKeyboardKey.controlLeft || 
           event.logicalKey == LogicalKeyboardKey.metaLeft)) {
        if (!_isLoading && _draftPicks.isNotEmpty) {
          _showExportDialog();
        }
        return true;
      }
      
      // Refresh shortcut: F5 or Ctrl/Cmd + R
      if (event.logicalKey == LogicalKeyboardKey.f5 ||
          ((event.logicalKey == LogicalKeyboardKey.keyR) && 
           (event.logicalKey == LogicalKeyboardKey.controlLeft || 
            event.logicalKey == LogicalKeyboardKey.metaLeft))) {
        if (!_isLoading) {
          HistoricalDraftService.clearCache();
          _initializeData();
        }
        return true;
      }
      
      // Navigate with arrow keys in pagination
      if (event.logicalKey == LogicalKeyboardKey.arrowLeft && _currentPage > 0) {
        _onPageChanged(_currentPage - 1);
        return true;
      }
      
      if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
        final totalPages = (_totalCount / _pageSize).ceil();
        if (_currentPage < totalPages - 1) {
          _onPageChanged(_currentPage + 1);
        }
        return true;
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final currentRouteName = ModalRoute.of(context)?.settings.name;

    return KeyboardListener(
      focusNode: FocusNode(),
      onKeyEvent: _handleKeyEvent,
      child: Stack(
        children: [
          Scaffold(
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
                  child: Material(
                    elevation: 2,
                    borderRadius: BorderRadius.circular(24),
                    shadowColor: ThemeConfig.gold.withOpacity(0.3),
                    child: ElevatedButton(
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        showDialog(context: context, builder: (_) => const AuthDialog());
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ThemeConfig.darkNavy,
                        foregroundColor: ThemeConfig.gold,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                      child: const Text('Sign In / Sign Up'),
                    ),
                  ),
                ),
              ],
            ),
            drawer: const AppDrawer(),
            body: Column(
              children: [
                _buildControls(),
                if (_summaryStats != null && !_isLoading && _showSummaryStats) _buildSummaryStats(),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: _isLoading
                        ? _buildLoadingState()
                        : _draftPicks.isEmpty 
                            ? _buildEmptyState()
                            : _buildDataTable(),
                  ),
                ),
                if (_draftPicks.isNotEmpty) _buildPaginationControls(),
              ],
            ),
          ),
          // Filter Panel Overlay
          if (_showFilterPanel)
            Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              width: 400,
              child: _buildFilterPanel(),
            ),
        ],
      ),
    );
  }

  Widget _buildControls() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade300),
        ),
      ),
      child: Row(
        children: [
          // Title and info
          Icon(Icons.history, color: ThemeConfig.darkNavy, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getSemanticTitle(),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: ThemeConfig.darkNavy,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    _getPageDescription(),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade600,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
                if (_draftPicks.isNotEmpty)
                  Text(
                    'Showing ${_draftPicks.length} of $_totalCount picks',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                  ),
              ],
            ),
          ),
          
          // Compact action buttons
          Row(
            children: [
              // Filter button
              ElevatedButton.icon(
                onPressed: _toggleFilterPanel,
                icon: Icon(
                  _showFilterPanel ? Icons.close : Icons.filter_list,
                  size: 16,
                ),
                label: Text(_showFilterPanel ? 'Close' : 'Filter'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _hasActiveFilters ? Colors.blue.shade600 : ThemeConfig.darkNavy,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  textStyle: const TextStyle(fontSize: 12),
                ),
              ),
              
              const SizedBox(width: 8),
              
              // Export button
              ElevatedButton.icon(
                onPressed: _isLoading || _draftPicks.isEmpty ? null : _showExportDialog,
                icon: const Icon(Icons.download, size: 16),
                label: const Text('Export'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: ThemeConfig.gold,
                  foregroundColor: ThemeConfig.darkNavy,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  textStyle: const TextStyle(fontSize: 12),
                ),
              ),
              
              const SizedBox(width: 8),
              
              // Stats toggle button
              if (_summaryStats != null && !_isLoading)
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() => _showSummaryStats = !_showSummaryStats);
                  },
                  icon: Icon(_showSummaryStats ? Icons.expand_less : Icons.expand_more, size: 16),
                  label: Text(_showSummaryStats ? 'Hide Stats' : 'Show Stats'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey.shade600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    textStyle: const TextStyle(fontSize: 12),
                  ),
                ),
              
              const SizedBox(width: 8),
              
              // Refresh button
              IconButton(
                onPressed: _isLoading ? null : () {
                  HistoricalDraftService.clearCache();
                  _initializeData();
                },
                icon: _isLoading 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.refresh),
                tooltip: 'Refresh data',
                style: IconButton.styleFrom(
                  backgroundColor: Colors.grey.shade100,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildYearFilter() {
    // Ensure unique years and that the selected year is in the list
    final uniqueYears = _availableYears.toSet().toList()..sort((a, b) => b.compareTo(a));
    final validSelectedYear = (_selectedYear != null && uniqueYears.contains(_selectedYear)) ? _selectedYear : null;
    
    return DropdownButtonFormField<int?>(
      value: validSelectedYear,
      decoration: InputDecoration(
        labelText: 'Year',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        isDense: true,
      ),
      items: [
        const DropdownMenuItem<int?>(
          value: null,
          child: Text('All Years'),
        ),
        ...uniqueYears.map((year) => DropdownMenuItem<int?>(
          value: year,
          child: Text(year.toString()),
        )),
      ],
      onChanged: (value) {
        setState(() => _selectedYear = value);
        _onFilterChanged();
      },
    );
  }

  Widget _buildTeamFilter() {
    // Ensure unique teams
    final uniqueTeams = _availableTeams.toSet().toList()..sort();
    final validSelectedTeam = (_selectedTeam != null && uniqueTeams.contains(_selectedTeam)) ? _selectedTeam : (uniqueTeams.isNotEmpty ? uniqueTeams.first : null);
    
    return DropdownButtonFormField<String>(
      value: validSelectedTeam,
      decoration: InputDecoration(
        labelText: 'Team',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        isDense: true,
      ),
      items: uniqueTeams.map((team) => DropdownMenuItem<String>(
        value: team,
        child: Text(team),
      )).toList(),
      onChanged: (value) {
        setState(() => _selectedTeam = value);
        _onFilterChanged();
      },
    );
  }

  Widget _buildPositionFilter() {
    // Ensure unique positions
    final uniquePositions = _availablePositions.toSet().toList()..sort();
    final validSelectedPosition = (_selectedPosition != null && uniquePositions.contains(_selectedPosition)) ? _selectedPosition : (uniquePositions.isNotEmpty ? uniquePositions.first : null);
    
    return DropdownButtonFormField<String>(
      value: validSelectedPosition,
      decoration: InputDecoration(
        labelText: 'Position',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        isDense: true,
      ),
      items: uniquePositions.map((position) => DropdownMenuItem<String>(
        value: position,
        child: Text(position),
      )).toList(),
      onChanged: (value) {
        setState(() => _selectedPosition = value);
        _onFilterChanged();
      },
    );
  }

  Widget _buildSchoolFilter() {
    // Ensure unique schools
    final uniqueSchools = _availableSchools.toSet().toList()..sort();
    final validSelectedSchool = (_selectedSchool != null && uniqueSchools.contains(_selectedSchool)) ? _selectedSchool : (uniqueSchools.isNotEmpty ? uniqueSchools.first : null);
    
    return DropdownButtonFormField<String>(
      value: validSelectedSchool,
      decoration: InputDecoration(
        labelText: 'School',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        isDense: true,
      ),
      items: uniqueSchools.map((school) => DropdownMenuItem<String>(
        value: school,
        child: Text(school, overflow: TextOverflow.ellipsis),
      )).toList(),
      onChanged: (value) {
        setState(() => _selectedSchool = value);
        _onFilterChanged();
      },
    );
  }

  Widget _buildSearchField() {
    return Semantics(
      label: 'Search for NFL draft picks by player name',
      hint: 'Type a player name and press enter or click search',
      child: TextField(
        controller: _searchController,
        focusNode: _searchFocusNode, // Attach focus node
        decoration: InputDecoration(
          labelText: 'Search players...',
          hintText: 'Enter player name (Ctrl+F)',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          isDense: true,
          suffixIcon: IconButton(
            icon: const Icon(Icons.search),
            tooltip: 'Search for players',
            onPressed: _performSearch,
          ),
        ),
        onChanged: (value) => _searchQuery = value,
        onSubmitted: (_) => _performSearch(),
      ),
    );
  }

  Widget _buildExportButton() {
    return Semantics(
      label: 'Export draft data to CSV or Excel file',
      hint: 'Press Ctrl+E to export data',
      child: ElevatedButton.icon(
        onPressed: _isLoading || _draftPicks.isEmpty ? null : _showExportDialog,
        icon: const Icon(Icons.download),
        label: const Text('Export'),
        style: ElevatedButton.styleFrom(
          backgroundColor: ThemeConfig.gold,
          foregroundColor: ThemeConfig.darkNavy,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildRefreshButton() {
    return Semantics(
      label: _isLoading ? 'Currently loading data' : 'Refresh draft data',
      hint: 'Press F5 or Ctrl+R to refresh',
      child: ElevatedButton.icon(
        onPressed: _isLoading ? null : () {
          HistoricalDraftService.clearCache();
          _initializeData();
        },
        icon: _isLoading 
          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
          : const Icon(Icons.refresh),
        label: Text(_isLoading ? 'Loading...' : 'Refresh'),
        style: ElevatedButton.styleFrom(
          backgroundColor: ThemeConfig.darkNavy,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildKeyboardShortcutsInfo() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.keyboard, size: 16, color: Colors.grey.shade600),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              'Shortcuts: Ctrl+F (Search), Ctrl+E (Export), F5 (Refresh), ←→ (Navigate)',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryStats() {
    if (_summaryStats == null) return const SizedBox.shrink();

    final totalPicks = _summaryStats!['totalPicks'] as int;
    final topPositions = _summaryStats!['topPositions'] as List<MapEntry<String, int>>;
    final topTeams = _summaryStats!['topTeams'] as List<MapEntry<String, int>>;
    final topSchools = _summaryStats!['topSchools'] as List<MapEntry<String, int>>;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            ThemeConfig.darkNavy.withOpacity(0.05),
            ThemeConfig.gold.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ThemeConfig.gold.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.analytics, color: ThemeConfig.darkNavy, size: 20),
              const SizedBox(width: 8),
              Text(
                'Draft Statistics',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: ThemeConfig.darkNavy,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: ThemeConfig.darkNavy,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$totalPicks picks',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Statistics Grid
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 800;
              
              if (isWide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _buildStatsColumn('Top Positions', topPositions, Icons.sports)),
                    const SizedBox(width: 16),
                    Expanded(child: _buildStatsColumn('Top Teams', topTeams, Icons.groups)),
                    const SizedBox(width: 16),
                    Expanded(child: _buildStatsColumn('Top Schools', topSchools, Icons.school)),
                  ],
                );
              } else {
                return Column(
                  children: [
                    _buildStatsColumn('Top Positions', topPositions, Icons.sports),
                    const SizedBox(height: 12),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _buildStatsColumn('Top Teams', topTeams, Icons.groups)),
                        const SizedBox(width: 16),
                        Expanded(child: _buildStatsColumn('Top Schools', topSchools, Icons.school)),
                      ],
                    ),
                  ],
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatsColumn(String title, List<MapEntry<String, int>> data, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: ThemeConfig.darkNavy),
              const SizedBox(width: 6),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...data.take(5).map((entry) {
            final percentage = data.isNotEmpty 
                ? (entry.value / data.first.value * 100).round()
                : 0;
            
            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      entry.key,
                      style: const TextStyle(fontSize: 11),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${entry.value}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: ThemeConfig.darkNavy,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Container(
                    width: 30,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: percentage / 100,
                      child: Container(
                        decoration: BoxDecoration(
                          color: ThemeConfig.gold,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildDataTable() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.surface,
            Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: ThemeConfig.gold.withOpacity(0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: ThemeConfig.darkNavy.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          controller: _horizontalScrollController,
          child: Container(
            width: _getResponsiveTableWidth(),
            child: Column(
              children: [
                // Headers
                _buildTableHeaders(),
                // Data
                Expanded(
                  child: ListView.builder(
                    controller: _verticalScrollController,
                    itemCount: _draftPicks.length,
                    itemBuilder: (context, index) {
                      return _buildTableRow(_draftPicks[index], index);
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTableHeaders() {
    final headers = ['Year', 'Round', 'Pick', 'Player', 'Position', 'School', 'Team'];
    final columnWidths = _getColumnWidths();
    
    return Container(
      height: 60,
      color: ThemeConfig.darkNavy,
      child: Row(
        children: headers.asMap().entries.map((entry) {
          final index = entry.key;
          final header = entry.value;
          
          return Container(
            width: columnWidths[index],
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white24, width: 0.5),
            ),
            child: Center(
              child: Text(
                header,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTableRow(HistoricalDraftPick pick, int index) {
    final isEven = index % 2 == 0;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final rowColor = isDark 
      ? (isEven ? Colors.grey.shade100 : Colors.grey.shade200)
      : (isEven ? Colors.white : Colors.grey.shade50);
    
    final columnWidths = _getColumnWidths();
    final cells = [
      pick.year.toString(),
      pick.round.toString(),
      pick.pick.toString(),
      pick.displayName,
      pick.displayPosition,
      pick.displaySchool,
      '', // Team cell handled separately
    ];

    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: rowColor,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200, width: 1),
        ),
      ),
      child: Row(
        children: cells.asMap().entries.map((entry) {
          final cellIndex = entry.key;
          final cellValue = entry.value;
          
          if (cellIndex == 6) { // Team column with logo
            return _buildTeamCell(pick, columnWidths[cellIndex]);
          }
          
          return Container(
            width: columnWidths[cellIndex],
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade200, width: 0.5),
            ),
            child: Center(
              child: Text(
                cellValue,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: cellIndex == 3 ? FontWeight.w600 : FontWeight.w500, // Bold for player names
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTeamCell(HistoricalDraftPick pick, double width) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade200, width: 0.5),
      ),
      child: pick.team.isNotEmpty && pick.team != 'Unknown'
        ? Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TeamLogoUtils.buildNFLTeamLogo(pick.team, size: 16),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  pick.team,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ],
          )
        : Center(
            child: Text(
              pick.displayTeam,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
    );
  }

  Widget _buildRoundFilter() {
    final rounds = [0, 1, 2, 3, 4, 5, 6, 7]; // 0 = All Rounds
    
    return DropdownButtonFormField<int?>(
      value: _selectedRound,
      decoration: InputDecoration(
        labelText: 'Round',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        isDense: true,
      ),
      items: rounds.map((round) => DropdownMenuItem<int?>(
        value: round == 0 ? null : round,
        child: Text(round == 0 ? 'All Rounds' : 'Round $round'),
      )).toList(),
      onChanged: (value) {
        setState(() => _selectedRound = value);
        _onFilterChanged();
      },
    );
  }

  List<double> _getColumnWidths() {
    final screenWidth = MediaQuery.of(context).size.width;
    final availableWidth = screenWidth - 32; // Account for margins
    
    if (screenWidth < 600) {
      // Mobile: tighter columns, wider team column for horizontal layout
      return [60, 60, 60, 140, 70, 120, 80]; // Total: 590
    } else if (screenWidth < 1000) {
      // Tablet: medium columns, wider team column  
      return [70, 70, 70, 180, 80, 140, 90]; // Total: 700
    } else {
      // Desktop: wider columns, wider team column
      return [80, 80, 80, 220, 100, 160, 100]; // Total: 820
    }
  }

  double _getResponsiveTableWidth() {
    final columnWidths = _getColumnWidths();
    return columnWidths.reduce((a, b) => a + b);
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: ThemeConfig.darkNavy.withOpacity(0.1),
              borderRadius: BorderRadius.circular(40),
            ),
            child: const Center(
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(ThemeConfig.darkNavy),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Loading draft picks...',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: ThemeConfig.darkNavy,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Fetching NFL draft history',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(60),
            ),
            child: Icon(
              Icons.sports_football_outlined,
              size: 64,
              color: Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No draft picks found',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your filters or search terms',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              setState(() {
                _selectedYear = _availableYears.isNotEmpty ? _availableYears.first : null;
                _selectedTeam = 'All Teams';
                _selectedPosition = 'All Positions';
                _selectedSchool = 'All Schools';
                _selectedRound = null;
                _searchController.clear();
                _searchQuery = '';
              });
              _onFilterChanged();
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Reset Filters'),
            style: ElevatedButton.styleFrom(
              backgroundColor: ThemeConfig.darkNavy,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaginationControls() {
    final totalPages = (_totalCount / _pageSize).ceil();
    if (totalPages <= 1) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        border: Border(
          top: BorderSide(color: Colors.grey.shade300),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Page ${_currentPage + 1} of $totalPages',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          Row(
            children: [
              Semantics(
                label: 'Previous page',
                hint: 'Use left arrow key to navigate to previous page',
                child: IconButton(
                  onPressed: _currentPage > 0 ? () => _onPageChanged(_currentPage - 1) : null,
                  icon: const Icon(Icons.chevron_left),
                  tooltip: 'Previous page (Left arrow)',
                ),
              ),
              const SizedBox(width: 16),
              Semantics(
                label: 'Next page',
                hint: 'Use right arrow key to navigate to next page',
                child: IconButton(
                  onPressed: _currentPage < totalPages - 1 ? () => _onPageChanged(_currentPage + 1) : null,
                  icon: const Icon(Icons.chevron_right),
                  tooltip: 'Next page (Right arrow)',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterPanel() {
    return Material(
      elevation: 10,
      shadowColor: Colors.black.withOpacity(0.2),
      child: Container(
        width: 400,
        color: Colors.white,
        child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: ThemeConfig.darkNavy,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                const Icon(Icons.filter_list, color: Colors.white),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Filter Draft Picks',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _toggleFilterPanel,
                  icon: const Icon(Icons.close, color: Colors.white),
                ),
              ],
            ),
          ),
          
          // Filter Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildYearFilter(),
                  const SizedBox(height: 16),
                  _buildTeamFilter(),
                  const SizedBox(height: 16),
                  _buildPositionFilter(),
                  const SizedBox(height: 16),
                  _buildSchoolFilter(),
                  const SizedBox(height: 16),
                  _buildRoundFilter(),
                  const SizedBox(height: 16),
                  _buildSearchField(),
                  const SizedBox(height: 24),
                  
                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _selectedYear = null;
                              _selectedTeam = 'All Teams';
                              _selectedPosition = 'All Positions';
                              _selectedSchool = 'All Schools';
                              _selectedRound = null;
                              _searchController.clear();
                              _searchQuery = '';
                            });
                            _onFilterChanged();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey.shade200,
                            foregroundColor: Colors.black87,
                          ),
                          child: const Text('Clear All'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _toggleFilterPanel,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: ThemeConfig.darkNavy,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Apply'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
        ),
      ),
    );
  }
}