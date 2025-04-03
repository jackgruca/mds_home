// lib/widgets/analytics/draft_trend_insights_tab.dart
import 'package:flutter/material.dart';
import '../../services/analytics_query_service.dart';
import '../../utils/team_logo_utils.dart';

class DraftTrendInsightsTab extends StatefulWidget {
  final int draftYear;
  
  const DraftTrendInsightsTab({
    super.key,
    required this.draftYear,
  });

  @override
  _DraftTrendInsightsTabState createState() => _DraftTrendInsightsTabState();
}

class _DraftTrendInsightsTabState extends State<DraftTrendInsightsTab> {
  bool _isLoading = true;
  int _selectedRound = 1;
  
  // Data states
  final List<Map<String, dynamic>> _positionRunData = [];
  Map<String, List<Map<String, dynamic>>> _positionsByRound = {};
  Map<String, dynamic> _positionDistribution = {};
  
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
      // Load position data for each round
      final Map<String, List<Map<String, dynamic>>> positionsByRound = {};
      
      // Load round-by-round position data (for rounds 1-4)
      for (int round = 1; round <= 4; round++) {
        final roundData = await AnalyticsQueryService.getConsolidatedPositionsByPick(
          round: round,
          year: widget.draftYear,
        );
        
        // Group by position trends
        positionsByRound['Round $round'] = roundData;
      }
      
      // Load overall position distribution
      final positionDist = await AnalyticsQueryService.getPositionBreakdownByTeam(
        team: 'All Teams', // Get overall data
        year: widget.draftYear,
      );
      
      setState(() {
        _positionsByRound = positionsByRound;
        _positionDistribution = positionDist;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading draft trend data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Round selector for position data
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              const Text('Round:', style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              )),
              const SizedBox(width: 8),
              DropdownButton<int>(
                value: _selectedRound,
                onChanged: (newValue) {
                  if (newValue != null) {
                    setState(() {
                      _selectedRound = newValue;
                    });
                  }
                },
                items: [1, 2, 3, 4].map((round) => DropdownMenuItem(
                  value: round,
                  child: Text('Round $round'),
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Position Trends by Round
                      Card(
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Position Trends (Round $_selectedRound)',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Most common positions drafted by pick number',
                                style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic),
                              ),
                              const SizedBox(height: 16),
                              _buildPositionTrendsForRound(_selectedRound),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Overall Position Distribution
                      Card(
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Overall Position Distribution',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Position frequency across all drafts',
                                style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic),
                              ),
                              const SizedBox(height: 16),
                              _buildPositionDistributionChart(),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Position Distribution by Round
                      Card(
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Round-by-Round Position Frequency',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'How position frequency changes by round',
                                style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic),
                              ),
                              const SizedBox(height: 16),
                              _buildPositionDistributionByRound(),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ],
    );
  }

  Widget _buildPositionTrendsForRound(int round) {
    final roundKey = 'Round $round';
    final roundData = _positionsByRound[roundKey];
    
    if (roundData == null || roundData.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('No position trend data available for this round'),
        ),
      );
    }

    // Group the data by common positions
    final Map<String, List<int>> commonPositions = {};
    for (var pickData in roundData) {
      final positionsList = pickData['positions'] as List<dynamic>;
      if (positionsList.isNotEmpty) {
        final topPosition = positionsList[0]['position'] as String;
        final pickNum = pickData['pick'] as int;
        
        if (!commonPositions.containsKey(topPosition)) {
          commonPositions[topPosition] = [];
        }
        commonPositions[topPosition]!.add(pickNum);
      }
    }
    
    // Sort positions by frequency
    final sortedPositions = commonPositions.entries.toList()
      ..sort((a, b) => b.value.length.compareTo(a.value.length));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var entry in sortedPositions.take(5)) ...[
          _buildPositionRunWidget(entry.key, entry.value),
          const SizedBox(height: 12),
        ],
      ],
    );
  }

  Widget _buildPositionRunWidget(String position, List<int> picks) {
    // Sort picks numerically
    picks.sort();
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _getPositionColor(position).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _getPositionColor(position).withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: _getPositionColor(position),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  position,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${picks.length} picks',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          
          // Show pick numbers
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: picks.map((pick) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade400),
              ),
              child: Text(
                '#$pick',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: Colors.grey.shade800,
                ),
              ),
            )).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildPositionDistributionChart() {
  if (_positionDistribution.isEmpty || !_positionDistribution.containsKey('positions')) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Text('No position distribution data available'),
      ),
    );
  }

  // Fix the type issue by using Map.from() to ensure we get a standard map
  final Map<String, dynamic> positionsMap = Map<String, dynamic>.from(_positionDistribution['positions'] as Map);
  final positions = positionsMap.entries.toList();
  
  // Sort by count (frequency)
  positions.sort((a, b) => 
    ((b.value as Map)['count'] as int).compareTo((a.value as Map)['count'] as int)
  );
  
  // Calculate total picks
  final int totalPicks = _positionDistribution['total'] as int;
  
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // Position bar chart
      SizedBox(
        height: 40,
        child: Row(
          children: positions.map((entry) {
            final position = entry.key;
            final data = Map<String, dynamic>.from(entry.value as Map);
            final count = data['count'] as int;
            final percent = count / totalPicks;
            
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
        children: positions.map((entry) {
          final position = entry.key;
          final data = Map<String, dynamic>.from(entry.value as Map);
          final count = data['count'] as int;
          final percentage = data['percentage'] as String;
          
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: _getPositionColor(position).withOpacity(0.2),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: _getPositionColor(position)),
            ),
            child: Text(
              '$position: $count ($percentage)',
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
  );
}

  Widget _buildPositionDistributionByRound() {
  if (_positionsByRound.isEmpty) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Text('No position distribution data available by round'),
      ),
    );
  }

  // Create a comparison of top positions by round
  final Map<String, Map<String, int>> topPositionsByRound = {};
  
  for (var roundEntry in _positionsByRound.entries) {
    final roundName = roundEntry.key;
    final roundData = roundEntry.value;
    
    // Count position frequencies
    final Map<String, int> positionCounts = {};
    
    for (var pickData in roundData) {
      final positionsList = List<dynamic>.from(pickData['positions'] as List);
      if (positionsList.isNotEmpty) {
        final topPosition = positionsList[0]['position'] as String;
        positionCounts[topPosition] = (positionCounts[topPosition] ?? 0) + 1;
      }
    }
    
    topPositionsByRound[roundName] = positionCounts;
  }
    
    // Get all unique positions
    final Set<String> allPositions = {};
    for (var counts in topPositionsByRound.values) {
      allPositions.addAll(counts.keys);
    }
    
    // Sort positions by overall frequency
    final List<String> sortedPositions = allPositions.toList()
      ..sort((a, b) {
        int totalA = 0;
        int totalB = 0;
        
        for (var counts in topPositionsByRound.values) {
          totalA += counts[a] ?? 0;
          totalB += counts[b] ?? 0;
        }
        
        return totalB.compareTo(totalA);
      });
    
    return Table(
      columnWidths: const {
        0: FlexColumnWidth(2),
        1: FlexColumnWidth(1),
        2: FlexColumnWidth(1),
        3: FlexColumnWidth(1),
        4: FlexColumnWidth(1),
      },
      border: TableBorder.all(
        color: Colors.grey.shade300,
        width: 1,
      ),
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
            _buildTableHeader('Round 1'),
            _buildTableHeader('Round 2'),
            _buildTableHeader('Round 3'),
            _buildTableHeader('Round 4'),
          ],
        ),
        
        // Data rows - top positions only
        ...sortedPositions.take(10).map((position) {
          return TableRow(
            children: [
              // Position name
              _buildPositionNameCell(position),
              
              // Round counts
              _buildPositionCountCell(topPositionsByRound['Round 1']?[position] ?? 0),
              _buildPositionCountCell(topPositionsByRound['Round 2']?[position] ?? 0),
              _buildPositionCountCell(topPositionsByRound['Round 3']?[position] ?? 0),
              _buildPositionCountCell(topPositionsByRound['Round 4']?[position] ?? 0),
            ],
          );
        }),
      ],
    );
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

  Widget _buildPositionNameCell(String position) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: _getPositionColor(position).withOpacity(0.2),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: _getPositionColor(position)),
            ),
            child: Text(
              position,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: _getPositionColor(position),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPositionCountCell(int count) {
    final color = count > 0 
        ? (count > 5 ? Colors.green : Colors.blue) 
        : Colors.grey;
    
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Text(
        count.toString(),
        style: TextStyle(
          fontWeight: count > 0 ? FontWeight.bold : FontWeight.normal,
          color: count > 0 ? color : null,
        ),
        textAlign: TextAlign.center,
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
}