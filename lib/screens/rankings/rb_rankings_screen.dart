import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../widgets/common/app_drawer.dart';
import '../../widgets/common/custom_app_bar.dart';
import '../../widgets/common/top_nav_bar.dart';
import '../../utils/theme_config.dart';
import '../../utils/theme_aware_colors.dart';

class RBRankingsScreen extends StatefulWidget {
  const RBRankingsScreen({super.key});

  @override
  State<RBRankingsScreen> createState() => _RBRankingsScreenState();
}

class _RBRankingsScreenState extends State<RBRankingsScreen> {
  List<Map<String, dynamic>> _rbRankings = [];
  bool _isLoading = true;
  String? _error;
  String _selectedSeason = '2024';
  String _selectedTier = 'All';
  bool _showRanks = false; // Toggle between showing ranks vs raw stats
  
  // Sorting state - default to rank ascending (rank 1 first)
  String _sortColumn = 'my_rank';
  bool _sortAscending = true;
  
  final List<String> _seasonOptions = ['2024', '2023', '2022', '2021', '2020', '2019', '2018', '2017', '2016'];
  final List<String> _tierOptions = ['All', '1', '2', '3', '4', '5', '6', '7', '8'];
  
  final Map<String, Map<String, double>> _percentileCache = {};

  @override
  void initState() {
    super.initState();
    _loadRBRankings();
  }

  Future<void> _loadRBRankings() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      Query query = FirebaseFirestore.instance.collection('rb_rankings')
          .where('season', isEqualTo: int.parse(_selectedSeason));

      if (_selectedTier != 'All') {
        query = query.where('tier', isEqualTo: int.parse(_selectedTier));
      }

      final snapshot = await query.get();
      
      setState(() {
        _rbRankings = snapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return {
            'id': doc.id,
            ...data,
          };
        }).toList();
        
        _sortData();
        _isLoading = false;
      });
      
      // Calculate percentiles for density visualization
      _calculatePercentiles();
      
    } catch (e) {
      setState(() {
        _error = 'Failed to load RB rankings: $e';
        _isLoading = false;
      });
    }
  }

  void _calculatePercentiles() {
    if (_rbRankings.isEmpty) return;
    
    // Define all the stat columns that need percentiles
    final statColumns = [
      'total_epa', 'total_tds', 'total_yards', 'rush_share', 'target_share',
      'explosive_rate', 'conversion_rate', 'third_down_rate', 'efficiency', 'ryoe_per_att'
    ];
    
    for (String column in statColumns) {
      final values = _rbRankings
          .map((rb) => (rb[column] as num?)?.toDouble() ?? 0.0)
          .where((value) => value.isFinite)
          .toList()
        ..sort();
      
      if (values.isNotEmpty) {
        _percentileCache[column] = {
          'min': values.first,
          'p25': _calculatePercentile(values, 0.25),
          'p50': _calculatePercentile(values, 0.5),
          'p75': _calculatePercentile(values, 0.75),
          'max': values.last,
        };
      }
    }
  }

  double _calculatePercentile(List<double> sortedValues, double percentile) {
    final index = (sortedValues.length - 1) * percentile;
    final lower = index.floor();
    final upper = index.ceil();
    
    if (lower == upper) {
      return sortedValues[lower];
    }
    
    return sortedValues[lower] * (upper - index) + sortedValues[upper] * (index - lower);
  }

  void _sortData() {
    _rbRankings.sort((a, b) {
      dynamic aValue = a[_sortColumn];
      dynamic bValue = b[_sortColumn];
      
      // Handle null values
      if (aValue == null && bValue == null) return 0;
      if (aValue == null) return _sortAscending ? 1 : -1;
      if (bValue == null) return _sortAscending ? -1 : 1;
      
      // Convert to comparable types
      if (aValue is num && bValue is num) {
        return _sortAscending ? aValue.compareTo(bValue) : bValue.compareTo(aValue);
      }
      
      // String comparison
      String aStr = aValue.toString().toLowerCase();
      String bStr = bValue.toString().toLowerCase();
      return _sortAscending ? aStr.compareTo(bStr) : bStr.compareTo(aStr);
    });
  }

  void _onSort(String column) {
    setState(() {
      if (_sortColumn == column) {
        _sortAscending = !_sortAscending;
      } else {
        _sortColumn = column;
        _sortAscending = column == 'my_rank' ? true : false; // Rank ascending by default
      }
      _sortData();
    });
  }

  Widget _buildSortableHeader(String title, String column, {double? width}) {
    final isSelected = _sortColumn == column;
    
    return InkWell(
      onTap: () => _onSort(column),
      child: Container(
        width: width,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: isSelected 
                      ? Theme.of(context).primaryColor
                      : Theme.of(context).textTheme.bodyLarge?.color,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              isSelected
                  ? (_sortAscending ? Icons.arrow_upward : Icons.arrow_downward)
                  : Icons.sort,
              size: 16,
              color: isSelected 
                  ? Theme.of(context).primaryColor
                  : Theme.of(context).textTheme.bodyMedium?.color,
            ),
          ],
        ),
      ),
    );
  }

  Color _getDensityColor(String column, double value) {
    final percentiles = _percentileCache[column];
    if (percentiles == null) return Colors.grey.shade200;
    
    final p25 = percentiles['p25']!;
    final p50 = percentiles['p50']!;
    final p75 = percentiles['p75']!;
    
    // Determine color intensity based on percentile
    if (value >= p75) {
      return Colors.green.withOpacity(0.7);
    } else if (value >= p50) {
      return Colors.green.withOpacity(0.4);
    } else if (value >= p25) {
      return Colors.orange.withOpacity(0.3);
    } else {
      return Colors.red.withOpacity(0.3);
    }
  }

  Widget _buildDensityCell(String column, dynamic value, dynamic rankValue) {
    final displayValue = _showRanks ? rankValue : value;
    final numValue = (displayValue as num?)?.toDouble() ?? 0.0;
    
    return Container(
      width: 80,
      height: 40,
      margin: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: _getDensityColor(column, _showRanks ? (1.0 - numValue) : numValue),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.grey.shade300, width: 0.5),
      ),
      child: Center(
        child: Text(
          _formatValue(displayValue, column),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  String _formatValue(dynamic value, String column) {
    if (value == null) return '-';
    
    if (_showRanks) {
      final percentile = (value as num).toDouble();
      return '${(percentile * 100).round()}%';
    }
    
    final numValue = (value as num).toDouble();
    
    switch (column) {
      case 'total_epa':
        return numValue.toStringAsFixed(1);
      case 'total_tds':
        return numValue.round().toString();
      case 'total_yards':
        return numValue.toStringAsFixed(1);
      case 'rush_share':
      case 'target_share':
      case 'explosive_rate':
      case 'conversion_rate':
      case 'third_down_rate':
        return '${(numValue * 100).toStringAsFixed(1)}%';
      case 'efficiency':
      case 'ryoe_per_att':
        return numValue.toStringAsFixed(2);
      default:
        return numValue.toString();
    }
  }

  Color _getTierColor(int tier) {
    switch (tier) {
      case 1: return Colors.purple;
      case 2: return Colors.blue;
      case 3: return Colors.green;
      case 4: return Colors.orange;
      case 5: return Colors.red;
      case 6: return Colors.brown;
      case 7: return Colors.grey;
      case 8: return Colors.blueGrey;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentRouteName = ModalRoute.of(context)?.settings.name;
    
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
      body: Column(
        children: [
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _buildHeader(),
                  Expanded(child: _buildContent()),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: ThemeConfig.darkNavy,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(
                Icons.directions_run,
                color: Colors.white,
                size: 28,
              ),
              const SizedBox(width: 12),
              const Text(
                'RB Rankings',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_rbRankings.length} Players',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildFilters(),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Row(
      children: [
        // Season filter
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              borderRadius: BorderRadius.circular(8),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedSeason,
                hint: const Text('Season'),
                isExpanded: true,
                items: _seasonOptions.map((season) {
                  return DropdownMenuItem(
                    value: season,
                    child: Text(season),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedSeason = value;
                    });
                    _loadRBRankings();
                  }
                },
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Tier filter
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              borderRadius: BorderRadius.circular(8),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedTier,
                hint: const Text('Tier'),
                isExpanded: true,
                items: _tierOptions.map((tier) {
                  return DropdownMenuItem(
                    value: tier,
                    child: Text(tier == 'All' ? 'All Tiers' : 'Tier $tier'),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedTier = value;
                    });
                    _loadRBRankings();
                  }
                },
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Toggle for ranks vs values
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Values',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: !_showRanks ? FontWeight.bold : FontWeight.normal,
                  color: !_showRanks ? ThemeConfig.darkNavy : Colors.grey,
                ),
              ),
              Switch(
                value: _showRanks,
                onChanged: (value) {
                  setState(() {
                    _showRanks = value;
                  });
                },
                activeColor: ThemeConfig.darkNavy,
              ),
              Text(
                'Ranks',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: _showRanks ? FontWeight.bold : FontWeight.normal,
                  color: _showRanks ? ThemeConfig.darkNavy : Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
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

    if (_rbRankings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.search_off,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              'No RB rankings found for $_selectedSeason',
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        _buildTableHeader(),
        Expanded(
          child: ListView.builder(
            itemCount: _rbRankings.length,
            itemBuilder: (context, index) {
              return AnimationConfiguration.staggeredList(
                position: index,
                duration: const Duration(milliseconds: 375),
                child: SlideAnimation(
                  verticalOffset: 50.0,
                  child: FadeInAnimation(
                    child: _buildPlayerRow(_rbRankings[index], index),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTableHeader() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.shade300,
            width: 1,
          ),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildSortableHeader('Rank', 'my_rank', width: 60),
            _buildSortableHeader('Player', 'player_name', width: 150),
            _buildSortableHeader('Team', 'team', width: 60),
            _buildSortableHeader('Tier', 'tier', width: 50),
            _buildSortableHeader('Score', 'my_rank_score', width: 80),
            _buildSortableHeader('EPA', 'total_epa', width: 80),
            _buildSortableHeader('TDs', 'total_tds', width: 80),
            _buildSortableHeader('YPG', 'total_yards', width: 80),
            _buildSortableHeader('Rush%', 'rush_share', width: 80),
            _buildSortableHeader('Tgt%', 'target_share', width: 80),
            _buildSortableHeader('Expl%', 'explosive_rate', width: 80),
            _buildSortableHeader('Conv%', 'conversion_rate', width: 80),
            _buildSortableHeader('3rd%', 'third_down_rate', width: 80),
            _buildSortableHeader('Eff', 'efficiency', width: 80),
            _buildSortableHeader('RYOE', 'ryoe_per_att', width: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayerRow(Map<String, dynamic> rb, int index) {
    final tier = rb['tier'] as int? ?? 8;
    final rank = rb['my_rank'] as int? ?? 0;
    
    return Container(
      decoration: BoxDecoration(
        color: index.isEven 
            ? Colors.white
            : Colors.grey.shade50,
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.shade200,
            width: 0.5,
          ),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            // Rank
            SizedBox(
              width: 60,
              height: 50,
              child: Center(
                child: Text(
                  rank.toString(),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ),
            ),
            // Player name
            Container(
              width: 150,
              height: 50,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    rb['player_name'] as String? ?? '',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '${rb['season']} • ${rb['games'] ?? 0} games',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            // Team
            SizedBox(
              width: 60,
              height: 50,
              child: Center(
                child: Text(
                  rb['team'] as String? ?? '',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            // Tier
            SizedBox(
              width: 50,
              height: 50,
              child: Center(
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: _getTierColor(tier),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Center(
                    child: Text(
                      tier.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            // Score
            SizedBox(
              width: 80,
              height: 50,
              child: Center(
                child: Text(
                  (rb['my_rank_score'] as num?)?.toStringAsFixed(3) ?? '-',
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            // Density cells for all stats
            _buildDensityCell('total_epa', rb['total_epa'], rb['epa_rank']),
            _buildDensityCell('total_tds', rb['total_tds'], rb['td_rank']),
            _buildDensityCell('total_yards', rb['total_yards'], rb['yards_rank']),
            _buildDensityCell('rush_share', rb['rush_share'], rb['rush_share_rank']),
            _buildDensityCell('target_share', rb['target_share'], rb['target_share_rank']),
            _buildDensityCell('explosive_rate', rb['explosive_rate'], rb['explosive_rank']),
            _buildDensityCell('conversion_rate', rb['conversion_rate'], rb['conversion_rank']),
            _buildDensityCell('third_down_rate', rb['third_down_rate'], rb['third_down_rank']),
            _buildDensityCell('efficiency', rb['efficiency'], rb['efficiency_rank']),
            _buildDensityCell('ryoe_per_att', rb['ryoe_per_att'], rb['ryoe_rank']),
          ],
        ),
      ),
    );
  }
} 