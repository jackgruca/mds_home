import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mds_home/utils/team_logo_utils.dart';
import 'dart:math';

import '../../widgets/common/custom_app_bar.dart';
import '../../widgets/common/app_drawer.dart';
import '../../widgets/common/top_nav_bar.dart';
import '../../widgets/auth/auth_dialog.dart';
import '../../utils/theme_config.dart';
import '../../widgets/design_system/mds_table.dart';

class PlayerTrendsScreen extends StatefulWidget {
  const PlayerTrendsScreen({super.key});

  @override
  _PlayerTrendsScreenState createState() => _PlayerTrendsScreenState();
}

class _PlayerTrendsScreenState extends State<PlayerTrendsScreen> {
  String _selectedPosition = 'RB';
  double _selectedWeeks = 4;
  List<Map<String, dynamic>> _playerData = [];
  bool _isLoading = true;
  String _sortColumn = 'recent_avg_fantasy_points_ppr';
  bool _sortAscending = false;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _fetchAndProcessPlayerTrends();
  }
  
  double _getMedian(List<double> arr) {
    if (arr.isEmpty) return 0;
    final sorted = [...arr]..sort((a, b) => a.compareTo(b));
    final mid = (sorted.length / 2).floor();
    if (sorted.length % 2 == 0) {
      return (sorted[mid - 1] + sorted[mid]) / 2;
    }
    return sorted[mid].toDouble();
  }

  // Helper to calculate stats for a list of game logs
  Map<String, double> _calculateStatsForLogs(List<Map<String, dynamic>> logs) {
    if (logs.isEmpty) return {};

    final games = logs.length.toDouble();
    
    // Generic stats for all positions
    final pprPoints = logs.map((l) => (l['fantasy_points_ppr'] as num? ?? 0).toDouble()).toList();
    
    // Position-specific stats
    List<double> targets = [], receptions = [], receivingYards = [], receivingTds = [];
    List<double> carries = [], rushingYards = [], rushingTds = [];
    List<double> passAttempts = [], passYards = [], passTds = [];
    
    for (var log in logs) {
        targets.add((log['targets'] as num? ?? 0).toDouble());
        receptions.add((log['receptions'] as num? ?? 0).toDouble());
        receivingYards.add((log['receiving_yards'] as num? ?? 0).toDouble());
        receivingTds.add((log['receiving_tds'] as num? ?? 0).toDouble());
        carries.add((log['carries'] as num? ?? 0).toDouble());
        rushingYards.add((log['rushing_yards'] as num? ?? 0).toDouble());
        rushingTds.add((log['rushing_tds'] as num? ?? 0).toDouble());
        passAttempts.add((log['attempts'] as num? ?? 0).toDouble());
        passYards.add((log['passing_yards'] as num? ?? 0).toDouble());
        passTds.add((log['passing_tds'] as num? ?? 0).toDouble());
    }

    final totalPPR = pprPoints.fold(0.0, (a, b) => a + b);

    // Combine rushing and receiving TDs for RBs and WRs/TEs
    final totalCombinedTds = List.generate(logs.length, (i) => receivingTds[i] + rushingTds[i]).fold(0.0, (a,b) => a+b);

    return {
      'games': games,
      'avg_fantasy_points_ppr': totalPPR / games,
      'median_fantasy_points_ppr': _getMedian(pprPoints),
      
      // WR/TE
      'avg_targets': targets.fold(0.0, (a,b) => a+b) / games,
      'avg_receptions': receptions.fold(0.0, (a,b) => a+b) / games,
      'avg_receiving_yards': receivingYards.fold(0.0, (a,b) => a+b) / games,
      
      // RB
      'avg_carries': carries.fold(0.0, (a,b) => a+b) / games,
      'avg_rushing_yards': rushingYards.fold(0.0, (a,b) => a+b) / games,
      'avg_total_td': totalCombinedTds / games,

      // QB
      'avg_passing_attempts': passAttempts.fold(0.0, (a,b) => a+b) / games,
      'avg_passing_yards': passYards.fold(0.0, (a,b) => a+b) / games,
      'avg_passing_tds': passTds.fold(0.0, (a,b) => a+b) / games,
      'avg_rushing_attempts_qb': carries.fold(0.0, (a,b) => a+b) / games,
      'avg_rushing_yards_qb': rushingYards.fold(0.0, (a,b) => a+b) / games,
      'avg_rushing_tds_qb': rushingTds.fold(0.0, (a,b) => a+b) / games,
    };
  }

  Future<void> _fetchAndProcessPlayerTrends() async {
    setState(() { _isLoading = true; });

    try {
      final querySnapshot = await _firestore
          .collection('playerGameLogs')
          .where('season', isEqualTo: 2023)
          .where('position', isEqualTo: _selectedPosition)
          .get();

      if (querySnapshot.docs.isEmpty) {
        setState(() { _playerData = []; _isLoading = false; });
        return;
      }
      
      final playersData = <String, dynamic>{};
      for (var doc in querySnapshot.docs) {
        final log = doc.data();
        final playerId = log['player_id'];
        if (playerId == null) continue;

        if (!playersData.containsKey(playerId)) {
          playersData[playerId] = {
            'player_name': log['player_name'],
            'position': log['position'],
            'team': log['team'],
            'logs': <Map<String, dynamic>>[]
          };
        }
        playersData[playerId]['logs'].add(log);
      }

      final List<Map<String, dynamic>> results = [];
      playersData.forEach((playerId, player) {
        final allLogs = (player['logs'] as List<Map<String, dynamic>>)..sort((a,b) => (b['week'] as int).compareTo(a['week'] as int));
        if (allLogs.isEmpty) return;
        
        final maxWeek = allLogs.first['week'] as int;
        final startWeek = max(1, maxWeek - _selectedWeeks.toInt() + 1);
        final recentLogs = allLogs.where((log) => (log['week'] as int) >= startWeek).toList();

        final fullSeasonStats = _calculateStatsForLogs(allLogs);
        final recentStats = _calculateStatsForLogs(recentLogs);
        
        // --- Calculate Trend Flags ---
        final Map<String, dynamic> trends = {};
        if (fullSeasonStats.isNotEmpty && recentStats.isNotEmpty) {
            // Define key metrics for trend calculation
            double fullUsage = 0, recentUsage = 0;
            final fullResult = fullSeasonStats['avg_fantasy_points_ppr'] ?? 0;
            final recentResult = recentStats['avg_fantasy_points_ppr'] ?? 0;

            if (_selectedPosition == 'RB') {
                fullUsage = (fullSeasonStats['avg_carries'] ?? 0) + (fullSeasonStats['avg_targets'] ?? 0);
                recentUsage = (recentStats['avg_carries'] ?? 0) + (recentStats['avg_targets'] ?? 0);
            } else if (_selectedPosition == 'WR' || _selectedPosition == 'TE') {
                fullUsage = fullSeasonStats['avg_targets'] ?? 0;
                recentUsage = recentStats['avg_targets'] ?? 0;
            } else if (_selectedPosition == 'QB') {
                fullUsage = fullSeasonStats['avg_passing_attempts'] ?? 0;
                recentUsage = recentStats['avg_passing_attempts'] ?? 0;
            }

            // Calculate percentage change and set flags
            if (fullUsage > 0) {
                final usageChange = (recentUsage - fullUsage) / fullUsage;
                trends['usage_value'] = usageChange;
            }
            if (fullResult > 0) {
                final resultChange = (recentResult - fullResult) / fullResult;
                trends['result_value'] = resultChange;
            }
        }
        
        final combinedData = <String, dynamic>{
          'playerName': player['player_name'],
          'team': player['team'],
          ...trends,
        };

        fullSeasonStats.forEach((key, value) {
          combinedData['full_$key'] = value;
        });
        recentStats.forEach((key, value) {
          combinedData['recent_$key'] = value;
        });

        results.add(combinedData);
      });
      
      setState(() {
        _playerData = results;
        _sortData();
        _isLoading = false;
      });

    } catch (e) {
      print("Error processing player trends: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error processing data: ${e.toString()}')),
        );
      }
      setState(() { _playerData = []; _isLoading = false; });
    }
  }
  
  void _onSort(String column, bool ascending) {
    setState(() {
      _sortColumn = column;
      _sortAscending = ascending;
      _sortData();
    });
  }

  void _sortData() {
    _playerData.sort((a, b) {
      final aValue = a[_sortColumn] as num?;
      final bValue = b[_sortColumn] as num?;
      
      if (aValue == null && bValue == null) return 0;
      if (aValue == null) return _sortAscending ? -1 : 1;
      if (bValue == null) return _sortAscending ? 1 : -1;

      final comparison = aValue.compareTo(bValue);
      return _sortAscending ? comparison : -comparison;
    });
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
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: Material(
              elevation: 2,
              borderRadius: BorderRadius.circular(24),
              shadowColor: ThemeConfig.gold.withOpacity(0.3),
              child: ElevatedButton(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  showDialog(context: context, builder: (_) => const AuthDialog());
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: ThemeConfig.darkNavy,
                  foregroundColor: ThemeConfig.gold,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                child: const Text('Sign In / Sign Up'),
              ),
            ),
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Card(
          elevation: 2,
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              _buildControls(),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _playerData.isEmpty 
                        ? const Center(child: Text('No data available for the selected filters.'))
                        : _buildDataTable(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildControls() {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        children: [
          Row(
            children: [
              const Text('Position: '),
              const SizedBox(width: 10),
              DropdownButton<String>(
                value: _selectedPosition,
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _selectedPosition = newValue;
                      _fetchAndProcessPlayerTrends();
                    });
                  }
                },
                items: <String>['RB', 'WR', 'TE', 'QB'].map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: _isLoading ? null : _fetchAndProcessPlayerTrends,
                child: const Text('Reload Data'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _buildSlider('Compare Recent Weeks:', _selectedWeeks, 1, 17, (val) => setState(() => _selectedWeeks = val)),
        ],
      ),
    );
  }

  Widget _buildSlider(String label, double value, double min, double max, ValueChanged<double> onChanged) {
    return Row(
      children: [
        Text(label),
        Expanded(
          child: Slider(
            value: value,
            min: min,
            max: max,
            divisions: (max - min).toInt(),
            label: 'Last ${value.round()} weeks',
            onChanged: onChanged,
            onChangeEnd: (value) => _fetchAndProcessPlayerTrends(),
          ),
        ),
      ],
    );
  }

  Widget _buildDataTable() {
    if (_playerData.isEmpty && !_isLoading) {
      return const Center(
        child: Text('No data found. Try adjusting your filters.',
            style: TextStyle(fontSize: 16)),
      );
    }

    return Column(
      children: [
        _buildSectionHeaders(),
        Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.surface,
                  Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(
                color: ThemeConfig.gold.withOpacity(0.2),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: ThemeConfig.darkNavy.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
              child: MdsTable(
                style: MdsTableStyle.premium,
                density: MdsTableDensity.comfortable,
                columns: _getMdsColumns(),
                rows: _getMdsRows(),
                sortColumn: _sortColumn,
                sortAscending: _sortAscending,
                showBorder: false, // Remove border since we're handling it with the container
                padding: EdgeInsets.zero, // Remove default padding
                onSort: (columnKey, ascending) {
                  setState(() {
                    _sortColumn = columnKey;
                    _sortAscending = ascending;
                    _sortData();
                  });
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeaders() {
    // Calculate exact column counts based on actual column structure
    final toDateCount = _getToDateColumnCount();
    final recentCount = _getRecentColumnCount();
    const trendsCount = 2; // Usage + Result
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
        gradient: LinearGradient(
          colors: [
            ThemeConfig.darkNavy,
            ThemeConfig.darkNavy.withOpacity(0.9),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: const Color(0xFFFFD700), // Gold trim
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Table(
        columnWidths: {
          0: const FlexColumnWidth(1), // Player column
          1: FlexColumnWidth(toDateCount.toDouble()), // Season To-Date columns
          2: FlexColumnWidth(recentCount.toDouble()), // Recent columns  
          3: const FlexColumnWidth(2), // Trends columns
        },
        children: [
          TableRow(
            children: [
              Container(
                height: 48,
                alignment: Alignment.center,
                child: const Text(
                  '',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Container(
                height: 48,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  border: Border(
                    left: BorderSide(color: Colors.white24, width: 1),
                    right: BorderSide(color: Colors.white24, width: 1),
                  ),
                ),
                child: const Text(
                  'Season To-Date',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Container(
                height: 48,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  border: Border(
                    right: BorderSide(color: Colors.white24, width: 1),
                  ),
                ),
                child: Text(
                  'Recent ${_selectedWeeks.round()} Weeks',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Container(
                height: 48,
                alignment: Alignment.center,
                child: const Text(
                  'Trends',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  int _getToDateColumnCount() {
    int count = 2; // Games + PPR
    if (_selectedPosition == 'WR' || _selectedPosition == 'TE') {
      count += 4; // Tgt, Rec, Yds, TD
    } else if (_selectedPosition == 'RB') {
      count += 5; // Car, RuYd, Tgt, ReYd, TD
    } else if (_selectedPosition == 'QB') {
      count += 6; // Att, PaYd, PaTD, RAtt, RuYd, RuTD
    }
    return count;
  }

  int _getRecentColumnCount() {
    int count = 3; // Games + PPR + Med
    if (_selectedPosition == 'WR' || _selectedPosition == 'TE') {
      count += 4; // Tgt, Rec, Yds, TD
    } else if (_selectedPosition == 'RB') {
      count += 5; // Car, RuYd, Tgt, ReYd, TD
    } else if (_selectedPosition == 'QB') {
      count += 6; // Att, PaYd, PaTD, RAtt, RuYd, RuTD
    }
    return count;
  }
  
  List<MdsTableColumn> _getMdsColumns() {
    List<MdsTableColumn> columns = [
      MdsTableColumn(
        key: 'playerName',
        label: 'Player',
        numeric: false,
        cellBuilder: (value, rowIndex, percentile) {
          final player = _playerData[rowIndex];
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (player['team'] != null && (player['team'] as String).isNotEmpty)
                TeamLogoUtils.buildNFLTeamLogo(player['team'], size: 24),
              const SizedBox(width: 8),
              Text(player['playerName'] as String? ?? 'N/A'),
            ],
          );
        },
      ),
    ];

    // --- TO-DATE STATS ---
    columns.addAll([
      const MdsTableColumn(key: 'full_games', label: 'G', numeric: true, enablePercentileShading: true),
      const MdsTableColumn(key: 'full_avg_fantasy_points_ppr', label: 'PPR', numeric: true, enablePercentileShading: true, isDoubleField: true),
    ]);

    if (_selectedPosition == 'WR' || _selectedPosition == 'TE') {
      columns.addAll([
        const MdsTableColumn(key: 'full_avg_targets', label: 'Tgt', numeric: true, enablePercentileShading: true, isDoubleField: true),
        const MdsTableColumn(key: 'full_avg_receptions', label: 'Rec', numeric: true, enablePercentileShading: true, isDoubleField: true),
        const MdsTableColumn(key: 'full_avg_receiving_yards', label: 'Yds', numeric: true, enablePercentileShading: true, isDoubleField: true),
        const MdsTableColumn(key: 'full_avg_total_td', label: 'TD', numeric: true, enablePercentileShading: true, isDoubleField: true),
      ]);
    } else if (_selectedPosition == 'RB') {
      columns.addAll([
        const MdsTableColumn(key: 'full_avg_carries', label: 'Car', numeric: true, enablePercentileShading: true, isDoubleField: true),
        const MdsTableColumn(key: 'full_avg_rushing_yards', label: 'RuYd', numeric: true, enablePercentileShading: true, isDoubleField: true),
        const MdsTableColumn(key: 'full_avg_targets', label: 'Tgt', numeric: true, enablePercentileShading: true, isDoubleField: true),
        const MdsTableColumn(key: 'full_avg_receiving_yards', label: 'ReYd', numeric: true, enablePercentileShading: true, isDoubleField: true),
        const MdsTableColumn(key: 'full_avg_total_td', label: 'TD', numeric: true, enablePercentileShading: true, isDoubleField: true),
      ]);
    } else if (_selectedPosition == 'QB') {
      columns.addAll([
        const MdsTableColumn(key: 'full_avg_passing_attempts', label: 'Att', numeric: true, enablePercentileShading: true, isDoubleField: true),
        const MdsTableColumn(key: 'full_avg_passing_yards', label: 'PaYd', numeric: true, enablePercentileShading: true, isDoubleField: true),
        const MdsTableColumn(key: 'full_avg_passing_tds', label: 'PaTD', numeric: true, enablePercentileShading: true, isDoubleField: true),
        const MdsTableColumn(key: 'full_avg_rushing_attempts_qb', label: 'RAtt', numeric: true, enablePercentileShading: true, isDoubleField: true),
        const MdsTableColumn(key: 'full_avg_rushing_yards_qb', label: 'RuYd', numeric: true, enablePercentileShading: true, isDoubleField: true),
        const MdsTableColumn(key: 'full_avg_rushing_tds_qb', label: 'RuTD', numeric: true, enablePercentileShading: true, isDoubleField: true),
      ]);
    }

    // --- RECENT STATS ---
    columns.addAll([
      const MdsTableColumn(key: 'recent_games', label: 'G', numeric: true, enablePercentileShading: true),
      const MdsTableColumn(key: 'recent_avg_fantasy_points_ppr', label: 'PPR', numeric: true, enablePercentileShading: true, isDoubleField: true),
      const MdsTableColumn(key: 'recent_median_fantasy_points_ppr', label: 'Med', numeric: true, enablePercentileShading: true, isDoubleField: true),
    ]);

    if (_selectedPosition == 'WR' || _selectedPosition == 'TE') {
      columns.addAll([
        const MdsTableColumn(key: 'recent_avg_targets', label: 'Tgt', numeric: true, enablePercentileShading: true, isDoubleField: true),
        const MdsTableColumn(key: 'recent_avg_receptions', label: 'Rec', numeric: true, enablePercentileShading: true, isDoubleField: true),
        const MdsTableColumn(key: 'recent_avg_receiving_yards', label: 'Yds', numeric: true, enablePercentileShading: true, isDoubleField: true),
        const MdsTableColumn(key: 'recent_avg_total_td', label: 'TD', numeric: true, enablePercentileShading: true, isDoubleField: true),
      ]);
    } else if (_selectedPosition == 'RB') {
      columns.addAll([
        const MdsTableColumn(key: 'recent_avg_carries', label: 'Car', numeric: true, enablePercentileShading: true, isDoubleField: true),
        const MdsTableColumn(key: 'recent_avg_rushing_yards', label: 'RuYd', numeric: true, enablePercentileShading: true, isDoubleField: true),
        const MdsTableColumn(key: 'recent_avg_targets', label: 'Tgt', numeric: true, enablePercentileShading: true, isDoubleField: true),
        const MdsTableColumn(key: 'recent_avg_receiving_yards', label: 'ReYd', numeric: true, enablePercentileShading: true, isDoubleField: true),
        const MdsTableColumn(key: 'recent_avg_total_td', label: 'TD', numeric: true, enablePercentileShading: true, isDoubleField: true),
      ]);
    } else if (_selectedPosition == 'QB') {
      columns.addAll([
        const MdsTableColumn(key: 'recent_avg_passing_attempts', label: 'Att', numeric: true, enablePercentileShading: true, isDoubleField: true),
        const MdsTableColumn(key: 'recent_avg_passing_yards', label: 'PaYd', numeric: true, enablePercentileShading: true, isDoubleField: true),
        const MdsTableColumn(key: 'recent_avg_passing_tds', label: 'PaTD', numeric: true, enablePercentileShading: true, isDoubleField: true),
        const MdsTableColumn(key: 'recent_avg_rushing_attempts_qb', label: 'RAtt', numeric: true, enablePercentileShading: true, isDoubleField: true),
        const MdsTableColumn(key: 'recent_avg_rushing_yards_qb', label: 'RuYd', numeric: true, enablePercentileShading: true, isDoubleField: true),
        const MdsTableColumn(key: 'recent_avg_rushing_tds_qb', label: 'RuTD', numeric: true, enablePercentileShading: true, isDoubleField: true),
      ]);
    }

    // --- TRENDS ---
    columns.addAll([
      MdsTableColumn(
        key: 'usage_value', 
        label: 'Usage', 
        numeric: true,
        cellBuilder: (value, rowIndex, percentile) => _buildTrendCellContent(value),
      ),
      MdsTableColumn(
        key: 'result_value', 
        label: 'Result', 
        numeric: true,
        cellBuilder: (value, rowIndex, percentile) => _buildTrendCellContent(value),
      ),
    ]);

    return columns;
  }

  List<MdsTableRow> _getMdsRows() {
    return _playerData.asMap().entries.map((entry) {
      final int index = entry.key;
      final player = entry.value;
      
      return MdsTableRow(
        id: 'player_$index',
        data: player,
      );
    }).toList();
  }

  Widget _buildMdsCellContent(String columnKey, dynamic value, Map<String, dynamic> player) {
    // Handle player name with team logo
    if (columnKey == 'playerName') {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (player['team'] != null && (player['team'] as String).isNotEmpty)
            TeamLogoUtils.buildNFLTeamLogo(player['team'], size: 24),
          const SizedBox(width: 8),
          Text(player['playerName'] as String? ?? 'N/A'),
        ],
      );
    }

    // Handle trend cells with special color coding
    if (columnKey == 'usage_value' || columnKey == 'result_value') {
      return _buildTrendCellContent(value);
    }

    // Handle numeric stats
    if (value is num) {
      return Text((value).toStringAsFixed(1));
    }

    return Text(value?.toString() ?? '-');
  }

  Widget _buildTrendCellContent(dynamic value) {
    if (value == null) {
      return const Text('-');
    }

    final doubleValue = (value is num) ? value.toDouble() : null;
    if (doubleValue == null) {
      return const Text('-');
    }

    final color = _getColorForPercentage(doubleValue);
    final textColor = color.computeLuminance() > 0.5 ? Colors.black : Colors.white;
    final text = '${(doubleValue * 100).toStringAsFixed(1)}%';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
        textAlign: TextAlign.center,
      ),
    );
  }

  Color _getColorForPercentage(double? value) {
    if (value == null) return Colors.transparent;

    // Clamp the value to a range of -30% to +30% for color scaling
    final clampedValue = value.clamp(-0.3, 0.3);

    // Red -> Yellow -> Green gradient
    if (clampedValue < 0) {
      // Interpolate between Yellow and Red
      return Color.lerp(Colors.yellow.shade600, Colors.red.shade500, clampedValue.abs() / 0.3)!;
    } else {
      // Interpolate between Yellow and Green
      return Color.lerp(Colors.yellow.shade600, Colors.green.shade500, clampedValue / 0.3)!;
    }
  }
} 