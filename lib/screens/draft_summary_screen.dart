// lib/screens/draft_summary_screen.dart - Updated version

import 'package:flutter/material.dart';
import '../models/draft_pick.dart';
import '../models/player.dart';
import '../models/trade_package.dart';
import '../services/draft_value_service.dart';

class DraftSummaryScreen extends StatefulWidget {
  final List<DraftPick> completedPicks;
  final List<Player> draftedPlayers;
  final List<TradePackage> executedTrades;
  final List<String> allTeams; // Add this to get all teams for filtering
  final String? userTeam;

  const DraftSummaryScreen({
    super.key,
    required this.completedPicks,
    required this.draftedPlayers,
    required this.executedTrades,
    required this.allTeams, // Add this parameter
    this.userTeam,
  });

  @override
  State<DraftSummaryScreen> createState() => _DraftSummaryScreenState();
}

class _DraftSummaryScreenState extends State<DraftSummaryScreen> {
  String? _selectedTeam;
  
  @override
  void initState() {
    super.initState();
    // Default to user team if available
    _selectedTeam = widget.userTeam ?? "All Teams";
  }

  @override
  Widget build(BuildContext context) {
    return Dialog.fullscreen(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Draft Summary'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        ),
        body: Column(
          children: [
            // Team filter dropdown
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  const Text('Select Team: ', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButton<String>(
                      value: _selectedTeam,
                      isExpanded: true,
                      hint: const Text('Select a team'),
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedTeam = newValue;
                        });
                      },
                      items: [
                        // Add "All Teams" as first option
                        const DropdownMenuItem<String>(
                          value: "All Teams",
                          child: Text("All Teams"),
                        ),
                        // Then add all the individual teams
                        ...widget.allTeams
                            .map<DropdownMenuItem<String>>((String team) {
                          return DropdownMenuItem<String>(
                            value: team,
                            child: Text(team),
                          );
                        }),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // Main content (filtered by selected team)
            Expanded(
              child: _buildSummaryContent(),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildAllTeamsGradeBanner() {
  // Calculate overall draft stats across all teams
  int totalPicks = widget.completedPicks.where((p) => p.selectedPlayer != null).length;
  int totalTrades = widget.executedTrades.length;
  
  // Calculate average value differential across all teams
  double totalValueDiff = 0;
  for (var pick in widget.completedPicks) {
    if (pick.selectedPlayer != null) {
      totalValueDiff += (pick.pickNumber - pick.selectedPlayer!.rank);
    }
  }
  double avgValueDiff = totalPicks > 0 ? totalValueDiff / totalPicks : 0;
  
  // Count how many teams got good grades
  Map<String, String> teamGrades = {};
  for (var team in widget.allTeams) {
    final teamPicks = widget.completedPicks.where(
      (pick) => pick.teamName == team && pick.selectedPlayer != null
    ).toList();
    
    final teamTrades = widget.executedTrades.where(
      (trade) => trade.teamOffering == team || trade.teamReceiving == team
    ).toList();
    
    if (teamPicks.isNotEmpty) {
      final gradeInfo = _calculateTeamGrade(teamPicks, teamTrades);
      teamGrades[team] = gradeInfo['grade'] ?? 'N/A';
    }
  }
  
  int aGrades = teamGrades.values.where((g) => g.startsWith('A')).length;
  int bGrades = teamGrades.values.where((g) => g.startsWith('B')).length;
  int cGrades = teamGrades.values.where((g) => g.startsWith('C')).length;
  int dGrades = teamGrades.values.where((g) => g.startsWith('D')).length;
  
  final isDarkMode = Theme.of(context).brightness == Brightness.dark;
  
  return Card(
    elevation: 4,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          colors: [
            Colors.purple.withOpacity(isDarkMode ? 0.7 : 0.2),
            Colors.indigo.withOpacity(isDarkMode ? 0.9 : 0.4),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          const Text(
            "Draft Overview",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Overall draft summary across all teams",
            style: TextStyle(
              fontSize: 15,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Stats grid
          Container(
            decoration: BoxDecoration(
              color: isDarkMode ? 
                  Colors.black.withOpacity(0.2) : 
                  Colors.white.withOpacity(0.4),
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Row(
                  children: [
                    // Draft stats
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildStatRow(
                            'Total Picks:', 
                            '$totalPicks', 
                            isDarkMode
                          ),
                          const SizedBox(height: 6),
                          _buildStatRow(
                            'Total Trades:', 
                            '$totalTrades', 
                            isDarkMode
                          ),
                          const SizedBox(height: 6),
                          _buildStatRow(
                            'Avg Value:', 
                            '${avgValueDiff > 0 ? "+" : ""}${avgValueDiff.toStringAsFixed(1)} pts/pick',
                            isDarkMode,
                            avgValueDiff >= 0 ? Colors.green : Colors.red
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(width: 20),
                    
                    // Team grades distribution
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildStatRow(
                            'A Grades:', 
                            '$aGrades teams', 
                            isDarkMode,
                            Colors.green
                          ),
                          const SizedBox(height: 6),
                          _buildStatRow(
                            'B Grades:', 
                            '$bGrades teams', 
                            isDarkMode,
                            Colors.blue
                          ),
                          const SizedBox(height: 6),
                          _buildStatRow(
                            'C Grades:', 
                            '$cGrades teams', 
                            isDarkMode,
                            Colors.orange
                          ),
                          const SizedBox(height: 6),
                          _buildStatRow(
                            'D Grades:', 
                            '$dGrades teams', 
                            isDarkMode,
                            Colors.red
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

Widget _buildTeamGradeComparison() {
  // Calculate grades for all teams
  List<Map<String, dynamic>> teamGrades = [];
  
  for (var team in widget.allTeams) {
    final teamPicks = widget.completedPicks.where(
      (pick) => pick.teamName == team && pick.selectedPlayer != null
    ).toList();
    
    final teamTrades = widget.executedTrades.where(
      (trade) => trade.teamOffering == team || trade.teamReceiving == team
    ).toList();
    
    if (teamPicks.isNotEmpty) {
      final gradeInfo = _calculateTeamGrade(teamPicks, teamTrades);
      teamGrades.add({
        'team': team,
        'grade': gradeInfo['grade'] ?? 'N/A',
        'value': gradeInfo['value'] ?? 0.0,
        'pickCount': gradeInfo['pickCount'] ?? 0,
        'isUserTeam': team == widget.userTeam,
      });
    }
  }
  
  // Sort by grade
  teamGrades.sort((a, b) {
    int gradeCompare = _compareGrades(b['grade'], a['grade'] as String);
    if (gradeCompare != 0) return gradeCompare;
    return (b['value'] as double).compareTo(a['value'] as double);
  });
  
  return Card(
    elevation: 2,
    child: Padding(
      padding: const EdgeInsets.all(8.0),
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: teamGrades.length,
        itemBuilder: (context, index) {
          final team = teamGrades[index];
          final isUserTeam = team['isUserTeam'] == true;
          
          return ListTile(
            title: Text(
              team['team'],
              style: TextStyle(
                fontWeight: isUserTeam ? FontWeight.bold : FontWeight.normal,
                color: isUserTeam ? Theme.of(context).primaryColor : null,
              ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getGradeColor(team['grade']).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: _getGradeColor(team['grade'])),
                  ),
                  child: Text(
                    team['grade'],
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _getGradeColor(team['grade']),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  "${team['value'] > 0 ? '+' : ''}${team['value'].toStringAsFixed(1)}",
                  style: TextStyle(
                    color: team['value'] >= 0 ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            onTap: () {
              setState(() {
                _selectedTeam = team['team'];
              });
            },
          );
        },
      ),
    ),
  );
}

Widget _buildBestValuePicksList() {
  // Find best value picks
  List<Map<String, dynamic>> valuePicks = [];
  
  for (var pick in widget.completedPicks) {
    if (pick.selectedPlayer == null) continue;
    
    int diff = pick.pickNumber - pick.selectedPlayer!.rank;
    if (diff >= 10) {
      valuePicks.add({
        'team': pick.teamName,
        'player': pick.selectedPlayer!.name,
        'position': pick.selectedPlayer!.position,
        'pick': pick.pickNumber,
        'rank': pick.selectedPlayer!.rank,
        'diff': diff,
      });
    }
  }
  
  // Sort by value differential
  valuePicks.sort((a, b) => b['diff'].compareTo(a['diff']));
  
  // Take top 5
  final topPicks = valuePicks.take(5).toList();
  
  if (topPicks.isEmpty) {
    return const Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Center(
          child: Text(
            'No significant value picks found yet',
            style: TextStyle(fontStyle: FontStyle.italic),
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
        children: topPicks.map((pick) {
          final isUserTeam = pick['team'] == widget.userTeam;
          
          return ListTile(
            title: Text(
              "${pick['player']} (${pick['position']})",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isUserTeam ? Theme.of(context).primaryColor : null,
              ),
            ),
            subtitle: Text(
              "${pick['team']} - Pick #${pick['pick']} (Rank #${pick['rank']})",
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green.shade100,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.green.shade700),
              ),
              child: Text(
                "+${pick['diff']}",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade700,
                ),
              ),
            ),
            onTap: () {
              setState(() {
                _selectedTeam = pick['team'];
              });
            },
          );
        }).toList(),
      ),
    ),
  );
}

Widget _buildOverallPositionBreakdown() {
  // Count positions drafted
  Map<String, int> positionCounts = {};
  for (var pick in widget.completedPicks) {
    if (pick.selectedPlayer != null) {
      final position = pick.selectedPlayer!.position;
      positionCounts[position] = (positionCounts[position] ?? 0) + 1;
    }
  }
  
  // If no positions, return empty message
  if (positionCounts.isEmpty) {
    return const Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Center(
          child: Text('No position data available'),
        ),
      ),
    );
  }
  
  // Create sorted list of positions
  final sortedPositions = positionCounts.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  
  // Calculate total for percentages
  final totalPicks = widget.completedPicks.where((p) => p.selectedPlayer != null).length;
  
  return Card(
    elevation: 2,
    child: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Position distribution bar chart
          SizedBox(
            height: 40,
            child: Row(
              children: sortedPositions.map((entry) {
                final position = entry.key;
                final count = entry.value;
                final percent = count / totalPicks;
                
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
            children: sortedPositions.map((entry) {
              final position = entry.key;
              final count = entry.value;
              final percent = (count / totalPicks * 100).round();
              
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

// Helper method for comparing grades
int _compareGrades(String a, String b) {
  // Convert grades to numeric values for comparison
  Map<String, int> gradeValues = {
    'A+': 7, 'A': 6, 'B+': 5, 'B': 4, 'C+': 3, 'C': 2, 'D': 1, 'F': 0,
  };
  
  int valueA = gradeValues[a] ?? 0;
  int valueB = gradeValues[b] ?? 0;
  
  return valueA.compareTo(valueB);
}

  Widget _buildSummaryContent() {
    if (_selectedTeam == null) {
      return const Center(
        child: Text('Please select a team to view draft summary'),
      );
    }
    
    // Handle "All Teams" selection
  if (_selectedTeam == "All Teams") {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Overall draft summary for all teams
          _buildAllTeamsGradeBanner(),
          
          const SizedBox(height: 24),
          
          // Team Grade Comparison
          const Text(
            'Team Grade Comparison',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _buildTeamGradeComparison(),
          
          const SizedBox(height: 24),
          
          // Best Value Picks across all teams
          const Text(
            'Best Value Picks',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _buildBestValuePicksList(),
          
          const SizedBox(height: 24),
          
          // Position breakdown across all teams
          const Text(
            'Overall Position Breakdown',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _buildOverallPositionBreakdown(),
        ],
      ),
    );
  }

    // Filter picks for selected team
    final teamPicks = widget.completedPicks.where(
      (pick) => pick.teamName == _selectedTeam && pick.selectedPlayer != null
    ).toList();
    
    // Sort by pick number
    teamPicks.sort((a, b) => a.pickNumber.compareTo(b.pickNumber));
    
    // Filter trades involving selected team
    final teamTrades = widget.executedTrades.where(
      (trade) => trade.teamOffering == _selectedTeam || trade.teamReceiving == _selectedTeam
    ).toList();
    
    // Calculate overall grade
    final gradeInfo = _calculateTeamGrade(teamPicks, teamTrades);
    
    return teamPicks.isEmpty
        ? Center(
            child: Text(
              '$_selectedTeam has not made any picks in this draft',
              style: const TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
            ),
          )
        : SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Overall grade banner
                _buildEnhancedGradeBanner(gradeInfo, teamTrades),
                
                const SizedBox(height: 24),
                
                // Team picks section
                const Text(
                  'Draft Picks',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                _buildTeamPicksList(teamPicks),
                
                const SizedBox(height: 24),
                
                // Team trades section (if any)
                if (teamTrades.isNotEmpty) ...[
                  const Text(
                    'Trades',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildTeamTradesList(teamTrades),
                  
                  const SizedBox(height: 24),
                ],
                
                // Position breakdown
                const Text(
                  'Position Breakdown',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                _buildPositionBreakdown(teamPicks),
              ],
            ),
          );
  }
  
  // In lib/screens/draft_summary_screen.dart

// Fix the _buildEnhancedGradeBanner method to handle null values
Widget _buildEnhancedGradeBanner(Map<String, dynamic> gradeInfo, List<TradePackage> teamTrades) {
  final grade = gradeInfo['grade'];
  final valuePerPick = gradeInfo['value'];
  final description = gradeInfo['description'];
  
  // Calculate additional metrics
  final totalPicks = gradeInfo['pickCount'] ?? 0; // Add null check
  final totalValue = (valuePerPick ?? 0) * totalPicks; // Add null check
  final tradeCount = teamTrades.length;
  
  // Calculate net trade value
  double tradeValue = 0;
  for (var trade in teamTrades) {
    if (trade.teamOffering == _selectedTeam) {
      tradeValue -= trade.valueDifferential;
    } else {
      tradeValue += trade.valueDifferential;
    }
  }
  
  // Determine color based on grade
  Color gradeColor;
  if (grade.startsWith('A')) {
    gradeColor = Colors.green.shade700;
  } else if (grade.startsWith('B')) {
    gradeColor = Colors.blue.shade700;
  } else if (grade.startsWith('C')) {
    gradeColor = Colors.orange.shade700;
  } else {
    gradeColor = Colors.red.shade700;
  }
  
  final isDarkMode = Theme.of(context).brightness == Brightness.dark;
  
  return Card(
    elevation: 4,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          colors: [
            gradeColor.withOpacity(isDarkMode ? 0.7 : 0.2),
            gradeColor.withOpacity(isDarkMode ? 0.9 : 0.4),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row with grade and team name
          Row(
            children: [
              // Grade circle
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDarkMode ? Colors.white.withOpacity(0.9) : Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 5,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    grade,
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: gradeColor,
                    ),
                  ),
                ),
              ),
              
              const SizedBox(width: 16),
              
              // Team name and description
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "$_selectedTeam Draft Grade",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 15,
                        color: isDarkMode ? Colors.white.withOpacity(0.9) : Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Stats grid with detailed metrics
          Container(
            decoration: BoxDecoration(
              color: isDarkMode ? 
                  Colors.black.withOpacity(0.2) : 
                  Colors.white.withOpacity(0.4),
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // First column of stats
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildStatRow(
                        'Total Picks:', 
                        '$totalPicks', 
                        isDarkMode
                      ),
                      const SizedBox(height: 6),
                      _buildStatRow(
                        'Avg Value:', 
                        '${valuePerPick != null && valuePerPick > 0 ? "+" : ""}${(valuePerPick ?? 0).toStringAsFixed(1)} pts/pick',
                        isDarkMode,
                        (valuePerPick ?? 0) >= 0 ? Colors.green : Colors.red
                      ),
                      const SizedBox(height: 6),
                      _buildStatRow(
                        'Total Value:', 
                        '${totalValue > 0 ? "+" : ""}${totalValue.toStringAsFixed(0)} pts',
                        isDarkMode,
                        totalValue >= 0 ? Colors.green : Colors.red
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(width: 20),
                
                // Second column of stats
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildStatRow(
                        'Total Trades:', 
                        '$tradeCount', 
                        isDarkMode
                      ),
                      const SizedBox(height: 6),
                      _buildStatRow(
                        'Trade Value:', 
                        '${tradeValue > 0 ? "+" : ""}${tradeValue.toStringAsFixed(0)} pts',
                        isDarkMode,
                        tradeValue >= 0 ? Colors.green : Colors.red
                      ),
                      const SizedBox(height: 6),
                      _buildStatRow(
                        'Overall Value:', 
                        '${(totalValue + tradeValue) > 0 ? "+" : ""}${(totalValue + tradeValue).toStringAsFixed(0)} pts',
                        isDarkMode,
                        (totalValue + tradeValue) >= 0 ? Colors.green : Colors.red
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

// Helper method for stat rows in the enhanced banner
Widget _buildStatRow(String label, String value, bool isDarkMode, [Color? valueColor]) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(
        label,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: isDarkMode ? Colors.white.withOpacity(0.8) : Colors.black87,
        ),
      ),
      Text(
        value,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: valueColor ?? (isDarkMode ? Colors.white : Colors.black87),
        ),
      ),
    ],
  );
}
  
  Widget _buildTeamPicksList(List<DraftPick> teamPicks) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: teamPicks.length,
      itemBuilder: (context, index) {
        final pick = teamPicks[index];
        final player = pick.selectedPlayer!;
        
        // Calculate individual pick grade
        final pickGrade = _calculatePickGrade(pick.pickNumber, player.rank);
        
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: _getPickNumberColor(pick.round),
              child: Text(
                '${pick.pickNumber}',
                style: const TextStyle(color: Colors.white),
              ),
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    player.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getGradeColor(pickGrade).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: _getGradeColor(pickGrade)),
                  ),
                  child: Text(
                    pickGrade,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _getGradeColor(pickGrade),
                    ),
                  ),
                ),
              ],
            ),
            subtitle: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: _getPositionColor(player.position),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    player.position,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                  ),
                ),
                Text(
                  player.school,
                  style: const TextStyle(
                    fontSize: 12,
                  ),
                ),
                const Spacer(),
                Text(
                  'Rank: #${player.rank}',
                  style: TextStyle(
                    fontSize: 12,
                    color: _getValueColor(pick.pickNumber - player.rank),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  _getValueText(pick.pickNumber - player.rank),
                  style: TextStyle(
                    fontSize: 12,
                    color: _getValueColor(pick.pickNumber - player.rank),
                  ),
                ),
              ],
            ),
            trailing: pick.tradeInfo != null && pick.tradeInfo!.isNotEmpty
                ? Tooltip(
                    message: pick.tradeInfo!,
                    child: const Icon(Icons.swap_horiz, color: Colors.orange),
                  )
                : null,
          ),
        );
      },
    );
  }
  
  Widget _buildTeamTradesList(List<TradePackage> teamTrades) {
    // Sort trades by the pick number they involved
    teamTrades.sort((a, b) => a.targetPick.pickNumber.compareTo(b.targetPick.pickNumber));
    
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: teamTrades.length,
      itemBuilder: (context, index) {
        final trade = teamTrades[index];
        final bool isTrading = trade.teamOffering == _selectedTeam;
        final double valueDiff = isTrading ? -trade.valueDifferential : trade.valueDifferential;
        
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Trade header
                Row(
                  children: [
                    Icon(
                      isTrading ? Icons.arrow_upward : Icons.arrow_downward,
                      color: isTrading ? Colors.orange : Colors.green,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isTrading 
                          ? "Traded Up with ${trade.teamReceiving}" 
                          : "Traded Down with ${trade.teamOffering}",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: valueDiff >= 0 ? Colors.green.shade100 : Colors.red.shade100,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: valueDiff >= 0 ? Colors.green.shade700 : Colors.red.shade700,
                        ),
                      ),
                      child: Text(
                        "${valueDiff > 0 ? "+" : ""}${valueDiff.toStringAsFixed(0)} pts",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: valueDiff >= 0 ? Colors.green.shade700 : Colors.red.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 8),
                
                // Trade description
                Text(trade.tradeDescription, style: const TextStyle(fontSize: 13)),
              ],
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildPositionBreakdown(List<DraftPick> teamPicks) {
    // Count positions drafted
    Map<String, int> positionCounts = {};
    for (var pick in teamPicks) {
      final position = pick.selectedPlayer!.position;
      positionCounts[position] = (positionCounts[position] ?? 0) + 1;
    }
    
    // If no positions, return empty message
    if (positionCounts.isEmpty) {
      return const Text('No position data available');
    }
    
    // Create sorted list of positions
    final sortedPositions = positionCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    // Calculate total for percentages
    final totalPicks = teamPicks.length;
    
    return Column(
      children: [
        // Position distribution bar chart
        SizedBox(
          height: 40,
          child: Row(
            children: sortedPositions.map((entry) {
              final position = entry.key;
              final count = entry.value;
              final percent = count / totalPicks;
              
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
          children: sortedPositions.map((entry) {
            final position = entry.key;
            final count = entry.value;
            final percent = (count / totalPicks * 100).round();
            
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
    );
  }
  
  Map<String, dynamic> _calculateTeamGrade(
  List<DraftPick> teamPicks, 
  List<TradePackage> teamTrades
) {
  if (teamPicks.isEmpty) {
    return {
      'grade': 'N/A',
      'value': 0.0,
      'description': 'No picks made',
      'pickCount': 0,
    };
  }
  
  // Calculate average rank differential
  double totalDiff = 0;
  for (var pick in teamPicks) {
    if (pick.selectedPlayer != null) {
      totalDiff += (pick.pickNumber - pick.selectedPlayer!.rank);
    }
  }
  double avgDiff = totalDiff / teamPicks.length;
  
  // Calculate trade value
  double tradeValue = 0;
  for (var trade in teamTrades) {
    if (trade.teamOffering == _selectedTeam) {
      tradeValue -= trade.valueDifferential;
    } else {
      tradeValue += trade.valueDifferential;
    }
  }
  
  // Trade value per pick
  double tradeValuePerPick = teamPicks.isNotEmpty ? tradeValue / teamPicks.length : 0;
  
  // Combine metrics for final grade
  double combinedValue = avgDiff + (tradeValuePerPick / 10);
  
  // Determine letter grade based on value
  String grade;
  String description;
  
  if (combinedValue >= 15) {
    grade = 'A+';
    description = 'Outstanding draft with exceptional value';
  } else if (combinedValue >= 10) {
    grade = 'A';
    description = 'Excellent draft with great value picks';
  } else if (combinedValue >= 5) {
    grade = 'B+';
    description = 'Very good draft with solid value picks';
  } else if (combinedValue >= 0) {
    grade = 'B';
    description = 'Solid draft with good value picks';
  } else if (combinedValue >= -5) {
    grade = 'C+';
    description = 'Average draft with some reaches';
  } else if (combinedValue >= -10) {
    grade = 'C';
    description = 'Below average draft with several reaches';
  } else {
    grade = 'D';
    description = 'Poor draft with significant reaches';
  }
  
  return {
    'grade': grade,
    'value': avgDiff,
    'description': description,
    'pickCount': teamPicks.length,
  };
}
  
  String _calculatePickGrade(int pickNumber, int playerRank) {
    int diff = pickNumber - playerRank;
    
    if (diff >= 20) return 'A+';
    if (diff >= 15) return 'A';
    if (diff >= 10) return 'B+';
    if (diff >= 5) return 'B';
    if (diff >= 0) return 'C+';
    if (diff >= -10) return 'C';
    if (diff >= -20) return 'D';
    return 'F';
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
  
  Color _getPickNumberColor(String round) {
    switch (round) {
      case '1': return Colors.blue.shade700;
      case '2': return Colors.green.shade700;
      case '3': return Colors.orange.shade700;
      case '4': return Colors.purple.shade700;
      case '5': return Colors.red.shade700;
      case '6': return Colors.teal.shade700;
      case '7': return Colors.brown.shade700;
      default: return Colors.grey.shade700;
    }
  }
  
  Color _getValueColor(int valueDiff) {
    if (valueDiff >= 15) return Colors.green.shade800; // Excellent value
    if (valueDiff >= 5) return Colors.green.shade600; // Good value
    if (valueDiff >= -5) return Colors.blue.shade600; // Fair value
    if (valueDiff >= -15) return Colors.orange.shade700; // Slight reach
    return Colors.red.shade700; // Big reach
  }
  
  String _getValueText(int valueDiff) {
    if (valueDiff > 0) return "(+$valueDiff)";
    if (valueDiff < 0) return "($valueDiff)";
    return "(0)";
  }
}