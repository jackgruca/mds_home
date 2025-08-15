// lib/widgets/analytics/team_draft_patterns_tab.dart

import 'package:flutter/material.dart';
import '../../services/analytics_query_service.dart';
import 'package:csv/csv.dart';
import 'package:flutter/services.dart';

class TeamDraftPatternsTab extends StatefulWidget {
  final String initialTeam;
  final List<String> allTeams;
  final int draftYear;

  const TeamDraftPatternsTab({
    super.key,
    required this.initialTeam,
    required this.allTeams,
    required this.draftYear,
  });

  @override
  _TeamDraftPatternsTabState createState() => _TeamDraftPatternsTabState();
}

class _TeamDraftPatternsTabState extends State<TeamDraftPatternsTab> with AutomaticKeepAliveClientMixin {
  bool _isLoading = true;
  String _selectedTeam = '';
  int? _selectedRound;
  List<int> _teamOriginalPicks = []; // Add this line
  
  // Data states
  List<Map<String, dynamic>> _topPicksByPosition = [];
  List<Map<String, dynamic>> _topPlayersByPick = [];
  Map<String, List<String>> _consensusNeeds = {};

  @override
  void initState() {
    super.initState();
    _selectedTeam = widget.initialTeam;
    _selectedRound = 1; // Default to round 1
    _loadData();
  }

  // Optimized data loading - only fetches what's needed based on selection
Future<void> _loadData() async {
  setState(() {
    _isLoading = true;
  });

  try {
    // Load original picks if a specific team is selected
    if (_selectedTeam != 'All Teams') {
      try {
        final data = await rootBundle.loadString('data/processed/draft_sim/${widget.draftYear}/draft_order.csv');
        List<List<dynamic>> csvTable = const CsvToListConverter(eol: "\n").convert(data);
        
        // Extract picks for this team
        List<int> originalPicks = [];
        for (int i = 1; i < csvTable.length; i++) {
          if (csvTable[i].length >= 3) {
            String csvTeam = csvTable[i][2].toString();
            if (csvTeam == _selectedTeam) {
              int pick = int.tryParse(csvTable[i][1].toString()) ?? 0;
              if (pick > 0) {
                originalPicks.add(pick);
              }
            }
          }
        }
        _teamOriginalPicks = originalPicks;
      } catch (e) {
        debugPrint('Error loading original picks: $e');
        _teamOriginalPicks = [];
      }
    } else {
      _teamOriginalPicks = [];
    }

    // Create a list of futures to execute in parallel
    final futures = <Future>[];
    
    // Future for position data
    final positionFuture = AnalyticsQueryService.getConsolidatedPositionsByPick(
      team: _selectedTeam == 'All Teams' ? null : _selectedTeam,
      round: _selectedRound,
      year: widget.draftYear,
    ).then((data) {
      _topPicksByPosition = data;
    });
    futures.add(positionFuture);
    
    // Future for player data
    final playerFuture = AnalyticsQueryService.getConsolidatedPlayersByPick(
      team: _selectedTeam == 'All Teams' ? null : _selectedTeam,
      round: _selectedRound,
      year: widget.draftYear,
    ).then((data) {
      _topPlayersByPick = data;
    });
    futures.add(playerFuture);
    
    // Only load consensus needs once, or when team changes
    if (_selectedTeam != 'All Teams' && (_consensusNeeds.isEmpty || !_consensusNeeds.containsKey(_selectedTeam))) {
      final needsFuture = AnalyticsQueryService.getConsensusTeamNeeds(
        year: widget.draftYear,
      ).then((data) {
        _consensusNeeds = data;
      });
      futures.add(needsFuture);
    }
    
    // Wait for all futures to complete
    await Future.wait(futures);

    setState(() {
      _isLoading = false;
    });
  } catch (e) {
    debugPrint('Error loading team draft pattern data: $e');
    setState(() {
      _isLoading = false;
    });
  }
}

Widget _buildPositionTrendsTable() {
  if (_topPicksByPosition.isEmpty) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Text('No position trend data available'),
      ),
    );
  }

  // Filter data if a team is selected
  List<Map<String, dynamic>> filteredPicks = _topPicksByPosition;
  if (_selectedTeam != 'All Teams' && _teamOriginalPicks.isNotEmpty) {
    filteredPicks = _topPicksByPosition.where((pick) => 
      _teamOriginalPicks.contains(pick['pick'])
    ).toList();
  }

  // If filtered list is empty but we've selected a team, show a message
  if (filteredPicks.isEmpty && _selectedTeam != 'All Teams') {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text('No original picks found for $_selectedTeam'),
      ),
    );
  }

  return Table(
    columnWidths: const {
      0: FlexColumnWidth(1),
      1: FlexColumnWidth(1),
      2: FlexColumnWidth(2),
      3: FlexColumnWidth(2),
      4: FlexColumnWidth(2),
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
          _buildTableHeader('Pick'),
          _buildTableHeader('Round'),
          _buildTableHeader('1st Position (%)'),
          _buildTableHeader('2nd Position (%)'),
          _buildTableHeader('3rd Position (%)'),
        ],
      ),
      // Data rows - use filteredPicks instead of _topPicksByPosition
      ...filteredPicks.map((data) {
        final positionsList = data['positions'] as List<dynamic>;
        return TableRow(
          children: [
            _buildTableCell('${data['pick'] ?? 'N/A'}'),
            _buildTableCell('${data['round'] ?? 'N/A'}'),
            _buildPositionCell(
              positionsList.isNotEmpty ? positionsList[0]['position'] : 'N/A',
              positionsList.isNotEmpty ? positionsList[0]['percentage'] : '0%',
            ),
            _buildPositionCell(
              positionsList.length > 1 ? positionsList[1]['position'] : 'N/A',
              positionsList.length > 1 ? positionsList[1]['percentage'] : '0%',
            ),
            _buildPositionCell(
              positionsList.length > 2 ? positionsList[2]['position'] : 'N/A',
              positionsList.length > 2 ? positionsList[2]['percentage'] : '0%',
            ),
          ],
        );
      }),
    ],
  );
}

  @override
  bool get wantKeepAlive => true;  // Keep state when switching tabs


// Add these helper methods to convert team-specific data formats


  @override
  Widget build(BuildContext context) {

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Team and round selectors
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              // Team selector
              const Text('Team:', style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              )),
              const SizedBox(width: 8),
              DropdownButton<String>(
                value: _selectedTeam,
                onChanged: (newValue) {
                  if (newValue != null) {
                    setState(() {
                      _selectedTeam = newValue;
                    });
                    _loadData();
                  }
                },
                items: [
                  const DropdownMenuItem(
                    value: 'All Teams',
                    child: Text('All Teams'),
                  ),
                  ...widget.allTeams.map((team) => DropdownMenuItem(
                    value: team,
                    child: Text(team),
                  )),
                ],
              ),
              const Spacer(),
              
              // Round selector with "All Rounds" option
              const Text('Round:', style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              )),
              const SizedBox(width: 8),
              DropdownButton<int?>(
                value: _selectedRound,
                onChanged: (newValue) {
                  setState(() {
                    _selectedRound = newValue;
                  });
                  _loadData();
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
            ? const Center(child: CircularProgressIndicator())
            : Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top Positions by Pick
                      Card(
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _selectedRound == null 
                                  ? 'Position Trends by Pick (All Rounds)'
                                  : 'Position Trends by Pick (Round $_selectedRound)',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              _buildPositionTrendsTable(),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Top Players by Pick
                      Card(
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _selectedRound == null 
                                    ? 'Most Common Players Selected (All Rounds)'
                                    : 'Most Common Players Selected (Round $_selectedRound)',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              _buildPlayerTrendsTable(),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Consensus Needs (only show for specific team)
                      if (_selectedTeam != 'All Teams')
                        Card(
                          elevation: 2,
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Community Consensus Needs for $_selectedTeam',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                _buildConsensusNeedsWidget(),
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

// Also update the player trends table
Widget _buildPlayerTrendsTable() {
  // First check if data is available
  if (_topPlayersByPick.isEmpty) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Text('No player trend data available'),
      ),
    );
  }

  // Filter data if a team is selected, similar to position trends
  List<Map<String, dynamic>> filteredPicks = _topPlayersByPick;
  if (_selectedTeam != 'All Teams' && _teamOriginalPicks.isNotEmpty) {
    filteredPicks = _topPlayersByPick.where((pick) => 
      _teamOriginalPicks.contains(pick['pick'])
    ).toList();
  }

  // If filtered list is empty but we've selected a team, show a message
  if (filteredPicks.isEmpty && _selectedTeam != 'All Teams') {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text('No original picks found for $_selectedTeam'),
      ),
    );
  }

  // Debug information to verify data structure
  debugPrint('Player data structure: ${filteredPicks.isNotEmpty ? filteredPicks.first.keys.join(', ') : 'No data'}');

  return Table(
    columnWidths: const {
      0: FlexColumnWidth(1),
      1: FlexColumnWidth(4),
      2: FlexColumnWidth(1),
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
          _buildTableHeader('Pick'),
          _buildTableHeader('Most Common Player'),
          _buildTableHeader('Position'),
          _buildTableHeader('Frequency'),
        ],
      ),
      // Data rows
      ...filteredPicks.map((data) {
        // Get the players list if it exists
        final playersList = data['players'] as List<dynamic>? ?? [];
        
        if (playersList.isEmpty) {
          return TableRow(
            children: [
              _buildTableCell('${data['pick'] ?? 'N/A'}'),
              _buildTableCell('No data'),
              _buildTableCell('N/A'),
              _buildTableCell('0%'),
            ],
          );
        }
        
        // Get the top player (most common)
        final topPlayer = playersList[0];
        return TableRow(
          children: [
            _buildTableCell('${data['pick'] ?? 'N/A'}'),
            _buildTableCell('${topPlayer['player'] ?? topPlayer['name'] ?? 'N/A'}'),
            _buildPositionCell(topPlayer['position'] ?? 'N/A', ''),
            _buildTableCell('${topPlayer['percentage'] ?? '0%'}'),
          ],
        );
      }),
    ],
  );
}

  Widget _buildConsensusNeedsWidget() {
    final teamNeeds = _consensusNeeds[_selectedTeam] ?? [];
    
    if (teamNeeds.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('No consensus need data available'),
        ),
      );
    }

    return Wrap(
      spacing: 8.0,
      runSpacing: 8.0,
      children: List.generate(
        teamNeeds.length,
        (index) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: _getPositionColor(teamNeeds[index]).withOpacity(0.2),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _getPositionColor(teamNeeds[index])),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${index + 1}. ',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: _getPositionColor(teamNeeds[index]),
                ),
              ),
              Text(
                teamNeeds[index],
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: _getPositionColor(teamNeeds[index]),
                ),
              ),
            ],
          ),
        ),
      ),
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

  Widget _buildPositionCell(String position, String percentage) {
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
          if (percentage.isNotEmpty) ...[
            const SizedBox(width: 4),
            Text(
              percentage,
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ],
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