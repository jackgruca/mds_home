// lib/widgets/analytics/advanced_insights_tab.dart (NEW)
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

class _AdvancedInsightsTabState extends State<AdvancedInsightsTab> with AutomaticKeepAliveClientMixin {
  bool _isLoading = true;
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
    });

    try {
      // Load data in parallel
      final futures = <Future>[];
      
      // Load team performance data
      final teamPerformanceFuture = AnalyticsApiService.getAnalyticsData(
        dataType: 'teamPerformance',
        filters: {'year': widget.draftYear},
      ).then((data) {
        if (data.containsKey('data')) {
          _teamPerformance = data['data'];
        }
      });
      futures.add(teamPerformanceFuture);
      
      // Load player correlations
      final correlationsFuture = AnalyticsApiService.getAnalyticsData(
        dataType: 'pickCorrelations',
        filters: {'year': widget.draftYear},
      ).then((data) {
        if (data.containsKey('data')) {
          _playerCorrelations = data['data'];
        }
      });
      futures.add(correlationsFuture);
      
      // Load historical trends
      final trendsFuture = AnalyticsApiService.getAnalyticsData(
        dataType: 'historicalTrends',
        filters: null,
      ).then((data) {
        if (data.containsKey('data')) {
          _historicalTrends = data['data'];
        }
      });
      futures.add(trendsFuture);
      
      // Wait for all futures to complete
      await Future.wait(futures);
      
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading advanced analytics data: $e');
      setState(() {
        _isLoading = false;
      });
    }
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
              const Text('Metric:', style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              )),
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
                ].map((metric) => DropdownMenuItem(
                  value: metric,
                  child: Text(metric),
                )).toList(),
              ),
            ],
          ),
        ),

        // Main content
        _isLoading
            ? const Expanded(child: Center(child: CircularProgressIndicator()))
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
        return const Center(
          child: Text('Select a metric to view'),
        );
    }
  }

  Widget _buildTeamPerformanceView() {
    if (_teamPerformance.isEmpty || !_teamPerformance.containsKey('metrics')) {
      return const Center(
        child: Text('No team performance data available'),
      );
    }

    final metrics = Map<String, dynamic>.from(_teamPerformance['metrics']);
    
    // Sort teams by value differential
    final sortedTeams = metrics.entries.toList()
      ..sort((a, b) => (b.value['avgPickValue'] as num).compareTo(a.value['avgPickValue'] as num));

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
                1: FlexColumnWidth(1.5), // Value
                2: FlexColumnWidth(1.5), // Trade Up %
                3: FlexColumnWidth(1.5), // Trade Down %
              },
              border: TableBorder.all(color: Colors.grey.shade300),
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
                
                // Team rows
                ...sortedTeams.take(10).map((entry) {
                  final team = entry.key;
                  final teamData = entry.value;
                  
                  return TableRow(
                    children: [
                      // Team name
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
                      
                      // Value differential
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
                      
                      // Trade up %
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          '${((teamData['tradeUpFrequency'] as num) * 100).toStringAsFixed(1)}%',
                          textAlign: TextAlign.center,
                        ),
                      ),
                      
                      // Trade down %
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
    // Collect round 1 position data
    final round1Positions = <String, int>{};
    
    for (final teamData in metrics.values) {
      if (teamData['picksByRound']?.containsKey('1') == true) {
        // Look at most common position for this team in round 1
        final positions = Map<String, dynamic>.from(teamData['positionDistribution']);
        
        // Find most common position
        String? topPosition;
        int maxCount = 0;
        
        for (final entry in positions.entries) {
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
    
    // Sort positions by frequency
    final sortedPositions = round1Positions.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    if (sortedPositions.isEmpty) {
      return const Center(
        child: Text('No round 1 position data available'),
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
            // Create a bar chart
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
                        child: percent > 0.1 ? Text(
                          position,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ) : null,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Position legend
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
      return const Center(
        child: Text('No player correlation data available'),
      );
    }

    final List<dynamic> playerCorrelations = _playerCorrelations['playerCorrelations'];
    final List<dynamic> positionCorrelations = _playerCorrelations['positionCorrelations'];

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
              children: positionCorrelations.take(5).map((corr) {
                final pos1 = corr['position1'];
                final pos2 = corr['position2'];
                final count = corr['count'] as int;
                final examples = List<dynamic>.from(corr['examples'] ?? []);
                
                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          // Position 1
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                          
                          // Position 2
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                          
                          // Count
                          Text(
                            '$count drafts',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
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
            itemCount: playerCorrelations.length > 10 ? 10 : playerCorrelations.length,
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
    if (_historicalTrends.isEmpty || !_historicalTrends.containsKey('trends')) {
      return const Center(
        child: Text('No historical trend data available'),
      );
    }

    final trends = _historicalTrends['trends'];
    final months = _historicalTrends['months'] ?? [];
    
    if (months.isEmpty) {
      return const Center(
        child: Text('No timeline data available for historical trends'),
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

  // Helper method to build a position trend chart
  Widget _buildPositionTrendChart(Map<String, dynamic> positionTrends, List<dynamic> months) {
    // Identify top 5 positions across all months
    final positionCounts = <String, int>{};
    
    for (final monthData in positionTrends.values) {
      for (final posEntry in monthData.entries) {
        final position = posEntry.key;
        final count = posEntry.value['count'] as int;
        
        positionCounts[position] = (positionCounts[position] ?? 0) + count;
      }
    }
    
    final topPositions = positionCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    final top5Positions = topPositions.take(5).map((e) => e.key).toList();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Create legend
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: top5Positions.map((position) => Container(
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
          )).toList(),
        ),
        
        const SizedBox(height: 16),
        
        // Simple table showing percentage trends
        Table(
          border: TableBorder.all(color: Colors.grey.shade300),
          children: [
            // Header row
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
            
            // Data rows for each position
            ...top5Positions.map((position) => TableRow(
              children: [
                // Position
                _buildTableCell(position),
                
                // Percentage for each month
                ...months.map((month) {
                  final monthData = positionTrends[month];
                  final percentage = monthData != null && 
                                    monthData[position] != null ? 
                                    monthData[position]['percentage'] * 100 : 0.0;
                  
                  return Container(
                    padding: const EdgeInsets.all(8.0),
                    color: _getPositionColor(position).withOpacity(percentage / 100),
                    child: Text(
                      '${percentage.toStringAsFixed(1)}%',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: percentage > 20 ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  );
                }),
              ],
            )),
          ],
        ),
      ],
    );
  }

  // lib/widgets/analytics/advanced_insights_tab.dart (continued)

  // Helper method to build a trade trend chart
  Widget _buildTradeTrendChart(Map<String, dynamic> tradeTrends, List<dynamic> months) {
    final tradeFrequency = tradeTrends['tradeFrequency'] ?? {};
    final valueDifferential = tradeTrends['averageValueDifferential'] ?? {};
    
    return Table(
      border: TableBorder.all(color: Colors.grey.shade300),
      columnWidths: const {
        0: FlexColumnWidth(1.5),
        1: FlexColumnWidth(1),
      },
      children: [
        // Header row
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
        
        // Data rows for each month
        ...months.map((month) {
          final frequency = tradeFrequency[month] ?? 0.0;
          final differential = valueDifferential[month] ?? 0.0;
          
          return TableRow(
            children: [
              // Month
              _buildTableCell(_formatMonth(month)),
              
              // Trade frequency
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
              
              // Value differential
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

  // Helper method to build a top player trend table
  Widget _buildTopPlayerTrendTable(Map<String, dynamic> playerTrends, List<dynamic> months) {
    // Show most recent 3 months for simplicity
    final recentMonths = months.length > 3 ? months.sublist(months.length - 3) : months;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: recentMonths.map((month) {
        final monthData = playerTrends[month] ?? [];
        
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
            
            // Table of top players
            monthData.isEmpty 
                ? const Text('No player data for this period') 
                : Table(
                    border: TableBorder.all(color: Colors.grey.shade300),
                    columnWidths: const {
                      0: FlexColumnWidth(3),
                      1: FlexColumnWidth(1),
                      2: FlexColumnWidth(1),
                    },
                    children: [
                      // Header
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
                      
                      // Player rows
                      ...List<dynamic>.from(monthData).take(5).map((player) => TableRow(
                        children: [
                          // Player name
                          _buildTableCell(player['name'] ?? ''),
                          
                          // Position
                          _buildPositionCell(player['position'] ?? ''),
                          
                          // Frequency
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

  // Helper function to format month string
  String _formatMonth(String monthStr) {
    final parts = monthStr.split('-');
    if (parts.length != 2) return monthStr;
    
    final year = parts[0];
    final month = parts[1];
    
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
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
        ),
      ),
    );
  }

  Color _getPositionColor(String position) {
    if (['QB', 'RB', 'FB'].contains(position)) {
      return Colors.blue.shade700; // Backfield
    } else if (['WR', 'TE'].contains(position)) {
      return Colors.green.shade700; // Receivers
    } else if (['OT', 'IOL', 'OL', 'G', 'C'].contains(position)) {
      return Colors.purple.shade700; // O-Line
    } else if (['EDGE', 'DL', 'IDL', 'DT', 'DE'].contains(position)) {
      return Colors.red.shade700; // D-Line
    } else if (['LB', 'ILB', 'OLB'].contains(position)) {
      return Colors.orange.shade700; // Linebackers
    } else if (['CB', 'S', 'FS', 'SS'].contains(position)) {
      return Colors.teal.shade700; // Secondary
    } else {
      return Colors.grey.shade700; // Special teams, etc.
    }
  }

  @override
  bool get wantKeepAlive => true;
}