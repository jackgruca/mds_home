// lib/widgets/analytics/team_draft_patterns_tab.dart

import 'package:flutter/material.dart';
import '../../services/analytics_query_service.dart';
import '../../services/analytics_cache_manager.dart';
import '../../utils/constants.dart';
import '../../utils/team_logo_utils.dart';
import 'package:flutter/services.dart';
import 'package:csv/csv.dart';

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
  
  // Data states
  List<Map<String, dynamic>> _topPicksByPosition = [];
  List<Map<String, dynamic>> _topPlayersByPick = [];
  Map<String, List<String>> _consensusNeeds = {};
  final Map<String, List<int>> _teamOriginalPicks = {};


  @override
void initState() {
  super.initState();
  _selectedTeam = widget.initialTeam;
  _selectedRound = 1; // Default to round 1
  _loadTeamOriginalPicks(); // Add this line
  _loadData();
}

Future<void> _loadTeamOriginalPicks() async {
  try {
    final data = await rootBundle.loadString('assets/${widget.draftYear}/draft_order.csv');
    List<List<dynamic>> csvTable = const CsvToListConverter(eol: "\n").convert(data);
    
    // Skip header row
    for (int i = 1; i < csvTable.length; i++) {
      final row = csvTable[i];
      if (row.length < 3) continue;
      
      final pickNumber = int.tryParse(row[1].toString()) ?? 0;
      final team = row[2].toString();
      
      if (pickNumber > 0 && team.isNotEmpty) {
        _teamOriginalPicks.putIfAbsent(team, () => []);
        _teamOriginalPicks[team]!.add(pickNumber);
      }
    }
    
    debugPrint('Loaded original picks for ${_teamOriginalPicks.length} teams');
  } catch (e) {
    debugPrint('Error loading team original picks: $e');
  }
}

  // Optimized data loading - only fetches what's needed based on selection
  Future<void> _loadData() async {
  setState(() {
    _isLoading = true;
  });

  try {
    // Create a list of futures to execute in parallel
    final futures = <Future>[];
    
    // Future for position data
    final positionFuture = AnalyticsQueryService.getConsolidatedPositionsByPick(
      team: _selectedTeam == 'All Teams' ? null : _selectedTeam,
      round: _selectedRound,
      year: widget.draftYear,
    ).then((data) {
      // Filter data to show only original picks for the selected team
      if (_selectedTeam != 'All Teams') {
        final teamPicks = _teamOriginalPicks[_selectedTeam] ?? [];
        _topPicksByPosition = data.where((pick) => 
          teamPicks.contains(pick['pick'])).toList();
      } else {
        _topPicksByPosition = data;
      }
    });
    futures.add(positionFuture);
    
    // Future for player data
    final playerFuture = AnalyticsQueryService.getConsolidatedPlayersByPick(
      team: _selectedTeam == 'All Teams' ? null : _selectedTeam,
      round: _selectedRound,
      year: widget.draftYear,
    ).then((data) {
      // Filter data to show only original picks for the selected team
      if (_selectedTeam != 'All Teams') {
        final teamPicks = _teamOriginalPicks[_selectedTeam] ?? [];
        _topPlayersByPick = data.where((pick) => 
          teamPicks.contains(pick['pick'])).toList();
      } else {
        _topPlayersByPick = data;
      }
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

  @override
  bool get wantKeepAlive => true;  // Keep state when switching tabs


// Add these helper methods to convert team-specific data formats
List<Map<String, dynamic>> _convertToPickPositionFormat(List<Map<String, dynamic>> teamData) {
  // This converts the team's pick history to the position trend table format
  List<Map<String, dynamic>> result = [];
  
  for (var pick in teamData) {
    // Each pick has the team's actual selection details
    final pickNumber = pick['pickNumber'] as int;
    final round = pick['round'] as String;
    final position = pick['position'] as String;
    
    // For team view, there's only one position per pick (what they actually selected)
    result.add({
      'pick': pickNumber,
      'round': round,
      'positions': [
        {'position': position, 'count': 1, 'percentage': '100.0%'}
      ],
      'totalDrafts': 1
    });
  }
  
  // Sort by pick number
  result.sort((a, b) => (a['pick'] as int).compareTo(b['pick'] as int));
  return result;
}

List<Map<String, dynamic>> _convertToPickPlayerFormat(List<Map<String, dynamic>> teamData) {
  // This converts the team's pick history to the player trend table format
  List<Map<String, dynamic>> result = [];
  
  for (var pick in teamData) {
    // Each pick has the team's actual selection details
    result.add({
      'pick': pick['pickNumber'] as int,
      'player': pick['playerName'] as String,
      'position': pick['position'] as String,
      'count': 1,
      'percentage': '100.0%',
      'totalDrafts': 1
    });
  }
  
  // Sort by pick number
  result.sort((a, b) => (a['pick'] as int).compareTo(b['pick'] as int));
  return result;
}

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

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

  // Update _buildPositionTrendsTable in team_draft_patterns_tab.dart

Widget _buildPositionTrendsTable() {
  if (_topPicksByPosition.isEmpty) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Text('No position trend data available'),
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
      // Data rows
      ..._topPicksByPosition.map((data) {
        final positionsList = data['positions'] as List<dynamic>;
        // Limit to top 3 positions
        final limitedPositions = positionsList.take(3).toList();
        // Pad with empty positions if needed
        while (limitedPositions.length < 3) {
          limitedPositions.add({'position': 'N/A', 'percentage': '0%'});
        }
        
        return TableRow(
          children: [
            _buildTableCell('${data['pick'] ?? 'N/A'}'),
            _buildTableCell('${data['round'] ?? 'N/A'}'),
            _buildPositionCell(
              limitedPositions[0]['position'],
              limitedPositions[0]['percentage'],
            ),
            _buildPositionCell(
              limitedPositions[1]['position'],
              limitedPositions[1]['percentage'],
            ),
            _buildPositionCell(
              limitedPositions[2]['position'],
              limitedPositions[2]['percentage'],
            ),
          ],
        );
      }),
    ],
  );
}

// Also update the player trends table
Widget _buildPlayerTrendsTable() {
  if (_topPlayersByPick.isEmpty) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Text('No player trend data available'),
      ),
    );
  }

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
      // Data rows - limit to top 3 players per pick
      ..._topPlayersByPick.map((data) {
        final playersList = data['players'] as List<dynamic>;
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
        
        // Taking only top player for each pick
        final topPlayer = playersList[0];
        return TableRow(
          children: [
            _buildTableCell('${data['pick'] ?? 'N/A'}'),
            _buildTableCell('${topPlayer['player'] ?? 'N/A'}'),
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