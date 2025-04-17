// lib/widgets/analytics/team_draft_patterns_tab.dart (Updated)

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
  bool _hasError = false;
  String _errorMessage = '';
  
  // Data states
  List<Map<String, dynamic>> _topPicksByPosition = [];
  List<Map<String, dynamic>> _topPlayersByPick = [];
  final Map<String, List<String>> _consensusNeeds = {};

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
      _hasError = false;
      _errorMessage = '';
    });

    try {
      // Create a list of futures to execute in parallel
      final futures = <Future>[];
      
      // ADDED: Debug info
      debugPrint('Loading data for team: $_selectedTeam, round: $_selectedRound, year: ${widget.draftYear}');
      
      // Future for position data
      final positionFuture = AnalyticsQueryService.getConsolidatedPositionsByPick(
        team: _selectedTeam == 'All Teams' ? null : _selectedTeam,
        round: _selectedRound,
        year: widget.draftYear,
      ).then((data) {
        // ADDED: Debug info
        debugPrint('Position data loaded: ${data.length} entries');
        _topPicksByPosition = data;
      }).catchError((e) {
        debugPrint('Error loading position data: $e');
        // Don't set error state here - we'll still try to load player data
      });
      futures.add(positionFuture);
      
      // Future for player data
      final playerFuture = AnalyticsQueryService.getConsolidatedPlayersByPick(
        team: _selectedTeam == 'All Teams' ? null : _selectedTeam,
        round: _selectedRound,
        year: widget.draftYear,
      ).then((data) {
        // ADDED: Debug info
        debugPrint('Player data loaded: ${data.length} entries');
        _topPlayersByPick = data;
      }).catchError((e) {
        debugPrint('Error loading player data: $e');
        // Don't set error state here either
      });
      futures.add(playerFuture);

      // Also load team needs if we're looking at a specific team
      if (_selectedTeam != 'All Teams') {
        final needsFuture = AnalyticsQueryService.getConsensusTeamNeeds(
          year: widget.draftYear,
        ).then((needs) {
          if (needs.containsKey(_selectedTeam)) {
            _consensusNeeds[_selectedTeam] = needs[_selectedTeam] ?? [];
          }
        }).catchError((e) {
          debugPrint('Error loading team needs: $e');
          // Non-critical, continue
        });
        futures.add(needsFuture);
      }
      
      // Wait for all futures to complete
      await Future.wait(futures);

      // Check if we got any data
      if (_topPicksByPosition.isEmpty && _topPlayersByPick.isEmpty) {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage = 'No data available for the selected team and round.';
        });
        return;
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading team draft pattern data: $e');
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = 'Error loading data: $e';
      });
    }
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
        if (_isLoading)
          const Expanded(
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_hasError)
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 48,
                    color: isDarkMode ? Colors.orange.shade300 : Colors.orange.shade700,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _errorMessage,
                    style: TextStyle(
                      fontSize: 16,
                      color: isDarkMode ? Colors.orange.shade300 : Colors.orange.shade700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _loadData,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Try Again'),
                  ),
                ],
              ),
            ),
          )
        else
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadData,
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
          ),
      ],
    );
  }

  Widget _buildPositionTrendsTable() {
    if (_topPicksByPosition.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              const Text('No position trend data available'),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _loadData,
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Refresh'),
              ),
            ],
          ),
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

  Widget _buildPlayerTrendsTable() {
    if (_topPlayersByPick.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              const Text('No player trend data available'),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _loadData,
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Refresh'),
              ),
            ],
          ),
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
          // Handle different data formats
          final String playerName = data['player'] ?? 
                                   ((data['players'] != null && (data['players'] as List).isNotEmpty) ? 
                                   data['players'][0]['player'] : 'N/A');
          
          final String position = data['position'] ?? 
                                 ((data['players'] != null && (data['players'] as List).isNotEmpty) ? 
                                 data['players'][0]['position'] : 'N/A');
          
          final String percentage = data['percentage'] ?? 
                                   ((data['players'] != null && (data['players'] as List).isNotEmpty) ? 
                                   data['players'][0]['percentage'] : '0%');
          
          return TableRow(
            children: [
              _buildTableCell('${data['pick'] ?? 'N/A'}'),
              _buildTableCell(playerName),
              _buildPositionCell(position, ''),
              _buildTableCell(percentage),
            ],
          );
        }),
      ],
    );
  }

  Widget _buildConsensusNeedsWidget() {
    final teamNeeds = _consensusNeeds[_selectedTeam] ?? [];
    
    if (teamNeeds.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              const Text('No consensus need data available'),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  AnalyticsQueryService.getConsensusTeamNeeds(
                    year: widget.draftYear,
                  ).then((needs) {
                    setState(() {
                      if (needs.containsKey(_selectedTeam)) {
                        _consensusNeeds[_selectedTeam] = needs[_selectedTeam] ?? [];
                      }
                    });
                  });
                },
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Refresh'),
              ),
            ],
          ),
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
    if (position == 'N/A') {
      return Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text(
          position,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.grey.shade500,
          ),
        ),
      );
    }
    
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
          if (percentage.isNotEmpty && percentage != '0%') ...[
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
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    // Different colors for different position groups with dark mode adjustments
    if (['QB', 'RB', 'FB'].contains(position)) {
      return isDarkMode ? Colors.blue.shade400 : Colors.blue.shade700; // Backfield
    } else if (['WR', 'TE'].contains(position)) {
      return isDarkMode ? Colors.green.shade400 : Colors.green.shade700; // Receivers
    } else if (['OT', 'IOL', 'OL', 'G', 'C'].contains(position)) {
      return isDarkMode ? Colors.purple.shade400 : Colors.purple.shade700; // O-Line
    } else if (['EDGE', 'DL', 'IDL', 'DT', 'DE'].contains(position)) {
      return isDarkMode ? Colors.red.shade400 : Colors.red.shade700; // D-Line
    } else if (['LB', 'ILB', 'OLB'].contains(position)) {
      return isDarkMode ? Colors.orange.shade400 : Colors.orange.shade700; // Linebackers
    } else if (['CB', 'S', 'FS', 'SS'].contains(position)) {
      return isDarkMode ? Colors.teal.shade400 : Colors.teal.shade700; // Secondary
    } else {
      return isDarkMode ? Colors.grey.shade400 : Colors.grey.shade700; // Special teams, etc.
    }
  }
}