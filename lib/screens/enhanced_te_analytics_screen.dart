import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../widgets/common/custom_app_bar.dart';
import '../widgets/common/top_nav_bar.dart';
import '../services/hybrid_data_service.dart';

class EnhancedTEAnalyticsScreen extends StatefulWidget {
  const EnhancedTEAnalyticsScreen({super.key});

  @override
  State<EnhancedTEAnalyticsScreen> createState() => _EnhancedTEAnalyticsScreenState();
}

class _EnhancedTEAnalyticsScreenState extends State<EnhancedTEAnalyticsScreen>
    with TickerProviderStateMixin {
  final HybridDataService _dataService = HybridDataService();
  
  bool _isLoading = true;
  List<Map<String, dynamic>> _teData = [];
  List<int> _availableSeasons = [];
  List<int> _selectedSeasons = [2024];
  
  // Sorting state
  String _sortColumn = 'fantasy_points_ppr';
  bool _sortAscending = false;
  
  late TabController _tabController;

  // Cleaned TE data sections (removed zero-value columns)
  final List<Map<String, dynamic>> _dataSections = [
    {
      'id': 'production',
      'title': '🎯 Core Production',
      'subtitle': 'Primary receiving & usage',
      'color': Colors.purple,
      'icon': Icons.sports_handball,
      'fields': [
        {'key': 'player_display_name', 'label': 'Player', 'type': 'string', 'width': 180.0},
        {'key': 'recent_team', 'label': 'Team', 'type': 'string', 'width': 60.0},
        {'key': 'games', 'label': 'G', 'type': 'int', 'width': 40.0},
        {'key': 'targets', 'label': 'Targets', 'type': 'int', 'width': 70.0},
        {'key': 'receptions', 'label': 'Rec', 'type': 'int', 'width': 50.0},
        {'key': 'receiving_yards', 'label': 'Rec Yds', 'type': 'int', 'width': 80.0},
        {'key': 'receiving_tds', 'label': 'Rec TD', 'type': 'int', 'width': 70.0},
        {'key': 'yards_per_reception', 'label': 'YPR', 'type': 'decimal', 'width': 60.0},
        {'key': 'catch_percentage', 'label': 'Catch %', 'type': 'percentage', 'width': 80.0},
        {'key': 'target_share', 'label': 'Tgt Share', 'type': 'percentage', 'width': 90.0},
        {'key': 'yards_per_touch', 'label': 'YPT', 'type': 'decimal', 'width': 60.0},
        {'key': 'fantasy_points_ppr', 'label': 'PPR Pts', 'type': 'decimal', 'width': 80.0},
      ]
    },
    {
      'id': 'target_context',
      'title': '📊 Target Quality',
      'subtitle': 'Route context & target depth',
      'color': Colors.blue,
      'icon': Icons.gps_fixed,
      'fields': [
        {'key': 'player_display_name', 'label': 'Player', 'type': 'string', 'width': 180.0},
        {'key': 'recent_team', 'label': 'Team', 'type': 'string', 'width': 60.0},
        {'key': 'avg_depth_of_target', 'label': 'Avg DOT', 'type': 'decimal', 'width': 80.0},
        {'key': 'avg_intended_air_yards', 'label': 'Int Air Yds', 'type': 'decimal', 'width': 100.0},
        {'key': 'rec_avg_intended_air_yards', 'label': 'Rec Int Air', 'type': 'decimal', 'width': 100.0},
        {'key': 'avg_completed_air_yards', 'label': 'Comp Air Yds', 'type': 'decimal', 'width': 110.0},
        {'key': 'max_completed_air_distance', 'label': 'Max Air Dist', 'type': 'decimal', 'width': 100.0},
        {'key': 'avg_air_yards_to_sticks', 'label': 'Air/Sticks', 'type': 'decimal', 'width': 90.0},
        {'key': 'avg_separation', 'label': 'Avg Sep', 'type': 'decimal', 'width': 80.0},
        {'key': 'avg_cushion', 'label': 'Avg Cushion', 'type': 'decimal', 'width': 100.0},
      ]
    },
    {
      'id': 'advanced_receiving',
      'title': '⚡ Advanced Receiving',
      'subtitle': 'Sophisticated receiving metrics',
      'color': Colors.green,
      'icon': Icons.analytics,
      'fields': [
        {'key': 'player_display_name', 'label': 'Player', 'type': 'string', 'width': 180.0},
        {'key': 'recent_team', 'label': 'Team', 'type': 'string', 'width': 60.0},
        {'key': 'air_yards_share', 'label': 'Air Yds %', 'type': 'percentage', 'width': 90.0},
        {'key': 'racr', 'label': 'RACR', 'type': 'decimal', 'width': 70.0},
        {'key': 'wopr', 'label': 'WOPR', 'type': 'decimal', 'width': 70.0},
        {'key': 'aggressiveness', 'label': 'Aggr%', 'type': 'percentage', 'width': 70.0},
        {'key': 'avg_time_to_los', 'label': 'Time/LOS', 'type': 'decimal', 'width': 80.0},
        {'key': 'receiving_tds_per_reception', 'label': 'TD/Rec', 'type': 'percentage', 'width': 80.0},
        {'key': 'avg_air_yards_differential', 'label': 'Air Diff', 'type': 'decimal', 'width': 80.0},
      ]
    },
    {
      'id': 'versatility',
      'title': '🏃 Versatility & Special',
      'subtitle': 'Multi-dimensional contributions',
      'color': Colors.orange,
      'icon': Icons.all_inclusive,
      'fields': [
        {'key': 'player_display_name', 'label': 'Player', 'type': 'string', 'width': 180.0},
        {'key': 'recent_team', 'label': 'Team', 'type': 'string', 'width': 60.0},
        {'key': 'rushing_attempts', 'label': 'Rush Att', 'type': 'int', 'width': 80.0},
        {'key': 'rushing_yards', 'label': 'Rush Yds', 'type': 'int', 'width': 80.0},
        {'key': 'rushing_tds', 'label': 'Rush TD', 'type': 'int', 'width': 70.0},
        {'key': 'yards_per_carry', 'label': 'YPC', 'type': 'decimal', 'width': 60.0},
        {'key': 'attempts', 'label': 'Pass Att', 'type': 'int', 'width': 80.0},
        {'key': 'passing_yards', 'label': 'Pass Yds', 'type': 'int', 'width': 80.0},
        {'key': 'passing_tds', 'label': 'Pass TD', 'type': 'int', 'width': 70.0},
        {'key': 'passer_rating', 'label': 'Pass Rtg', 'type': 'decimal', 'width': 80.0},
      ]
    },
    {
      'id': 'summary',
      'title': '🏆 Summary & Fantasy',
      'subtitle': 'Overall impact & fantasy',
      'color': Colors.red,
      'icon': Icons.emoji_events,
      'fields': [
        {'key': 'player_display_name', 'label': 'Player', 'type': 'string', 'width': 180.0},
        {'key': 'recent_team', 'label': 'Team', 'type': 'string', 'width': 60.0},
        {'key': 'fantasy_points_ppr', 'label': 'PPR Pts', 'type': 'decimal', 'width': 80.0},
        {'key': 'fantasy_points_ppr_per_game', 'label': 'PPR/Game', 'type': 'decimal', 'width': 90.0},
        {'key': 'fantasy_points', 'label': 'Std Pts', 'type': 'decimal', 'width': 80.0},
        {'key': 'fantasy_points_per_game', 'label': 'Std/Game', 'type': 'decimal', 'width': 90.0},
        {'key': 'receiving_yards', 'label': 'Rec Yds', 'type': 'int', 'width': 80.0},
        {'key': 'receiving_tds', 'label': 'Rec TD', 'type': 'int', 'width': 70.0},
        {'key': 'rushing_yards', 'label': 'Rush Yds', 'type': 'int', 'width': 80.0},
        {'key': 'rushing_tds', 'label': 'Rush TD', 'type': 'int', 'width': 70.0},
        {'key': 'target_share', 'label': 'Tgt Share', 'type': 'percentage', 'width': 90.0},
      ]
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _dataSections.length, vsync: this);
    _loadTEData();
  }

  Future<void> _loadTEData() async {
    setState(() => _isLoading = true);
    
    try {
      _availableSeasons = await _dataService.getAvailableSeasons();
      
      final allTEs = await _dataService.getPlayerStats(
        position: 'TE',
        seasons: _selectedSeasons,
        orderBy: _sortColumn,
        descending: !_sortAscending,
      );
      
      final minTargets = _selectedSeasons.length == 1 ? 15 : 60;
      _teData = allTEs
          .where((te) => (te['targets'] ?? 0) >= minTargets)
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
      
      _teData.sort((a, b) {
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
        titleWidget: Text('🏈 Enhanced TE Analytics'),
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
          colors: [Colors.purple.shade700, Colors.indigo.shade600],
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
                  'Enhanced TE Analytics',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  '${_teData.length} Qualified TEs • Clean Data • Sortable Columns • ${_selectedSeasons.length == 1 ? _selectedSeasons.first.toString() : '${_selectedSeasons.length} Seasons'}',
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
                    
                    _loadTEData();
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
                    rows: _teData.take(50).map((te) {
                      return DataRow(
                        cells: fields.map((field) {
                          final value = te[field['key']];
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