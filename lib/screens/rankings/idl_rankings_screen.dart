import 'package:flutter/material.dart';
import '../../widgets/common/app_drawer.dart';
import '../../widgets/common/custom_app_bar.dart';
import '../../widgets/common/top_nav_bar.dart';
import '../../utils/team_logo_utils.dart';
import '../../utils/theme_config.dart';
import '../../services/csv_idl_rankings_service.dart';

class IdlRankingsScreen extends StatefulWidget {
  const IdlRankingsScreen({super.key});

  @override
  State<IdlRankingsScreen> createState() => _IdlRankingsScreenState();
}

class _IdlRankingsScreenState extends State<IdlRankingsScreen> {
  List<Map<String, dynamic>> _idlRankings = [];
  bool _isLoading = true;
  String? _error;
  
  // Filters
  String _selectedSeason = '2024';
  String _selectedTeam = 'All';
  String _selectedTier = 'All';
  
  // Sorting
  String _sortColumn = 'ranking';
  bool _sortAscending = true;

  // Filter options
  List<String> _seasonOptions = [];
  List<String> _teamOptions = [];
  List<String> _tierOptions = [];

  @override
  void initState() {
    super.initState();
    _loadFilterOptions();
    _fetchIdlRankings();
  }

  Future<void> _loadFilterOptions() async {
    try {
      List<String> seasons = await CsvIdlRankingsService.getSeasons();
      List<String> teams = await CsvIdlRankingsService.getTeams();
      List<int> tiers = await CsvIdlRankingsService.getTiers();

      setState(() {
        _seasonOptions = ['All', ...seasons];
        _teamOptions = ['All', ...teams];
        _tierOptions = ['All', ...tiers.map((t) => t.toString())];
      });
    } catch (e) {
      print('Error loading filter options: $e');
    }
  }

  Future<void> _fetchIdlRankings() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      List<Map<String, dynamic>> results = await CsvIdlRankingsService.getIdlRankings(
        season: _selectedSeason == 'All' ? null : _selectedSeason,
        team: _selectedTeam == 'All' ? null : _selectedTeam,
        tier: _selectedTier == 'All' ? null : int.tryParse(_selectedTier),
        limit: 200,
        orderBy: _sortColumn,
        orderDescending: !_sortAscending,
      );

      setState(() {
        _idlRankings = results;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error loading IDL rankings: $e';
        _isLoading = false;
      });
    }
  }

  void _sort(String column, bool ascending) {
    setState(() {
      _sortColumn = column;
      _sortAscending = ascending;
    });
    _fetchIdlRankings();
  }

  Color _getTierColor(int tier) {
    switch (tier) {
      case 1: return const Color(0xFF1B5E20); // Elite - Dark Green
      case 2: return const Color(0xFF2E7D32); // Great - Green
      case 3: return const Color(0xFF388E3C); // Good - Light Green
      case 4: return const Color(0xFFFF8F00); // Average - Orange
      case 5: return const Color(0xFFE65100); // Below Average - Dark Orange
      case 6: return const Color(0xFFBF360C); // Poor - Red Orange
      case 7: return const Color(0xFFD32F2F); // Bad - Red
      default: return const Color(0xFF9E9E9E); // Unknown - Grey
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        titleWidget: Row(
          children: [
            const Text('NFL IDL Rankings', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
      drawer: const AppDrawer(),
      body: Column(
        children: [
          TopNavBarContent(currentRoute: ModalRoute.of(context)?.settings.name),
          _buildFilters(),
          _buildContent(),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildFilterDropdown(
                  'Season',
                  _selectedSeason,
                  _seasonOptions,
                  (value) {
                    setState(() => _selectedSeason = value!);
                    _fetchIdlRankings();
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildFilterDropdown(
                  'Team',
                  _selectedTeam,
                  _teamOptions,
                  (value) {
                    setState(() => _selectedTeam = value!);
                    _fetchIdlRankings();
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildFilterDropdown(
                  'Tier',
                  _selectedTier,
                  _tierOptions,
                  (value) {
                    setState(() => _selectedTier = value!);
                    _fetchIdlRankings();
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              ElevatedButton.icon(
                onPressed: _fetchIdlRankings,
                icon: const Icon(Icons.refresh),
                label: const Text('Refresh'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: ThemeConfig.darkNavy,
                  foregroundColor: Colors.white,
                ),
              ),
              const Spacer(),
              Text(
                '${_idlRankings.length} players',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
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
    void Function(String?) onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        DropdownButtonFormField<String>(
          value: options.contains(value) ? value : (options.isNotEmpty ? options.first : null),
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

  Widget _buildContent() {
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
                onPressed: _fetchIdlRankings,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_idlRankings.isEmpty) {
      return const Expanded(
        child: Center(
          child: Text('No IDL rankings found for the selected filters.'),
        ),
      );
    }

    return Expanded(
      child: Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
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
                headingRowColor: WidgetStateProperty.all(ThemeConfig.darkNavy),
                sortColumnIndex: _getSortColumnIndex(),
                sortAscending: _sortAscending,
                columnSpacing: 24,
                dataRowMinHeight: 48,
                columns: _buildColumns(),
                rows: _buildRows(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<DataColumn> _buildColumns() {
    return [
      DataColumn(
        label: const Text('Rank', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        onSort: (columnIndex, ascending) => _sort('ranking', ascending),
      ),
      DataColumn(
        label: const Text('Player', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        onSort: (columnIndex, ascending) => _sort('name', ascending),
      ),
      DataColumn(
        label: const Text('Team', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        onSort: (columnIndex, ascending) => _sort('team', ascending),
      ),
      DataColumn(
        label: const Text('Position', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        onSort: (columnIndex, ascending) => _sort('position', ascending),
      ),
      DataColumn(
        label: const Text('Tier', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        onSort: (columnIndex, ascending) => _sort('tier', ascending),
        numeric: true,
      ),
      DataColumn(
        label: const Text('Tackles', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        onSort: (columnIndex, ascending) => _sort('solo_tackles', ascending),
        numeric: true,
      ),
      DataColumn(
        label: const Text('TFLs', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        onSort: (columnIndex, ascending) => _sort('tfls', ascending),
        numeric: true,
      ),
      DataColumn(
        label: const Text('Run Stuffs', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        onSort: (columnIndex, ascending) => _sort('run_stuffs', ascending),
        numeric: true,
      ),
      DataColumn(
        label: const Text('Stuff Rate %', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        onSort: (columnIndex, ascending) => _sort('run_stuff_rate', ascending),
        numeric: true,
      ),
      DataColumn(
        label: const Text('Sacks', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        onSort: (columnIndex, ascending) => _sort('sacks', ascending),
        numeric: true,
      ),
      DataColumn(
        label: const Text('Snaps', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        onSort: (columnIndex, ascending) => _sort('def_snaps', ascending),
        numeric: true,
      ),
    ];
  }

  List<DataRow> _buildRows() {
    return _idlRankings.asMap().entries.map((entry) {
      final index = entry.key;
      final player = entry.value;
      final tier = _parseDouble(player['tier']).toInt();
      final tierColor = _getTierColor(tier);

      return DataRow(
        color: WidgetStateProperty.resolveWith<Color?>(
          (Set<WidgetState> states) {
            if (states.contains(WidgetState.hovered)) {
              return tierColor.withValues(alpha: 0.1);
            }
            return index % 2 == 0 ? Colors.grey.shade50 : Colors.white;
          },
        ),
        cells: [
          DataCell(
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: tierColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '#${_parseDouble(player['ranking']).toInt()}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          DataCell(
            Row(
              children: [
                TeamLogoUtils.buildNFLTeamLogo(player['team'] ?? '', size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    player['name'] ?? 'Unknown',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
          DataCell(Text(player['team'] ?? '')),
          DataCell(Text(player['position'] ?? '')),
          DataCell(
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: tierColor,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'T$tier',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
              ),
            ),
          ),
          DataCell(Text(_parseDouble(player['solo_tackles']).toInt().toString())),
          DataCell(Text(_parseDouble(player['tfls']).toInt().toString())),
          DataCell(Text(_parseDouble(player['run_stuffs']).toInt().toString())),
          DataCell(Text('${_parseDouble(player['run_stuff_rate']).toStringAsFixed(2)}%')),
          DataCell(Text(_parseDouble(player['sacks']).toStringAsFixed(1))),
          DataCell(Text(_parseDouble(player['def_snaps']).toInt().toString())),
        ],
      );
    }).toList();
  }

  int _getSortColumnIndex() {
    final columns = ['ranking', 'name', 'team', 'position', 'tier', 'solo_tackles', 'tfls', 'run_stuffs', 'run_stuff_rate', 'sacks', 'def_snaps'];
    return columns.indexOf(_sortColumn);
  }

  double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
}