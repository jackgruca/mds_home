import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../widgets/common/custom_app_bar.dart';
import '../widgets/common/app_drawer.dart';
import '../widgets/common/top_nav_bar.dart';
import '../widgets/auth/auth_dialog.dart';
import '../utils/team_logo_utils.dart';
import '../utils/theme_config.dart';
import '../models/nfl_trade/nfl_player.dart';
import '../services/nfl_roster_service.dart';

class NflRostersScreen extends StatefulWidget {
  const NflRostersScreen({super.key});

  @override
  State<NflRostersScreen> createState() => _NflRostersScreenState();
}

class _NflRostersScreenState extends State<NflRostersScreen> {
  bool _isLoading = true;
  String? _error;
  List<NFLPlayer> _players = [];
  List<NFLPlayer> _filteredPlayers = [];
  int _totalRecords = 0;

  // Pagination state
  int _currentPage = 0;
  static const int _rowsPerPage = 25;

  // Sort state
  String _sortColumn = 'overallRating';
  bool _sortAscending = false;

  // Filter state
  String _selectedSeason = '2024';
  String _selectedTeam = 'All';
  String _selectedPosition = 'All';
  
  // Filter options
  final List<String> _seasons = ['All', '2024', '2023', '2022', '2021', '2020'];
  List<String> _teams = ['All'];
  List<String> _positions = ['All'];

  // Search functionality
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Load all players from CSV
      List<NFLPlayer> allPlayers = await _loadAllPlayers();
      
      // Extract unique teams and positions for filters
      Set<String> teamsSet = allPlayers.map((p) => p.team).toSet();
      Set<String> positionsSet = allPlayers.map((p) => p.position).toSet();
      
      _teams = ['All', ...teamsSet.toList()..sort()];
      _positions = ['All', ...positionsSet.toList()..sort()];
      
      setState(() {
        _players = allPlayers;
        _isLoading = false;
      });
      
      _applyFilters();
      
    } catch (e) {
      setState(() {
        _error = 'Error loading roster data: $e';
        _isLoading = false;
      });
    }
  }

  Future<List<NFLPlayer>> _loadAllPlayers() async {
    List<NFLPlayer> allPlayers = [];
    
    // Load players from all teams
    for (String team in ['ARI', 'ATL', 'BAL', 'BUF', 'CAR', 'CHI', 'CIN', 'CLE', 
                        'DAL', 'DEN', 'DET', 'GB', 'HOU', 'IND', 'JAX', 'KC', 
                        'LV', 'LAC', 'LAR', 'MIA', 'MIN', 'NE', 'NO', 'NYG', 
                        'NYJ', 'PHI', 'PIT', 'SF', 'SEA', 'TB', 'TEN', 'WAS']) {
      try {
        List<NFLPlayer> teamPlayers = await NFLRosterService.getTeamRoster(
          team, 
          season: _selectedSeason == 'All' ? '2024' : _selectedSeason,
          limit: 1000, // Get all players
        );
        allPlayers.addAll(teamPlayers);
      } catch (e) {
        print('Error loading team $team: $e');
      }
    }
    
    return allPlayers;
  }

  void _applyFilters() {
    List<NFLPlayer> filtered = _players;

    // Apply team filter
    if (_selectedTeam != 'All') {
      filtered = filtered.where((player) => player.team == _selectedTeam).toList();
    }

    // Apply position filter
    if (_selectedPosition != 'All') {
      filtered = filtered.where((player) => player.position == _selectedPosition).toList();
    }

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      final searchLower = _searchQuery.toLowerCase();
      filtered = filtered.where((player) {
        return player.name.toLowerCase().contains(searchLower) ||
               player.team.toLowerCase().contains(searchLower) ||
               player.position.toLowerCase().contains(searchLower);
      }).toList();
    }

    // Apply sorting
    filtered = _sortPlayers(filtered, _sortColumn, _sortAscending);

    setState(() {
      _filteredPlayers = filtered;
      _totalRecords = filtered.length;
      _currentPage = 0; // Reset to first page when filters change
    });
  }

  List<NFLPlayer> _sortPlayers(List<NFLPlayer> players, String sortBy, bool ascending) {
    players.sort((a, b) {
      dynamic aValue, bValue;
      
      switch (sortBy) {
        case 'name':
          aValue = a.name;
          bValue = b.name;
          break;
        case 'team':
          aValue = a.team;
          bValue = b.team;
          break;
        case 'position':
          aValue = a.position;
          bValue = b.position;
          break;
        case 'age':
          aValue = a.age;
          bValue = b.age;
          break;
        case 'experience':
          aValue = a.experience;
          bValue = b.experience;
          break;
        case 'overallRating':
          aValue = a.overallRating;
          bValue = b.overallRating;
          break;
        case 'salary':
          aValue = a.annualSalary;
          bValue = b.annualSalary;
          break;
        default:
          aValue = a.overallRating;
          bValue = b.overallRating;
      }

      if (aValue == null && bValue == null) return 0;
      if (aValue == null) return ascending ? -1 : 1;
      if (bValue == null) return ascending ? 1 : -1;

      return ascending 
          ? Comparable.compare(aValue, bValue)
          : Comparable.compare(bValue, aValue);
    });

    return players;
  }

  List<NFLPlayer> get _currentPagePlayers {
    int startIndex = _currentPage * _rowsPerPage;
    int endIndex = startIndex + _rowsPerPage;
    return _filteredPlayers.sublist(
      startIndex, 
      endIndex > _filteredPlayers.length ? _filteredPlayers.length : endIndex
    );
  }

  int get _totalPages => (_totalRecords / _rowsPerPage).ceil();

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
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: Column(
        children: [
          _buildFilters(),
          _buildDataTable(),
          _buildPaginationControls(),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Search bar
          TextField(
            controller: _searchController,
            decoration: const InputDecoration(
              hintText: 'Search players...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
            onChanged: (value) {
              _searchQuery = value;
              _applyFilters();
            },
          ),
          const SizedBox(height: 16),
          // Filter dropdowns
          Row(
            children: [
              Expanded(
                child: _buildFilterDropdown(
                  'Season', 
                  _selectedSeason, 
                  _seasons, 
                  (value) {
                    _selectedSeason = value!;
                    _loadData(); // Reload data for different season
                  }
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildFilterDropdown(
                  'Team', 
                  _selectedTeam, 
                  _teams, 
                  (value) {
                    _selectedTeam = value!;
                    _applyFilters();
                  }
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildFilterDropdown(
                  'Position', 
                  _selectedPosition, 
                  _positions, 
                  (value) {
                    _selectedPosition = value!;
                    _applyFilters();
                  }
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterDropdown(
    String label, 
    String value, 
    List<String> options, 
    void Function(String?) onChanged
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        DropdownButtonFormField<String>(
          value: value,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            isDense: true,
          ),
          items: options.map((option) {
            return DropdownMenuItem(value: option, child: Text(option));
          }).toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildDataTable() {
    if (_isLoading) {
      return const Expanded(
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Expanded(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error, size: 64, color: Colors.red[400]),
              const SizedBox(height: 16),
              Text(_error!, style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadData,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_filteredPlayers.isEmpty) {
      return const Expanded(
        child: Center(
          child: Text('No players found matching the current filters.'),
        ),
      );
    }

    return Expanded(
      child: Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SingleChildScrollView(
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(Theme.of(context).colorScheme.primary),
                sortColumnIndex: _getSortColumnIndex(),
                sortAscending: _sortAscending,
                columnSpacing: 24,
                dataRowMinHeight: 48,
                columns: [
                  DataColumn(
                    label: const Text(
                      'Player Name',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    onSort: (columnIndex, ascending) => _sort('name', ascending),
                  ),
                  DataColumn(
                    label: const Text(
                      'Team',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    onSort: (columnIndex, ascending) => _sort('team', ascending),
                  ),
                  DataColumn(
                    label: const Text(
                      'Position',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    onSort: (columnIndex, ascending) => _sort('position', ascending),
                  ),
                  DataColumn(
                    label: const Text(
                      'Age',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    numeric: true,
                    onSort: (columnIndex, ascending) => _sort('age', ascending),
                  ),
                  DataColumn(
                    label: const Text(
                      'Experience',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    numeric: true,
                    onSort: (columnIndex, ascending) => _sort('experience', ascending),
                  ),
                  DataColumn(
                    label: const Text(
                      'Overall Rating',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    numeric: true,
                    onSort: (columnIndex, ascending) => _sort('overallRating', ascending),
                  ),
                  DataColumn(
                    label: const Text(
                      'Salary',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    numeric: true,
                    onSort: (columnIndex, ascending) => _sort('salary', ascending),
                  ),
            ],
            rows: _currentPagePlayers.map((player) {
              return DataRow(
                cells: [
                  DataCell(Text(player.name)),
                  DataCell(Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TeamLogoUtils.buildNFLTeamLogo(player.team, size: 20),
                      const SizedBox(width: 8),
                      Text(player.team),
                    ],
                  )),
                  DataCell(Text(player.position)),
                  DataCell(Text('${player.age}')),
                  DataCell(Text('${player.experience}')),
                  DataCell(Text(player.overallRating.toStringAsFixed(1))),
                  DataCell(Text('\$${player.annualSalary.toStringAsFixed(1)}M')),
                ],
              );
            }).toList(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPaginationControls() {
    if (_totalPages <= 1) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Page ${_currentPage + 1} of $_totalPages • $_totalRecords total records'),
          Row(
            children: [
              IconButton(
                onPressed: _currentPage > 0 ? () => _goToPage(_currentPage - 1) : null,
                icon: const Icon(Icons.chevron_left),
              ),
              IconButton(
                onPressed: _currentPage < _totalPages - 1 ? () => _goToPage(_currentPage + 1) : null,
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _goToPage(int page) {
    setState(() {
      _currentPage = page;
    });
  }

  void _sort(String column, bool ascending) {
    setState(() {
      _sortColumn = column;
      _sortAscending = ascending;
    });
    _applyFilters();
  }

  int _getSortColumnIndex() {
    switch (_sortColumn) {
      case 'name': return 0;
      case 'team': return 1;
      case 'position': return 2;
      case 'age': return 3;
      case 'experience': return 4;
      case 'overallRating': return 5;
      case 'salary': return 6;
      default: return 5; // Default to rating
    }
  }
}