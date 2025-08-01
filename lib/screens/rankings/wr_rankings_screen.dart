import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

import '../../widgets/common/app_drawer.dart';
import '../../widgets/common/custom_app_bar.dart';
import '../../widgets/common/top_nav_bar.dart';
import '../../utils/team_logo_utils.dart';
import '../../utils/theme_config.dart';
import '../../utils/seo_helper.dart';
import '../../services/rankings/ranking_service.dart';
import '../../services/rankings/ranking_cell_shading_service.dart';
import '../../services/rankings/ranking_calculation_service.dart';
import '../../services/rankings/filter_service.dart';
import '../../models/custom_weight_config.dart';
import '../../widgets/rankings/weight_adjustment_panel.dart';
import '../../widgets/rankings/filter_panel.dart';

class WRRankingsScreen extends StatefulWidget {
  const WRRankingsScreen({super.key});

  @override
  State<WRRankingsScreen> createState() => _WRRankingsScreenState();
}

class _WRRankingsScreenState extends State<WRRankingsScreen> {
  List<Map<String, dynamic>> _wrRankings = [];
  List<Map<String, dynamic>> _originalRankings = []; // Store original rankings
  bool _isLoading = true;
  String? _error;
  String _selectedSeason = '2024';
  String _selectedTier = 'All';
  bool _showRanks = false; // Toggle between showing ranks vs raw stats
  bool _showWeightPanel = false; // Toggle weight adjustment panel
  bool _showFilterPanel = false; // Toggle filter panel
  bool _usingCustomWeights = false; // Track if custom weights are applied
  bool _usingFilters = false; // Track if filters are applied
  
  // Sorting state - default to rank ascending (rank 1 first)
  String _sortColumn = 'myRankNum';
  bool _sortAscending = true;
  
  late final List<String> _seasonOptions;
  late final List<String> _tierOptions;
  late Map<String, Map<String, dynamic>> _wrStatFields;
  late CustomWeightConfig _currentWeights;
  late CustomWeightConfig _defaultWeights;
  late FilterQuery _currentFilter;
  
  final Map<String, Map<String, double>> _percentileCache = {};

  @override
  void initState() {
    super.initState();
    
    // Update SEO meta tags for WR Rankings page
    WidgetsBinding.instance.addPostFrameCallback((_) {
      SEOHelper.updateForWRRankings();
    });
    
    _seasonOptions = RankingService.getSeasonOptions();
    _tierOptions = RankingService.getTierOptions();
    _defaultWeights = RankingCalculationService.getDefaultWeights('wr');
    _currentWeights = _defaultWeights;
    _currentFilter = const FilterQuery();
    _updateStatFields();
    _loadWRRankings();
  }
  
  void _updateStatFields() {
    _wrStatFields = RankingService.getStatFields('wr', showRanks: _showRanks);
  }

  Future<void> _loadWRRankings() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final rankings = await RankingService.loadRankings(
        position: 'wr',
        season: _selectedSeason,
        tier: _selectedTier,
      );
      
      // Store original rankings
      _originalRankings = rankings.map((r) => Map<String, dynamic>.from(r)).toList();
      
      // Apply custom weights if enabled
      List<Map<String, dynamic>> processedRankings;
      if (_usingCustomWeights) {
        processedRankings = RankingCalculationService.calculateCustomWRRankings(
          _originalRankings,
          _currentWeights,
        );
      } else {
        processedRankings = rankings;
      }
      
      // Apply filters if enabled
      List<Map<String, dynamic>> filteredRankings;
      if (_usingFilters) {
        filteredRankings = FilterService.applyFilters(processedRankings, _currentFilter);
      } else {
        filteredRankings = processedRankings;
      }
      
      // Calculate percentiles for stat ranking
      final statFields = _wrStatFields.keys.where((key) => 
        !['myRankNum', 'player_name', 'posteam', 'tier', 'season', 'player_id', 'position', 'team', 'receiver_player_id', 'receiver_player_name', 'player_position', 'fantasy_player_id', 'wrTier'].contains(key)
      ).toList();
      
      final percentiles = RankingCellShadingService.calculatePercentiles(filteredRankings, statFields);
      _percentileCache.clear();
      _percentileCache.addAll(percentiles);
      
      // Sort by default column
      _sortData(filteredRankings);
      
      setState(() {
        _wrRankings = filteredRankings;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load WR rankings: ${e.toString()}';
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
      _sortData(_wrRankings);
    });
  }

  void _onWeightsChanged(CustomWeightConfig newWeights) {
    // Do all calculations and state updates in a single setState to prevent race conditions
    if (_originalRankings.isNotEmpty) {
      final customRankings = RankingCalculationService.calculateCustomWRRankings(
        _originalRankings,
        newWeights,
      );
      
      // Apply filters if enabled
      final processedRankings = _usingFilters 
          ? FilterService.applyFilters(customRankings, _currentFilter)
          : customRankings;
      
      // Update percentiles for new rankings
      final statFields = _wrStatFields.keys.where((key) => 
        !['myRankNum', 'player_name', 'posteam', 'tier', 'season', 'player_id', 'position', 'team', 'receiver_player_id', 'receiver_player_name', 'player_position', 'fantasy_player_id', 'wrTier'].contains(key)
      ).toList();
      
      final percentiles = RankingCellShadingService.calculatePercentiles(processedRankings, statFields);
      
      // Sort by current column
      _sortData(processedRankings);
      
      setState(() {
        _currentWeights = newWeights;
        _usingCustomWeights = true;
        _percentileCache.clear();
        _percentileCache.addAll(percentiles);
        _wrRankings = processedRankings;
      });
    } else {
      // If no rankings loaded, just update the weights
      setState(() {
        _currentWeights = newWeights;
        _usingCustomWeights = true;
      });
    }
  }

  void _resetToDefaultWeights() {
    // Do all calculations and state updates in a single setState to prevent race conditions
    if (_originalRankings.isNotEmpty) {
      // Apply filters if enabled
      final processedRankings = _usingFilters 
          ? FilterService.applyFilters(_originalRankings, _currentFilter)
          : _originalRankings;
      
      // Update percentiles for original rankings
      final statFields = _wrStatFields.keys.where((key) => 
        !['myRankNum', 'player_name', 'posteam', 'tier', 'season', 'player_id', 'position', 'team', 'receiver_player_id', 'receiver_player_name', 'player_position', 'fantasy_player_id', 'wrTier'].contains(key)
      ).toList();
      
      final percentiles = RankingCellShadingService.calculatePercentiles(processedRankings, statFields);
      
      // Sort by current column
      _sortData(processedRankings);
      
      setState(() {
        _currentWeights = _defaultWeights;
        _usingCustomWeights = false;
        _percentileCache.clear();
        _percentileCache.addAll(percentiles);
        _wrRankings = processedRankings;
      });
    } else {
      // If no rankings loaded, just reset the weights
      setState(() {
        _currentWeights = _defaultWeights;
        _usingCustomWeights = false;
      });
    }
  }

  void _toggleWeightPanel() {
    setState(() {
      _showWeightPanel = !_showWeightPanel;
      if (_showWeightPanel) {
        _showFilterPanel = false; // Close filter panel when opening weight panel
      }
    });
  }

  void _toggleFilterPanel() {
    setState(() {
      _showFilterPanel = !_showFilterPanel;
      if (_showFilterPanel) {
        _showWeightPanel = false; // Close weight panel when opening filter panel
      }
    });
  }

  void _onFilterChanged(FilterQuery newFilter) {
    setState(() {
      _currentFilter = newFilter;
      _usingFilters = newFilter.hasActiveFilters;
    });
    
    // Apply filter to current rankings
    if (_originalRankings.isNotEmpty) {
      // Start with appropriate base rankings (custom weighted or original)
      List<Map<String, dynamic>> baseRankings;
      if (_usingCustomWeights) {
        baseRankings = RankingCalculationService.calculateCustomWRRankings(
          _originalRankings,
          _currentWeights,
        );
      } else {
        baseRankings = _originalRankings;
      }
      
      // Apply filters
      final filteredRankings = FilterService.applyFilters(baseRankings, newFilter);
      
      // Update percentiles
      final statFields = _wrStatFields.keys.where((key) => 
        !['myRankNum', 'player_name', 'posteam', 'tier', 'season', 'player_id', 'position', 'team', 'receiver_player_id', 'receiver_player_name', 'player_position', 'fantasy_player_id', 'wrTier'].contains(key)
      ).toList();
      
      final percentiles = RankingCellShadingService.calculatePercentiles(filteredRankings, statFields);
      _percentileCache.clear();
      _percentileCache.addAll(percentiles);
      
      // Sort by current column
      _sortData(filteredRankings);
      
      setState(() {
        _wrRankings = filteredRankings;
      });
    }
  }

  int _getSortColumnIndex() {
    final baseColumns = ['myRankNum', 'player_name', 'posteam', 'tier'];
    if (_selectedSeason == 'All Seasons') {
      baseColumns.add('season');
    }
    final statFieldsToShow = _wrStatFields.keys.where((key) => 
      !['myRankNum', 'player_name', 'posteam', 'tier', 'season', 'player_id', 'position', 'team', 'receiver_player_id', 'receiver_player_name', 'player_position', 'fantasy_player_id', 'wrTier'].contains(key)
    ).toList();
    
    // The stat fields are already filtered by the service based on _showRanks
    final fieldsToDisplay = statFieldsToShow;
    
    baseColumns.addAll(fieldsToDisplay);
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
          if (_showWeightPanel)
            Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              child: WeightAdjustmentPanel(
                position: 'wr',
                currentWeights: _currentWeights,
                onWeightsChanged: _onWeightsChanged,
                onReset: _resetToDefaultWeights,
                onClose: _toggleWeightPanel,
                isVisible: _showWeightPanel,
              ),
            ),
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
                statFields: FilterService.getFilterableStats(_wrStatFields),
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
              onPressed: _loadWRRankings,
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
                  _loadWRRankings();
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
                  _loadWRRankings();
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
            'Wide Receiver Rankings',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          // Filter button
          Container(
            margin: const EdgeInsets.only(right: 8),
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
          // Customize Rankings button
          Container(
            margin: const EdgeInsets.only(right: 16),
            child: ElevatedButton.icon(
              onPressed: _toggleWeightPanel,
              icon: Icon(
                _showWeightPanel ? Icons.close : Icons.tune,
                size: 16,
              ),
              label: Text(_showWeightPanel ? 'Close' : 'Customize'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _usingCustomWeights ? Colors.blue.shade600 : ThemeConfig.darkNavy,
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
                  _loadWRRankings(); // Reload to recalculate percentiles
                }),
                _buildToggleButton('Ranks', _showRanks, () {
                  setState(() {
                    _showRanks = true;
                    _updateStatFields();
                  });
                  _loadWRRankings(); // Reload to recalculate percentiles
                }),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${_wrRankings.length} players',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.grey.shade600,
                ),
              ),
              if (_usingCustomWeights)
                Text(
                  'Custom weights applied',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.blue.shade600,
                    fontWeight: FontWeight.bold,
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
    if (_wrRankings.isEmpty) {
      return const Center(
        child: Text(
          'No WR rankings found for the selected criteria.',
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
        label: const Text('Player'),
        onSort: (columnIndex, ascending) => _sort('player_name', ascending),
      ),
      DataColumn(
        label: const Text('Team'),
        onSort: (columnIndex, ascending) => _sort('posteam', ascending),
      ),
      DataColumn(
        label: const Text('Tier'),
        onSort: (columnIndex, ascending) => _sort('tier', ascending),
      ),
    ];

    // Add season column if showing all seasons
    if (_selectedSeason == 'All Seasons') {
      columns.add(DataColumn(
        label: const Text('Season'),
        onSort: (columnIndex, ascending) => _sort('season', ascending),
      ));
    }

    // Add stat columns - skip base fields that are already added
    final statFieldsToShow = _wrStatFields.keys.where((key) => 
      !['myRankNum', 'rank_number', 'player_name', 'receiver_player_name', 'posteam', 'team', 'tier', 'wr_tier', 'wrTier', 'season', 'numGames', 'games', 'player_id', 'position', 'receiver_player_id', 'player_position', 'fantasy_player_id'].contains(key)
    ).toList();
    
    // The stat fields are already filtered by the service based on _showRanks
    final fieldsToDisplay = statFieldsToShow;
    
    for (final field in fieldsToDisplay) {
      final statInfo = _wrStatFields[field]!;
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
    return _wrRankings.asMap().entries.map((entry) {
      final index = entry.key;
      final wr = entry.value;
      final tier = wr['tier'] ?? wr['wrTier'] ?? 1;
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
              '#${wr['myRankNum'] ?? index + 1}',
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
              TeamLogoUtils.buildNFLTeamLogo(wr['posteam'] ?? '', size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  wr['fantasy_player_name'] ?? wr['player_name'] ?? wr['receiver_player_name'] ?? 'Unknown',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
        DataCell(Text(wr['posteam'] ?? '')),
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

      // Add season cell if showing all seasons
      if (_selectedSeason == 'All Seasons') {
        cells.add(DataCell(Text(wr['season']?.toString() ?? '')));
      }

      // Add stat cells - skip base fields that are already added
      final statFieldsToShow = _wrStatFields.keys.where((key) => 
        !['myRankNum', 'rank_number', 'player_name', 'receiver_player_name', 'posteam', 'team', 'tier', 'wr_tier', 'wrTier', 'season', 'numGames', 'games', 'player_id', 'position', 'receiver_player_id', 'player_position', 'fantasy_player_id'].contains(key)
      ).toList();
      
      // The stat fields are already filtered by the service based on _showRanks
      final fieldsToDisplay = statFieldsToShow;
      
      for (final field in fieldsToDisplay) {
        final value = wr[field];
        final statInfo = _wrStatFields[field]!;
        
        // Use the cell shading service for stat cells
        cells.add(DataCell(
          RankingCellShadingService.buildDensityCell(
            column: field,
            value: value,
            rankValue: value, // For rank fields, the value IS the rank
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
            return index % 2 == 0 ? Colors.grey.shade50 : Colors.white;
          },
        ),
      );
    }).toList();
  }
}