import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mds_home/utils/team_logo_utils.dart';
import 'dart:math';

import '../../widgets/common/custom_app_bar.dart';
import '../../widgets/common/app_drawer.dart';
import '../../widgets/common/top_nav_bar.dart';
import '../../widgets/auth/auth_dialog.dart';

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
    final theme = Theme.of(context);

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
            child: ElevatedButton(
              onPressed: () => showDialog(context: context, builder: (_) => const AuthDialog()),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
              ),
              child: const Text('Sign In / Sign Up'),
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
    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Theme(
          data: Theme.of(context).copyWith(
            dividerColor: Colors.grey.shade300,
            dataTableTheme: DataTableThemeData(
              headingRowColor: WidgetStateProperty.all(Colors.blue.shade700),
              headingTextStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          child: DataTable(
            columnSpacing: 28.0,
            horizontalMargin: 10.0,
            sortColumnIndex: _getColumnIndex(_sortColumn),
            sortAscending: _sortAscending,
            columns: _getColumns(),
            rows: _getRows(),
          ),
        ),
      ),
    );
  }
  
  DataCell _buildStatCell(dynamic value) {
    return DataCell(Text((value as num?)?.toStringAsFixed(1) ?? '0.0'));
  }

  List<DataColumn> _getColumns() {
    List<DataColumn> columns = [
      DataColumn(label: const Text('Player'), onSort: (i, asc) => _onSort('playerName', asc)),
    ];

    // --- TO-DATE STATS ---
    columns.addAll([
      DataColumn(label: const Text('Games'), numeric: true, onSort: (i, asc) => _onSort('full_games', asc)),
      DataColumn(label: const Text('Avg\nPPR'), numeric: true, onSort: (i, asc) => _onSort('full_avg_fantasy_points_ppr', asc)),
    ]);
    if (_selectedPosition == 'WR' || _selectedPosition == 'TE') {
      columns.addAll([
        DataColumn(label: const Text('Avg\nTgt'), numeric: true, onSort: (i, asc) => _onSort('full_avg_targets', asc)),
        DataColumn(label: const Text('Avg\nRec'), numeric: true, onSort: (i, asc) => _onSort('full_avg_receptions', asc)),
        DataColumn(label: const Text('Avg\nYds'), numeric: true, onSort: (i, asc) => _onSort('full_avg_receiving_yards', asc)),
        DataColumn(label: const Text('Avg\nTD'), numeric: true, onSort: (i, asc) => _onSort('full_avg_total_td', asc)),
      ]);
    } else if (_selectedPosition == 'RB') {
      columns.addAll([
        DataColumn(label: const Text('Avg\nRush'), numeric: true, onSort: (i, asc) => _onSort('full_avg_carries', asc)),
        DataColumn(label: const Text('Avg\nRush Yds'), numeric: true, onSort: (i, asc) => _onSort('full_avg_rushing_yards', asc)),
        DataColumn(label: const Text('Avg\nTgt'), numeric: true, onSort: (i, asc) => _onSort('full_avg_targets', asc)),
        DataColumn(label: const Text('Avg\nRec Yds'), numeric: true, onSort: (i, asc) => _onSort('full_avg_receiving_yards', asc)),
        DataColumn(label: const Text('Avg\nTD'), numeric: true, onSort: (i, asc) => _onSort('full_avg_total_td', asc)),
      ]);
    } else if (_selectedPosition == 'QB') {
      columns.addAll([
        DataColumn(label: const Text('Avg\nAtt'), numeric: true, onSort: (i, asc) => _onSort('full_avg_passing_attempts', asc)),
        DataColumn(label: const Text('Avg\nPass Yds'), numeric: true, onSort: (i, asc) => _onSort('full_avg_passing_yards', asc)),
        DataColumn(label: const Text('Avg\nPass TD'), numeric: true, onSort: (i, asc) => _onSort('full_avg_passing_tds', asc)),
        DataColumn(label: const Text('Avg\nRush Att'), numeric: true, onSort: (i, asc) => _onSort('full_avg_rushing_attempts_qb', asc)),
        DataColumn(label: const Text('Avg\nRush Yds'), numeric: true, onSort: (i, asc) => _onSort('full_avg_rushing_yards_qb', asc)),
        DataColumn(label: const Text('Avg\nRush TD'), numeric: true, onSort: (i, asc) => _onSort('full_avg_rushing_tds_qb', asc)),
      ]);
    }

    // --- DIVIDER ---
    columns.add(const DataColumn(label: VerticalDivider(width: 1, thickness: 1)));

    // --- RECENT STATS ---
    columns.addAll([
      DataColumn(label: const Text('Games'), numeric: true, onSort: (i, asc) => _onSort('recent_games', asc)),
      DataColumn(label: const Text('Avg\nPPR'), numeric: true, onSort: (i, asc) => _onSort('recent_avg_fantasy_points_ppr', asc)),
      DataColumn(label: const Text('Med\nPPR'), numeric: true, onSort: (i, asc) => _onSort('recent_median_fantasy_points_ppr', asc)),
    ]);
    if (_selectedPosition == 'WR' || _selectedPosition == 'TE') {
      columns.addAll([
        DataColumn(label: const Text('Avg\nTgt'), numeric: true, onSort: (i, asc) => _onSort('recent_avg_targets', asc)),
        DataColumn(label: const Text('Avg\nRec'), numeric: true, onSort: (i, asc) => _onSort('recent_avg_receptions', asc)),
        DataColumn(label: const Text('Avg\nYds'), numeric: true, onSort: (i, asc) => _onSort('recent_avg_receiving_yards', asc)),
        DataColumn(label: const Text('Avg\nTD'), numeric: true, onSort: (i, asc) => _onSort('recent_avg_total_td', asc)),
      ]);
    } else if (_selectedPosition == 'RB') {
        columns.addAll([
        DataColumn(label: const Text('Avg\nRush'), numeric: true, onSort: (i, asc) => _onSort('recent_avg_carries', asc)),
        DataColumn(label: const Text('Avg\nRush Yds'), numeric: true, onSort: (i, asc) => _onSort('recent_avg_rushing_yards', asc)),
        DataColumn(label: const Text('Avg\nTgt'), numeric: true, onSort: (i, asc) => _onSort('recent_avg_targets', asc)),
        DataColumn(label: const Text('Avg\nRec Yds'), numeric: true, onSort: (i, asc) => _onSort('recent_avg_receiving_yards', asc)),
        DataColumn(label: const Text('Avg\nTD'), numeric: true, onSort: (i, asc) => _onSort('recent_avg_total_td', asc)),
      ]);
    } else if (_selectedPosition == 'QB') {
        columns.addAll([
        DataColumn(label: const Text('Avg\nAtt'), numeric: true, onSort: (i, asc) => _onSort('recent_avg_passing_attempts', asc)),
        DataColumn(label: const Text('Avg\nPass Yds'), numeric: true, onSort: (i, asc) => _onSort('recent_avg_passing_yards', asc)),
        DataColumn(label: const Text('Avg\nPass TD'), numeric: true, onSort: (i, asc) => _onSort('recent_avg_passing_tds', asc)),
        DataColumn(label: const Text('Avg\nRush Att'), numeric: true, onSort: (i, asc) => _onSort('recent_avg_rushing_attempts_qb', asc)),
        DataColumn(label: const Text('Avg\nRush Yds'), numeric: true, onSort: (i, asc) => _onSort('recent_avg_rushing_yards_qb', asc)),
        DataColumn(label: const Text('Avg\nRush TD'), numeric: true, onSort: (i, asc) => _onSort('recent_avg_rushing_tds_qb', asc)),
      ]);
    }

    // --- DIVIDER ---
    columns.add(const DataColumn(label: VerticalDivider(width: 1, thickness: 1)));

    // --- TRENDS ---
    columns.addAll([
        DataColumn(label: const Text('Usage\nTrend %'), numeric: true, onSort: (i, asc) => _onSort('usage_value', asc)),
        DataColumn(label: const Text('Result\nTrend %'), numeric: true, onSort: (i, asc) => _onSort('result_value', asc)),
    ]);

    return columns;
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

  DataCell _buildTrendCell(double? value) {
    if (value == null) {
      return const DataCell(Text('-'));
    }

    final color = _getColorForPercentage(value);
    final textColor = color.computeLuminance() > 0.5 ? Colors.black : Colors.white;
    final text = '${(value * 100).toStringAsFixed(1)}%';

    return DataCell(
      SizedBox.expand(
        child: Container(
          color: color,
          alignment: Alignment.center,
          child: Text(
            text,
            style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
        ),
      ),
      showEditIcon: false, 
      placeholder: false,
    );
  }

  List<DataRow> _getRows() {
    return _playerData.asMap().entries.map((entry) {
      final int index = entry.key;
      final player = entry.value;

      final rowColor = WidgetStateProperty.resolveWith<Color?>(
        (Set<WidgetState> states) {
          if (index.isEven) {
            return Colors.grey.withOpacity(0.05);
          }
          return null; // Use default
        },
      );

      List<DataCell> cells = [
        DataCell(
          Row(
            children: [
              if (player['team'] != null && (player['team'] as String).isNotEmpty)
                TeamLogoUtils.buildNFLTeamLogo(player['team'], size: 24),
              const SizedBox(width: 8),
              Text(player['playerName'] as String? ?? 'N/A'),
            ],
          ),
        ),
      ];
      
      // --- TO-DATE STATS ---
      cells.addAll([
        _buildStatCell(player['full_games']),
        _buildStatCell(player['full_avg_fantasy_points_ppr']),
      ]);
      if (_selectedPosition == 'WR' || _selectedPosition == 'TE') {
        cells.addAll([
          _buildStatCell(player['full_avg_targets']),
          _buildStatCell(player['full_avg_receptions']),
          _buildStatCell(player['full_avg_receiving_yards']),
          _buildStatCell(player['full_avg_total_td']),
        ]);
      } else if (_selectedPosition == 'RB') {
        cells.addAll([
          _buildStatCell(player['full_avg_carries']),
          _buildStatCell(player['full_avg_rushing_yards']),
          _buildStatCell(player['full_avg_targets']),
          _buildStatCell(player['full_avg_receiving_yards']),
          _buildStatCell(player['full_avg_total_td']),
        ]);
      } else if (_selectedPosition == 'QB') {
        cells.addAll([
          _buildStatCell(player['full_avg_passing_attempts']),
          _buildStatCell(player['full_avg_passing_yards']),
          _buildStatCell(player['full_avg_passing_tds']),
          _buildStatCell(player['full_avg_rushing_attempts_qb']),
          _buildStatCell(player['full_avg_rushing_yards_qb']),
          _buildStatCell(player['full_avg_rushing_tds_qb']),
        ]);
      }

      // --- DIVIDER ---
      cells.add(const DataCell(VerticalDivider(width: 1, thickness: 1)));

      // --- RECENT STATS ---
      cells.addAll([
        _buildStatCell(player['recent_games']),
        _buildStatCell(player['recent_avg_fantasy_points_ppr']),
        _buildStatCell(player['recent_median_fantasy_points_ppr']),
      ]);
      if (_selectedPosition == 'WR' || _selectedPosition == 'TE') {
        cells.addAll([
          _buildStatCell(player['recent_avg_targets']),
          _buildStatCell(player['recent_avg_receptions']),
          _buildStatCell(player['recent_avg_receiving_yards']),
          _buildStatCell(player['recent_avg_total_td']),
        ]);
      } else if (_selectedPosition == 'RB') {
        cells.addAll([
          _buildStatCell(player['recent_avg_carries']),
          _buildStatCell(player['recent_avg_rushing_yards']),
          _buildStatCell(player['recent_avg_targets']),
          _buildStatCell(player['recent_avg_receiving_yards']),
          _buildStatCell(player['recent_avg_total_td']),
        ]);
      } else if (_selectedPosition == 'QB') {
        cells.addAll([
          _buildStatCell(player['recent_avg_passing_attempts']),
          _buildStatCell(player['recent_avg_passing_yards']),
          _buildStatCell(player['recent_avg_passing_tds']),
          _buildStatCell(player['recent_avg_rushing_attempts_qb']),
          _buildStatCell(player['recent_avg_rushing_yards_qb']),
          _buildStatCell(player['recent_avg_rushing_tds_qb']),
        ]);
      }

      // --- DIVIDER ---
      cells.add(const DataCell(VerticalDivider(width: 1, thickness: 1)));

      // --- TRENDS ---
      cells.addAll([
          _buildTrendCell(player['usage_value']),
          _buildTrendCell(player['result_value']),
      ]);

      return DataRow(cells: cells, color: rowColor);
    }).toList();
  }
  
  int? _getColumnIndex(String column) {
    final List<String> columnIds = [];
    columnIds.add('playerName');
    
    // --- TO-DATE STATS ---
    columnIds.add('full_games');
    columnIds.add('full_avg_fantasy_points_ppr');
    if (_selectedPosition == 'WR' || _selectedPosition == 'TE') {
      columnIds.addAll(['full_avg_targets', 'full_avg_receptions', 'full_avg_receiving_yards', 'full_avg_total_td']);
    } else if (_selectedPosition == 'RB') {
      columnIds.addAll(['full_avg_carries', 'full_avg_rushing_yards', 'full_avg_targets', 'full_avg_receiving_yards', 'full_avg_total_td']);
    } else if (_selectedPosition == 'QB') {
      columnIds.addAll(['full_avg_passing_attempts', 'full_avg_passing_yards', 'full_avg_passing_tds', 'full_avg_rushing_attempts_qb', 'full_avg_rushing_yards_qb', 'full_avg_rushing_tds_qb']);
    }
    
    // --- RECENT STATS ---
    columnIds.add('recent_games');
    columnIds.add('recent_avg_fantasy_points_ppr');
    columnIds.add('recent_median_fantasy_points_ppr');
    if (_selectedPosition == 'WR' || _selectedPosition == 'TE') {
      columnIds.addAll(['recent_avg_targets', 'recent_avg_receptions', 'recent_avg_receiving_yards', 'recent_avg_total_td']);
    } else if (_selectedPosition == 'RB') {
      columnIds.addAll(['recent_avg_carries', 'recent_avg_rushing_yards', 'recent_avg_targets', 'recent_avg_receiving_yards', 'recent_avg_total_td']);
    } else if (_selectedPosition == 'QB') {
      columnIds.addAll(['recent_avg_passing_attempts', 'recent_avg_passing_yards', 'recent_avg_passing_tds', 'recent_avg_rushing_attempts_qb', 'recent_avg_rushing_yards_qb', 'recent_avg_rushing_tds_qb']);
    }
    
    // --- TRENDS ---
    columnIds.addAll(['usage_value', 'result_value']);

    // Find the index in the list of SORTABLE ids
    int sortableIndex = columnIds.indexOf(_sortColumn);
    if (sortableIndex == -1) return null;

    // --- Calculate Visual Index by Accounting for Dividers ---
    final int fullSeasonStatCount;
    if (_selectedPosition == 'WR' || _selectedPosition == 'TE') {
      fullSeasonStatCount = 4;
    } else if (_selectedPosition == 'RB') {
      fullSeasonStatCount = 5;
    } else { // QB
      fullSeasonStatCount = 6;
    }
    final toDateColumnCount = 1 + 2 + fullSeasonStatCount;

    final int recentStatCount;
    if (_selectedPosition == 'WR' || _selectedPosition == 'TE') {
      recentStatCount = 3 + 4;
    } else if (_selectedPosition == 'RB') {
      recentStatCount = 3 + 5;
    } else { // QB
      recentStatCount = 3 + 6;
    }
    
    final recentSectionStartIndex = toDateColumnCount;
    final trendsSectionStartIndex = toDateColumnCount + recentStatCount;

    if (sortableIndex >= trendsSectionStartIndex) {
      // It's a trend stat, after TWO dividers
      return sortableIndex + 2;
    } else if (sortableIndex >= recentSectionStartIndex) {
      // It's a recent stat, after ONE divider
      return sortableIndex + 1;
    } else {
      // It's a to-date stat, before any dividers
      return sortableIndex;
    }
  }
} 