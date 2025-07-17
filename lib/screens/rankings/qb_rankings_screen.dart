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
import '../../services/rankings/ranking_service.dart';
import '../../services/rankings/ranking_cell_shading_service.dart';

class QBRankingsScreen extends StatefulWidget {
  const QBRankingsScreen({super.key});

  @override
  State<QBRankingsScreen> createState() => _QBRankingsScreenState();
}

class _QBRankingsScreenState extends State<QBRankingsScreen> {
  List<Map<String, dynamic>> _qbRankings = [];
  bool _isLoading = true;
  String? _error;
  String _selectedSeason = '2024';
  String _selectedTier = 'All';
  bool _showRanks = false; // Toggle between showing ranks vs raw stats
  
  // Sorting state - default to rank ascending (rank 1 first)
  String _sortColumn = 'myRankNum';
  bool _sortAscending = true;
  
  late final List<String> _seasonOptions;
  late final List<String> _tierOptions;
  late Map<String, Map<String, dynamic>> _qbStatFields;
  
  final Map<String, Map<String, double>> _percentileCache = {};

  @override
  void initState() {
    super.initState();
    _seasonOptions = RankingService.getSeasonOptions();
    _tierOptions = RankingService.getTierOptions();
    _updateStatFields();
    _loadQBRankings();
  }
  
  void _updateStatFields() {
    _qbStatFields = RankingService.getStatFields('qb', showRanks: _showRanks);
  }

  Future<void> _loadQBRankings() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final rankings = await RankingService.loadRankings(
        position: 'qb',
        season: _selectedSeason,
        tier: _selectedTier,
      );
      
      // Calculate percentiles for stat ranking
      final statFields = _qbStatFields.keys.where((key) => 
        !['rank_number', 'player_name', 'team', 'qb_tier', 'season', 'player_id', 'position', 'games', 'pass_attempts', 'posteam', 'player_position', 'passer_player_id', 'passer_player_name', 'myRankNum', 'tier', 'teamQBTier'].contains(key)
      ).toList();
      
      final percentiles = RankingCellShadingService.calculatePercentiles(rankings, statFields);
      _percentileCache.clear();
      _percentileCache.addAll(percentiles);
      
      // Sort by default column
      _sortData(rankings);
      
      setState(() {
        _qbRankings = rankings;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load QB rankings: ${e.toString()}';
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
      _sortData(_qbRankings);
    });
  }

  int _getSortColumnIndex() {
    final baseColumns = ['myRankNum', 'player_name', 'team', 'qb_tier'];
    if (_selectedSeason == 'All Seasons') {
      baseColumns.add('season');
    }
    final statFieldsToShow = _qbStatFields.keys.where((key) => 
      !['rank_number', 'player_name', 'team', 'qb_tier', 'season', 'player_id', 'position', 'games', 'pass_attempts', 'posteam', 'player_position', 'passer_player_id', 'passer_player_name', 'myRankNum', 'tier', 'teamQBTier'].contains(key)
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
      body: _buildContent(),
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
              onPressed: _loadQBRankings,
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
                  _loadQBRankings();
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
                  _loadQBRankings();
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
            'Quarterback Rankings',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
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
                  _loadQBRankings(); // Reload to recalculate percentiles
                }),
                _buildToggleButton('Ranks', _showRanks, () {
                  setState(() {
                    _showRanks = true;
                    _updateStatFields();
                  });
                  _loadQBRankings(); // Reload to recalculate percentiles
                }),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Text(
            '${_qbRankings.length} players',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.grey.shade600,
            ),
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
    if (_qbRankings.isEmpty) {
      return const Center(
        child: Text(
          'No QB rankings found for the selected criteria.',
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
                    onSort: (columnIndex, ascending) => _sort('team', ascending),
      ),
      DataColumn(
        label: const Text('Tier'),
        onSort: (columnIndex, ascending) => _sort('qb_tier', ascending),
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
    final statFieldsToShow = _qbStatFields.keys.where((key) => 
      !['rank_number', 'player_name', 'team', 'qb_tier', 'season', 'player_id', 'position', 'games', 'pass_attempts', 'posteam', 'player_position', 'passer_player_id', 'passer_player_name', 'myRankNum', 'tier', 'teamQBTier'].contains(key)
    ).toList();
    
    // The stat fields are already filtered by the service based on _showRanks
    final fieldsToDisplay = statFieldsToShow;
    
    for (final field in fieldsToDisplay) {
      final statInfo = _qbStatFields[field]!;
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
    return _qbRankings.asMap().entries.map((entry) {
      final index = entry.key;
      final qb = entry.value;
                    final tier = qb['qb_tier'] ?? qb['tier'] ?? 1;
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
              '#${qb['myRankNum'] ?? index + 1}',
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
                                TeamLogoUtils.buildNFLTeamLogo(qb['team'] ?? '', size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  qb['passer_player_name'] ?? qb['player_name'] ?? 'Unknown',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
                  DataCell(Text(qb['team'] ?? '')),
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
        cells.add(DataCell(Text(qb['season']?.toString() ?? '')));
      }

      // Add stat cells - skip base fields that are already added
      final statFieldsToShow = _qbStatFields.keys.where((key) => 
        !['rank_number', 'player_name', 'team', 'qb_tier', 'season', 'player_id', 'position', 'games', 'pass_attempts', 'posteam', 'player_position', 'passer_player_id', 'passer_player_name', 'myRankNum', 'tier', 'teamQBTier'].contains(key)
      ).toList();
      
      // The stat fields are already filtered by the service based on _showRanks
      final fieldsToDisplay = statFieldsToShow;
      
      for (final field in fieldsToDisplay) {
        final value = qb[field];
        final statInfo = _qbStatFields[field]!;
        
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