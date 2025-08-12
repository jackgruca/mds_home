import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

import '../../widgets/common/app_drawer.dart';
import '../../widgets/common/custom_app_bar.dart';
import '../../widgets/common/top_nav_bar.dart';
import '../../utils/team_logo_utils.dart';
import '../../utils/theme_config.dart';
import '../../services/rankings/offense_tier_service.dart';
import '../../services/rankings/ranking_service.dart';
import '../../services/rankings/csv_rankings_service.dart';
import '../../services/rankings/ranking_cell_shading_service.dart';
import '../../services/rankings/filter_service.dart';
import '../../widgets/rankings/filter_panel.dart';

class RunOffenseRankingsScreen extends StatefulWidget {
  const RunOffenseRankingsScreen({super.key});

  @override
  State<RunOffenseRankingsScreen> createState() => _RunOffenseRankingsScreenState();
}

class _RunOffenseRankingsScreenState extends State<RunOffenseRankingsScreen> {
  List<Map<String, dynamic>> _rankings = [];
  List<Map<String, dynamic>> _originalRankings = [];
  bool _isLoading = true;
  String? _error;
  String _selectedSeason = '2024';
  String _selectedTier = 'All';
  bool _showRanks = false;
  bool _showFilterPanel = false;
  bool _usingFilters = false;
  
  // Sorting state - default to rank ascending (rank 1 first)
  String _sortColumn = 'myRankNum';
  bool _sortAscending = true;
  
  late final List<String> _seasonOptions;
  late final List<String> _tierOptions;
  late Map<String, Map<String, dynamic>> _statFields;
  late FilterQuery _currentFilter;
  
  final Map<String, Map<String, double>> _percentileCache = {};
  final OffenseTierService _offenseService = OffenseTierService();

  @override
  void initState() {
    super.initState();
    _seasonOptions = ['2024', '2023', '2022', '2021', '2020', '2019', '2018', '2017', '2016'];
    _tierOptions = ['All', '1', '2', '3', '4', '5', '6', '7', '8'];
    _currentFilter = const FilterQuery();
    _updateStatFields();
    _loadRankings();
  }
  
  void _updateStatFields() {
    if (_showRanks) {
      _statFields = _getRankFields();
    } else {
      _statFields = {
        'totalYds': {'name': 'Rush Yards', 'format': 'integer', 'description': 'Total rushing yards'},
        'totalTD': {'name': 'Rush TDs', 'format': 'integer', 'description': 'Total rushing touchdowns'},
        'successRate': {'name': 'Success Rate', 'format': 'percentage', 'description': 'Rushing success rate'},
        'totalEP': {'name': 'Expected Points', 'format': 'decimal1', 'description': 'Expected points added'},
      };
    }
  }

  Map<String, Map<String, dynamic>> _getRankFields() {
    return {
      'yds_rank': {'name': 'Yards Rank', 'format': 'integer', 'description': 'Yards rank (1 = best)'},
      'TD_rank': {'name': 'TD Rank', 'format': 'integer', 'description': 'TD rank (1 = best)'},
      'success_rank': {'name': 'Success Rank', 'format': 'integer', 'description': 'Success rate rank (1 = best)'},
      'EP_rank': {'name': 'EP Rank', 'format': 'integer', 'description': 'Expected points rank (1 = best)'},
    };
  }

  Future<void> _loadRankings() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final csvService = CSVRankingsService();
      final allRankings = await csvService.fetchRunOffenseRankings();
      
      // Filter by season
      final rankings = allRankings.where((ranking) {
        return _selectedSeason == 'All' || 
               ranking['season']?.toString() == _selectedSeason;
      }).toList();
      
      // Store original rankings
      _originalRankings = rankings.map((r) => Map<String, dynamic>.from(r)).toList();
      
      // Filter by tier if not 'All'
      List<Map<String, dynamic>> filteredRankings = rankings;
      if (_selectedTier != 'All') {
        final tierNum = int.parse(_selectedTier);
        filteredRankings = rankings.where((r) => 
          (r['tier'] == tierNum || r['runOffenseTier'] == tierNum)).toList();
      }
      
      // Apply filters if enabled
      if (_usingFilters) {
        filteredRankings = FilterService.applyFilters(filteredRankings, _currentFilter);
      }
      
      // Calculate percentiles for stat ranking
      final statFields = _statFields.keys.where((key) => 
        !['myRankNum', 'posteam', 'tier', 'season', 'runOffenseTier'].contains(key)
      ).toList();
      
      final percentiles = RankingCellShadingService.calculatePercentiles(filteredRankings, statFields);
      _percentileCache.clear();
      _percentileCache.addAll(percentiles);
      
      // Sort by default column
      _sortData(filteredRankings);
      
      setState(() {
        _rankings = filteredRankings;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load run offense rankings: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  void _sortData(List<Map<String, dynamic>> rankings) {
    rankings.sort((a, b) {
      dynamic aValue = a[_sortColumn];
      dynamic bValue = b[_sortColumn];
      
      if (aValue == null && bValue == null) return 0;
      if (aValue == null) return 1;
      if (bValue == null) return -1;
      
      int comparison;
      if (aValue is String && bValue is String) {
        comparison = aValue.compareTo(bValue);
      } else if (aValue is num && bValue is num) {
        comparison = aValue.compareTo(bValue);
      } else {
        comparison = aValue.toString().compareTo(bValue.toString());
      }
      
      return _sortAscending ? comparison : -comparison;
    });
  }

  void _sort(String column, bool ascending) {
    setState(() {
      _sortColumn = column;
      _sortAscending = ascending;
      _sortData(_rankings);
    });
  }

  void _toggleFilterPanel() {
    setState(() {
      _showFilterPanel = !_showFilterPanel;
    });
  }

  void _onFilterChanged(FilterQuery newFilter) {
    setState(() {
      _currentFilter = newFilter;
      _usingFilters = newFilter.hasActiveFilters;
    });
    _loadRankings();
  }

  int _getSortColumnIndex() {
    final baseColumns = ['myRankNum', 'posteam', 'tier'];
    final statFieldsToShow = _statFields.keys.where((key) => 
      !['myRankNum', 'posteam', 'tier', 'season', 'runOffenseTier'].contains(key)
    ).toList();
    
    baseColumns.addAll(statFieldsToShow);
    return baseColumns.indexOf(_sortColumn);
  }

  Color _getTierColor(int tier) {
    final colors = RankingService.getTierColors();
    return Color(colors[tier] ?? 0xFF9E9E9E);
  }

  String _formatStatValue(dynamic value, String format) {
    return RankingService.formatStatValue(value, format);
  }

  @override
  Widget build(BuildContext context) {
    final currentRouteName = ModalRoute.of(context)?.settings.name;
    
    return Scaffold(
      appBar: CustomAppBar(
        titleWidget: Row(
          children: [
            const Text('StickToTheModel', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(width: 20),
            Expanded(child: TopNavBarContent(currentRoute: currentRouteName)),
          ],
        ),
      ),
      drawer: const AppDrawer(),
      body: Stack(
        children: [
          _buildContent(),
          if (_showFilterPanel)
            Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              child: FilterPanel(
                currentQuery: _currentFilter,
                onFilterChanged: _onFilterChanged,
                onClose: _toggleFilterPanel,
                isVisible: _showFilterPanel,
                availableTeams: FilterService.getAvailableTeams(_originalRankings),
                availableSeasons: FilterService.getAvailableSeasons(_originalRankings),
                statFields: FilterService.getFilterableStats(_statFields),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red.shade400),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadRankings,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        _buildFiltersSection(),
        _buildTableHeader(),
        Expanded(child: _buildDataTable()),
      ],
    );
  }

  Widget _buildFiltersSection() {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: DropdownButtonFormField<String>(
              value: _selectedSeason,
              decoration: const InputDecoration(
                labelText: 'Season',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: _seasonOptions.map((season) {
                return DropdownMenuItem(value: season, child: Text(season));
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedSeason = value);
                  _loadRankings();
                }
              },
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: DropdownButtonFormField<String>(
              value: _selectedTier,
              decoration: const InputDecoration(
                labelText: 'Tier',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: _tierOptions.map((tier) {
                return DropdownMenuItem(value: tier, child: Text(tier));
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedTier = value);
                  _loadRankings();
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableHeader() {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Row(
        children: [
          Text(
            'Run Offense Rankings',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          // Filter button
          Container(
            margin: const EdgeInsets.only(right: 16),
            child: ElevatedButton.icon(
              onPressed: _toggleFilterPanel,
              icon: Icon(
                _showFilterPanel ? Icons.close : Icons.filter_list,
                size: 16,
              ),
              label: Text(_showFilterPanel ? 'Close' : 'Filter'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _usingFilters ? Colors.blue.shade600 : ThemeConfig.darkNavy,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
          ),
          // Toggle button for ranks vs raw stats
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildToggleButton('Raw Stats', !_showRanks, () {
                  setState(() {
                    _showRanks = false;
                    _updateStatFields();
                  });
                  _loadRankings();
                }),
                _buildToggleButton('Ranks', _showRanks, () {
                  setState(() {
                    _showRanks = true;
                    _updateStatFields();
                  });
                  _loadRankings();
                }),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${_rankings.length} teams',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.grey.shade600,
                ),
              ),
              if (_usingFilters)
                Text(
                  'Filters applied',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.blue.shade600,
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildToggleButton(String label, bool isActive, VoidCallback onPressed) {
    return InkWell(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? ThemeConfig.darkNavy : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.white : Colors.grey.shade700,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildDataTable() {
    if (_rankings.isEmpty) {
      return const Center(
        child: Text(
          'No run offense rankings found for the selected criteria.',
          style: TextStyle(fontSize: 16),
        ),
      );
    }

    return AnimationLimiter(
      child: SingleChildScrollView(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            sortColumnIndex: _getSortColumnIndex(),
            sortAscending: _sortAscending,
            columns: _buildDataColumns(),
            rows: _buildDataRows(),
            columnSpacing: 20,
            headingRowHeight: 56,
            dataRowMinHeight: 48,
            dataRowMaxHeight: 48,
          ),
        ),
      ),
    );
  }

  List<DataColumn> _buildDataColumns() {
    final columns = <DataColumn>[
      DataColumn(
        label: const Text('Rank'),
        onSort: (columnIndex, ascending) => _sort('myRankNum', ascending),
      ),
      DataColumn(
        label: const Text('Team'),
        onSort: (columnIndex, ascending) => _sort('posteam', ascending),
      ),
      DataColumn(
        label: const Text('Tier'),
        onSort: (columnIndex, ascending) => _sort('runOffenseTier', ascending),
      ),
    ];

    // Add stat columns
    final statFieldsToShow = _statFields.keys.where((key) => 
      !['myRankNum', 'posteam', 'tier', 'season', 'runOffenseTier'].contains(key)
    ).toList();
    
    for (final field in statFieldsToShow) {
      final statInfo = _statFields[field]!;
      columns.add(DataColumn(
        label: Tooltip(
          message: statInfo['description'],
          child: Text(statInfo['name']),
        ),
        numeric: true,
        onSort: (columnIndex, ascending) => _sort(field, ascending),
      ));
    }

    return columns;
  }

  List<DataRow> _buildDataRows() {
    return _rankings.asMap().entries.map((entry) {
      final index = entry.key;
      final team = entry.value;
      final tier = team['runOffenseTier'] ?? 1;
      final tierColor = _getTierColor(tier);

      final cells = <DataCell>[
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: tierColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '#${team['myRankNum'] ?? index + 1}',
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
              TeamLogoUtils.buildNFLTeamLogo(team['posteam'] ?? '', size: 20),
              const SizedBox(width: 8),
              Text(
                team['posteam'] ?? 'Unknown',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: tierColor,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              'Tier $tier',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
            ),
          ),
        ),
      ];

      // Add stat cells
      final statFieldsToShow = _statFields.keys.where((key) => 
        !['myRankNum', 'posteam', 'tier', 'season', 'runOffenseTier'].contains(key)
      ).toList();
      
      for (final field in statFieldsToShow) {
        final value = team[field];
        final statInfo = _statFields[field]!;
        
        // Use the cell shading service for stat cells
        cells.add(DataCell(
          RankingCellShadingService.buildDensityCell(
            column: field,
            value: value,
            rankValue: value,
            showRanks: _showRanks,
            percentileCache: _percentileCache,
            formatValue: (val, col) => _formatStatValue(val, statInfo['format']),
            width: double.infinity,
            height: 48,
          ),
        ));
      }

      return DataRow(
        cells: cells,
        color: WidgetStateProperty.resolveWith<Color?>(
          (Set<WidgetState> states) {
            if (states.contains(WidgetState.hovered)) {
              return tierColor.withValues(alpha: 0.1);
            }
            final theme = Theme.of(context);
            final even = theme.colorScheme.surfaceContainerLow;
            final odd = theme.colorScheme.surface;
            return index % 2 == 0 ? even : odd;
          },
        ),
      );
    }).toList();
  }
}