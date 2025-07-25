import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../widgets/common/app_drawer.dart';
import '../../widgets/common/custom_app_bar.dart';
import '../../widgets/common/top_nav_bar.dart';
import '../../utils/team_logo_utils.dart';
import '../../utils/theme_config.dart';
import '../../utils/theme_aware_colors.dart';
import '../../utils/seo_helper.dart';
import '../../services/rankings/ranking_service.dart';
import '../../services/rankings/ranking_cell_shading_service.dart';
import '../../services/rankings/ranking_calculation_service.dart';
import '../../services/rankings/filter_service.dart';
import '../../models/custom_weight_config.dart';
import '../../widgets/rankings/weight_adjustment_panel.dart';
import '../../widgets/rankings/filter_panel.dart';

class RBRankingsScreen extends StatefulWidget {
  const RBRankingsScreen({super.key});

  @override
  State<RBRankingsScreen> createState() => _RBRankingsScreenState();
}

class _RBRankingsScreenState extends State<RBRankingsScreen> {
  List<Map<String, dynamic>> _rbRankings = [];
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
  late Map<String, Map<String, dynamic>> _rbStatFields;
  late CustomWeightConfig _currentWeights;
  late CustomWeightConfig _defaultWeights;
  late FilterQuery _currentFilter;
  List<Map<String, dynamic>> _filteredRankings = [];
  
  final Map<String, Map<String, double>> _percentileCache = {};

  @override
  void initState() {
    super.initState();
    
    // Update SEO meta tags for RB Rankings page
    WidgetsBinding.instance.addPostFrameCallback((_) {
      SEOHelper.updateForRBRankings();
    });
    
    _seasonOptions = RankingService.getSeasonOptions();
    _tierOptions = RankingService.getTierOptions();
    _defaultWeights = RankingCalculationService.getDefaultWeights('rb');
    _currentWeights = _defaultWeights;
    _currentFilter = const FilterQuery();
    _updateStatFields();
    _loadRBRankings();
  }
  
  void _updateStatFields() {
    _rbStatFields = RankingService.getStatFields('rb', showRanks: _showRanks);
  }

  Future<void> _loadRBRankings() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final rankings = await RankingService.loadRankings(
        position: 'rb',
        season: _selectedSeason,
        tier: _selectedTier,
      );
      
      // Store original rankings
      _originalRankings = rankings.map((r) => Map<String, dynamic>.from(r)).toList();
      
      // Apply custom weights if enabled
      List<Map<String, dynamic>> processedRankings;
      if (_usingCustomWeights) {
        processedRankings = RankingCalculationService.calculateCustomRBRankings(
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
      final statFields = _rbStatFields.keys.where((key) => 
        !['myRankNum', 'player_name', 'posteam', 'tier', 'season', 'player_id', 'position', 'team', 'receiver_player_id', 'receiver_player_name', 'player_position', 'fantasy_player_id', 'qbTier', 'rbTier'].contains(key)
      ).toList();
      
      final percentiles = RankingCellShadingService.calculatePercentiles(filteredRankings, statFields);
      _percentileCache.clear();
      _percentileCache.addAll(percentiles);
      
      // Sort by default column
      _sortData(filteredRankings);
      
      setState(() {
        _rbRankings = filteredRankings;
        _filteredRankings = filteredRankings;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load RB rankings: ${e.toString()}';
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
      _sortData(_rbRankings);
    });
  }

  void _onWeightsChanged(CustomWeightConfig newWeights) {
    // Do all calculations and state updates in a single setState to prevent race conditions
    if (_originalRankings.isNotEmpty) {
      final customRankings = RankingCalculationService.calculateCustomRBRankings(
        _originalRankings,
        newWeights,
      );
      
      // Apply filters if enabled
      final processedRankings = _usingFilters 
          ? FilterService.applyFilters(customRankings, _currentFilter)
          : customRankings;
      
      // Update percentiles for new rankings
      final statFields = _rbStatFields.keys.where((key) => 
        !['myRankNum', 'player_name', 'posteam', 'tier', 'season', 'player_id', 'position', 'team', 'receiver_player_id', 'receiver_player_name', 'player_position', 'fantasy_player_id', 'qbTier', 'rbTier'].contains(key)
      ).toList();
      
      final percentiles = RankingCellShadingService.calculatePercentiles(processedRankings, statFields);
      
      // Sort by current column
      _sortData(processedRankings);
      
      setState(() {
        _currentWeights = newWeights;
        _usingCustomWeights = true;
        _percentileCache.clear();
        _percentileCache.addAll(percentiles);
        _rbRankings = processedRankings;
        _filteredRankings = processedRankings;
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
      final statFields = _rbStatFields.keys.where((key) => 
        !['myRankNum', 'player_name', 'posteam', 'tier', 'season', 'player_id', 'position', 'team', 'receiver_player_id', 'receiver_player_name', 'player_position', 'fantasy_player_id', 'qbTier', 'rbTier'].contains(key)
      ).toList();
      
      final percentiles = RankingCellShadingService.calculatePercentiles(processedRankings, statFields);
      
      // Sort by current column
      _sortData(processedRankings);
      
      setState(() {
        _currentWeights = _defaultWeights;
        _usingCustomWeights = false;
        _percentileCache.clear();
        _percentileCache.addAll(percentiles);
        _rbRankings = processedRankings;
        _filteredRankings = processedRankings;
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
        baseRankings = RankingCalculationService.calculateCustomRBRankings(
          _originalRankings,
          _currentWeights,
        );
      } else {
        baseRankings = _originalRankings;
      }
      
      // Apply filters
      final filteredRankings = FilterService.applyFilters(baseRankings, newFilter);
      
      // Update percentiles
      final statFields = _rbStatFields.keys.where((key) => 
        !['myRankNum', 'player_name', 'posteam', 'tier', 'season', 'player_id', 'position', 'team', 'receiver_player_id', 'receiver_player_name', 'player_position', 'fantasy_player_id', 'qbTier', 'rbTier'].contains(key)
      ).toList();
      
      final percentiles = RankingCellShadingService.calculatePercentiles(filteredRankings, statFields);
      _percentileCache.clear();
      _percentileCache.addAll(percentiles);
      
      // Sort by current column
      _sortData(filteredRankings);
      
      setState(() {
        _rbRankings = filteredRankings;
        _filteredRankings = filteredRankings;
      });
    }
  }

  int _getSortColumnIndex() {
    final baseColumns = ['myRankNum', 'player_name', 'posteam', 'tier'];
    if (_selectedSeason == 'All Seasons') {
      baseColumns.add('season');
    }
    final statFieldsToShow = _rbStatFields.keys.where((key) => 
      !['myRankNum', 'player_name', 'posteam', 'tier', 'season', 'player_id', 'position', 'team', 'receiver_player_id', 'receiver_player_name', 'player_position', 'fantasy_player_id', 'qbTier', 'rbTier'].contains(key)
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
                position: 'rb',
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
                statFields: FilterService.getFilterableStats(_rbStatFields),
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
              onPressed: _loadRBRankings,
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
            color: Colors.grey.withOpacity(0.1),
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
                  _loadRBRankings();
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
                  _loadRBRankings();
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
            'Running Back Rankings',
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
                  _loadRBRankings(); // Reload to recalculate percentiles
                }),
                _buildToggleButton('Ranks', _showRanks, () {
                  setState(() {
                    _showRanks = true;
                    _updateStatFields();
                  });
                  _loadRBRankings(); // Reload to recalculate percentiles
                }),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${_rbRankings.length} players',
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
    if (_rbRankings.isEmpty) {
      return const Center(
        child: Text(
          'No RB rankings found for the selected criteria.',
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
            dataRowHeight: 48,
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
    final statFieldsToShow = _rbStatFields.keys.where((key) => 
      !['myRankNum', 'rank_number', 'player_name', 'receiver_player_name', 'posteam', 'team', 'tier', 'qb_tier', 'qbTier', 'season', 'numGames', 'games', 'player_id', 'position', 'receiver_player_id', 'player_position', 'fantasy_player_id', 'rbTier'].contains(key)
    ).toList();
    
    // The stat fields are already filtered by the service based on _showRanks
    final fieldsToDisplay = statFieldsToShow;
    
    for (final field in fieldsToDisplay) {
      final statInfo = _rbStatFields[field]!;
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
    return _rbRankings.asMap().entries.map((entry) {
      final index = entry.key;
      final rb = entry.value;
      final tier = rb['tier'] ?? 1;
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
              '#${rb['myRankNum'] ?? index + 1}',
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
              TeamLogoUtils.buildNFLTeamLogo(rb['posteam'] ?? '', size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  rb['fantasy_player_name'] ?? rb['player_name'] ?? 'Unknown',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
        DataCell(Text(rb['posteam'] ?? '')),
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
        cells.add(DataCell(Text(rb['season']?.toString() ?? '')));
      }

      // Add stat cells - skip base fields that are already added
      final statFieldsToShow = _rbStatFields.keys.where((key) => 
        !['myRankNum', 'rank_number', 'player_name', 'receiver_player_name', 'posteam', 'team', 'tier', 'qb_tier', 'qbTier', 'season', 'numGames', 'games', 'player_id', 'position', 'receiver_player_id', 'player_position', 'fantasy_player_id', 'rbTier'].contains(key)
      ).toList();
      
      // The stat fields are already filtered by the service based on _showRanks
      final fieldsToDisplay = statFieldsToShow;
      
      for (final field in fieldsToDisplay) {
        final value = rb[field];
        final statInfo = _rbStatFields[field]!;
        
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
              return tierColor.withOpacity(0.1);
            }
            return index % 2 == 0 ? Colors.grey.shade50 : Colors.white;
          },
        ),
      );
    }).toList();
  }
} 