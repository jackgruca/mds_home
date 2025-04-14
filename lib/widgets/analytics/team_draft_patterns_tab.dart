// lib/widgets/analytics/team_draft_patterns_tab.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../services/analytics_query_service.dart';
import '../../services/analytics_cache_manager.dart';
import '../../utils/constants.dart';
import '../../utils/team_logo_utils.dart';

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
    debugPrint('Loading team draft patterns data...');
    
    // Try to get positions by pick with better error handling
    try {
      debugPrint('Fetching positions data for team: $_selectedTeam, round: $_selectedRound');
      final positionsData = await AnalyticsQueryService.getConsolidatedPositionsByPick(
        team: _selectedTeam == 'All Teams' ? null : _selectedTeam,
        round: _selectedRound,
        year: widget.draftYear,
      );
      
      debugPrint('Positions data received: ${positionsData.length} items');
      
      // Inspect the first item if available
      if (positionsData.isNotEmpty) {
        debugPrint('First item: ${positionsData.first}');
      }
      
      setState(() {
        _topPicksByPosition = positionsData;
      });
    } catch (e) {
      debugPrint('Error getting positions: $e');
      setState(() {
        _topPicksByPosition = [];
      });
    }
    
    // Try to get player data with better error handling
    try {
      debugPrint('Fetching players data for team: $_selectedTeam, round: $_selectedRound');
      final playersData = await AnalyticsQueryService.getConsolidatedPlayersByPick(
        team: _selectedTeam == 'All Teams' ? null : _selectedTeam,
        round: _selectedRound,
        year: widget.draftYear,
      );
      
      debugPrint('Players data received: ${playersData.length} items');
      
      setState(() {
        _topPlayersByPick = playersData;
      });
    } catch (e) {
      debugPrint('Error getting players: $e');
      setState(() {
        _topPlayersByPick = [];
      });
    }
    
    // Try to get consensus needs with better error handling
    if (_selectedTeam != 'All Teams') {
      try {
        debugPrint('Fetching consensus needs');
        final needs = await AnalyticsQueryService.getConsensusTeamNeeds(
          year: widget.draftYear,
        );
        
        debugPrint('Needs data received for ${needs.keys.length} teams');
        
        setState(() {
          _consensusNeeds = needs;
        });
      } catch (e) {
        debugPrint('Error getting consensus needs: $e');
        setState(() {
          _consensusNeeds = {};
        });
      }
    }
    
    setState(() {
      _isLoading = false;
    });
    
    debugPrint('Team draft patterns data loaded successfully');
  } catch (e) {
    debugPrint('Error in _loadData: $e');
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

Widget _buildDebugInfo() {
  return ExpansionTile(
    title: const Text('Debugging Information', 
      style: TextStyle(fontSize: 12, color: Colors.grey)),
    children: [
      FutureBuilder(
        future: FirebaseFirestore.instance
            .collection('precomputedAnalytics')
            .doc('metadata')
            .get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const CircularProgressIndicator();
          }
          
          final data = snapshot.data?.data();
          final lastUpdated = data?['lastUpdated'] as Timestamp?;
          final processed = data?['documentsProcessed'];
          
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Metadata: ${data != null ? 'Found' : 'Not found'}'),
              if (lastUpdated != null)
                Text('Last updated: ${lastUpdated.toDate()}'),
              Text('Documents processed: ${processed ?? 'Unknown'}'),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () {
                  AnalyticsCacheManager.clearCache();
                  setState(() {});
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Cache cleared'))
                  );
                },
                child: const Text('Clear Cache & Reload'),
              ),
            ],
          );
        },
      ),
    ],
  );
}

  @override
  Widget build(BuildContext context) {
    // Add this debugging code at the very start of the build method
  debugPrint('TeamDraftPatternsTab - picked data: ${_topPicksByPosition.length} items');
  if (_topPicksByPosition.isNotEmpty) {
    debugPrint('First item: ${_topPicksByPosition.first}');
  }
  
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
              const SizedBox(width: 16),
      ElevatedButton(
        onPressed: () async {
          final db = FirebaseFirestore.instance;
          final doc = await db.collection('precomputedAnalytics').doc('positionsByPickRound1').get();
          
          if (doc.exists) {
            final data = doc.data();
            debugPrint('Document structure: ${data?.keys.join(', ')}');
            
            if (data?.containsKey('data') == true) {
              final items = data!['data'];
              if (items is List) {
                debugPrint('Items count: ${items.length}');
                if (items.isNotEmpty) {
                  debugPrint('First item: ${items.first}');
                }
              } else {
                debugPrint('Data is not a list: ${items.runtimeType}');
              }
            } else {
              debugPrint('Document does not contain data field');
            }
          } else {
            debugPrint('Document does not exist');
          }
        },
        child: const Text('Debug Document Structure'),
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
              // Add the debug info here, at the top of this list
              _buildDebugInfo(),
              
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
        child: Column(
          children: [
            Text('No position trend data available'),
            SizedBox(height: 20),
            Text('Debug - Data structure may not match expected format', 
              style: TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  // Use a ListView instead of a Table for more flexibility with data formats
  return ListView.builder(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    itemCount: _topPicksByPosition.length,
    itemBuilder: (context, index) {
      final data = _topPicksByPosition[index];
      
      // Safely extract data with null checks
      final pickNumber = data['pick'] ?? 'N/A';
      final round = data['round'] ?? 'N/A';
      
      // Create a simple card for each pick
      return Card(
        margin: const EdgeInsets.symmetric(vertical: 4),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Pick #$pickNumber (Round $round)', 
                style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              
              // Safely handle positions list
              Builder(builder: (context) {
                final positions = data['positions'];
                if (positions is List && positions.isNotEmpty) {
                  return Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: List.generate(
                      positions.length > 3 ? 3 : positions.length,
                      (i) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getPositionColor(positions[i]['position'] ?? 'N/A').withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '${positions[i]['position'] ?? 'N/A'} (${positions[i]['percentage'] ?? '0%'})',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ),
                  );
                }
                return const Text('No position data available');
              }),
            ],
          ),
        ),
      );
    },
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