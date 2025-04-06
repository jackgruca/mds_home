// lib/widgets/analytics/team_draft_patterns_tab.dart

import 'package:flutter/material.dart';
import '../../services/analytics_query_service.dart';
import '../../utils/constants.dart';
import '../../utils/team_logo_utils.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

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

class _TeamDraftPatternsTabState extends State<TeamDraftPatternsTab> {
  bool _isLoading = true;
  String _selectedTeam = '';
  int? _selectedRound; // Changed to int? to support "All Rounds" option
  bool _isFirstLoad = true;
  bool _hasLoadedData = false;
  
  // Data states
  List<Map<String, dynamic>> _topPicksByPosition = [];
  final List<Map<String, dynamic>> _topPlayersByPick = [];
  Map<String, List<String>> _consensusNeeds = {};

@override
void initState() {
  super.initState();
  _selectedTeam = widget.initialTeam;
  _selectedRound = 1; // Default to round 1
  
  // First try to load from local storage
  _loadFromLocalStorage();
  
  // Then fetch fresh data, but don't block the UI
  Future.delayed(Duration.zero, () {
    _loadData();
  });
}


Future<void> _loadFromLocalStorage() async {
  if (!_isFirstLoad) return;
  
  setState(() {
    _isLoading = true;
  });
  
  try {
    final prefs = await SharedPreferences.getInstance();
    
    // Load position data
    final storedPositionData = prefs.getString(
      'position_trends_${_selectedTeam}_${_selectedRound}_${widget.draftYear}'
    );
    
    // Load needs data 
    final storedNeedsData = prefs.getString(
      'consensus_needs_${widget.draftYear}'
    );
    
    if (storedPositionData != null) {
      final data = jsonDecode(storedPositionData);
      setState(() {
        _topPicksByPosition = List<Map<String, dynamic>>.from(
          data.map((x) => Map<String, dynamic>.from(x))
        );
        _hasLoadedData = true;
      });
    }
    
    if (storedNeedsData != null) {
      final data = jsonDecode(storedNeedsData);
      final Map<String, List<String>> result = {};
      
      data.forEach((key, value) {
        if (value is List) {
          result[key] = List<String>.from(value);
        }
      });
      
      setState(() {
        _consensusNeeds = result;
        _hasLoadedData = true;
      });
    }
  } catch (e) {
    debugPrint('Error loading from local storage: $e');
  } finally {
    setState(() {
      _isLoading = !_hasLoadedData;
      _isFirstLoad = false;
    });
  }
}

Future<void> _loadData() async {
  // If we already have data, show loading indicator but don't block UI
  if (_hasLoadedData) {
    // Just show a small loading indicator
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Refreshing data in background...'),
          duration: Duration(seconds: 1),
        ),
      );
    }
  } else {
    setState(() {
      _isLoading = true;
    });
  }

  try {
    // Get aggregated position data by pick - using more efficient method
    debugPrint('Fetching position data for team: $_selectedTeam, round: $_selectedRound');
    final positionData = await AnalyticsQueryService.getConsolidatedPositionsByPick(
      team: _selectedTeam == 'All Teams' ? null : _selectedTeam,
      round: _selectedRound,
      year: widget.draftYear,
    );
    
    debugPrint('Position data received: ${positionData.length} items');

    // Get consensus team needs - only if needed
    Map<String, List<String>> needsData = {};
    if (_consensusNeeds.isEmpty) {
      needsData = await AnalyticsQueryService.getConsensusTeamNeeds(
        year: widget.draftYear,
      );
      debugPrint('Needs data received for ${needsData.length} teams');
    }

    setState(() {
      if (positionData.isNotEmpty) {
        _topPicksByPosition = positionData;
        debugPrint('Updated position data in state');
      } else {
        debugPrint('Received empty position data');
      }
      
      if (needsData.isNotEmpty) {
        _consensusNeeds = needsData;
        debugPrint('Updated needs data in state');
      } else if (_consensusNeeds.isEmpty) {
        debugPrint('Needs data is empty');
      }
      
      _isLoading = false;
      _hasLoadedData = true;
    });
  } catch (e) {
    debugPrint('Error loading team draft pattern data: $e');
    // Display error to user
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading data: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
    setState(() {
      _isLoading = false;
    });
  }
}

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
      // Data rows
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