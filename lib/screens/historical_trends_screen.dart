import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../widgets/common/custom_app_bar.dart';
import '../widgets/common/top_nav_bar.dart';
import '../services/hybrid_data_service.dart';

class HistoricalTrendsScreen extends StatefulWidget {
  const HistoricalTrendsScreen({super.key});

  @override
  State<HistoricalTrendsScreen> createState() => _HistoricalTrendsScreenState();
}

class _HistoricalTrendsScreenState extends State<HistoricalTrendsScreen> {
  final HybridDataService _dataService = HybridDataService();
  
  bool _isLoading = true;
  String _selectedPlayer = '';
  String _selectedMetric = 'fantasy_points_ppr';
  String _selectedPosition = 'QB';
  
  List<Map<String, dynamic>> _playerData = [];
  List<Map<String, dynamic>> _availablePlayers = [];
  Map<int, double> _trendData = {};

  final List<String> _positions = ['QB', 'RB', 'WR', 'TE'];
  final Map<String, String> _metrics = {
    'fantasy_points_ppr': 'PPR Fantasy Points',
    'passing_yards': 'Passing Yards',
    'rushing_yards': 'Rushing Yards', 
    'receiving_yards': 'Receiving Yards',
    'passer_rating': 'Passer Rating',
    'yards_per_carry': 'Yards per Carry',
    'yards_per_reception': 'Yards per Reception',
    'target_share': 'Target Share %',
    'completion_percentage': 'Completion %',
    'rush_yards_over_expected': 'Rush Yards Over Expected',
    'racr': 'Receiver Air Conversion Ratio',
  };

  @override
  void initState() {
    super.initState();
    _loadPositionPlayers();
  }

  Future<void> _loadPositionPlayers() async {
    setState(() => _isLoading = true);
    
    try {
      // Load all players for selected position across all seasons
      final allPlayers = await _dataService.getPlayerStats(
        position: _selectedPosition,
        orderBy: _selectedMetric,
        descending: true,
      );
      
      // Get unique players (by name) and their career stats
      final playerMap = <String, Map<String, dynamic>>{};
      for (final player in allPlayers) {
        final name = player['player_display_name'] ?? 'Unknown';
        if (!playerMap.containsKey(name)) {
          playerMap[name] = player;
        }
      }
      
      _availablePlayers = playerMap.values.toList();
      
      // Set default player if available
      if (_availablePlayers.isNotEmpty && _selectedPlayer.isEmpty) {
        _selectedPlayer = _availablePlayers.first['player_display_name'] ?? '';
        await _loadPlayerTrends();
      }
      
      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadPlayerTrends() async {
    if (_selectedPlayer.isEmpty) return;
    
    try {
      // Load all seasons for selected player
      final playerSeasons = await _dataService.getPlayerStats(
        position: _selectedPosition,
      );
      
      // Filter for selected player and extract trend data
      _playerData = playerSeasons
          .where((p) => p['player_display_name'] == _selectedPlayer)
          .toList();
      
      _trendData.clear();
      for (final season in _playerData) {
        final year = season['season'] as int?;
        final value = season[_selectedMetric] as num?;
        if (year != null && value != null) {
          _trendData[year] = value.toDouble();
        }
      }
      
      setState(() {});
    } catch (e) {
      // Handle error
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        titleWidget: Text('📈 Historical Trends & Player Analysis'),
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
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    _buildHeader(),
                    
                    const SizedBox(height: 24),
                    
                    // Controls
                    _buildControls(),
                    
                    const SizedBox(height: 32),
                    
                    // Trend Chart
                    if (_trendData.isNotEmpty) ...[
                      _buildTrendChart(),
                      const SizedBox(height: 32),
                    ],
                    
                    // Career Stats Table
                    _buildCareerStatsTable(),
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
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.indigo.shade700,
            Colors.blue.shade600,
          ],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.trending_up, size: 32, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Historical Player Analysis',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Track player performance trends across ${_playerData.isNotEmpty ? _playerData.length : 'multiple'} seasons (2020-2024)',
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
        ],
      ),
    );
  }

  Widget _buildControls() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Analysis Controls',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            // Position selector
            Row(
              children: [
                const Text('Position: ', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(width: 8),
                DropdownButton<String>(
                  value: _selectedPosition,
                  items: _positions.map((position) => DropdownMenuItem(
                    value: position,
                    child: Text(position),
                  )).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedPosition = value;
                        _selectedPlayer = '';
                        _trendData.clear();
                      });
                      _loadPositionPlayers();
                    }
                  },
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Player selector
            if (_availablePlayers.isNotEmpty) ...[
              Row(
                children: [
                  const Text('Player: ', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButton<String>(
                      value: _selectedPlayer.isNotEmpty ? _selectedPlayer : null,
                      hint: const Text('Select a player'),
                      isExpanded: true,
                      items: _availablePlayers.take(20).map((player) {
                        final name = player['player_display_name'] ?? 'Unknown';
                        return DropdownMenuItem<String>(
                          value: name,
                          child: Text(name),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _selectedPlayer = value;
                          });
                          _loadPlayerTrends();
                        }
                      },
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
            ],
            
            // Metric selector  
            Row(
              children: [
                const Text('Metric: ', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButton<String>(
                    value: _selectedMetric,
                    isExpanded: true,
                    items: _metrics.entries.map((entry) => DropdownMenuItem(
                      value: entry.key,
                      child: Text(entry.value),
                    )).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedMetric = value;
                        });
                        _loadPlayerTrends();
                      }
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrendChart() {
    if (_trendData.isEmpty) return const SizedBox.shrink();
    
    final sortedYears = _trendData.keys.toList()..sort();
    final spots = sortedYears.asMap().entries.map((entry) {
      final index = entry.key.toDouble();
      final year = entry.value;
      final value = _trendData[year]!;
      return FlSpot(index, value);
    }).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${_selectedPlayer} - ${_metrics[_selectedMetric]} Trend',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 300,
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: true),
                  titlesData: FlTitlesData(
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: true, reservedSize: 40),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index >= 0 && index < sortedYears.length) {
                            return Text(sortedYears[index].toString());
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(show: true),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      color: Colors.blue,
                      barWidth: 3,
                      dotData: const FlDotData(show: true),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCareerStatsTable() {
    if (_playerData.isEmpty) return const SizedBox.shrink();
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${_selectedPlayer} - Career Statistics',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columnSpacing: 16,
                columns: const [
                  DataColumn(label: Text('Season', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Team', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Games', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('PPR Pts', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('PPR/Game', style: TextStyle(fontWeight: FontWeight.bold))),
                ],
                rows: _playerData.map((season) {
                  return DataRow(cells: [
                    DataCell(Text(season['season']?.toString() ?? '-')),
                    DataCell(Text(season['recent_team']?.toString() ?? '-')),
                    DataCell(Text(season['games']?.toString() ?? '-')),
                    DataCell(Text(season['fantasy_points_ppr']?.toStringAsFixed(1) ?? '-')),
                    DataCell(Text(season['fantasy_points_ppr_per_game']?.toStringAsFixed(1) ?? '-')),
                  ]);
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}