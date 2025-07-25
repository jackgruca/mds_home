import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../widgets/common/custom_app_bar.dart';
import '../widgets/common/top_nav_bar.dart';
import '../services/hybrid_data_service.dart';

class EnhancedRBAnalyticsScreen extends StatefulWidget {
  const EnhancedRBAnalyticsScreen({super.key});

  @override
  State<EnhancedRBAnalyticsScreen> createState() => _EnhancedRBAnalyticsScreenState();
}

class _EnhancedRBAnalyticsScreenState extends State<EnhancedRBAnalyticsScreen>
    with TickerProviderStateMixin {
  final HybridDataService _dataService = HybridDataService();
  
  bool _isLoading = true;
  List<Map<String, dynamic>> _rbData = [];
  List<int> _availableSeasons = [];
  List<int> _selectedSeasons = [2024];
  
  // Sorting state
  String _sortColumn = 'fantasy_points_ppr';
  bool _sortAscending = false;
  
  late TabController _tabController;

  // Cleaned RB data sections (removed zero-value columns)
  final List<Map<String, dynamic>> _dataSections = [
    {
      'id': 'production',
      'title': '🏃 Core Production',
      'subtitle': 'Rushing & receiving volume',
      'color': Colors.green,
      'icon': Icons.directions_run,
      'fields': [
        {'key': 'player_display_name', 'label': 'Player', 'type': 'string', 'width': 180.0},
        {'key': 'recent_team', 'label': 'Team', 'type': 'string', 'width': 60.0},
        {'key': 'games', 'label': 'G', 'type': 'int', 'width': 40.0},
        {'key': 'rushing_attempts', 'label': 'Rush Att', 'type': 'int', 'width': 80.0},
        {'key': 'rushing_yards', 'label': 'Rush Yds', 'type': 'int', 'width': 80.0},
        {'key': 'rushing_tds', 'label': 'Rush TD', 'type': 'int', 'width': 70.0},
        {'key': 'targets', 'label': 'Targets', 'type': 'int', 'width': 70.0},
        {'key': 'receptions', 'label': 'Rec', 'type': 'int', 'width': 50.0},
        {'key': 'receiving_yards', 'label': 'Rec Yds', 'type': 'int', 'width': 80.0},
        {'key': 'receiving_tds', 'label': 'Rec TD', 'type': 'int', 'width': 70.0},
        {'key': 'yards_per_carry', 'label': 'YPC', 'type': 'decimal', 'width': 60.0},
        {'key': 'yards_per_reception', 'label': 'YPR', 'type': 'decimal', 'width': 60.0},
      ]
    },
    {
      'id': 'efficiency',
      'title': '⚡ Efficiency Metrics',
      'subtitle': 'Advanced rushing efficiency',
      'color': Colors.orange,
      'icon': Icons.speed,
      'fields': [
        {'key': 'player_display_name', 'label': 'Player', 'type': 'string', 'width': 180.0},
        {'key': 'recent_team', 'label': 'Team', 'type': 'string', 'width': 60.0},
        {'key': 'rush_efficiency', 'label': 'Rush Eff', 'type': 'decimal', 'width': 80.0},
        {'key': 'rush_pct_over_expected', 'label': 'Rush %OE', 'type': 'percentage', 'width': 90.0},
        {'key': 'rush_yards_over_expected', 'label': 'RYOE Total', 'type': 'decimal', 'width': 90.0},
        {'key': 'rush_yards_over_expected_per_att', 'label': 'RYOE/Att', 'type': 'decimal', 'width': 80.0},
        {'key': 'avg_time_to_los', 'label': 'Time/LOS', 'type': 'decimal', 'width': 80.0},
        {'key': 'rushing_tds_per_attempt', 'label': 'TD Rate', 'type': 'percentage', 'width': 80.0},
        {'key': 'yards_per_touch', 'label': 'YPT', 'type': 'decimal', 'width': 60.0},
        {'key': 'rushing_yards_per_attempt', 'label': 'Rush YPA', 'type': 'decimal', 'width': 80.0},
      ]
    },
    {
      'id': 'receiving',
      'title': '🎯 Receiving Analytics',
      'subtitle': 'Target quality & receiving',
      'color': Colors.blue,
      'icon': Icons.sports_football,
      'fields': [
        {'key': 'player_display_name', 'label': 'Player', 'type': 'string', 'width': 180.0},
        {'key': 'recent_team', 'label': 'Team', 'type': 'string', 'width': 60.0},
        {'key': 'target_share', 'label': 'Tgt Share', 'type': 'percentage', 'width': 90.0},
        {'key': 'catch_percentage', 'label': 'Catch %', 'type': 'percentage', 'width': 80.0},
        {'key': 'avg_separation', 'label': 'Avg Sep', 'type': 'decimal', 'width': 80.0},
        {'key': 'avg_cushion', 'label': 'Avg Cush', 'type': 'decimal', 'width': 80.0},
        {'key': 'avg_depth_of_target', 'label': 'Avg DOT', 'type': 'decimal', 'width': 80.0},
        {'key': 'rec_avg_intended_air_yards', 'label': 'Int Air Yds', 'type': 'decimal', 'width': 100.0},
        {'key': 'air_yards_share', 'label': 'Air Yds %', 'type': 'percentage', 'width': 90.0},
        {'key': 'receiving_tds_per_reception', 'label': 'TD/Rec', 'type': 'percentage', 'width': 80.0},
        {'key': 'wopr', 'label': 'WOPR', 'type': 'decimal', 'width': 70.0},
        {'key': 'avg_air_yards_differential', 'label': 'Air Diff', 'type': 'decimal', 'width': 80.0},
      ]
    },
    {
      'id': 'advanced',
      'title': '📊 Advanced Analytics',
      'subtitle': 'NextGen performance metrics',
      'color': Colors.purple,
      'icon': Icons.analytics,
      'fields': [
        {'key': 'player_display_name', 'label': 'Player', 'type': 'string', 'width': 180.0},
        {'key': 'recent_team', 'label': 'Team', 'type': 'string', 'width': 60.0},
        {'key': 'rush_yards_over_expected', 'label': 'RYOE', 'type': 'decimal', 'width': 70.0},
        {'key': 'rush_pct_over_expected', 'label': 'Rush %OE', 'type': 'percentage', 'width': 90.0},
        {'key': 'avg_separation', 'label': 'Separation', 'type': 'decimal', 'width': 90.0},
        {'key': 'avg_cushion', 'label': 'Cushion', 'type': 'decimal', 'width': 80.0},
        {'key': 'racr', 'label': 'RACR', 'type': 'decimal', 'width': 70.0},
        {'key': 'wopr', 'label': 'WOPR', 'type': 'decimal', 'width': 70.0},
        {'key': 'avg_time_to_los', 'label': 'Time/LOS', 'type': 'decimal', 'width': 80.0},
      ]
    },
    {
      'id': 'fantasy',
      'title': '🏆 Fantasy Impact',
      'subtitle': 'Fantasy football scoring',
      'color': Colors.red,
      'icon': Icons.emoji_events,
      'fields': [
        {'key': 'player_display_name', 'label': 'Player', 'type': 'string', 'width': 180.0},
        {'key': 'recent_team', 'label': 'Team', 'type': 'string', 'width': 60.0},
        {'key': 'fantasy_points_ppr', 'label': 'PPR Pts', 'type': 'decimal', 'width': 80.0},
        {'key': 'fantasy_points_ppr_per_game', 'label': 'PPR/Game', 'type': 'decimal', 'width': 90.0},
        {'key': 'fantasy_points', 'label': 'Std Pts', 'type': 'decimal', 'width': 80.0},
        {'key': 'fantasy_points_per_game', 'label': 'Std/Game', 'type': 'decimal', 'width': 90.0},
        {'key': 'rushing_yards', 'label': 'Rush Yds', 'type': 'int', 'width': 80.0},
        {'key': 'receiving_yards', 'label': 'Rec Yds', 'type': 'int', 'width': 80.0},
        {'key': 'rushing_tds', 'label': 'Rush TD', 'type': 'int', 'width': 70.0},
        {'key': 'receiving_tds', 'label': 'Rec TD', 'type': 'int', 'width': 70.0},
        {'key': 'target_share', 'label': 'Tgt Share', 'type': 'percentage', 'width': 90.0},
      ]
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _dataSections.length, vsync: this);
    _loadRBData();
  }

  Future<void> _loadRBData() async {
    setState(() => _isLoading = true);
    
    try {
      _availableSeasons = await _dataService.getAvailableSeasons();
      
      final allRBs = await _dataService.getPlayerStats(
        position: 'RB',
        seasons: _selectedSeasons,
        orderBy: _sortColumn,
        descending: !_sortAscending,
      );
      
      final minAttempts = _selectedSeasons.length == 1 ? 20 : 100;
      _rbData = allRBs
          .where((rb) => (rb['rushing_attempts'] ?? 0) >= minAttempts)
          .toList();
      
      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _sortData(String column, bool ascending) {
    setState(() {
      _sortColumn = column;
      _sortAscending = ascending;
      
      _rbData.sort((a, b) {
        final aVal = a[column];
        final bVal = b[column];
        
        if (aVal == null && bVal == null) return 0;
        if (aVal == null) return ascending ? -1 : 1;
        if (bVal == null) return ascending ? 1 : -1;
        
        if (aVal is num && bVal is num) {
          return ascending ? aVal.compareTo(bVal) : bVal.compareTo(aVal);
        }
        
        return ascending 
          ? aVal.toString().compareTo(bVal.toString())
          : bVal.toString().compareTo(aVal.toString());
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        titleWidget: Text('🏃 Enhanced RB Analytics'),
      ),
      body: Column(
        children: [
          const TopNavBarContent(),
          
          if (_isLoading)
            const Expanded(
              child: Center(child: CircularProgressIndicator()),
            )
          else
            Expanded(
              child: Column(
                children: [
                  _buildHeader(),
                  _buildSeasonSelector(),
                  _buildSectionTabs(),
                  
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: _dataSections.map((section) => 
                        _buildDataTable(section)
                      ).toList(),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green.shade700, Colors.blue.shade600],
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.table_chart, size: 32, color: Colors.white),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Enhanced RB Analytics',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  '${_rbData.length} Qualified RBs • Clean Data • Sortable Columns • ${_selectedSeasons.length == 1 ? _selectedSeasons.first.toString() : '${_selectedSeasons.length} Seasons'}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeasonSelector() {
    if (_availableSeasons.isEmpty) return const SizedBox.shrink();
    
    return Container(
      padding: const EdgeInsets.all(16),
      color: Theme.of(context).cardColor,
      child: Row(
        children: [
          const Icon(Icons.calendar_today, size: 20),
          const SizedBox(width: 12),
          const Text('Seasons:', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(width: 16),
          Expanded(
            child: Wrap(
              spacing: 8,
              children: _availableSeasons.map((season) {
                final isSelected = _selectedSeasons.contains(season);
                return FilterChip(
                  label: Text(season.toString()),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        if (!_selectedSeasons.contains(season)) {
                          _selectedSeasons.add(season);
                        }
                      } else {
                        _selectedSeasons.remove(season);
                      }
                      
                      if (_selectedSeasons.isEmpty) {
                        _selectedSeasons.add(2024);
                      }
                    });
                    
                    _loadRBData();
                  },
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTabs() {
    return Container(
      color: Theme.of(context).cardColor,
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        tabs: _dataSections.map((section) => Tab(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(section['icon'], size: 16),
              const SizedBox(width: 8),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    section['title'],
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    section['subtitle'],
                    style: const TextStyle(fontSize: 10),
                  ),
                ],
              ),
            ],
          ),
        )).toList(),
      ),
    );
  }

  Widget _buildDataTable(Map<String, dynamic> section) {
    final fields = section['fields'] as List<Map<String, dynamic>>;
    
    return Padding(
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SingleChildScrollView(
          child: DataTable(
                    columnSpacing: 16,
                    sortColumnIndex: fields.indexWhere((f) => f['key'] == _sortColumn),
                    sortAscending: _sortAscending,
                    columns: fields.map((field) => DataColumn(
                      label: SizedBox(
                        width: field['width'],
                        child: Text(
                          field['label'],
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      onSort: field['type'] != 'string' ? (columnIndex, ascending) {
                        _sortData(field['key'], ascending);
                      } : null,
                    )).toList(),
                    rows: _rbData.take(50).map((rb) {
                      return DataRow(
                        cells: fields.map((field) {
                          final value = rb[field['key']];
                          return DataCell(
                            SizedBox(
                              width: field['width'],
                              child: Text(
                                _formatFieldValue(value, field['type']),
                                style: const TextStyle(fontSize: 11),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          );
                        }).toList(),
                      );
                    }).toList(),
          ),
        ),
      ),
    );
  }

  String _formatFieldValue(dynamic value, String type) {
    if (value == null) return '-';
    
    switch (type) {
      case 'string':
        return value.toString();
      case 'int':
        return value.toString();
      case 'decimal':
        if (value is num) {
          return value.toStringAsFixed(1);
        }
        return value.toString();
      case 'percentage':
        if (value is num) {
          return '${value.toStringAsFixed(1)}%';
        }
        return value.toString();
      default:
        return value.toString();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}