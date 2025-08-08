import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

import '../../widgets/common/app_drawer.dart';
import '../../widgets/common/custom_app_bar.dart';
import '../../widgets/common/top_nav_bar.dart';
import '../../utils/team_logo_utils.dart';
import '../../utils/theme_config.dart';
import '../../services/rankings/csv_rankings_service.dart';
import '../../services/rankings/ranking_cell_shading_service.dart';
import '../../services/rankings/ranking_service.dart';
import '../../services/rankings/ranking_calculation_service.dart';
import '../../services/rankings/filter_service.dart';
import '../../models/custom_weight_config.dart';
import '../../widgets/rankings/weight_adjustment_panel.dart';
import '../../widgets/rankings/filter_panel.dart';

class EdgeRankingsScreen extends StatefulWidget {
  const EdgeRankingsScreen({super.key});

  @override
  State<EdgeRankingsScreen> createState() => _EdgeRankingsScreenState();
}

class _EdgeRankingsScreenState extends State<EdgeRankingsScreen> {
  List<Map<String, dynamic>> _edgeRankings = [];
  List<Map<String, dynamic>> _originalRankings = [];
  bool _isLoading = true;
  String? _error;
  String _selectedSeason = '2024';
  String _selectedTier = 'All';
  bool _showRanks = false;
  bool _showWeightPanel = false;
  bool _showFilterPanel = false;
  bool _usingCustomWeights = false;
  bool _usingFilters = false;
  
  // Sorting state
  String _sortColumn = 'ranking';
  bool _sortAscending = true;
  
  late final List<String> _seasonOptions;
  late final List<String> _tierOptions;
  late Map<String, Map<String, dynamic>> _edgeStatFields;
  late CustomWeightConfig _currentWeights;
  late CustomWeightConfig _defaultWeights;
  late FilterQuery _currentFilter;
  
  final Map<String, Map<String, double>> _percentileCache = {};

  @override
  void initState() {
    super.initState();
    _seasonOptions = ['2024', '2023', '2022', '2021', 'All'];
    _tierOptions = ['All', '1', '2', '3', '4', '5'];
    _defaultWeights = RankingCalculationService.getDefaultWeights('edge');
    _currentWeights = _defaultWeights;
    _currentFilter = const FilterQuery();
    _updateStatFields();
    _loadEdgeRankings();
  }
  
  void _updateStatFields() {
    _edgeStatFields = RankingService.getStatFields('edge', showRanks: _showRanks);
  }

  Future<void> _loadEdgeRankings() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final csvService = CSVRankingsService();
      final allRankings = await csvService.fetchEdgeRankings();
      
      // Filter by season and tier
      final rankings = allRankings.where((ranking) {
        bool matchesSeason = _selectedSeason == 'All' || 
                            ranking['season']?.toString() == _selectedSeason;
        bool matchesTier = _selectedTier == 'All' || 
                          (ranking['tier']?.toString() == _selectedTier);
        return matchesSeason && matchesTier;
      }).toList();
      
      // Add rank fields if they're missing
      for (var ranking in rankings) {
        // Ensure myRankNum exists
        if (ranking['myRankNum'] == null && ranking['ranking'] != null) {
          ranking['myRankNum'] = ranking['ranking'];
        }
      }
      
      // Compute rank fields for stats
      if (rankings.isNotEmpty) {
        // Sort by each stat and assign ranks
        final statFields = ['sacks', 'qb_hits', 'pressure_rate', 'tfls', 'forced_fumbles'];
        
        for (final field in statFields) {
          // Map field names to their rank field names
          final rankFieldName = field == 'pressure_rate' ? 'pressure_rank' : '${field}_rank';
          
          // Create a list of values with their indices
          final valuesWithIndex = <Map<String, dynamic>>[];
          for (int i = 0; i < rankings.length; i++) {
            final value = rankings[i][field];
            double numValue = 0.0;
            if (value != null) {
              if (value is num) {
                numValue = value.toDouble();
              } else if (value is String) {
                numValue = double.tryParse(value) ?? 0.0;
              }
            }
            valuesWithIndex.add({
              'index': i,
              'value': numValue,
            });
          }
          
          // Sort by value (descending - higher is better)
          valuesWithIndex.sort((a, b) {
            final aVal = a['value'] as double;
            final bVal = b['value'] as double;
            return bVal.compareTo(aVal);
          });
          
          // Assign ranks with tie handling
          for (int i = 0; i < valuesWithIndex.length; i++) {
            final currentValue = valuesWithIndex[i]['value'] as double;
            int rank = i + 1;
            
            // Check for ties with previous values
            if (i > 0) {
              final prevValue = valuesWithIndex[i - 1]['value'] as double;
              if ((currentValue - prevValue).abs() < 0.001) {
                // Same value, use same rank as previous
                final prevIndex = valuesWithIndex[i - 1]['index'] as int;
                rank = rankings[prevIndex][rankFieldName] as int;
              }
            }
            
            final originalIndex = valuesWithIndex[i]['index'] as int;
            rankings[originalIndex][rankFieldName] = rank;
          }
        }
      }
      
      // Store original rankings
      _originalRankings = rankings.map((r) => Map<String, dynamic>.from(r)).toList();
      
      // Apply custom weights if enabled
      List<Map<String, dynamic>> processedRankings;
      if (_usingCustomWeights) {
        processedRankings = RankingCalculationService.calculateCustomEdgeRankings(
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
      final statFields = _edgeStatFields.keys.where((key) => 
        !['myRankNum', 'player_name', 'team', 'tier', 'season', 'player_id', 'position', 'name', 'ranking'].contains(key)
      ).toList();
      
      final percentiles = RankingCellShadingService.calculatePercentiles(filteredRankings, statFields);
      _percentileCache.clear();
      _percentileCache.addAll(percentiles);
      
      // Sort by default column
      _sortData(filteredRankings);
      
      setState(() {
        _edgeRankings = filteredRankings;
        _isLoading = false;
      });

    } catch (e) {
      setState(() {
        _error = e.toString();
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
      _sortData(_edgeRankings);
    });
  }

  int _getSortColumnIndex() {
    final baseColumns = ['ranking', 'name', 'team', 'tier'];
    if (_selectedSeason == 'All') {
      baseColumns.add('season');
    }
    final statFieldsToShow = _edgeStatFields.keys.where((key) => 
      !['myRankNum', 'player_name', 'team', 'tier', 'season', 'player_id', 'position', 'name', 'ranking'].contains(key)
    ).toList();
    
    final fieldsToDisplay = statFieldsToShow;
    
    baseColumns.addAll(fieldsToDisplay);
    return baseColumns.indexOf(_sortColumn);
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
                position: 'edge',
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
                statFields: FilterService.getFilterableStats(_edgeStatFields),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading EDGE rankings...'),
          ],
        ),
      );
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
              onPressed: _loadEdgeRankings,
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
                  _loadEdgeRankings();
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
                  _loadEdgeRankings();
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
            'EDGE Rankings',
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
                  _loadEdgeRankings();
                }),
                _buildToggleButton('Ranks', _showRanks, () {
                  setState(() {
                    _showRanks = true;
                    _updateStatFields();
                  });
                  _loadEdgeRankings();
                }),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${_edgeRankings.length} players',
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
    if (_edgeRankings.isEmpty) {
      return const Center(
        child: Text(
          'No EDGE rankings found for the selected criteria.',
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
        onSort: (columnIndex, ascending) => _sort('ranking', ascending),
      ),
      DataColumn(
        label: const Text('Player'),
        onSort: (columnIndex, ascending) => _sort('name', ascending),
      ),
      DataColumn(
        label: const Text('Team'),
        onSort: (columnIndex, ascending) => _sort('team', ascending),
      ),
      DataColumn(
        label: const Text('Tier'),
        onSort: (columnIndex, ascending) => _sort('tier', ascending),
      ),
    ];

    // Add season column if showing all seasons
    if (_selectedSeason == 'All') {
      columns.add(DataColumn(
        label: const Text('Season'),
        onSort: (columnIndex, ascending) => _sort('season', ascending),
      ));
    }

    // Add stat columns - skip base fields that are already added
    final statFieldsToShow = _edgeStatFields.keys.where((key) => 
      !['myRankNum', 'player_name', 'team', 'tier', 'season', 'player_id', 'position', 'name', 'ranking'].contains(key)
    ).toList();
    
    final fieldsToDisplay = statFieldsToShow;
    
    for (final field in fieldsToDisplay) {
      final statInfo = _edgeStatFields[field]!;
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
    return _edgeRankings.asMap().entries.map((entry) {
      final index = entry.key;
      final edge = entry.value;
      final tierValue = edge['tier'] ?? 1;
      final tier = tierValue is int ? tierValue : int.tryParse(tierValue.toString()) ?? 1;
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
              '#${edge['ranking'] ?? index + 1}',
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
              TeamLogoUtils.buildNFLTeamLogo(edge['team'] ?? '', size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  edge['name'] ?? 'Unknown',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
        DataCell(Text(edge['team'] ?? '')),
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
      if (_selectedSeason == 'All') {
        cells.add(DataCell(Text(edge['season']?.toString() ?? '')));
      }

      // Add stat cells - skip base fields that are already added
      final statFieldsToShow = _edgeStatFields.keys.where((key) => 
        !['myRankNum', 'player_name', 'team', 'tier', 'season', 'player_id', 'position', 'name', 'ranking'].contains(key)
      ).toList();
      
      final fieldsToDisplay = statFieldsToShow;
      
      for (final field in fieldsToDisplay) {
        final value = edge[field];
        final statInfo = _edgeStatFields[field]!;
        
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
            return index % 2 == 0 ? Colors.grey.shade50 : Colors.white;
          },
        ),
      );
    }).toList();
  }

  Color _getTierColor(int tier) {
    final colors = RankingService.getTierColors();
    return Color(colors[tier] ?? 0xFF9E9E9E);
  }

  String _formatStatValue(dynamic value, String format) {
    return RankingService.formatStatValue(value, format);
  }

  void _onWeightsChanged(CustomWeightConfig newWeights) {
    if (_originalRankings.isNotEmpty) {
      final customRankings = RankingCalculationService.calculateCustomEdgeRankings(
        _originalRankings,
        newWeights,
      );
      
      final processedRankings = _usingFilters 
          ? FilterService.applyFilters(customRankings, _currentFilter)
          : customRankings;
      
      final statFields = _edgeStatFields.keys.where((key) => 
        !['myRankNum', 'player_name', 'team', 'tier', 'season', 'player_id', 'position', 'name', 'ranking'].contains(key)
      ).toList();
      
      final percentiles = RankingCellShadingService.calculatePercentiles(processedRankings, statFields);
      
      _sortData(processedRankings);
      
      setState(() {
        _currentWeights = newWeights;
        _usingCustomWeights = true;
        _percentileCache.clear();
        _percentileCache.addAll(percentiles);
        _edgeRankings = processedRankings;
      });
    } else {
      setState(() {
        _currentWeights = newWeights;
        _usingCustomWeights = true;
      });
    }
  }

  void _resetToDefaultWeights() {
    if (_originalRankings.isNotEmpty) {
      final processedRankings = _usingFilters 
          ? FilterService.applyFilters(_originalRankings, _currentFilter)
          : _originalRankings;
      
      final statFields = _edgeStatFields.keys.where((key) => 
        !['myRankNum', 'player_name', 'team', 'tier', 'season', 'player_id', 'position', 'name', 'ranking'].contains(key)
      ).toList();
      
      final percentiles = RankingCellShadingService.calculatePercentiles(processedRankings, statFields);
      
      _sortData(processedRankings);
      
      setState(() {
        _currentWeights = _defaultWeights;
        _usingCustomWeights = false;
        _percentileCache.clear();
        _percentileCache.addAll(percentiles);
        _edgeRankings = processedRankings;
      });
    } else {
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
        _showFilterPanel = false;
      }
    });
  }

  void _toggleFilterPanel() {
    setState(() {
      _showFilterPanel = !_showFilterPanel;
      if (_showFilterPanel) {
        _showWeightPanel = false;
      }
    });
  }

  void _onFilterChanged(FilterQuery newFilter) {
    setState(() {
      _currentFilter = newFilter;
      _usingFilters = newFilter.hasActiveFilters;
    });
    
    if (_originalRankings.isNotEmpty) {
      List<Map<String, dynamic>> baseRankings;
      if (_usingCustomWeights) {
        baseRankings = RankingCalculationService.calculateCustomEdgeRankings(
          _originalRankings,
          _currentWeights,
        );
      } else {
        baseRankings = _originalRankings;
      }
      
      final filteredRankings = FilterService.applyFilters(baseRankings, newFilter);
      
      final statFields = _edgeStatFields.keys.where((key) => 
        !['myRankNum', 'player_name', 'team', 'tier', 'season', 'player_id', 'position', 'name', 'ranking'].contains(key)
      ).toList();
      
      final percentiles = RankingCellShadingService.calculatePercentiles(filteredRankings, statFields);
      _percentileCache.clear();
      _percentileCache.addAll(percentiles);
      
      _sortData(filteredRankings);
      
      setState(() {
        _edgeRankings = filteredRankings;
      });
    }
  }
}