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

class WRProjections2025Screen extends StatefulWidget {
  const WRProjections2025Screen({super.key});

  @override
  State<WRProjections2025Screen> createState() => _WRProjections2025ScreenState();
}

class _WRProjections2025ScreenState extends State<WRProjections2025Screen> {
  List<Map<String, dynamic>> _wrProjections = [];
  bool _isLoading = true;
  String? _error;
  String _selectedTeam = 'All';
  bool _showRanks = false; // Toggle between showing ranks vs raw stats
  
  // Sorting state - default to projected rank ascending
  final String _sortColumn = 'projected_rank';
  final bool _sortAscending = true;
  
  final List<String> _teamOptions = ['All', 'ARI', 'ATL', 'BAL', 'BUF', 'CAR', 'CHI', 'CIN', 'CLE', 'DAL', 'DEN', 'DET', 'GB', 'HOU', 'IND', 'JAX', 'KC', 'LV', 'LAC', 'LA', 'MIA', 'MIN', 'NE', 'NO', 'NYG', 'NYJ', 'PHI', 'PIT', 'SEA', 'SF', 'TB', 'TEN', 'WAS'];
  
  // Relevant projection stats with their metadata
  final Map<String, Map<String, dynamic>> _projectionStatFields = {
    'projected_points': {'name': 'Proj Points', 'format': 'decimal1', 'description': '2025 projected fantasy points'},
    'projected_yards': {'name': 'Proj Yards', 'format': 'integer', 'description': '2025 projected receiving yards'},
    'projected_target_share': {'name': 'Proj Tgt%', 'format': 'percentage', 'description': '2025 projected target share'},
    'NY_numGames': {'name': 'Proj Games', 'format': 'integer', 'description': '2025 projected games'},
    'NY_passOffenseTier': {'name': 'Pass Off Tier', 'format': 'integer', 'description': '2025 pass offense tier'},
    'NY_qbTier': {'name': 'QB Tier', 'format': 'integer', 'description': '2025 QB tier'},
    'NY_passFreqTier': {'name': 'Pass Freq Tier', 'format': 'integer', 'description': '2025 pass frequency tier'},
    // Historical 2024 stats for comparison
    'numYards': {'name': '2024 Yards', 'format': 'integer', 'description': '2024 actual receiving yards'},
    'numTD': {'name': '2024 TDs', 'format': 'integer', 'description': '2024 actual touchdowns'},
    'tgt_share': {'name': '2024 Tgt%', 'format': 'percentage', 'description': '2024 actual target share'},
    'points': {'name': '2024 Points', 'format': 'decimal1', 'description': '2024 actual fantasy points'},
  };
  
  final Map<String, Map<double, double>> _percentileCache = {};

  @override
  void initState() {
    super.initState();
    _loadWRProjections();
  }

  Future<void> _loadWRProjections() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      Query query = FirebaseFirestore.instance.collection('wr_predictions_2025');
      
      final snapshot = await query.get();
      final projections = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          ...data,
          'id': doc.id,
        };
      }).toList();
      
      // Apply team filter
      List<Map<String, dynamic>> filteredProjections = projections;
      if (_selectedTeam != 'All') {
        filteredProjections = projections.where((wr) => 
          wr['NY_posteam'] == _selectedTeam || wr['posteam'] == _selectedTeam
        ).toList();
      }
      
      // Calculate percentiles for stat ranking
      _calculatePercentiles(filteredProjections);
      
      // Sort by default column
      _sortData(filteredProjections);
      
      setState(() {
        _wrProjections = filteredProjections;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load WR projections: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  void _calculatePercentiles(List<Map<String, dynamic>> projections) {
    _percentileCache.clear();
    
    for (String field in _projectionStatFields.keys) {
      List<double> values = projections
          .map((wr) => (wr[field] as num?)?.toDouble() ?? 0.0)
          .where((value) => value > 0)
          .toList();
      
      if (values.isNotEmpty) {
        values.sort();
        Map<double, double> percentiles = {};
        
        for (double value in values) {
          double percentile = (values.indexOf(value) + 1) / values.length;
          percentiles[value] = percentile;
        }
        
        _percentileCache[field] = percentiles;
      }
    }
  }

  void _sortData(List<Map<String, dynamic>> data) {
    data.sort((a, b) {
      var aValue = a[_sortColumn];
      var bValue = b[_sortColumn];
      
      if (aValue == null && bValue == null) return 0;
      if (aValue == null) return 1;
      if (bValue == null) return -1;
      
      int comparison;
      if (aValue is String && bValue is String) {
        comparison = aValue.compareTo(bValue);
      } else {
        double aNum = (aValue as num?)?.toDouble() ?? 0.0;
        double bNum = (bValue as num?)?.toDouble() ?? 0.0;
        comparison = aNum.compareTo(bNum);
      }
      
      return _sortAscending ? comparison : -comparison;
    });
  }

  Widget _buildFilterControls() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              // Team Filter
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButton<String>(
                    value: _selectedTeam,
                    isExpanded: true,
                    underline: Container(),
                    items: _teamOptions.map((team) {
                      return DropdownMenuItem(
                        value: team,
                        child: Text(team == 'All' ? 'All Teams' : team),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedTeam = value!;
                      });
                      _loadWRProjections();
                    },
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Toggle Switch
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Values', style: TextStyle(
                      fontWeight: !_showRanks ? FontWeight.bold : FontWeight.normal,
                    )),
                    Switch(
                      value: _showRanks,
                      onChanged: (value) {
                        setState(() {
                          _showRanks = value;
                        });
                      },
                    ),
                    Text('Ranks', style: TextStyle(
                      fontWeight: _showRanks ? FontWeight.bold : FontWeight.normal,
                    )),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getTierColor(int tier) {
    switch (tier) {
      case 1: return Colors.green.shade700;
      case 2: return Colors.green.shade500;
      case 3: return Colors.lightGreen.shade400;
      case 4: return Colors.yellow.shade600;
      case 5: return Colors.orange.shade500;
      case 6: return Colors.orange.shade700;
      case 7: return Colors.red.shade500;
      case 8: return Colors.red.shade700;
      default: return Colors.grey.shade600;
    }
  }

  Color _getRankColor(double percentile) {
    if (percentile >= 0.95) return Colors.green.shade700;
    if (percentile >= 0.90) return Colors.green.shade500;
    if (percentile >= 0.75) return Colors.lightGreen.shade400;
    if (percentile >= 0.50) return Colors.yellow.shade600;
    if (percentile >= 0.25) return Colors.orange.shade500;
    return Colors.red.shade500;
  }

  Widget _buildProjectionCard(Map<String, dynamic> projection, int index) {
    final player = projection['player_name'] ?? 'Unknown';
    final team2024 = projection['posteam'] ?? '';
    final team2025 = projection['NY_posteam'] ?? team2024;
    final projectedRank = projection['projected_rank'] ?? 999;
    final projectedPoints = projection['projected_points'] ?? 0;
    final projectedYards = projection['projected_yards'] ?? 0;
    
    // Calculate tier based on projected rank
    int tier = ((projectedRank - 1) ~/ 12) + 1;
    if (tier > 8) tier = 8;
    
    return AnimationConfiguration.staggeredList(
      position: index,
      duration: const Duration(milliseconds: 375),
      child: SlideAnimation(
        verticalOffset: 50.0,
        child: FadeInAnimation(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: _getTierColor(tier), width: 2),
              ),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: LinearGradient(
                    colors: [
                      _getTierColor(tier).withOpacity(0.1),
                      _getTierColor(tier).withOpacity(0.05),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: ExpansionTile(
                  tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  childrenPadding: const EdgeInsets.all(16),
                  leading: CircleAvatar(
                    radius: 20,
                    backgroundColor: _getTierColor(tier),
                    child: Text(
                      projectedRank.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  title: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              player,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Row(
                              children: [
                                if (team2024 != team2025) ...[
                                  Text(
                                    '$team2024 → $team2025',
                                    style: TextStyle(
                                      color: Colors.blue.shade600,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ] else ...[
                                  Text(
                                    team2025,
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: _getTierColor(tier),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    'Tier $tier',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${projectedPoints.toStringAsFixed(1)} pts',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            '$projectedYards yds',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  children: [
                    _buildStatsGrid(projection),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatsGrid(Map<String, dynamic> projection) {
    return Container(
      padding: const EdgeInsets.all(8),
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 3,
        childAspectRatio: 2.5,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        children: _projectionStatFields.entries.map((entry) {
          final field = entry.key;
          final meta = entry.value;
          final value = projection[field];
          
          return _buildStatCard(field, meta, value);
        }).toList(),
      ),
    );
  }

  Widget _buildStatCard(String field, Map<String, dynamic> meta, dynamic value) {
    String displayValue = '';
    Color backgroundColor = Colors.grey.shade100;
    
    if (value != null) {
      if (_showRanks && _percentileCache[field] != null) {
        double numValue = (value as num).toDouble();
        double percentile = _percentileCache[field]![numValue] ?? 0.0;
        int rank = ((1 - percentile) * _wrProjections.length).round() + 1;
        displayValue = '#$rank';
        backgroundColor = _getRankColor(percentile);
      } else {
        switch (meta['format']) {
          case 'percentage':
            displayValue = '${(value * 100).toStringAsFixed(1)}%';
            break;
          case 'decimal1':
            displayValue = value.toStringAsFixed(1);
            break;
          case 'integer':
            displayValue = value.toString();
            break;
          default:
            displayValue = value.toString();
        }
      }
    } else {
      displayValue = '--';
    }
    
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            meta['name'],
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: _showRanks ? Colors.white : Colors.grey.shade700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            displayValue,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: _showRanks ? Colors.white : Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(titleWidget: Text('2025 WR Projections')),
      drawer: const AppDrawer(),
              body: Column(
          children: [
            Container(
              color: Colors.grey.shade100,
              child: const Row(
                children: [
                  Expanded(child: TopNavBarContent(currentRoute: '/projections/wr-2025')),
                ],
              ),
            ),
            _buildFilterControls(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error, size: 64, color: Colors.red.shade400),
                            const SizedBox(height: 16),
                            Text(
                              _error!,
                              style: TextStyle(color: Colors.red.shade600),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _loadWRProjections,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : _wrProjections.isEmpty
                        ? const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.search_off, size: 64, color: Colors.grey),
                                SizedBox(height: 16),
                                Text(
                                  'No projections found',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : AnimationLimiter(
                            child: ListView.builder(
                              itemCount: _wrProjections.length,
                              itemBuilder: (context, index) {
                                return _buildProjectionCard(_wrProjections[index], index);
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }
} 