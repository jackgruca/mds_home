import 'package:flutter/material.dart';
import '../../services/analytics_api_service.dart';
import '../../utils/team_logo_utils.dart';

class AdvancedInsightsTab extends StatefulWidget {
  final int draftYear;

  const AdvancedInsightsTab({
    super.key,
    required this.draftYear,
  });

  @override
  _AdvancedInsightsTabState createState() => _AdvancedInsightsTabState();
}

class _AdvancedInsightsTabState extends State<AdvancedInsightsTab>
    with AutomaticKeepAliveClientMixin {
  bool _isLoading = true;
  bool _hasError = false;
  String _selectedMetric = 'Team Performance';

  // Data states
  Map<String, dynamic> _teamPerformance = {};
  Map<String, dynamic> _playerCorrelations = {};
  Map<String, dynamic> _historicalTrends = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final futures = <Future>[];

      final teamPerformanceFuture = _loadTeamPerformanceData();
      futures.add(teamPerformanceFuture);

      final correlationsFuture = _loadPlayerCorrelationsData();
      futures.add(correlationsFuture);

      final trendsFuture = _loadHistoricalTrendsData();
      futures.add(trendsFuture);

      await Future.wait(futures);
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading advanced analytics data: $e');
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
    }
  }

  // Sample API calls with delayed dummy data
  Future<void> _loadTeamPerformanceData() async {
    _teamPerformance = {
      'metrics': {
        'Arizona Cardinals': {
          'avgPickValue': 12.3,
          'totalPicks': 8,
          'picksByRound': {
            '1': 1,
            '2': 1,
            '3': 2,
            '4': 1,
            '5': 1,
            '6': 1,
            '7': 1
          },
          'positionDistribution': {
            'OT': {'count': 2, 'percentage': '25.0%'},
            'WR': {'count': 2, 'percentage': '25.0%'},
            'CB': {'count': 2, 'percentage': '25.0%'},
            'EDGE': {'count': 1, 'percentage': '12.5%'},
            'QB': {'count': 1, 'percentage': '12.5%'},
          },
          'tradeUpFrequency': 0.2,
          'tradeDownFrequency': 0.3,
        },
        'Atlanta Falcons': {
          'avgPickValue': 8.7,
          'totalPicks': 7,
          'picksByRound': {
            '1': 1,
            '2': 1,
            '3': 1,
            '4': 1,
            '5': 1,
            '6': 1,
            '7': 1
          },
          'positionDistribution': {
            'QB': {'count': 1, 'percentage': '14.3%'},
            'EDGE': {'count': 2, 'percentage': '28.6%'},
            'CB': {'count': 1, 'percentage': '14.3%'},
            'WR': {'count': 1, 'percentage': '14.3%'},
            'OT': {'count': 1, 'percentage': '14.3%'},
            'RB': {'count': 1, 'percentage': '14.3%'},
          },
          'tradeUpFrequency': 0.4,
          'tradeDownFrequency': 0.1,
        },
      }
    };
    return Future.delayed(const Duration(milliseconds: 300));
  }

  Future<void> _loadPlayerCorrelationsData() async {
    _playerCorrelations = {
      'playerCorrelations': [
        {
          'player1': {'name': 'Caleb Williams', 'position': 'QB'},
          'player2': {'name': 'Malik Nabers', 'position': 'WR'},
          'count': 18
        },
        {
          'player1': {'name': 'Drake Maye', 'position': 'QB'},
          'player2': {'name': 'Olu Fashanu', 'position': 'OT'},
          'count': 14
        },
        {
          'player1': {'name': 'Jayden Daniels', 'position': 'QB'},
          'player2': {'name': 'Rome Odunze', 'position': 'WR'},
          'count': 12
        }
      ],
      'positionCorrelations': [
        {
          'position1': 'QB',
          'position2': 'WR',
          'count': 32,
          'examples': [
            {
              'player1': 'Caleb Williams',
              'player2': 'Malik Nabers',
              'count': 18
            },
            {
              'player1': 'Jayden Daniels',
              'player2': 'Rome Odunze',
              'count': 12
            }
          ]
        },
        {
          'position1': 'QB',
          'position2': 'OT',
          'count': 28,
          'examples': [
            {
              'player1': 'Drake Maye',
              'player2': 'Olu Fashanu',
              'count': 14
            },
            {
              'player1': 'Michael Penix Jr.',
              'player2': 'JC Latham',
              'count': 10
            }
          ]
        },
        {
          'position1': 'EDGE',
          'position2': 'CB',
          'count': 25,
          'examples': [
            {
              'player1': 'Dallas Turner',
              'player2': 'Quinyon Mitchell',
              'count': 12
            },
            {
              'player1': 'Jared Verse',
              'player2': 'Terrion Arnold',
              'count': 9
            }
          ]
        }
      ]
    };
    return Future.delayed(const Duration(milliseconds: 300));
  }

  Future<void> _loadHistoricalTrendsData() async {
    _historicalTrends = {
      'trends': {
        'positionTrends': {
          '2025-01': {
            'QB': {'count': 15, 'percentage': 0.14},
            'EDGE': {'count': 12, 'percentage': 0.11},
            'WR': {'count': 18, 'percentage': 0.17},
            'OT': {'count': 14, 'percentage': 0.13},
            'CB': {'count': 16, 'percentage': 0.15},
          },
          '2025-02': {
            'QB': {'count': 14, 'percentage': 0.13},
            'EDGE': {'count': 14, 'percentage': 0.13},
            'WR': {'count': 20, 'percentage': 0.19},
            'OT': {'count': 15, 'percentage': 0.14},
            'CB': {'count': 14, 'percentage': 0.13},
          },
          '2025-03': {
            'QB': {'count': 12, 'percentage': 0.11},
            'EDGE': {'count': 15, 'percentage': 0.14},
            'WR': {'count': 22, 'percentage': 0.21},
            'OT': {'count': 13, 'percentage': 0.12},
            'CB': {'count': 16, 'percentage': 0.15},
          }
        },
        'tradeTrends': {
          'tradeFrequency': {
            '2025-01': 1.8,
            '2025-02': 2.1,
            '2025-03': 2.4
          },
          'averageValueDifferential': {
            '2025-01': 112.3,
            '2025-02': 98.6,
            '2025-03': 104.8
          }
        },
        'top10Players': {
          '2025-01': [
            {
              'name': 'Caleb Williams',
              'position': 'QB',
              'count': 32,
              'percentage': '94.1%'
            },
            {
              'name': 'Malik Nabers',
              'position': 'WR',
              'count': 28,
              'percentage': '82.4%'
            },
            {
              'name': 'Drake Maye',
              'position': 'QB',
              'count': 26,
              'percentage': '76.5%'
            }
          ],
          '2025-02': [
            {
              'name': 'Caleb Williams',
              'position': 'QB',
              'count': 35,
              'percentage': '92.1%'
            },
            {
              'name': 'Malik Nabers',
              'position': 'WR',
              'count': 30,
              'percentage': '78.9%'
            },
            {
              'name': 'Drake Maye',
              'position': 'QB',
              'count': 29,
              'percentage': '76.3%'
            }
          ],
          '2025-03': [
            {
              'name': 'Caleb Williams',
              'position': 'QB',
              'count': 38,
              'percentage': '90.5%'
            },
            {
              'name': 'Malik Nabers',
              'position': 'WR',
              'count': 34,
              'percentage': '81.0%'
            },
            {
              'name': 'Marvin Harrison Jr.',
              'position': 'WR',
              'count': 33,
              'percentage': '78.6%'
            }
          ]
        }
      },
      'months': ['2025-01', '2025-02', '2025-03']
    };
    return Future.delayed(const Duration(milliseconds: 300));
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Metric selector
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              const Text(
                'Metric:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(width: 8),
              DropdownButton<String>(
                value: _selectedMetric,
                onChanged: (newValue) {
                  if (newValue != null) {
                    setState(() {
                      _selectedMetric = newValue;
                    });
                  }
                },
                items: [
                  'Team Performance',
                  'Player Correlations',
                  'Historical Trends',
                ]
                    .map(
                      (metric) => DropdownMenuItem(
                        value: metric,
                        child: Text(metric),
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
        ),
        // Main content
        _hasError
            ? Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 48,
                        color: Colors.orange,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Could not load advanced analytics data',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Advanced analytics features are coming soon.',
                        style: TextStyle(fontSize: 14),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.refresh),
                        label: const Text('Try Again'),
                        onPressed: _loadData,
                      ),
                    ],
                  ),
                ),
              )
            : _isLoading
                ? const Expanded(
                    child: Center(child: CircularProgressIndicator()))
                : Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16.0),
                      child: _buildSelectedMetricView(),
                    ),
                  ),
      ],
    );
  }

  Widget _buildSelectedMetricView() {
    switch (_selectedMetric) {
      case 'Team Performance':
        return _buildTeamPerformanceView();
      case 'Player Correlations':
        return _buildPlayerCorrelationsView();
      case 'Historical Trends':
        return _buildHistoricalTrendsView();
      default:
        return _buildEmptyDataMessage(
          'Select a metric to view advanced analytics',
          'Each metric provides unique insights into draft trends and patterns.',
        );
    }
  }

  Widget _buildTeamPerformanceView() {
    if (_teamPerformance.isEmpty ||
        !_teamPerformance.containsKey('metrics')) {
      return _buildEmptyDataMessage(
        'No team performance data available',
        'Team performance data will populate as the community completes more drafts.',
      );
    }

    final metrics =
        Map<String, dynamic>.from(_teamPerformance['metrics'] as Map);
    // Sort teams by average pick value in descending order
    final sortedTeams = metrics.entries.toList()
      ..sort((a, b) => (b.value['avgPickValue'] as num)
          .compareTo(a.value['avgPickValue'] as num));

    if (sortedTeams.isEmpty) {
      return _buildEmptyDataMessage(
        'No team performance data available',
        'Team performance data will populate as the community completes more drafts.',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Team Draft Strategy Insights',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Table(
              columnWidths: const {
                0: FlexColumnWidth(2), // Team
                1: FlexColumnWidth(1.5), // Avg Value
                2: FlexColumnWidth(1.5), // Trade Up %
                3: FlexColumnWidth(1.5), // Trade Down %
              },
              border: TableBorder.all(color: Colors.grey),
              children: [
                // Header row
                TableRow(
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey.shade800
                        : Colors.grey.shade200,
                  ),
                  children: [
                    _buildTableHeader('Team'),
                    _buildTableHeader('Avg Value'),
                    _buildTableHeader('Trade Up'),
                    _buildTableHeader('Trade Down'),
                  ],
                ),
                // Data rows
                ...sortedTeams.take(10).map((entry) {
                  final team = entry.key;
                  final teamData = entry.value as Map;
                  return TableRow(
                    children: [
                      // Team Name with logo
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 24,
                              height: 24,
                              child: TeamLogoUtils.buildNFLTeamLogo(team, size: 20),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                team,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Avg Pick Value
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          (teamData['avgPickValue'] as num).toStringAsFixed(1),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: (teamData['avgPickValue'] as num) >= 0
                                ? Colors.green
                                : Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      // Trade Up Frequency
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          '${((teamData['tradeUpFrequency'] as num) * 100).toStringAsFixed(1)}%',
                          textAlign: TextAlign.center,
                        ),
                      ),
                      // Trade Down Frequency
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          '${((teamData['tradeDownFrequency'] as num) * 100).toStringAsFixed(1)}%',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  );
                }),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Round 1 Position Preferences',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        _buildRound1PositionChart(metrics),
      ],
    );
  }

  Widget _buildRound1PositionChart(Map<String, dynamic> metrics) {
    final round1Positions = <String, int>{};

    for (var teamData in metrics.values) {
      if (teamData['picksByRound']?.containsKey('1') == true) {
        // Get the most common position for round 1 from the team's position distribution
        final positions = Map<String, dynamic>.from(teamData['positionDistribution']);
        String? topPosition;
        int maxCount = 0;
        for (var entry in positions.entries) {
          final pos = entry.key;
          final count = entry.value['count'] as int;
          if (count > maxCount) {
            maxCount = count;
            topPosition = pos;
          }
        }
        if (topPosition != null) {
          round1Positions[topPosition] = (round1Positions[topPosition] ?? 0) + 1;
        }
      }
    }

    final sortedPositions = round1Positions.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    if (sortedPositions.isEmpty) {
      return _buildEmptyDataMessage(
        'No round 1 position data available',
        'Round 1 position preferences will populate as more data is collected.',
      );
    }
    final total = sortedPositions.fold(0, (sum, entry) => sum + entry.value);
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 40,
              child: Row(
                children: sortedPositions.map((entry) {
                  final position = entry.key;
                  final count = entry.value;
                  final percent = count / total;
                  return Expanded(
                    flex: (percent * 100).round(),
                    child: Container(
                      color: _getPositionColor(position),
                      child: Center(
                        child: percent > 0.1
                            ? Text(
                                position,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              )
                            : null,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: sortedPositions.map((entry) {
                final position = entry.key;
                final count = entry.value;
                final percent = (count / total * 100).round();
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getPositionColor(position).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: _getPositionColor(position)),
                  ),
                  child: Text(
                    '$position: $count ($percent%)',
                    style: TextStyle(
                      fontSize: 12,
                      color: _getPositionColor(position),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayerCorrelationsView() {
    if (_playerCorrelations.isEmpty ||
        !_playerCorrelations.containsKey('playerCorrelations') ||
        !_playerCorrelations.containsKey('positionCorrelations')) {
      return _buildEmptyDataMessage(
        'No player correlation data available',
        'Player correlation data will populate as the community completes more drafts.',
      );
    }

    final List<dynamic> playerCorrelations =
        _playerCorrelations['playerCorrelations'] as List<dynamic>;
    final List<dynamic> positionCorrelations =
        _playerCorrelations['positionCorrelations'] as List<dynamic>;

    if (playerCorrelations.isEmpty || positionCorrelations.isEmpty) {
      return _buildEmptyDataMessage(
        'No player correlation data available',
        'Player correlation data will populate as the community completes more drafts.',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Position Pairing Tendencies',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Most common position combinations in the same draft',
          style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic),
        ),
        const SizedBox(height: 16),
        Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: positionCorrelations.take(3).map((corr) {
                final pos1 = corr['position1'] as String;
                final pos2 = corr['position2'] as String;
                final count = corr['count'] as int;
                final examples = List<dynamic>.from(corr['examples'] ?? []);
                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _getPositionColor(pos1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              pos1,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8),
                            child: Icon(Icons.add, size: 16),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _getPositionColor(pos2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              pos2,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '$count drafts',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      if (examples.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        const Text(
                          'Example pairings:',
                          style: TextStyle(
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        const SizedBox(height: 4),
                        ...examples.map((ex) => Padding(
                              padding: const EdgeInsets.only(left: 16, bottom: 2),
                              child: Text(
                                '${ex['player1']} + ${ex['player2']} (${ex['count']} drafts)',
                                style: const TextStyle(fontSize: 12),
                              ),
                            )),
                      ],
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Specific Player Pairings',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Players most commonly drafted together',
          style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic),
        ),
        const SizedBox(height: 16),
        Card(
          elevation: 2,
          child: ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: playerCorrelations.length > 5 ? 5 : playerCorrelations.length,
            itemBuilder: (context, index) {
              final corr = playerCorrelations[index];
              return ListTile(
                title: Text(
                  '${corr['player1']['name']} + ${corr['player2']['name']}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  '${corr['player1']['position']} + ${corr['player2']['position']}',
                ),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade100,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '${corr['count']} drafts',
                    style: TextStyle(
                      color: Colors.blue.shade800,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildHistoricalTrendsView() {
    if (_historicalTrends.isEmpty ||
        !_historicalTrends.containsKey('trends')) {
      return _buildEmptyDataMessage(
        'No historical trend data available',
        'Historical trend data will populate as we collect more draft data over time.',
      );
    }

    final trends = _historicalTrends['trends'];
    final months = _historicalTrends['months'] as List<dynamic>? ?? [];
    if (months.isEmpty) {
      return _buildEmptyDataMessage(
        'No timeline data available for historical trends',
        'Timeline data will populate as we collect more draft data over time.',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Position Popularity Trends',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: _buildPositionTrendChart(trends['positionTrends'], months),
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Trade Activity Trends',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: _buildTradeTrendChart(trends['tradeTrends'], months),
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Top Players Over Time',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: _buildTopPlayerTrendTable(trends['top10Players'], months),
          ),
        ),
      ],
    );
  }

  Widget _buildPositionTrendChart(Map<String, dynamic> positionTrends, List<dynamic> months) {
    final positionCounts = <String, int>{};
    for (final monthData in positionTrends.values) {
      for (final posEntry in (monthData as Map).entries) {
        final position = posEntry.key;
        final count = (posEntry.value as Map)['count'] as int;
        positionCounts[position] = (positionCounts[position] ?? 0) + count;
      }
    }
    final topPositions = positionCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    if (topPositions.isEmpty) {
      return _buildEmptyDataMessage(
        'No position trend data available',
        'Position trend data will populate as we collect more draft data over time.',
      );
    }
    final top5Positions = topPositions.take(5).map((e) => e.key).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: top5Positions.map((position) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getPositionColor(position).withOpacity(0.2),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: _getPositionColor(position)),
              ),
              child: Text(
                position,
                style: TextStyle(
                  color: _getPositionColor(position),
                  fontWeight: FontWeight.bold,
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
        Table(
          border: TableBorder.all(color: Colors.grey),
          children: [
            TableRow(
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey.shade800
                    : Colors.grey.shade200,
              ),
              children: [
                _buildTableHeader('Position'),
                ...months.map((month) => _buildTableHeader(_formatMonth(month))),
              ],
            ),
            ...top5Positions.map((position) {
              return TableRow(
                children: [
                  _buildTableCell(position),
                  ...months.map((month) {
                    final monthData = positionTrends[month] as Map<dynamic, dynamic>?;
                    final percentage = monthData != null && monthData[position] != null
                        ? (monthData[position]['percentage'] as num) * 100
                        : 0.0;
                    return Container(
                      padding: const EdgeInsets.all(8.0),
                      color: _getPositionColor(position).withOpacity(percentage / 100),
                      child: Text(
                        '${percentage.toStringAsFixed(1)}%',
                        textAlign: TextAlign.center,
                      ),
                    );
                  }),
                ],
              );
            }),
          ],
        )
      ],
    );
  }

  Widget _buildTradeTrendChart(Map<String, dynamic> tradeTrends, List<dynamic> months) {
    final tradeFrequency = tradeTrends['tradeFrequency'] ?? {};
    final valueDifferential = tradeTrends['averageValueDifferential'] ?? {};
    if (tradeFrequency.isEmpty || valueDifferential.isEmpty) {
      return _buildEmptyDataMessage(
        'No trade trend data available',
        'Trade trend data will populate as we collect more draft data over time.',
      );
    }
    return Table(
      border: TableBorder.all(color: Colors.grey),
      columnWidths: const {
        0: FlexColumnWidth(1.5),
        1: FlexColumnWidth(1),
        2: FlexColumnWidth(1),
      },
      children: [
        TableRow(
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.grey.shade800
                : Colors.grey.shade200,
          ),
          children: [
            _buildTableHeader('Month'),
            _buildTableHeader('Trades/Draft'),
            _buildTableHeader('Avg Value Diff'),
          ],
        ),
        ...months.map((month) {
          final frequency = tradeFrequency[month] ?? 0.0;
          final differential = valueDifferential[month] ?? 0.0;
          return TableRow(
            children: [
              _buildTableCell(_formatMonth(month)),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  frequency.toStringAsFixed(2),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: frequency > 1 ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  differential.toStringAsFixed(1),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: differential > 100 ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            ],
          );
        }),
      ],
    );
  }

  Widget _buildTopPlayerTrendTable(Map<String, dynamic> playerTrends, List<dynamic> months) {
    final recentMonths = months.length > 3 ? months.sublist(months.length - 3) : months;
    if (recentMonths.isEmpty || playerTrends.isEmpty) {
      return _buildEmptyDataMessage(
        'No player trend data available',
        'Player trend data will populate as we collect more draft data over time.',
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: recentMonths.map((month) {
        final monthData = playerTrends[month] as List<dynamic>? ?? [];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _formatMonth(month),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            monthData.isEmpty
                ? const Text('No player data for this period')
                : Table(
                    border: TableBorder.all(color: Colors.grey),
                    columnWidths: const {
                      0: FlexColumnWidth(3),
                      1: FlexColumnWidth(1),
                      2: FlexColumnWidth(1),
                    },
                    children: [
                      TableRow(
                        decoration: BoxDecoration(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.grey.shade800
                              : Colors.grey.shade200,
                        ),
                        children: [
                          _buildTableHeader('Player'),
                          _buildTableHeader('Pos'),
                          _buildTableHeader('Freq'),
                        ],
                      ),
                      ...monthData.take(3).map((player) => TableRow(
                            children: [
                              _buildTableCell(player['name'] ?? ''),
                              _buildPositionCell(player['position'] ?? ''),
                              _buildTableCell(player['percentage'] ?? ''),
                            ],
                          )),
                    ],
                  ),
            const SizedBox(height: 16),
          ],
        );
      }).toList(),
    );
  }

  String _formatMonth(String monthStr) {
    final parts = monthStr.split('-');
    if (parts.length != 2) return monthStr;
    final year = parts[0];
    final month = parts[1];
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    final monthInt = int.tryParse(month);
    if (monthInt == null || monthInt < 1 || monthInt > 12) return monthStr;
    return '${months[monthInt - 1]} $year';
  }

  Widget _buildTableHeader(String text) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.bold),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildTableCell(String text) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Text(
        text,
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildPositionCell(String position) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          decoration: BoxDecoration(
            color: _getPositionColor(position).withOpacity(0.2),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: _getPositionColor(position)),
          ),
          child: Text(
            position,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 10,
              color: _getPositionColor(position),
            ),
            textAlign: TextAlign.center,
          )),
    );
  }

  Widget _buildEmptyDataMessage(String title, String subtitle) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.grey.shade800.withOpacity(0.3)
            : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.grey.shade700
              : Colors.grey.shade300,
        ),
      ),
      child: Column(
        children: [
          const Icon(Icons.analytics_outlined, size: 36, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey.shade400
                  : Colors.grey.shade700,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Color _getPositionColor(String position) {
    if (['QB', 'RB', 'FB'].contains(position)) {
      return Colors.blue.shade700;
    } else if (['WR', 'TE'].contains(position)) {
      return Colors.green.shade700;
    } else if (['OT', 'IOL', 'OL', 'G', 'C'].contains(position)) {
      return Colors.purple.shade700;
    } else if (['EDGE', 'DL', 'IDL', 'DT', 'DE'].contains(position)) {
      return Colors.red.shade700;
    } else if (['LB', 'ILB', 'OLB'].contains(position)) {
      return Colors.orange.shade700;
    } else if (['CB', 'S', 'FS', 'SS'].contains(position)) {
      return Colors.teal.shade700;
    } else {
      return Colors.grey.shade700;
    }
  }

  @override
  bool get wantKeepAlive => true;
}