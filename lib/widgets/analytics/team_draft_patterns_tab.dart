// lib/widgets/analytics/team_draft_patterns_tab.dart

import 'package:flutter/material.dart';
import '../../services/analytics_query_service.dart';
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

class _TeamDraftPatternsTabState extends State<TeamDraftPatternsTab> {
  bool _isLoading = true;
  String _selectedTeam = '';
  int _selectedRound = 1;
  
  // Data states
  List<Map<String, dynamic>> _topPicksByPosition = [];
  List<Map<String, dynamic>> _topPlayersByPick = [];
  Map<String, List<String>> _consensusNeeds = {};

  @override
  void initState() {
    super.initState();
    _selectedTeam = widget.initialTeam;
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // 1. Get top positions by pick number for selected team
      final positionData = await AnalyticsQueryService.getTopPositionsByTeam(
        team: _selectedTeam == 'All Teams' ? null : _selectedTeam,
        round: _selectedRound,
        year: widget.draftYear,
      );

      // 2. Get top players by pick for selected team
      final playerData = await AnalyticsQueryService.getTopPlayersByTeam(
        team: _selectedTeam == 'All Teams' ? null : _selectedTeam,
        round: _selectedRound,
        year: widget.draftYear,
      );

      // 3. Get consensus team needs based on user drafts
      final needsData = await AnalyticsQueryService.getConsensusTeamNeeds(
        year: widget.draftYear,
      );

      setState(() {
        _topPicksByPosition = positionData;
        _topPlayersByPick = playerData;
        _consensusNeeds = needsData;
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
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Team selector
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              const Text('Team:', style: TextStyle(fontWeight: FontWeight.bold)),
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
              // Round selector
              const Text('Round:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(width: 8),
              DropdownButton<int>(
                value: _selectedRound,
                onChanged: (newValue) {
                  if (newValue != null) {
                    setState(() {
                      _selectedRound = newValue;
                    });
                    _loadData();
                  }
                },
                items: List.generate(7, (index) => DropdownMenuItem(
                  value: index + 1,
                  child: Text('Round ${index + 1}'),
                )),
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
                                'Position Trends by Pick (Round $_selectedRound)',
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
                                'Most Common Players Selected (Round $_selectedRound)',
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
          return TableRow(
  children: [
    _buildTableCell('${data['pick'] ?? 'N/A'}'),
    _buildTableCell('${data['round'] ?? 'N/A'}'),
    _buildPositionCell(
      (data['positions'] != null && data['positions'].length > 0) 
          ? data['positions'][0]['position'] ?? 'N/A' 
          : 'N/A',
      (data['positions'] != null && data['positions'].length > 0) 
          ? data['positions'][0]['percentage'] ?? '0%' 
          : '0%',
    ),
    _buildPositionCell(
      (data['positions'] != null && data['positions'].length > 1) 
          ? data['positions'][1]['position'] ?? 'N/A' 
          : 'N/A',
      (data['positions'] != null && data['positions'].length > 1) 
          ? data['positions'][1]['percentage'] ?? '0%' 
          : '0%',
    ),
    _buildPositionCell(
      (data['positions'] != null && data['positions'].length > 2) 
          ? data['positions'][2]['position'] ?? 'N/A' 
          : 'N/A',
      (data['positions'] != null && data['positions'].length > 2) 
          ? data['positions'][2]['percentage'] ?? '0%' 
          : '0%',
    ),
  ],
);
        }),
      ],
    );
  }

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
            _buildTableHeader('Player'),
            _buildTableHeader('Position'),
            _buildTableHeader('Frequency'),
          ],
        ),
        // Data rows
        ..._topPlayersByPick.map((data) {
          return TableRow(
            children: [
              _buildTableCell('${data['pick'] ?? 'N/A'}'),
              _buildTableCell('${data['player'] ?? 'N/A'}'),
              _buildPositionCell(data['position'] ?? 'N/A', ''),
              _buildTableCell('${data['percentage'] ?? '0%'}'),
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