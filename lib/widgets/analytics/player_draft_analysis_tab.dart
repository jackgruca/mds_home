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
  
  // Data states
  List<Map<String, dynamic>> _riserPlayers = [];
  List<Map<String, dynamic>> _fallerPlayers = [];
  
  // List of all positions for filtering
  final List<String> _allPositions = [
    'All Positions', 'QB', 'RB', 'WR', 'TE', 'OT', 'IOL', 'EDGE', 'DL', 
    'LB', 'CB', 'S'
  ];

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
      // Load player rank deviations (risers and fallers)
      final deviations = await AnalyticsQueryService.getPlayerRankDeviations(
        year: widget.draftYear,
        position: _selectedPosition == 'All Positions' ? null : _selectedPosition,
        limit: 20,  // Get enough data to split into risers and fallers
      );
      
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
      
      setState(() {
        _riserPlayers = risers;
        _fallerPlayers = fallers;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading player analysis data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  bool get wantKeepAlive => true;  // Keep state when switching tabs

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Position filter
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
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