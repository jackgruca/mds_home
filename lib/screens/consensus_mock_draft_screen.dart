// lib/screens/consensus_mock_draft_screen.dart
import 'package:flutter/material.dart';
import '../services/analytics_query_service.dart';
import '../utils/team_logo_utils.dart';

class ConsensusMockDraftScreen extends StatefulWidget {
  final int? year;
  final int rounds;

  const ConsensusMockDraftScreen({
    super.key,
    this.year,
    this.rounds = 1,
  });

  @override
  _ConsensusMockDraftScreenState createState() => _ConsensusMockDraftScreenState();
}

class _ConsensusMockDraftScreenState extends State<ConsensusMockDraftScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _consensusMock = [];
  int _selectedRound = 1;
  
  @override
  void initState() {
    super.initState();
    _loadConsensusMock();
  }
  
  Future<void> _loadConsensusMock() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final mock = await AnalyticsQueryService.generateConsensusMockDraft(
        year: widget.year,
        rounds: widget.rounds,
      );
      
      setState(() {
        _consensusMock = mock;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading consensus mock: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Consensus Mock Draft ${widget.year ?? ''}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadConsensusMock,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Round selector
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Round:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 8),
                      ...List.generate(
                        widget.rounds,
                        (index) => Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4.0),
                          child: ChoiceChip(
                            label: Text('${index + 1}'),
                            selected: _selectedRound == index + 1,
                            onSelected: (selected) {
                              if (selected) {
                                setState(() {
                                  _selectedRound = index + 1;
                                });
                              }
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Display description text
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text(
                    'Based on ${_consensusMock.isNotEmpty ? _getDataPointsCount() : "0"} mock drafts',
                    style: TextStyle(
                      fontStyle: FontStyle.italic,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),
                
                // Mock draft list
                Expanded(
                  child: _consensusMock.isEmpty
                      ? const Center(
                          child: Text('No consensus data available'),
                        )
                      : _buildMockDraftList(),
                ),
              ],
            ),
    );
  }
  
  String _getDataPointsCount() {
    // Find a pick with data to get an estimate of drafts analyzed
    for (final pick in _consensusMock) {
      if (pick['confidence'] != 0.0) {
        // Since confidence = topCount/totalCount, we can estimate if we know one pick's confidence
        final confidence = pick['confidence'] as double;
        final alternates = pick['alternateSelections'] as List;
        int totalCount = 0;
        
        // Count alternates
        for (final alt in alternates) {
          totalCount += alt['count'] as int;
        }
        
        // Confidence = topCount / (topCount + totalAltsCount)
        // So topCount = confidence * (topCount + totalAltsCount)
        // topCount - confidence*topCount = confidence*totalAltsCount
        // topCount(1-confidence) = confidence*totalAltsCount
        // topCount = confidence*totalAltsCount/(1-confidence)
        final topCount = (confidence * totalCount) / (1 - confidence);
        final estimatedTotal = (topCount + totalCount).round();
        
        return estimatedTotal.toString();
      }
    }
    return "unknown";
  }
  
  Widget _buildMockDraftList() {
    // Filter picks for the selected round
    final filteredPicks = _consensusMock.where(
      (pick) => pick['round'] == _selectedRound.toString()
    ).toList();
    
    return ListView.builder(
      itemCount: filteredPicks.length,
      itemBuilder: (context, index) {
        final pick = filteredPicks[index];
        final hasConsensus = pick['consensusPlayer'] != null;
        final confidencePercent = ( (pick['confidence'] as double) * 100).round();
        
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
          child: ExpansionTile(
            leading: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${pick['pickNumber']}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            title: Row(
              children: [
                SizedBox(
                  width: 30,
                  height: 30,
                  child: TeamLogoUtils.buildNFLTeamLogo(
                    pick['originalTeam'],
                    size: 30,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  hasConsensus 
                      ? pick['consensusPlayer'] 
                      : 'No consensus',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: hasConsensus ? null : Colors.grey,
                  ),
                ),
              ],
            ),
            subtitle: Row(
              children: [
                if (hasConsensus) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: _getPositionColor(pick['position']).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: _getPositionColor(pick['position'])),
                    ),
                    child: Text(
                      pick['position'],
                      style: TextStyle(
                        fontSize: 12,
                        color: _getPositionColor(pick['position']),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                
                // Confidence indicator
                if (hasConsensus) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: _getConfidenceColor(confidencePercent).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: _getConfidenceColor(confidencePercent)),
                    ),
                    child: Text(
                      '$confidencePercent% consensus',
                      style: TextStyle(
                        fontSize: 12,
                        color: _getConfidenceColor(confidencePercent),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Alternative Selections:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    
                    if ((pick['alternateSelections'] as List).isEmpty) ...[
                      const Text('No alternative selections found'),
                    ] else ...[
                      ...List.generate(
                        (pick['alternateSelections'] as List).length,
                        (i) {
                          final alt = (pick['alternateSelections'] as List)[i];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 4.0),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: _getPositionColor(alt['position']).withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(color: _getPositionColor(alt['position'])),
                                  ),
                                  child: Text(
                                    alt['position'],
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: _getPositionColor(alt['position']),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(alt['player']),
                                const Spacer(),
                                Text(
                                  alt['percentage'],
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
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
  
  Color _getConfidenceColor(int confidencePercent) {
    if (confidencePercent >= 75) {
      return Colors.green.shade700;
    } else if (confidencePercent >= 50) {
      return Colors.blue.shade700;
    } else if (confidencePercent >= 25) {
      return Colors.orange.shade700;
    } else {
      return Colors.red.shade700;
    }
  }
}