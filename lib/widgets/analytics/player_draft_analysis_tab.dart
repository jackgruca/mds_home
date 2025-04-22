// lib/widgets/analytics/player_draft_analysis_tab.dart
import 'package:flutter/material.dart';
import '../../services/analytics_query_service.dart';
import '../../utils/constants.dart';
import '../../utils/team_logo_utils.dart';

class PlayerDraftAnalysisTab extends StatefulWidget {
  final int draftYear;
  
  const PlayerDraftAnalysisTab({
    super.key,
    required this.draftYear,
  });

  @override
  _PlayerDraftAnalysisTabState createState() => _PlayerDraftAnalysisTabState();
}

class _PlayerDraftAnalysisTabState extends State<PlayerDraftAnalysisTab> with AutomaticKeepAliveClientMixin {
  bool _isLoading = true;
  String _selectedPosition = 'All Positions';
  int? _selectedRound;
  
  // Data states
  List<Map<String, dynamic>> _riserPlayers = [];
  List<Map<String, dynamic>> _fallerPlayers = [];
  
  // New data states
  List<Map<String, dynamic>> valuePlayersByRound = [];
  List<Map<String, dynamic>> reachPlayersByRound = [];
  List<Map<String, dynamic>> tradeTeamsByRound = [];
  
  // List of all positions for filtering
  final List<String> _allPositions = [
    'All Positions', 'QB', 'RB', 'WR', 'TE', 'OT', 'IOL', 'EDGE', 'DL', 
    'LB', 'CB', 'S'
  ];

  @override
  void initState() {
    super.initState();
    _selectedRound = 1; // Default to round 1
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Create a list of futures to execute in parallel
      final futures = <Future>[];
      
      // Load player rank deviations (risers and fallers)
      final deviationsFuture = AnalyticsQueryService.getPlayerRankDeviations(
        year: widget.draftYear,
        position: _selectedPosition == 'All Positions' ? null : _selectedPosition,
        limit: 20,  // Get enough data to split into risers and fallers
      ).then((deviations) {
        // Process the deviations data
        final players = deviations['players'] as List<dynamic>;
        final List<Map<String, dynamic>> risers = [];
        final List<Map<String, dynamic>> fallers = [];
        
        for (var player in players) {
          // Parse average deviation value
          double avgDeviation = double.tryParse(player['avgDeviation'].toString()) ?? 0.0;
          
          // Add player details
          Map<String, dynamic> playerData = {
            'name': player['name'],
            'position': player['position'],
            'avgDeviation': avgDeviation,
            'deviationText': avgDeviation.toStringAsFixed(1),
            'sampleSize': player['sampleSize'],
          };
          
          // Categorize as riser or faller
          if (avgDeviation > 0) {
            risers.add(playerData);
          } else if (avgDeviation < 0) {
            fallers.add(playerData);
          }
        }
        
        // Sort risers (picked later than rank = positive deviation = value picks)
        risers.sort((a, b) => (b['avgDeviation'] as double).compareTo(a['avgDeviation'] as double));
        
        // Sort fallers (picked earlier than rank = negative deviation = reaches)
        fallers.sort((a, b) => (a['avgDeviation'] as double).compareTo(b['avgDeviation'] as double));
        
        _riserPlayers = risers;
        _fallerPlayers = fallers;
      });
      futures.add(deviationsFuture);
      
      // Load value players data
      final valuePlayersFuture = AnalyticsQueryService.getValuePlayersByRound(
        round: _selectedRound,
      ).then((data) {
        valuePlayersByRound = data;
      });
      futures.add(valuePlayersFuture);
      
      // Load reach players data
      final reachPlayersFuture = AnalyticsQueryService.getReachPicksByRound(
        round: _selectedRound,
      ).then((data) {
        reachPlayersByRound = data;
      });
      futures.add(reachPlayersFuture);
      
      // Load trade teams data
      final tradeTeamsFuture = AnalyticsQueryService.getMostActiveTradeTeamsByRound(
        round: _selectedRound,
      ).then((data) {
        tradeTeamsByRound = data;
      });
      futures.add(tradeTeamsFuture);
      
      // Wait for all futures to complete
      await Future.wait(futures);
      
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading player analysis data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  void _updateRoundFilter(int? round) {
    setState(() {
      _selectedRound = round;
    });
    _loadData();
  }

  @override
  bool get wantKeepAlive => true;  // Keep state when switching tabs

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Position and round filters
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              // Position filter
              const Text('Position:', style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              )),
              const SizedBox(width: 8),
              DropdownButton<String>(
                value: _selectedPosition,
                onChanged: (newValue) {
                  if (newValue != null) {
                    setState(() {
                      _selectedPosition = newValue;
                    });
                    _loadData();
                  }
                },
                items: _allPositions.map((position) => DropdownMenuItem(
                  value: position,
                  child: Text(position),
                )).toList(),
              ),
              
              const Spacer(),
              
              // Round filter
              const Text('Round:', style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              )),
              const SizedBox(width: 8),
              DropdownButton<int?>(
                value: _selectedRound,
                onChanged: (newValue) {
                  _updateRoundFilter(newValue);
                },
                items: [
                  const DropdownMenuItem<int?>(
                    value: null,
                    child: Text('All Rounds'),
                  ),
                  ...List.generate(7, (index) => DropdownMenuItem<int?>(
                    value: index + 1,
                    child: Text('Round ${index + 1}'),
                  )),
                ],
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
                      // Value Players Section
                      _buildValuePlayersCard(),
                      
                      const SizedBox(height: 24),
                      
                      // Reach Players Section
                      _buildReachPlayersCard(),
                      
                      const SizedBox(height: 24),
                      
                      // Trade Teams Section
                      _buildTradeTeamsCard(),
                      
                      const SizedBox(height: 24),
                      
                      // Value Picks / Risers Section
                      Card(
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Value Picks (Drafted Later Than Rank)',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Players consistently selected later than their rankings',
                                style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic),
                              ),
                              const SizedBox(height: 16),
                              _buildPlayerDeviationTable(_riserPlayers, true),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Reach Picks / Fallers Section
                      Card(
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Reach Picks (Drafted Earlier Than Rank)',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Players consistently selected earlier than their rankings',
                                style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic),
                              ),
                              const SizedBox(height: 16),
                              _buildPlayerDeviationTable(_fallerPlayers, false),
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

  Widget _buildPlayerDeviationTable(List<Map<String, dynamic>> players, bool isRiser) {
    if (players.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'No ${isRiser ? 'value pick' : 'reach pick'} data available${_selectedPosition != 'All Positions' ? ' for $_selectedPosition' : ''}',
            style: const TextStyle(fontStyle: FontStyle.italic),
          ),
        ),
      );
    }

    return Table(
      columnWidths: const {
        0: FlexColumnWidth(3),
        1: FlexColumnWidth(1),
        2: FlexColumnWidth(2),
        3: FlexColumnWidth(1),
      },
      border: TableBorder.all(
        color: Colors.grey.shade300,
        width: 1,
      ),
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
            _buildTableHeader('Avg Deviation'),
            _buildTableHeader('Count'),
          ],
        ),
        // Data rows - limited to top 5 for readability
        ...players.take(5).map((player) {
          return TableRow(
            children: [
              _buildTableCell(player['name'] ?? 'N/A'),
              _buildPositionCell(player['position'] ?? 'N/A'),
              _buildDeviationCell(
                player['deviationText'] ?? '0.0',
                isRiser,
              ),
              _buildTableCell('${player['sampleSize'] ?? 'N/A'}'),
            ],
          );
        }),
      ],
    );
  }

  Widget _buildValuePlayersCard() {
    if (valuePlayersByRound.isEmpty) {
      return const Card(
        elevation: 2,
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Best Value Players',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Players drafted later than their rank (positive value)',
                style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic),
              ),
              SizedBox(height: 16),
              Center(
                child: Text('No value player data available for the selected round'),
              ),
            ],
          ),
        ),
      );
    }
    
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Best Value Players',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Players drafted later than their rank (positive value)',
              style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('Player')),
                  DataColumn(label: Text('Position')),
                  DataColumn(label: Text('School')),
                  DataColumn(label: Text('Value')),
                  DataColumn(label: Text('Sample Size')),
                ],
                rows: valuePlayersByRound.map((player) {
                  return DataRow(
                    cells: [
                      DataCell(Text(player['name']?.toString() ?? '')),
                      DataCell(_buildPositionCell(player['position']?.toString() ?? 'N/A')),
                      DataCell(Text(player['school']?.toString() ?? '')),
                      DataCell(Text(
                        '+${player['avgDeviation']}',
                        style: const TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      )),
                      DataCell(Text(player['sampleSize']?.toString() ?? '0')),
                    ],
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReachPlayersCard() {
    if (reachPlayersByRound.isEmpty) {
      return const Card(
        elevation: 2,
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Biggest Reaches',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Players drafted earlier than their rank (negative value)',
                style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic),
              ),
              SizedBox(height: 16),
              Center(
                child: Text('No reach pick data available for the selected round'),
              ),
            ],
          ),
        ),
      );
    }
    
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Biggest Reaches',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Players drafted earlier than their rank (negative value)',
              style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('Player')),
                  DataColumn(label: Text('Position')),
                  DataColumn(label: Text('School')),
                  DataColumn(label: Text('Reach')),
                  DataColumn(label: Text('Sample Size')),
                ],
                rows: reachPlayersByRound.map((player) {
                  return DataRow(
                    cells: [
                      DataCell(Text(player['name']?.toString() ?? '')),
                      DataCell(_buildPositionCell(player['position']?.toString() ?? 'N/A')),
                      DataCell(Text(player['school']?.toString() ?? '')),
                      DataCell(Text(
                        '${player['avgDeviation']}',
                        style: const TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      )),
                      DataCell(Text(player['sampleSize']?.toString() ?? '0')),
                    ],
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTradeTeamsCard() {
    if (tradeTeamsByRound.isEmpty) {
      return const Card(
        elevation: 2,
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Most Active Trading Teams',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 16),
              Center(
                child: Text('No trade data available for the selected round'),
              ),
            ],
          ),
        ),
      );
    }
    
    return Column(
      children: tradeTeamsByRound.map((roundData) {
        final round = roundData['round'];
        final tradeUps = List<Map<String, dynamic>>.from(roundData['tradeUps'] ?? []);
        final tradeDowns = List<Map<String, dynamic>>.from(roundData['tradeDowns'] ?? []);
        
        if (tradeUps.isEmpty && tradeDowns.isEmpty) {
          return const SizedBox.shrink();
        }
        
        return Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Round $round Trading Teams', 
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                
                // Trade ups
                if (tradeUps.isNotEmpty) ...[
                  const Text(
                    'Most Active Teams Trading Up',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columnSpacing: 24,
                      columns: const [
                        DataColumn(label: Text('Team')),
                        DataColumn(label: Text('Trades')),
                      ],
                      rows: tradeUps.map((team) {
                        return DataRow(
                          cells: [
                            DataCell(Text(team['team']?.toString() ?? '')),
                            DataCell(Text('${team['count'] ?? 0} times')),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                
                // Trade downs
                if (tradeDowns.isNotEmpty) ...[
                  const Text(
                    'Most Active Teams Trading Down',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columnSpacing: 24,
                      columns: const [
                        DataColumn(label: Text('Team')),
                        DataColumn(label: Text('Trades')),
                      ],
                      rows: tradeDowns.map((team) {
                        return DataRow(
                          cells: [
                            DataCell(Text(team['team']?.toString() ?? '')),
                            DataCell(Text('${team['count'] ?? 0} times')),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      }).toList(),
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
      child: Center(
        child: Container(
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
      ),
    );
  }

  Widget _buildDeviationCell(String value, bool isPositive) {
    // For risers, positive is good (green)
    // For fallers, negative is shown (red)
    final Color color = isPositive ? Colors.green : Colors.red;
    final prefix = isPositive ? '+' : '';
    
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Text(
        '$prefix$value',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: color,
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