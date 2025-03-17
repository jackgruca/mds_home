// lib/widgets/analytics/draft_analytics_dashboard.dart
import 'dart:math';

import 'package:flutter/material.dart';
import '../../models/draft_pick.dart';
import '../../models/player.dart';
import '../../models/trade_package.dart';
import '../../services/draft_value_service.dart';
import '../../models/team_need.dart';

class DraftAnalyticsDashboard extends StatefulWidget {
  final List<DraftPick> completedPicks;
  final List<Player> draftedPlayers;
  final List<TradePackage> executedTrades;
  final List<TeamNeed> teamNeeds;
  final String? userTeam;

  const DraftAnalyticsDashboard({
    super.key,
    required this.completedPicks,
    required this.draftedPlayers,
    required this.executedTrades,
    required this.teamNeeds,
    this.userTeam,
  });

  @override
  State<DraftAnalyticsDashboard> createState() => _DraftAnalyticsDashboardState();
}

class _DraftAnalyticsDashboardState extends State<DraftAnalyticsDashboard> {
  // Analytics data
  Map<String, int> _positionCounts = {};
  Map<String, Map<String, dynamic>> _teamGrades = {};
  List<Map<String, dynamic>> _valuePicks = [];
  List<Map<String, dynamic>> _reachPicks = [];
  List<Map<String, dynamic>> _positionRuns = [];
  
  @override
  void initState() {
    super.initState();
    _calculateAnalytics();
  }
  
  @override
  void didUpdateWidget(DraftAnalyticsDashboard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Recalculate if data changes
    if (widget.completedPicks.length != oldWidget.completedPicks.length ||
        widget.executedTrades.length != oldWidget.executedTrades.length) {
      _calculateAnalytics();
    }
  }

  void _calculateAnalytics() {
    // Reset analytics
    _positionCounts = {};
    _teamGrades = {};
    _valuePicks = [];
    _reachPicks = [];
    _positionRuns = [];
    
    // Only process data if there are completed picks
    if (widget.completedPicks.isEmpty) {
      return; // Exit early if no picks have been made yet
    }
    
    // Count positions drafted
    for (var pick in widget.completedPicks) {
      if (pick.selectedPlayer != null) {
        String position = pick.selectedPlayer!.position;
        _positionCounts[position] = (_positionCounts[position] ?? 0) + 1;
      }
    }
    
    // Calculate team grades and value metrics
    _calculateTeamGrades();
    
    // Find value picks and reach picks
    _findValueAndReachPicks();
    
    // Identify position runs
    _identifyPositionRuns();
    
    setState(() {});
  }
  
  void _calculateTeamGrades() {
    // Group picks by team
    Map<String, List<DraftPick>> teamPicks = {};
    
    for (var pick in widget.completedPicks) {
      if (pick.selectedPlayer != null) {
        teamPicks.putIfAbsent(pick.teamName, () => []);
        teamPicks[pick.teamName]!.add(pick);
      }
    }
    
    // Calculate grade for each team
    for (var entry in teamPicks.entries) {
      String team = entry.key;
      List<DraftPick> picks = entry.value;
      
      // Calculate average value differential
      double totalDiff = 0;
      for (var pick in picks) {
        totalDiff += (pick.pickNumber - pick.selectedPlayer!.rank);
      }
      double avgDiff = picks.isEmpty ? 0 : totalDiff / picks.length;
      
      // Calculate trade value
      double tradeValue = 0;
      for (var trade in widget.executedTrades) {
        if (trade.teamOffering == team) {
          tradeValue -= trade.valueDifferential;
        } else if (trade.teamReceiving == team) {
          tradeValue += trade.valueDifferential;
        }
      }
      
      // Combine metrics for final grade
      double combinedValue = avgDiff + (tradeValue / 100);
      
      // Determine letter grade
      String grade;
      if (combinedValue >= 15) grade = 'A+';
      else if (combinedValue >= 10) grade = 'A';
      else if (combinedValue >= 5) grade = 'B+';
      else if (combinedValue >= 0) grade = 'B';
      else if (combinedValue >= -5) grade = 'C+';
      else if (combinedValue >= -10) grade = 'C';
      else grade = 'D';
      
      // Store team metrics
      _teamGrades[team] = {
        'grade': grade,
        'avgDiff': avgDiff,
        'tradeValue': tradeValue,
        'combinedValue': combinedValue,
        'pickCount': picks.length,
        'isUserTeam': team == widget.userTeam,
      };
    }
  }
  
  void _findValueAndReachPicks() {
    for (var pick in widget.completedPicks) {
      if (pick.selectedPlayer == null) continue;
      
      int diff = pick.pickNumber - pick.selectedPlayer!.rank;
      
      // Value picks (player taken later than rank)
      if (diff >= 15) {
        _valuePicks.add({
          'team': pick.teamName,
          'player': pick.selectedPlayer!.name,
          'position': pick.selectedPlayer!.position,
          'pick': pick.pickNumber,
          'rank': pick.selectedPlayer!.rank,
          'diff': diff,
          'isUserTeam': pick.teamName == widget.userTeam,
        });
      }
      
      // Reach picks (player taken earlier than rank)
      if (diff <= -15) {
        _reachPicks.add({
          'team': pick.teamName,
          'player': pick.selectedPlayer!.name,
          'position': pick.selectedPlayer!.position,
          'pick': pick.pickNumber,
          'rank': pick.selectedPlayer!.rank,
          'diff': diff,
          'isUserTeam': pick.teamName == widget.userTeam,
        });
      }
    }
    
    // Sort by value differential
    _valuePicks.sort((a, b) => b['diff'].compareTo(a['diff']));
    _reachPicks.sort((a, b) => a['diff'].compareTo(b['diff'])); // Most significant reaches first
  }
  
  void _identifyPositionRuns() {
  // Create list of picks in order
  List<DraftPick> orderedPicks = List.from(widget.completedPicks)
    ..sort((a, b) => a.pickNumber.compareTo(b.pickNumber));
  
  // Map of position to list of pick numbers
  Map<String, List<int>> positionToPicks = {};
  
  // First collect all picks by position
  for (var pick in orderedPicks) {
    if (pick.selectedPlayer == null) continue;
    
    String position = pick.selectedPlayer!.position;
    int pickNumber = pick.pickNumber;
    
    if (!positionToPicks.containsKey(position)) {
      positionToPicks[position] = [];
    }
    
    positionToPicks[position]!.add(pickNumber);
  }
  
  // Now analyze each position for runs
  for (var entry in positionToPicks.entries) {
    String position = entry.key;
    List<int> picks = entry.value..sort();
    
    // Need at least 3 picks to form a run
    if (picks.length < 3) continue;
    
    // Sliding window to find runs
    for (int i = 0; i <= picks.length - 3; i++) {
      // Check if there's a run of 3+ picks with a reasonable span
      int start = picks[i];
      
      // Try to find the longest run starting from this pick
      int maxRunLength = 0;
      int endIdx = i;
      
      for (int j = i + 1; j < picks.length; j++) {
        int span = picks[j] - start + 1;
        
        // Consider runs with spans of up to 15 picks
        if (span <= 15) {
          maxRunLength = j - i + 1;
          endIdx = j;
        } else {
          break; // Span too large, stop extending this run
        }
      }
      
      // Only consider runs of 3 or more
      if (maxRunLength >= 3) {
        int end = picks[endIdx];
        int span = end - start + 1;
        
        // Check if this run overlaps with any previously identified run
        bool overlapsWithExisting = _positionRuns.any((run) => 
          run['position'] == position && 
          ((run['startPick'] <= start && run['endPick'] >= start) || 
           (run['startPick'] <= end && run['endPick'] >= end) ||
           (start <= run['startPick'] && end >= run['endPick']))
        );
        
        // If this is a new non-overlapping run, add it
        if (!overlapsWithExisting) {
          _positionRuns.add({
            'position': position,
            'startPick': start,
            'endPick': end,
            'count': maxRunLength,
          });
          
          // Skip ahead to avoid detecting sub-runs
          i = endIdx - 1;
        }
      }
    }
  }
  
  // Sort position runs by position, then by start pick
  _positionRuns.sort((a, b) {
    int posCompare = a['position'].compareTo(b['position']);
    if (posCompare != 0) return posCompare;
    return a['startPick'].compareTo(b['startPick']);
  });
}

  @override
  Widget build(BuildContext context) {
    if (widget.completedPicks.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.analytics_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              "No draft data available yet",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              "Analytics will appear after the draft begins",
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Team Grades Section
          _buildSectionHeader("Team Draft Grades"),
          _buildTeamGradesTable(),
          
          const SizedBox(height: 24),
          
          // Value Picks Section
          _buildSectionHeader("Best Value Picks"),
          _buildValuePicksList(true), // true for value picks
          
          const SizedBox(height: 24),
          
          // Reach Picks Section
          _buildSectionHeader("Biggest Reaches"),
          _buildValuePicksList(false), // false for reach picks
          
          const SizedBox(height: 24),
          
          // Position Runs Section
          _buildSectionHeader("Position Runs"),
          _buildPositionRunsList(),
          
          const SizedBox(height: 24),
          
          // Position Distribution
          _buildSectionHeader("Position Distribution"),
          _buildPositionDistribution(),
        ],
      ),
    );
  }
  
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).primaryColor,
        ),
      ),
    );
  }
  
  Widget _buildTeamGradesTable() {
    // Sort teams by grade
    List<MapEntry<String, Map<String, dynamic>>> sortedTeams = _teamGrades.entries.toList();
    sortedTeams.sort((a, b) {
      // Sort by grade first
      String gradeA = a.value['grade'];
      String gradeB = b.value['grade'];
      
      // A+ > A > B+ > B > C+ > C > D
      int gradeCompare = _compareGrades(gradeB, gradeA);
      if (gradeCompare != 0) return gradeCompare;
      
      // If same grade, sort by combined value
      return b.value['combinedValue'].compareTo(a.value['combinedValue']);
    });
    
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Table header
            Table(
              columnWidths: const {
                0: FlexColumnWidth(1.5), // Team name
                1: FlexColumnWidth(0.7), // Grade
                2: FlexColumnWidth(1.0), // Value
                3: FlexColumnWidth(0.7), // Picks
              },
              border: TableBorder(
                horizontalInside: BorderSide(
                  color: Colors.grey.shade300,
                  width: 1,
                ),
                bottom: BorderSide(
                  color: Colors.grey.shade300,
                  width: 1,
                ),
              ),
              children: [
                TableRow(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                  ),
                  children: const [
                    Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text(
                        'Team',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text(
                        'Grade',
                        style: TextStyle(fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text(
                        'Avg Value',
                        style: TextStyle(fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text(
                        'Picks',
                        style: TextStyle(fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
                
                // Team rows
                ...sortedTeams.map((entry) {
                  final team = entry.key;
                  final data = entry.value;
                  final bool isUserTeam = data['isUserTeam'] == true;
                  
                  return TableRow(
                    decoration: isUserTeam
                        ? BoxDecoration(color: Colors.blue.shade50)
                        : null,
                    children: [
                      // Team name
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          team,
                          style: TextStyle(
                            fontWeight: isUserTeam ? FontWeight.bold : FontWeight.normal,
                            color: isUserTeam ? Colors.blue.shade800 : null,
                          ),
                        ),
                      ),
                      
                      // Grade
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: _getGradeColor(data['grade']).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: _getGradeColor(data['grade'])),
                            ),
                            child: Text(
                              data['grade'],
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: _getGradeColor(data['grade']),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ),
                      
                      // Average value
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          '${data['avgDiff'] >= 0 ? '+' : ''}${data['avgDiff'].toStringAsFixed(1)}',
                          style: TextStyle(
                            color: data['avgDiff'] >= 0 ? Colors.green : Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      
                      // Pick count
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          '${data['pickCount']}',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  );
                }),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildValuePicksList(bool isValuePicks) {
    // Use value picks or reach picks based on parameter
    final picks = isValuePicks ? _valuePicks : _reachPicks;
    
    // If no picks, show empty message
    if (picks.isEmpty) {
      return Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Center(
            child: Text(
              'No ${isValuePicks ? 'value' : 'reach'} picks found yet',
              style: const TextStyle(fontStyle: FontStyle.italic),
            ),
          ),
        ),
      );
    }
    
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Display top 5 picks
            ...picks.take(5).map((pick) {
              final isUserTeam = pick['isUserTeam'] == true;
              final diff = pick['diff'];
              
              return ListTile(
                title: RichText(
                  text: TextSpan(
                    style: DefaultTextStyle.of(context).style,
                    children: [
                      TextSpan(
                        text: '${pick['player']} ',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isUserTeam ? Colors.blue.shade800 : null,
                        ),
                      ),
                      TextSpan(
                        text: '(${pick['position']})',
                        style: const TextStyle(
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
                subtitle: Text(
                  '${pick['team']} - Pick #${pick['pick']} (Rank #${pick['rank']})',
                ),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isValuePicks ? Colors.green.shade100 : Colors.red.shade100,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: isValuePicks ? Colors.green.shade700 : Colors.red.shade700,
                    ),
                  ),
                  child: Text(
                    isValuePicks ? '+$diff' : '$diff',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isValuePicks ? Colors.green.shade700 : Colors.red.shade700,
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
  
  Widget _buildPositionRunsList() {
  // If no position runs, show empty message
  if (_positionRuns.isEmpty) {
    return const Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Center(
          child: Text(
            'No significant position runs detected',
            style: TextStyle(fontStyle: FontStyle.italic),
          ),
        ),
      ),
    );
  }
  
  // Group position runs by position
  Map<String, List<Map<String, dynamic>>> positionRunsByPosition = {};
  
  for (var run in _positionRuns) {
    String position = run['position'];
    if (!positionRunsByPosition.containsKey(position)) {
      positionRunsByPosition[position] = [];
    }
    positionRunsByPosition[position]!.add(run);
  }
  
  return Card(
    elevation: 2,
    color: Theme.of(context).brightness == Brightness.dark ? 
        const Color(0xFF1e1e2f) : null,
    child: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Significant position runs (3+ picks of same position in short span)",
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Theme.of(context).brightness == Brightness.dark 
                ? Colors.white70 
                : Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          ...positionRunsByPosition.entries.map((entry) {
            String position = entry.key;
            List<Map<String, dynamic>> runs = entry.value;
            int runCount = runs.length;
            
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Position header with run count
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: _getPositionColor(position),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        position,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      "$runCount ${runCount == 1 ? 'run' : 'runs'}",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                
                // Individual runs for this position
                ...runs.map((run) {
                  int pickSpan = run['endPick'] - run['startPick'] + 1;
                  return Padding(
                    padding: const EdgeInsets.only(left: 16, bottom: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.trending_up,
                          size: 20,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "${run['count']} picks between #${run['startPick']} and #${run['endPick']}",
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "($pickSpan pick span)",
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                
                const Divider(height: 24),
              ],
            );
          }),
        ],
      ),
    ),
  );
}
  
  Widget _buildPositionDistribution() {
    // Sort positions by count
    List<MapEntry<String, int>> positionEntries = _positionCounts.entries.toList();
    positionEntries.sort((a, b) => b.value.compareTo(a.value));
    
    // Calculate total positions for percentages
    int totalPositions = positionEntries.fold(0, (sum, entry) => sum + entry.value);
    
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Position distribution bar chart
            SizedBox(
              height: 40,
              child: Row(
                children: positionEntries.map((entry) {
                  final position = entry.key;
                  final count = entry.value;
                  final percent = count / totalPositions;
                  
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
            
            // Legend
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: positionEntries.map((entry) {
                final position = entry.key;
                final count = entry.value;
                final percent = (count / totalPositions * 100).round();
                
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getPositionColor(position).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: _getPositionColor(position)),
                  ),
                  child: Text(
                    '$position: $count ($percent%)',
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
        ),
      ),
    );
  }
  
  // Helper methods
  
  int _compareGrades(String a, String b) {
    // Convert grades to numeric values for comparison
    Map<String, int> gradeValues = {
      'A+': 7, 'A': 6, 'B+': 5, 'B': 4, 'C+': 3, 'C': 2, 'D': 1, 'F': 0,
    };
    
    int valueA = gradeValues[a] ?? 0;
    int valueB = gradeValues[b] ?? 0;
    
    return valueA.compareTo(valueB);
  }
  
  Color _getGradeColor(String grade) {
    if (grade.startsWith('A')) return Colors.green.shade700;
    if (grade.startsWith('B')) return Colors.blue.shade700;
    if (grade.startsWith('C')) return Colors.orange.shade700;
    return Colors.red.shade700;
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