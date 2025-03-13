// lib/widgets/analytics/draft_analytics_dashboard.dart
import 'dart:math';

import 'package:flutter/material.dart';
import '../../models/draft_pick.dart';
import '../../models/player.dart';
import '../../models/trade_package.dart';
import '../../services/draft_value_service.dart';

class DraftAnalyticsDashboard extends StatefulWidget {
  final List<DraftPick> completedPicks;
  final List<Player> draftedPlayers;
  final List<TradePackage> executedTrades;
  final String? userTeam;

  const DraftAnalyticsDashboard({
    super.key,
    required this.completedPicks,
    required this.draftedPlayers,
    required this.executedTrades,
    this.userTeam,
  });

  @override
  State<DraftAnalyticsDashboard> createState() => _DraftAnalyticsDashboardState();
}

class _DraftAnalyticsDashboardState extends State<DraftAnalyticsDashboard> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  // Analytics data
  Map<String, int> _positionCounts = {};
  Map<String, List<DraftPick>> _teamPicks = {};
  Map<String, double> _valueByTeam = {};
  Map<String, int> _rankDifferentials = {};
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _calculateAnalytics() {
    // Reset analytics
    _positionCounts = {};
    _teamPicks = {};
    _valueByTeam = {};
    _rankDifferentials = {};
    
    // Only process data if there are completed picks
    if (widget.completedPicks.isEmpty) {
      return; // Exit early if no picks have been made yet
    }
    
    // Count positions drafted
    for (var pick in widget.completedPicks) {
      if (pick.selectedPlayer != null) {
        String position = pick.selectedPlayer!.position;
        _positionCounts[position] = (_positionCounts[position] ?? 0) + 1;
        
        // Calculate rank differential (how much value gained/lost)
        int rankDiff = pick.pickNumber - pick.selectedPlayer!.rank;
        _rankDifferentials[pick.teamName] = 
          (_rankDifferentials[pick.teamName] ?? 0) + rankDiff;
      }
      
      // Group picks by team
      _teamPicks.putIfAbsent(pick.teamName, () => []);
      _teamPicks[pick.teamName]!.add(pick);
    }
    
    // Calculate total pick value by team
    for (var entry in _teamPicks.entries) {
      double teamValue = 0;
      for (var pick in entry.value) {
        teamValue += DraftValueService.getValueForPick(pick.pickNumber);
      }
      _valueByTeam[entry.key] = teamValue;
    }
    
    setState(() {});
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

    return Column(
      children: [
        TabBar(
          controller: _tabController,
          indicatorColor: Colors.blue,
          tabs: const [
            Tab(text: 'Your Draft', icon: Icon(Icons.person)),
            Tab(text: 'League Overview', icon: Icon(Icons.groups)),
            Tab(text: 'Draft Trends', icon: Icon(Icons.analytics)),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildYourDraftTab(),
              _buildLeagueOverviewTab(),
              _buildDraftTrendsTab(),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildYourDraftTab() {
  if (widget.userTeam == null) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person_off, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            "No team selected",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey),
          ),
          SizedBox(height: 8),
          Text(
            "Select a team to see your draft analysis",
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
  
  // Get user team picks
  final userPicks = widget.completedPicks
      .where((pick) => pick.teamName == widget.userTeam && pick.selectedPlayer != null)
      .toList();
      
  // Get user trades
  final userTrades = widget.executedTrades
      .where((trade) => 
        trade.teamOffering == widget.userTeam || 
        trade.teamReceiving == widget.userTeam)
      .toList();
      
  // Calculate draft value metrics
  final draftMetrics = _calculateUserDraftMetrics(userPicks, userTrades);
  
  return SingleChildScrollView(
    padding: const EdgeInsets.all(16.0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Draft grade banner
        _buildEnhancedDraftGradeBanner(draftMetrics),
        
        const SizedBox(height: 24),
        
        // Key metrics cards
        _buildDraftMetricsCards(draftMetrics),
        
        const SizedBox(height: 24),
        
        // Draft picks by round
        _buildDraftPicksByRound(userPicks),
        
        const SizedBox(height: 24),
        
        // Trade summary
        if (userTrades.isNotEmpty)
          _buildUserTradesSummary(userTrades),
        
        // Position breakdown for user picks
        const SizedBox(height: 24),
        _buildUserPositionBreakdown(userPicks),
      ],
    ),
  );
}

// 1. Method to calculate metrics for the user's draft
Map<String, dynamic> _calculateUserDraftMetrics(List<DraftPick> userPicks, List<TradePackage> userTrades) {
  // Calculate total value differential for picks
  double totalValueDiff = 0;
  int totalPicks = userPicks.length;
  List<DraftPick> valuePicks = [];
  List<DraftPick> reachPicks = [];
  
  for (var pick in userPicks) {
    int diff = pick.pickNumber - pick.selectedPlayer!.rank;
    totalValueDiff += diff;
    
    if (diff >= 10) {
      valuePicks.add(pick);
    } else if (diff <= -10) {
      reachPicks.add(pick);
    }
  }
  
  // Calculate average value differential
  double avgValueDiff = totalPicks > 0 ? totalValueDiff / totalPicks : 0;
  
  // Calculate trade value added
  double tradeValueAdded = 0;
  for (var trade in userTrades) {
    if (trade.teamOffering == widget.userTeam) {
      // User traded away picks
      tradeValueAdded -= trade.valueDifferential;
    } else {
      // User received picks
      tradeValueAdded += trade.valueDifferential;
    }
  }
  
  // Determine draft grade
  String grade = _calculateEnhancedDraftGrade(avgValueDiff, tradeValueAdded, totalPicks);
  
  return {
    'totalPicks': totalPicks,
    'totalValueDiff': totalValueDiff,
    'avgValueDiff': avgValueDiff,
    'valuePicks': valuePicks,
    'reachPicks': reachPicks,
    'tradeValueAdded': tradeValueAdded,
    'totalTrades': userTrades.length,
    'grade': grade,
  };
}

// 2. Method to calculate draft grade
String _calculateEnhancedDraftGrade(double avgValueDiff, double tradeValueAdded, int totalPicks) {
  // Base grade on average value differential
  String baseGrade;
  if (avgValueDiff >= 15) baseGrade = "A+";
  else if (avgValueDiff >= 10) baseGrade = "A";
  else if (avgValueDiff >= 5) baseGrade = "B+";
  else if (avgValueDiff >= 0) baseGrade = "B";
  else if (avgValueDiff >= -5) baseGrade = "C+";
  else if (avgValueDiff >= -10) baseGrade = "C";
  else baseGrade = "D";
  
  // Adjust for trade value
  if (tradeValueAdded > 200 && totalPicks >= 3) {
    // Boost grade for excellent trade value
    if (baseGrade == "B+") baseGrade = "A";
    else if (baseGrade == "B") baseGrade = "B+";
    else if (baseGrade == "C+") baseGrade = "B";
    else if (baseGrade == "C") baseGrade = "C+";
    else if (baseGrade == "D") baseGrade = "C";
  } else if (tradeValueAdded < -200 && totalPicks >= 3) {
    // Lower grade for poor trade value
    if (baseGrade == "A") baseGrade = "B+";
    else if (baseGrade == "B+") baseGrade = "B";
    else if (baseGrade == "B") baseGrade = "C+";
    else if (baseGrade == "C+") baseGrade = "C";
    else if (baseGrade == "C") baseGrade = "D";
  }
  
  return baseGrade;
}

// 3. Method to build enhanced draft grade banner
Widget _buildEnhancedDraftGradeBanner(Map<String, dynamic> metrics) {
  String grade = metrics['grade'];
  double avgValueDiff = metrics['avgValueDiff'];
  int totalPicks = metrics['totalPicks'];
  
  // Grade color based on letter grade
  Color gradeColor;
  String description;
  
  if (grade.startsWith("A")) {
    gradeColor = Colors.green.shade700;
    description = "Excellent draft with exceptional value";
  } else if (grade.startsWith("B")) {
    gradeColor = Colors.blue.shade700;
    description = "Solid draft with good value picks";
  } else if (grade.startsWith("C")) {
    gradeColor = Colors.orange.shade700;
    description = "Average draft with some reaches";
  } else {
    gradeColor = Colors.red.shade700;
    description = "Below average draft with significant reaches";
  }
  
  return Card(
    elevation: 4,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    child: Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          colors: [
            gradeColor.withOpacity(0.7),
            gradeColor,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          // Grade circle
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
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
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: gradeColor,
                ),
              ),
            ),
          ),
          
          const SizedBox(width: 20),
          
          // Draft summary text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "${widget.userTeam} Draft Grade",
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Average Value: ${avgValueDiff.toStringAsFixed(1)} points per pick",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
                Text(
                  "Total Picks: $totalPicks",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.8),
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

// 4. Method to build draft metrics cards
Widget _buildDraftMetricsCards(Map<String, dynamic> metrics) {
  return Row(
    children: [
      Expanded(
        child: _buildMetricCard(
          "Value Picks",
          "${metrics['valuePicks'].length}",
          Icons.thumb_up,
          Colors.green.shade700,
          "Picks with 10+ points of value",
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: _buildMetricCard(
          "Reach Picks",
          "${metrics['reachPicks'].length}",
          Icons.thumb_down,
          Colors.red.shade700,
          "Picks that were 10+ point reaches",
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: _buildMetricCard(
          "Trade Value",
          "${metrics['tradeValueAdded'] > 0 ? '+' : ''}${metrics['tradeValueAdded'].toStringAsFixed(0)}",
          Icons.swap_horiz,
          metrics['tradeValueAdded'] >= 0 ? Colors.blue.shade700 : Colors.orange.shade700,
          "Net value gained through trades",
        ),
      ),
    ],
  );
}

// 5. Helper method to build a metric card
Widget _buildMetricCard(String title, String value, IconData icon, Color color, String tooltip) {
  return Card(
    elevation: 2,
    child: Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ),
  );
}

// 6. Method to build draft picks by round
Widget _buildDraftPicksByRound(List<DraftPick> userPicks) {
  // Group picks by round
  Map<String, List<DraftPick>> picksByRound = {};
  
  // Sort picks by round and pick number
  userPicks.sort((a, b) {
    int roundComparison = a.round.compareTo(b.round);
    if (roundComparison != 0) return roundComparison;
    return a.pickNumber.compareTo(b.pickNumber);
  });
  
  // Group by round
  for (var pick in userPicks) {
    picksByRound.putIfAbsent(pick.round, () => []);
    picksByRound[pick.round]!.add(pick);
  }
  
  // Create a card for each round
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        "Draft Picks by Round",
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      const SizedBox(height: 8),
      
      if (picksByRound.isEmpty)
        const Card(
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Text("No picks made yet"),
          ),
        )
      else
        ...picksByRound.entries.map((entry) {
          String round = entry.key;
          List<DraftPick> picks = entry.value;
          
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Column(
              children: [
                // Round header
                Container(
                  padding: const EdgeInsets.all(12),
                  width: double.infinity,
                  color: _getRoundColor(round).withOpacity(0.1),
                  child: Text(
                    "Round $round",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _getRoundColor(round),
                    ),
                  ),
                ),
                
                // Picks in this round
                ...picks.map((pick) => 
                  ListTile(
                    leading: CircleAvatar(
                      backgroundColor: _getRoundColor(round),
                      child: Text(
                        "${pick.pickNumber}",
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ),
                    title: Text(
                      pick.selectedPlayer!.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      "${pick.selectedPlayer!.position} - ${pick.selectedPlayer!.school}",
                      style: const TextStyle(fontSize: 12),
                    ),
                    trailing: _buildValueBadge(pick.pickNumber, pick.selectedPlayer!.rank),
                  ),
                ),
              ],
            ),
          );
        }),
    ],
  );
}

// 7. Method to build user trades summary
Widget _buildUserTradesSummary(List<TradePackage> userTrades) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        "Trade Summary",
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      const SizedBox(height: 8),
      
      // List of trades
      ...userTrades.map((trade) {
        bool isTrading = trade.teamOffering == widget.userTeam;
        String otherTeam = isTrading ? trade.teamReceiving : trade.teamOffering;
        double valueDiff = isTrading ? -trade.valueDifferential : trade.valueDifferential;
        
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
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
                      isTrading ? "Traded Up with $otherTeam" : "Traded Down with $otherTeam",
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
                
                // Trade details
                const SizedBox(height: 8),
                Text(trade.tradeDescription, style: const TextStyle(fontSize: 13)),
              ],
            ),
          ),
        );
      }),
    ],
  );
}

// 8. Method to build user position breakdown
Widget _buildUserPositionBreakdown(List<DraftPick> userPicks) {
  // Group by position
  Map<String, List<DraftPick>> picksByPosition = {};
  for (var pick in userPicks) {
    String position = pick.selectedPlayer!.position;
    picksByPosition.putIfAbsent(position, () => []);
    picksByPosition[position]!.add(pick);
  }
  
  // Sort positions by count
  List<MapEntry<String, List<DraftPick>>> sortedPositions = 
    picksByPosition.entries.toList()
      ..sort((a, b) => b.value.length.compareTo(a.value.length));
  
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        "Position Breakdown",
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      const SizedBox(height: 12),
      
      if (sortedPositions.isEmpty)
        const Text("No picks made yet")
      else
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: sortedPositions.map((entry) {
            String position = entry.key;
            int count = entry.value.length;
            Color posColor = _getPositionColor(position);
            
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: posColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: posColor),
              ),
              child: Text(
                "$position: $count",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: posColor,
                ),
              ),
            );
          }).toList(),
        ),
    ],
  );
}

// 9. Helper method to build a value badge
Widget _buildValueBadge(int pickNumber, int rank) {
  int diff = pickNumber - rank;
  Color color;
  String label;
  
  if (diff >= 20) {
    color = Colors.green.shade700;
    label = "Steal";
  } else if (diff >= 10) {
    color = Colors.green.shade600;
    label = "Value";
  } else if (diff >= -10) {
    color = Colors.blue.shade600;
    label = "Fair";
  } else if (diff >= -20) {
    color = Colors.orange.shade700;
    label = "Reach";
  } else {
    color = Colors.red.shade700;
    label = "Big Reach";
  }
  
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(4),
      border: Border.all(color: color),
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 11,
          ),
        ),
        Text(
          "${diff > 0 ? "+" : ""}$diff",
          style: TextStyle(
            color: color,
            fontSize: 10,
          ),
        ),
      ],
    ),
  );
}

// 10. Helper method to get round color
Color _getRoundColor(String round) {
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

Widget _buildDraftGradeBanner() {
  // Simple placeholder for the draft grade banner
  // Will be expanded in Phase 2
  return Card(
    elevation: 4,
    child: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          // Draft grade circle
          Container(
            width: 60,
            height: 60,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.blue,
            ),
            child: const Center(
              child: Text(
                "B+",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          
          const SizedBox(width: 16),
          
          // Text information
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "${widget.userTeam} Draft Grade",
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  "Solid draft with good value picks",
                  style: TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

Widget _buildUserPicksList() {
  // Simple list of user picks - will be enhanced in Phase 2
  final userPicks = widget.completedPicks.where(
    (pick) => pick.teamName == widget.userTeam && pick.selectedPlayer != null
  ).toList();
  
  if (userPicks.isEmpty) {
    return const Padding(
      padding: EdgeInsets.all(16.0),
      child: Text("No picks made yet"),
    );
  }
  
  return ListView.builder(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    itemCount: userPicks.length,
    itemBuilder: (context, index) {
      final pick = userPicks[index];
      return ListTile(
        leading: CircleAvatar(
          child: Text("${pick.pickNumber}"),
        ),
        title: Text(pick.selectedPlayer!.name),
        subtitle: Text("${pick.selectedPlayer!.position} - ${pick.selectedPlayer!.school}"),
      );
    },
  );
}

Widget _buildTeamGradesSection() {
  // Placeholder for team grades - will be enhanced in Phase 3
  return const Card(
    child: Padding(
      padding: EdgeInsets.all(16.0),
      child: Text("Team grades will appear here"),
    ),
  );
}

Widget _buildTradesSummarySection() {
  // Placeholder for trades summary - will be enhanced in Phase 3
  return const Card(
    child: Padding(
      padding: EdgeInsets.all(16.0),
      child: Text("Trade summary will appear here"),
    ),
  );
}

Widget _buildPositionByRoundSection() {
  // Placeholder for position by round - will be enhanced in Phase 4
  return const Card(
    child: Padding(
      padding: EdgeInsets.all(16.0),
      child: Text("Position breakdown by round will appear here"),
    ),
  );
}

Widget _buildLeagueOverviewTab() {
  // Calculate team grades and metrics for all teams
  final teamMetrics = _calculateAllTeamMetrics();
  
  return SingleChildScrollView(
    padding: const EdgeInsets.all(16.0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // League-wide draft grades
        _buildLeagueDraftGradesSection(teamMetrics),
        
        const SizedBox(height: 24),
        
        // Value winners and losers
        _buildValueWinnersAndLosersSection(teamMetrics),
        
        const SizedBox(height: 24),
        
        // League-wide trade activity
        if (widget.executedTrades.isNotEmpty)
          _buildLeagueTradeActivitySection(),
          
        const SizedBox(height: 24),
        
        // Team pick counts
        _buildTeamPickCountsSection(teamMetrics),
      ],
    ),
  );
}

// 1. Calculate metrics for all teams
Map<String, Map<String, dynamic>> _calculateAllTeamMetrics() {
  Map<String, Map<String, dynamic>> teamMetrics = {};
  
  // Get all team names from completed picks
  Set<String> teamNames = widget.completedPicks
      .map((pick) => pick.teamName)
      .toSet();
      
  // Calculate metrics for each team
  for (var teamName in teamNames) {
    // Get team picks
    final teamPicks = widget.completedPicks
        .where((pick) => pick.teamName == teamName && pick.selectedPlayer != null)
        .toList();
        
    if (teamPicks.isEmpty) continue;
    
    // Get team trades
    final teamTrades = widget.executedTrades
        .where((trade) => 
          trade.teamOffering == teamName || 
          trade.teamReceiving == teamName)
        .toList();
    
    // Calculate basic metrics
    double totalValueDiff = 0;
    int totalPicks = teamPicks.length;
    
    for (var pick in teamPicks) {
      int diff = pick.pickNumber - pick.selectedPlayer!.rank;
      totalValueDiff += diff;
    }
    
    // Calculate average value differential
    double avgValueDiff = totalPicks > 0 ? totalValueDiff / totalPicks : 0;
    
    // Calculate trade value added
    double tradeValueAdded = 0;
    for (var trade in teamTrades) {
      if (trade.teamOffering == teamName) {
        // Team traded away picks
        tradeValueAdded -= trade.valueDifferential;
      } else {
        // Team received picks
        tradeValueAdded += trade.valueDifferential;
      }
    }
    
    // Determine draft grade (use existing method to be consistent)
    String grade = _calculateEnhancedDraftGrade(avgValueDiff, tradeValueAdded, totalPicks);
    
    // Store team metrics
    teamMetrics[teamName] = {
      'totalPicks': totalPicks,
      'totalValueDiff': totalValueDiff,
      'avgValueDiff': avgValueDiff,
      'tradeValueAdded': tradeValueAdded,
      'totalTrades': teamTrades.length,
      'grade': grade,
    };
  }
  
  return teamMetrics;
}

// 2. Build league draft grades section
Widget _buildLeagueDraftGradesSection(Map<String, Map<String, dynamic>> teamMetrics) {
  // Convert to list for sorting
  List<MapEntry<String, Map<String, dynamic>>> teamEntries = teamMetrics.entries.toList();
  
  // Sort by grade (A+ first, then A, B+, etc.)
  teamEntries.sort((a, b) {
    String gradeA = a.value['grade'];
    String gradeB = b.value['grade'];
    
    // Sort by first letter first
    int letterCompare = gradeB[0].compareTo(gradeA[0]);
    if (letterCompare != 0) return letterCompare;
    
    // If same letter, check for + symbol
    bool hasPlus1 = gradeA.length > 1 && gradeA[1] == '+';
    bool hasPlus2 = gradeB.length > 1 && gradeB[1] == '+';
    
    if (hasPlus1 && !hasPlus2) return -1;
    if (!hasPlus1 && hasPlus2) return 1;
    
    return 0;
  });
  
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        "League Draft Grades",
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      const SizedBox(height: 12),
      
      Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Header row
              const Padding(
                padding: EdgeInsets.only(bottom: 8.0),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Text("Team", style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    Expanded(
                      flex: 1,
                      child: Text("Grade", 
                        style: TextStyle(fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text("Value/Pick", 
                        style: TextStyle(fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: Text("Picks", 
                        style: TextStyle(fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
              
              const Divider(),
              
              // Team rows
              ...teamEntries.map((entry) {
                final teamName = entry.key;
                final metrics = entry.value;
                final grade = metrics['grade'];
                final avgValueDiff = metrics['avgValueDiff'].toDouble();
                final totalPicks = metrics['totalPicks'];
                
                // Grade color based on letter
                Color gradeColor = _getGradeColor(grade);
                
                // Highlight user team
                bool isUserTeam = teamName == widget.userTeam;
                
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Row(
                    children: [
                      // Team name
                      Expanded(
                        flex: 2,
                        child: Text(
                          teamName,
                          style: TextStyle(
                            fontWeight: isUserTeam ? FontWeight.bold : FontWeight.normal,
                            color: isUserTeam ? Colors.blue : null,
                          ),
                        ),
                      ),
                      
                      // Grade
                      Expanded(
                        flex: 1,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: gradeColor.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: gradeColor),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            grade,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: gradeColor,
                            ),
                          ),
                        ),
                      ),
                      
                      // Value per pick
                      Expanded(
                        flex: 2,
                        child: Text(
                          "${avgValueDiff > 0 ? "+" : ""}${avgValueDiff.toStringAsFixed(1)}",
                          style: TextStyle(
                            color: avgValueDiff >= 0 ? Colors.green : Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      
                      // Total picks
                      Expanded(
                        flex: 1,
                        child: Text(
                          "$totalPicks",
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    ],
  );
}

// 3. Build value winners and losers section
Widget _buildValueWinnersAndLosersSection(Map<String, Map<String, dynamic>> teamMetrics) {
  // Convert to list for sorting
  List<MapEntry<String, Map<String, dynamic>>> teamEntries = teamMetrics.entries.toList();
  
  // Sort by average value differential (highest first)
  teamEntries.sort((a, b) => 
    b.value['avgValueDiff'].toDouble().compareTo(a.value['avgValueDiff'].toDouble()));
  
  // Get top 5 winners and bottom 5 losers
  final winners = teamEntries.take(5).toList();
  final losers = teamEntries.reversed.take(5).toList();
  
  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // Value Winners
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Value Winners",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            
            Card(
              child: Column(
                children: winners.map((entry) {
                  final teamName = entry.key;
                  final avgValueDiff = entry.value['avgValueDiff'].toDouble();
                  final isUserTeam = teamName == widget.userTeam;
                  
                  return ListTile(
                    dense: true,
                    title: Text(
                      teamName,
                      style: TextStyle(
                        fontWeight: isUserTeam ? FontWeight.bold : FontWeight.normal,
                        color: isUserTeam ? Colors.blue : null,
                      ),
                    ),
                    trailing: Text(
                      "+${avgValueDiff.toStringAsFixed(1)}",
                      style: const TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
      
      const SizedBox(width: 16),
      
      // Value Losers
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Value Losers",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            
            Card(
              child: Column(
                children: losers.map((entry) {
                  final teamName = entry.key;
                  final avgValueDiff = entry.value['avgValueDiff'].toDouble();
                  final isUserTeam = teamName == widget.userTeam;
                  
                  return ListTile(
                    dense: true,
                    title: Text(
                      teamName,
                      style: TextStyle(
                        fontWeight: isUserTeam ? FontWeight.bold : FontWeight.normal,
                        color: isUserTeam ? Colors.blue : null,
                      ),
                    ),
                    trailing: Text(
                      "${avgValueDiff.toStringAsFixed(1)}",
                      style: const TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

// 4. Build league trade activity section
Widget _buildLeagueTradeActivitySection() {
  // Count trades by team
  Map<String, int> tradesByTeam = {};
  
  for (var trade in widget.executedTrades) {
    tradesByTeam[trade.teamOffering] = (tradesByTeam[trade.teamOffering] ?? 0) + 1;
    tradesByTeam[trade.teamReceiving] = (tradesByTeam[trade.teamReceiving] ?? 0) + 1;
  }
  
  // Sort teams by trade count
  List<MapEntry<String, int>> sortedTeams = tradesByTeam.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        "Trade Activity",
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      const SizedBox(height: 12),
      
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Trade activity chart
          Expanded(
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Most Active Teams",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    
                    ...sortedTeams.take(5).map((entry) {
                      final teamName = entry.key;
                      final tradeCount = entry.value;
                      final isUserTeam = teamName == widget.userTeam;
                      
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Row(
                          children: [
                            Text(
                              teamName,
                              style: TextStyle(
                                fontWeight: isUserTeam ? FontWeight.bold : FontWeight.normal,
                                color: isUserTeam ? Colors.blue : null,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: LinearProgressIndicator(
                                value: tradeCount / (sortedTeams.first.value),
                                backgroundColor: Colors.grey.shade200,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  isUserTeam ? Colors.blue : Colors.orange,
                                ),
                                minHeight: 12,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              "$tradeCount",
                              style: TextStyle(
                                fontWeight: isUserTeam ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
          ),
          
          const SizedBox(width: 16),
          
          // Trade metrics
          Expanded(
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Trade Summary",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    
                    // Total trades
                    _buildTradeMetricRow(
                      "Total Trades",
                      "${widget.executedTrades.length}",
                      Icons.swap_horiz,
                      Colors.blue,
                    ),
                    
                    // Average value differential
                    _buildTradeMetricRow(
                      "Avg. Value Differential",
                      "${_calculateAverageTradeValue().toStringAsFixed(1)} pts",
                      Icons.analytics,
                      Colors.purple,
                    ),
                    
                    // Total picks traded
                    _buildTradeMetricRow(
                      "Picks Traded",
                      "${_calculateTotalPicksTraded()}",
                      Icons.compare_arrows,
                      Colors.green,
                    ),
                    
                    // Most common trade rounds
                    _buildTradeMetricRow(
                      "Most Common",
                      _getMostCommonTradeRound(),
                      Icons.star,
                      Colors.amber,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      
      const SizedBox(height: 16),
      
      // Recent trades list
      Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Recent Trades",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              
              // Show last 3 trades
              ...widget.executedTrades.reversed.take(3).map((trade) {
                bool isUserInvolved = trade.teamOffering == widget.userTeam || 
                                      trade.teamReceiving == widget.userTeam;
                
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Trade header
                      Row(
                        children: [
                          Text(
                            "${trade.teamOffering} → ${trade.teamReceiving}",
                            style: TextStyle(
                              fontWeight: isUserInvolved ? FontWeight.bold : FontWeight.normal,
                              color: isUserInvolved ? Colors.blue : null,
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: trade.valueDifferential >= 0 ? 
                                Colors.green.shade100 : Colors.red.shade100,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              "${trade.valueDifferential > 0 ? "+" : ""}${trade.valueDifferential.toStringAsFixed(0)} pts",
                              style: TextStyle(
                                fontSize: 11,
                                color: trade.valueDifferential >= 0 ? 
                                  Colors.green.shade800 : Colors.red.shade800,
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                      // Trade description
                      Padding(
                        padding: const EdgeInsets.only(top: 4.0, left: 8.0),
                        child: Text(
                          trade.tradeDescription,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                      
                      const Divider(),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    ],
  );
}

// 5. Build team pick counts section
Widget _buildTeamPickCountsSection(Map<String, Map<String, dynamic>> teamMetrics) {
  // Get all team picks
  Map<String, int> pickCountsByTeam = {};
  for (var pick in widget.completedPicks) {
    if (pick.selectedPlayer != null) {
      pickCountsByTeam[pick.teamName] = (pickCountsByTeam[pick.teamName] ?? 0) + 1;
    }
  }
  
  // Sort teams by pick count
  List<MapEntry<String, int>> sortedTeams = pickCountsByTeam.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        "Team Pick Counts",
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      const SizedBox(height: 12),
      
      Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              ...sortedTeams.map((entry) {
                final teamName = entry.key;
                final pickCount = entry.value;
                final isUserTeam = teamName == widget.userTeam;
                
                // Get metrics for this team if available
                Map<String, dynamic>? metrics = teamMetrics[teamName];
                String grade = metrics != null ? metrics['grade'] : 'N/A';
                Color gradeColor = _getGradeColor(grade);
                
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Row(
                    children: [
                      // Team name
                      SizedBox(
                        width: 140,
                        child: Text(
                          teamName,
                          style: TextStyle(
                            fontWeight: isUserTeam ? FontWeight.bold : FontWeight.normal,
                            color: isUserTeam ? Colors.blue : null,
                          ),
                        ),
                      ),
                      
                      // Pick count bar
                      Expanded(
                        child: Stack(
                          children: [
                            // Background
                            Container(
                              height: 16,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            // Progress
                            Container(
                              height: 16,
                              width: (pickCount / sortedTeams.first.value) * 
                                    MediaQuery.of(context).size.width * 0.5,
                              decoration: BoxDecoration(
                                color: isUserTeam ? Colors.blue : Colors.orange,
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Pick count
                      SizedBox(
                        width: 40,
                        child: Text(
                          "$pickCount",
                          textAlign: TextAlign.center,
                        ),
                      ),
                      
                      // Grade
                      if (metrics != null)
                        Container(
                          margin: const EdgeInsets.only(left: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: gradeColor.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: gradeColor),
                          ),
                          child: Text(
                            grade,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: gradeColor,
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    ],
  );
}

// 6. Helper method to build trade metric row
Widget _buildTradeMetricRow(String label, String value, IconData icon, Color color) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 12.0),
    child: Row(
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 8),
        Text(label),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ],
    ),
  );
}

// 7. Helper method to get grade color
Color _getGradeColor(String grade) {
  if (grade.startsWith("A")) {
    return Colors.green.shade700;
  } else if (grade.startsWith("B")) {
    return Colors.blue.shade700;
  } else if (grade.startsWith("C")) {
    return Colors.orange.shade700;
  } else {
    return Colors.red.shade700;
  }
}

// 8. Helper method to calculate average trade value
double _calculateAverageTradeValue() {
  if (widget.executedTrades.isEmpty) return 0;
  
  double totalValue = 0;
  for (var trade in widget.executedTrades) {
    totalValue += trade.valueDifferential.abs();
  }
  
  return totalValue / widget.executedTrades.length;
}

// 9. Helper method to calculate total picks traded
int _calculateTotalPicksTraded() {
  int count = 0;
  for (var trade in widget.executedTrades) {
    count += trade.picksOffered.length;
    count += 1 + trade.additionalTargetPicks.length; // Target pick + additional picks
  }
  return count;
}

// 10. Helper method to get most common trade round
String _getMostCommonTradeRound() {
  Map<String, int> roundCounts = {};
  
  for (var trade in widget.executedTrades) {
    String round = _getRoundFromPickNumber(trade.targetPick.pickNumber);
    roundCounts[round] = (roundCounts[round] ?? 0) + 1;
  }
  
  if (roundCounts.isEmpty) return "N/A";
  
  // Sort by count
  List<MapEntry<String, int>> sortedRounds = roundCounts.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
    
  return "Round ${sortedRounds.first.key}";
}

// 11. Helper method to get round from pick number
String _getRoundFromPickNumber(int pickNumber) {
  return ((pickNumber - 1) ~/ 32 + 1).toString();
}

Widget _buildDraftTrendsTab() {
  // For now, just a placeholder that we'll expand in Phase 4
  return SingleChildScrollView(
    padding: const EdgeInsets.all(16.0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Draft Trends",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        
        const SizedBox(height: 16),
        
        // Temporarily reuse position breakdown
        const Text(
          'Position Breakdown',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 40,
          child: _buildPositionBreakdownBar(),
        ),
        
        const SizedBox(height: 24),
        
        // Temporarily include some other analytics
        _buildPositionByRoundSection(),
      ],
    ),
  );
}

  Widget _buildDraftStrategyInsights() {
  // Calculate offense vs defense balance for each team
  Map<String, Map<String, int>> teamPositionTypes = {};
  
  // Position type classification
  final Map<String, String> positionTypes = {
    'QB': 'Offense',
    'RB': 'Offense',
    'WR': 'Offense',
    'TE': 'Offense',
    'OT': 'Offense',
    'IOL': 'Offense',
    'OL': 'Offense',
    'G': 'Offense',
    'C': 'Offense',
    'FB': 'Offense',
    'EDGE': 'Defense',
    'DL': 'Defense',
    'IDL': 'Defense',
    'DT': 'Defense',
    'DE': 'Defense',
    'LB': 'Defense',
    'ILB': 'Defense',
    'OLB': 'Defense',
    'CB': 'Defense',
    'S': 'Defense',
    'FS': 'Defense',
    'SS': 'Defense',
    'K': 'Special Teams',
    'P': 'Special Teams',
    'LS': 'Special Teams',
  };
  
  // Analyze team draft strategies
  for (var pick in widget.completedPicks) {
    if (pick.selectedPlayer != null) {
      final team = pick.teamName;
      final position = pick.selectedPlayer!.position;
      final type = positionTypes[position] ?? 'Other';
      
      // Initialize team data if needed
      teamPositionTypes.putIfAbsent(team, () => {'Offense': 0, 'Defense': 0, 'Special Teams': 0, 'Other': 0});
      
      // Increment count for this type
      teamPositionTypes[team]![type] = (teamPositionTypes[team]![type] ?? 0) + 1;
    }
  }
  
  // Convert to a list and sort by offense-defense ratio for interesting insights
  List<MapEntry<String, Map<String, int>>> teamPositionsList = teamPositionTypes.entries.toList();
  teamPositionsList.sort((a, b) {
    final aOffenseRatio = a.value['Offense']! / (a.value['Offense']! + a.value['Defense']! + 0.01);
    final bOffenseRatio = b.value['Offense']! / (b.value['Offense']! + b.value['Defense']! + 0.01);
    return bOffenseRatio.compareTo(aOffenseRatio); // Sort high to low offense ratio
  });
  
  // Display strategy insights
  return Column(
    children: [
      const Text('Teams sorted by offensive focus in draft:',
        style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic)),
      const SizedBox(height: 8),
      
      // Team strategies
      ...teamPositionsList.map((entry) {
        final team = entry.key;
        final data = entry.value;
        final offenseCount = data['Offense'] ?? 0;
        final defenseCount = data['Defense'] ?? 0;
        final totalCount = offenseCount + defenseCount + (data['Special Teams'] ?? 0) + (data['Other'] ?? 0);
        
        // Skip teams with no picks
        if (totalCount == 0) return const SizedBox.shrink();
        
        final offensePct = (offenseCount / totalCount * 100).toInt();
        final defensePct = (defenseCount / totalCount * 100).toInt();
        
        // Determine team strategy
        String strategy;
        Color strategyColor;
        
        if (offensePct > 75) {
          strategy = "Offense-heavy";
          strategyColor = Colors.red;
        } else if (offensePct > 60) {
          strategy = "Offense-focused";
          strategyColor = Colors.orange;
        } else if (defensePct > 75) {
          strategy = "Defense-heavy";
          strategyColor = Colors.blue;
        } else if (defensePct > 60) {
          strategy = "Defense-focused";
          strategyColor = Colors.lightBlue;
        } else {
          strategy = "Balanced";
          strategyColor = Colors.green;
        }
        
        // Highlight user team
        final isUserTeam = team == widget.userTeam;
        
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: Row(
            children: [
              // Team name
              SizedBox(
                width: 60,
                child: Text(
                  team,
                  style: TextStyle(
                    fontWeight: isUserTeam ? FontWeight.bold : FontWeight.normal,
                    color: isUserTeam ? Colors.blue : null,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              
              // Offense-Defense ratio bar
              Expanded(
                child: Stack(
                  children: [
                    Container(
                      height: 20,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        color: Colors.grey.shade200,
                      ),
                    ),
                    Row(
                      children: [
                        // Offense part
                        Container(
                          height: 20,
                          width: (offenseCount / totalCount) * 100,
                          decoration: const BoxDecoration(
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(4),
                              bottomLeft: Radius.circular(4),
                            ),
                            color: Colors.red,
                          ),
                          alignment: Alignment.center,
                          child: offenseCount > 0 ? const Text(
                            'O',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ) : null,
                        ),
                        // Defense part
                        Container(
                          height: 20,
                          width: (defenseCount / totalCount) * 100,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.only(
                              topRight: offenseCount + defenseCount == totalCount ? const Radius.circular(4) : Radius.zero,
                              bottomRight: offenseCount + defenseCount == totalCount ? const Radius.circular(4) : Radius.zero,
                            ),
                            color: Colors.blue,
                          ),
                          alignment: Alignment.center,
                          child: defenseCount > 0 ? const Text(
                            'D',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ) : null,
                        ),
                        // Special Teams part (if any)
                        if ((data['Special Teams'] ?? 0) > 0)
                          Container(
                            height: 20,
                            width: ((data['Special Teams'] ?? 0) / totalCount) * 100,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.only(
                                topRight: offenseCount + defenseCount + (data['Special Teams'] ?? 0) == totalCount ? const Radius.circular(4) : Radius.zero,
                                bottomRight: offenseCount + defenseCount + (data['Special Teams'] ?? 0) == totalCount ? const Radius.circular(4) : Radius.zero,
                              ),
                              color: Colors.green,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Strategy label
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: strategyColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: strategyColor),
                ),
                child: Text(
                  strategy,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: strategyColor,
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    ],
  );
}

Widget _buildDraftSuccessTab() {
  // Calculate predictive metrics for each team's picks
  Map<String, List<Map<String, dynamic>>> teamDraftGrades = {};
  
  // Process completed picks
  for (var pick in widget.completedPicks) {
    if (pick.selectedPlayer != null) {
      final team = pick.teamName;
      final player = pick.selectedPlayer!;
      
      // Calculate metrics
      final pickQuality = _calculatePickQuality(player.rank, pick.pickNumber);
      final positionValue = _getPositionValueCoefficient(player.position);
      final roundFactor = _getRoundSuccessFactor(pick.round);
      
      // Calculate overall success score (0-100)
      final successScore = (pickQuality * 0.5 + positionValue * 0.3 + roundFactor * 0.2) * 100;
      
      // Initialize team data if needed
      teamDraftGrades.putIfAbsent(team, () => []);
      
      // Add pick data
      teamDraftGrades[team]!.add({
        'player': player.name,
        'position': player.position,
        'pickNumber': pick.pickNumber,
        'rank': player.rank,
        'successScore': successScore,
      });
    }
  }
  
  // Calculate team average success scores
  Map<String, double> teamAverageScores = {};
  for (var entry in teamDraftGrades.entries) {
    final team = entry.key;
    final picks = entry.value;
    
    if (picks.isNotEmpty) {
      double totalScore = 0;
      for (var pick in picks) {
        totalScore += pick['successScore'];
      }
      teamAverageScores[team] = totalScore / picks.length;
    }
  }
  
  // Sort teams by average success score
  List<MapEntry<String, double>> sortedTeams = teamAverageScores.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  
  return SingleChildScrollView(
    padding: const EdgeInsets.all(16.0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Draft Success Prediction',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Based on historical data patterns of successful NFL picks',
          style: TextStyle(
            fontStyle: FontStyle.italic,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 16),
        
        // Team success ratings
        Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Team Draft Success Ratings',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                
                // Team ratings
                ...sortedTeams.map((entry) {
                  final team = entry.key;
                  final score = entry.value;
                  final isUserTeam = team == widget.userTeam;
                  
                  // Get letter grade
                  String grade;
                  Color gradeColor;
                  
                  if (score >= 90) {
                    grade = 'A+';
                    gradeColor = Colors.green.shade800;
                  } else if (score >= 85) {
                    grade = 'A';
                    gradeColor = Colors.green.shade700;
                  } else if (score >= 80) {
                    grade = 'A-';
                    gradeColor = Colors.green.shade600;
                  } else if (score >= 75) {
                    grade = 'B+';
                    gradeColor = Colors.green.shade500;
                  } else if (score >= 70) {
                    grade = 'B';
                    gradeColor = Colors.green.shade400;
                  } else if (score >= 65) {
                    grade = 'B-';
                    gradeColor = Colors.blue.shade600;
                  } else if (score >= 60) {
                    grade = 'C+';
                    gradeColor = Colors.blue.shade500;
                  } else if (score >= 55) {
                    grade = 'C';
                    gradeColor = Colors.orange.shade700;
                  } else if (score >= 50) {
                    grade = 'C-';
                    gradeColor = Colors.orange.shade600;
                  } else if (score >= 45) {
                    grade = 'D+';
                    gradeColor = Colors.orange.shade500;
                  } else if (score >= 40) {
                    grade = 'D';
                    gradeColor = Colors.red.shade600;
                  } else {
                    grade = 'F';
                    gradeColor = Colors.red.shade700;
                  }
                  
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Row(
                      children: [
                        // Team name
                        SizedBox(
                          width: 60,
                          child: Text(
                            team,
                            style: TextStyle(
                              fontWeight: isUserTeam ? FontWeight.bold : FontWeight.normal,
                              color: isUserTeam ? Colors.blue : null,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        
                        // Success score bar
                        Expanded(
                          child: Stack(
                            children: [
                              Container(
                                height: 20,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(4),
                                  color: Colors.grey.shade200,
                                ),
                              ),
                              Container(
                                height: 20,
                                width: (score / 100) * 300, // Scale to fit
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(4),
                                  gradient: LinearGradient(
                                    colors: [
                                      gradeColor.withOpacity(0.7),
                                      gradeColor,
                                    ],
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        // Grade and score
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: gradeColor.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: gradeColor),
                          ),
                          child: Row(
                            children: [
                              Text(
                                grade,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: gradeColor,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                score.toStringAsFixed(1),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: gradeColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Best value picks
        _buildBestValuePicksSection(),
      ],
    ),
  );
}

Widget _buildBestValuePicksSection() {
  // Gather all picks with their value differential
  List<Map<String, dynamic>> valuePicks = [];
  
  for (var pick in widget.completedPicks) {
    if (pick.selectedPlayer != null) {
      final valueGap = pick.pickNumber - pick.selectedPlayer!.rank;
      
      if (valueGap > 0) {
        valuePicks.add({
          'team': pick.teamName,
          'player': pick.selectedPlayer!.name,
          'position': pick.selectedPlayer!.position,
          'pickNumber': pick.pickNumber,
          'rank': pick.selectedPlayer!.rank,
          'valueGap': valueGap,
        });
      }
    }
  }
  
  // Sort by value gap (highest first)
  valuePicks.sort((a, b) => b['valueGap'].compareTo(a['valueGap']));
  
  return Card(
    elevation: 2,
    child: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Best Value Picks',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          // Top 5 value picks
          ...valuePicks.take(5).map((pick) {
            final isUserTeam = pick['team'] == widget.userTeam;
            
            return ListTile(
              dense: true,
              title: RichText(
                text: TextSpan(
                  style: DefaultTextStyle.of(context).style,
                  children: [
                    TextSpan(
                      text: '${pick['player']} ',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isUserTeam ? Colors.blue : null,
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
              subtitle: Text('${pick['team']} - Pick #${pick['pickNumber']} (Rank #${pick['rank']})'),
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.green.shade700),
                ),
                child: Text(
                  '+${pick['valueGap']}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade700,
                  ),
                ),
              ),
            );
          }),
          
          if (valuePicks.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'No value picks found yet',
                  style: TextStyle(fontStyle: FontStyle.italic),
                ),
              ),
            ),
        ],
      ),
    ),
  );
}

// Helper functions for draft success predictions
double _calculatePickQuality(int rank, int pickNumber) {
  final valueDifference = pickNumber - rank;
  
  // Scale to 0.0-1.0 range
  if (valueDifference >= 30) return 1.0; // Great value
  if (valueDifference <= -30) return 0.0; // Terrible value
  
  // Linear scale between -30 and 30
  return (valueDifference + 30) / 60.0;
}

double _getPositionValueCoefficient(String position) {
  // Premium positions tend to have higher success rates
  if (['QB', 'OT', 'EDGE', 'CB'].contains(position)) {
    return 0.9; // Premium positions
  } else if (['WR', 'DE', 'S', 'TE', 'IDL'].contains(position)) {
    return 0.7; // Above average value
  } else if (['RB', 'IOL', 'G', 'C', 'LB'].contains(position)) {
    return 0.5; // Average value
  } else {
    return 0.3; // Below average value
  }
}

double _getRoundSuccessFactor(String round) {
  // Earlier rounds have historically better success rates
  int roundNum = int.tryParse(round) ?? 7;
  
  switch (roundNum) {
    case 1: return 0.9;
    case 2: return 0.75;
    case 3: return 0.6;
    case 4: return 0.45;
    case 5: return 0.3;
    case 6: return 0.2;
    case 7: return 0.1;
    default: return 0.1;
  }
}

  Widget _buildTeamDropdown() {
  // Get all teams with picks
  final List<String> availableTeams = _teamPicks.keys.toList();
  
  // Make sure we have a valid initial selection
  String currentSelection = widget.userTeam ?? '';
  
  // If user team isn't in the list or not specified, use the first team
  if (currentSelection.isEmpty || !availableTeams.contains(currentSelection)) {
    currentSelection = availableTeams.isNotEmpty ? availableTeams.first : '';
  }
  
  // If there are no teams with picks, show a placeholder
  if (availableTeams.isEmpty) {
    return const Text('No team data available');
  }
  
  return DropdownButton<String>(
    value: currentSelection,
    onChanged: (String? newValue) {
      // In a stateful implementation, you would update state here
      // For now, we'll just print the selected value
      if (newValue != null) {
        debugPrint('Selected team: $newValue');
      }
    },
    items: availableTeams.map<DropdownMenuItem<String>>((String team) {
      return DropdownMenuItem<String>(
        value: team,
        child: Text(team),
      );
    }).toList(),
  );
}

  Widget _buildTeamsTab() {
    // Sort teams by pick value
    List<MapEntry<String, double>> sortedTeamValues = _valueByTeam.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    // Sort teams by rank differential (value gained in draft)
    List<MapEntry<String, int>> sortedRankDiffs = _rankDifferentials.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Team draft value chart
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Team Draft Capital',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 300,
                    child: ListView.builder(
                      itemCount: sortedTeamValues.length,
                      itemBuilder: (context, index) {
                        final entry = sortedTeamValues[index];
                        final team = entry.key;
                        final value = entry.value;
                        final maxValue = sortedTeamValues.first.value;
                        final progress = value / maxValue;
                        
                        // Highlight user team
                        final isUserTeam = team == widget.userTeam;
                        
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 60,
                                child: Text(
                                  team,
                                  style: TextStyle(
                                    fontWeight: isUserTeam ? FontWeight.bold : FontWeight.normal,
                                    color: isUserTeam ? Colors.blue : null,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: LinearProgressIndicator(
                                  value: progress,
                                  backgroundColor: Colors.grey.withOpacity(0.2),
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    isUserTeam ? Colors.blue : Colors.green,
                                  ),
                                  minHeight: 16,
                                ),
                              ),
                              const SizedBox(width: 8),
                              SizedBox(
                                width: 60,
                                child: Text(
                                  value.toStringAsFixed(0),
                                  textAlign: TextAlign.end,
                                  style: TextStyle(
                                    fontWeight: isUserTeam ? FontWeight.bold : FontWeight.normal,
                                    color: isUserTeam ? Colors.blue : null,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Team value gained chart
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Value Gained From Picks',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 300,
                    child: ListView.builder(
                      itemCount: sortedRankDiffs.length,
                      itemBuilder: (context, index) {
                        final entry = sortedRankDiffs[index];
                        final team = entry.key;
                        final diff = entry.value;
                        
                        // Highlight user team
                        final isUserTeam = team == widget.userTeam;
                        
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 60,
                                child: Text(
                                  team,
                                  style: TextStyle(
                                    fontWeight: isUserTeam ? FontWeight.bold : FontWeight.normal,
                                    color: isUserTeam ? Colors.blue : null,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Container(
                                  height: 16,
                                  alignment: diff < 0 ? Alignment.centerRight : Alignment.centerLeft,
                                  child: Container(
                                    width: (diff.abs() / 50.0 * 200).clamp(20, 200),
                                    decoration: BoxDecoration(
                                      color: diff >= 0 ? Colors.green : Colors.red,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              SizedBox(
                                width: 60,
                                child: Text(
                                  diff > 0 ? '+$diff' : '$diff',
                                  textAlign: TextAlign.end,
                                  style: TextStyle(
                                    fontWeight: isUserTeam ? FontWeight.bold : FontWeight.normal,
                                    color: diff >= 0 ? Colors.green : Colors.red,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Team pick details
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Team Selections Detail',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Team selector
                  _buildTeamDropdown(),

                  
                  const SizedBox(height: 16),
                  
                  // Selected team's picks
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _teamPicks[widget.userTeam ?? sortedTeamValues.first.key]?.length ?? 0,
                    itemBuilder: (context, index) {
                      final pick = _teamPicks[widget.userTeam ?? sortedTeamValues.first.key]![index];
                      
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.blue,
                          child: Text('${pick.pickNumber}'),
                        ),
                        title: Text(
                          pick.selectedPlayer?.name ?? 'Not selected',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          pick.selectedPlayer?.position ?? 'N/A',
                        ),
                        trailing: pick.selectedPlayer != null
                            ? Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: pick.pickNumber <= pick.selectedPlayer!.rank
                                      ? Colors.red.withOpacity(0.2)
                                      : Colors.green.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  pick.pickNumber <= pick.selectedPlayer!.rank
                                      ? '-${pick.selectedPlayer!.rank - pick.pickNumber}'
                                      : '+${pick.pickNumber - pick.selectedPlayer!.rank}',
                                  style: TextStyle(
                                    color: pick.pickNumber <= pick.selectedPlayer!.rank
                                        ? Colors.red
                                        : Colors.green,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              )
                            : null,
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildTradesTab() {
    if (widget.executedTrades.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'No trades have been executed yet',
            style: TextStyle(
              fontSize: 16,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      );
    }
    
    // Group trades by team
    Map<String, List<TradePackage>> tradesByTeam = {};
    for (var trade in widget.executedTrades) {
      // Team offering
      tradesByTeam.putIfAbsent(trade.teamOffering, () => []);
      tradesByTeam[trade.teamOffering]!.add(trade);
      
      // Team receiving
      tradesByTeam.putIfAbsent(trade.teamReceiving, () => []);
      tradesByTeam[trade.teamReceiving]!.add(trade);
    }
    
    // Calculate trade value by team
    Map<String, double> valueGainedByTeam = {};
    for (var trade in widget.executedTrades) {
      // Team offering loses value
      valueGainedByTeam[trade.teamOffering] = 
        (valueGainedByTeam[trade.teamOffering] ?? 0) - trade.valueDifferential;
      
      // Team receiving gains value
      valueGainedByTeam[trade.teamReceiving] = 
        (valueGainedByTeam[trade.teamReceiving] ?? 0) + trade.valueDifferential;
    }
    
    // Sort teams by trade activity
    List<MapEntry<String, List<TradePackage>>> sortedTradeActivity = 
      tradesByTeam.entries.toList()
        ..sort((a, b) => b.value.length.compareTo(a.value.length));
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Trade summary
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Trade Summary',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _buildStatCard(
                        title: 'Total Trades',
                        value: '${widget.executedTrades.length}',
                        icon: Icons.swap_horiz,
                        color: Colors.orange,
                        width: 130,
                      ),
                      const SizedBox(width: 16),
                      _buildStatCard(
                        title: 'Picks Moved',
                        value: '${_calculatePicksTraded()}',
                        icon: Icons.sync_alt,
                        color: Colors.blue,
                        width: 130,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Trade activity by team
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Trade Activity By Team',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 250,
                    child: ListView.builder(
                      itemCount: sortedTradeActivity.length,
                      itemBuilder: (context, index) {
                        final entry = sortedTradeActivity[index];
                        final team = entry.key;
                        final trades = entry.value.length;
                        final valueGained = valueGainedByTeam[team] ?? 0;
                        
                        // Highlight user team
                        final isUserTeam = team == widget.userTeam;
                        
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 60,
                                child: Text(
                                  team,
                                  style: TextStyle(
                                    fontWeight: isUserTeam ? FontWeight.bold : FontWeight.normal,
                                    color: isUserTeam ? Colors.blue : null,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                flex: 3,
                                child: Row(
                                  children: List.generate(
                                    trades,
                                    (i) => Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 2.0),
                                      child: Container(
                                        width: 16,
                                        height: 16,
                                        decoration: BoxDecoration(
                                          color: isUserTeam ? Colors.blue : Colors.orange,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                flex: 2,
                                child: Container(
                                  height: 16,
                                  alignment: valueGained < 0 ? Alignment.centerRight : Alignment.centerLeft,
                                  child: Container(
                                    width: (valueGained.abs() / 100.0 * 100).clamp(10, 100),
                                    decoration: BoxDecoration(
                                      color: valueGained >= 0 ? Colors.green : Colors.red,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              SizedBox(
                                width: 60,
                                child: Text(
                                  valueGained > 0 ? '+${valueGained.toStringAsFixed(0)}' : valueGained.toStringAsFixed(0),
                                  textAlign: TextAlign.end,
                                  style: TextStyle(
                                    fontWeight: isUserTeam ? FontWeight.bold : FontWeight.normal,
                                    color: valueGained >= 0 ? Colors.green : Colors.red,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Trade details list
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Trade Details',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: widget.executedTrades.length,
                    separatorBuilder: (context, index) => const Divider(),
                    itemBuilder: (context, index) {
                      final trade = widget.executedTrades[index];
                      final isUserInvolved = trade.teamOffering == widget.userTeam || 
                                           trade.teamReceiving == widget.userTeam;
                      
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Trade header
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'Trade #${index + 1}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: isUserInvolved ? Colors.blue : null,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: trade.isFairTrade 
                                      ? Colors.green.withOpacity(0.2)
                                      : Colors.orange.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    trade.isFairTrade ? 'Fair Trade' : 'Uneven Trade',
                                    style: TextStyle(
                                      color: trade.isFairTrade ? Colors.green : Colors.orange,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            
                            // Trade description
                            Text(trade.tradeDescription),
                            const SizedBox(height: 8),
                            
                            // Trade value
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'Value: ${trade.totalValueOffered.toStringAsFixed(0)} for ${trade.targetPickValue.toStringAsFixed(0)}',
                                    style: const TextStyle(
                                      fontStyle: FontStyle.italic,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                Text(
                                  trade.valueDifferential >= 0 
                                    ? '+${trade.valueDifferential.toStringAsFixed(0)}' 
                                    : trade.valueDifferential.toStringAsFixed(0),
                                  style: TextStyle(
                                    color: trade.valueDifferential >= 0 ? Colors.green : Colors.red,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildStatCard({
    required String title, 
    required String value, 
    required IconData icon,
    required Color color,
    String? subtitle,
    double width = 150,
  }) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: color,
            size: 20,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: color.withOpacity(0.8),
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                fontStyle: FontStyle.italic,
                color: color.withOpacity(0.7),
              ),
            ),
          ],
        ],
      ),
    );
  }
  
  Widget _buildPositionBreakdownBar() {
    // Get position groups
    Map<String, int> positionGroups = {
      'QB': 0,
      'OL': 0,
      'WR/TE': 0,
      'RB': 0,
      'DL': 0,
      'LB': 0,
      'DB': 0,
      'ST': 0,
    };
    
    // Map positions to groups
    for (var entry in _positionCounts.entries) {
      String pos = entry.key;
      int count = entry.value;
      
      if (pos == 'QB') {
        positionGroups['QB'] = (positionGroups['QB'] ?? 0) + count;
      } else if (['OT', 'IOL', 'G', 'C'].contains(pos)) {
        positionGroups['OL'] = (positionGroups['OL'] ?? 0) + count;
      } else if (['WR', 'TE'].contains(pos)) {
        positionGroups['WR/TE'] = (positionGroups['WR/TE'] ?? 0) + count;
      } else if (pos == 'RB') {
        positionGroups['RB'] = (positionGroups['RB'] ?? 0) + count;
      } else if (['EDGE', 'IDL', 'DT', 'DE'].contains(pos)) {
        positionGroups['DL'] = (positionGroups['DL'] ?? 0) + count;
      } else if (['LB', 'ILB', 'OLB'].contains(pos)) {
        positionGroups['LB'] = (positionGroups['LB'] ?? 0) + count;
      } else if (['CB', 'S', 'FS', 'SS'].contains(pos)) {
        positionGroups['DB'] = (positionGroups['DB'] ?? 0) + count;
      } else {
        positionGroups['ST'] = (positionGroups['ST'] ?? 0) + count;
      }
    }
    
    // Calculate total for percentages
    int total = positionGroups.values.fold(0, (sum, count) => sum + count);
    if (total == 0) return Container(); // No data yet
    
    // Build segments
    List<Widget> segments = [];
    double currentLeft = 0.0;
    
    // Colors for position groups
    Map<String, Color> groupColors = {
      'QB': Colors.red,
      'OL': Colors.orange,
      'WR/TE': Colors.yellow.shade800,
      'RB': Colors.green,
      'DL': Colors.blue,
      'LB': Colors.indigo,
      'DB': Colors.purple,
      'ST': Colors.grey,
    };
    
    for (var entry in positionGroups.entries) {
      String group = entry.key;
      int count = entry.value;
      if (count == 0) continue;
      
      double percentage = count / total;
      Color color = groupColors[group] ?? Colors.grey;
      
      segments.add(
        Positioned(
          left: currentLeft,
          top: 0,
          bottom: 0,
          width: percentage * 300, // Adjust width based on container size
          child: Container(
            color: color,
            alignment: Alignment.center,
            child: Text(
              percentage > 0.08 ? '$group: $count' : '',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ),
      );
      
      currentLeft += percentage * 300;
    }
    
    return SizedBox(
      width: 300, // Match the width used for segments
      child: Stack(children: segments),
    );
  }
  
  Widget _buildRecentPicksList() {
    // Get last 5 picks
    List<DraftPick> recentPicks = widget.completedPicks
        .where((pick) => pick.selectedPlayer != null)
        .toList()
        .reversed
        .take(5)
        .toList();
    
    if (recentPicks.isEmpty) {
      return const Text('No picks made yet');
    }
    
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: recentPicks.length,
      itemBuilder: (context, index) {
        final pick = recentPicks[index];
        final player = pick.selectedPlayer!;
        
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: _getPickNumberColor(pick.round),
            child: Text(
              '${pick.pickNumber}',
              style: const TextStyle(color: Colors.white),
            ),
          ),
          title: Text(
            player.name,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text('${pick.teamName} - ${player.position}'),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: player.rank <= pick.pickNumber 
                  ? Colors.green.withOpacity(0.2)
                  : Colors.red.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              player.rank <= pick.pickNumber 
                  ? '+${pick.pickNumber - player.rank}'
                  : '-${player.rank - pick.pickNumber}',
              style: TextStyle(
                color: player.rank <= pick.pickNumber 
                    ? Colors.green
                    : Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildTradeActivityChart() {
    if (widget.executedTrades.isEmpty) {
      return const Text('No trades have been executed yet');
    }
    
    // Group trades by round
    Map<String, int> tradesByRound = {};
    for (var trade in widget.executedTrades) {
      String round = '${DraftValueService.getRoundForPick(trade.targetPick.pickNumber)}';
      tradesByRound[round] = (tradesByRound[round] ?? 0) + 1;
    }
    
    return Row(
      children: [
        for (int i = 1; i <= 7; i++)
          Expanded(
            child: Column(
              children: [
                Container(
                  height: 100,
                  width: 20,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    width: 20,
                    height: ((tradesByRound[i.toString()] ?? 0) / 
                             (tradesByRound.values.fold(0, max) + 1)) * 100,
                    color: _getPickNumberColor(i.toString()),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Rd $i',
                  style: const TextStyle(fontSize: 12),
                ),
                Text(
                  '${tradesByRound[i.toString()] ?? 0}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
      ],
    );
  }
  
  Widget _buildUserTeamSummary() {
    if (widget.userTeam == null) {
      return Container();
    }
    
    // Filter user team picks
    List<DraftPick> userPicks = widget.completedPicks
        .where((pick) => pick.teamName == widget.userTeam && pick.selectedPlayer != null)
        .toList();
    
    if (userPicks.isEmpty) {
      return const Text('Your team has not made any picks yet');
    }
    
    // Count positions drafted
    Map<String, int> userPositionCounts = {};
    for (var pick in userPicks) {
      String position = pick.selectedPlayer!.position;
      userPositionCounts[position] = (userPositionCounts[position] ?? 0) + 1;
    }
    
    // Calculate average rank differential
    double avgRankDiff = 0;
    for (var pick in userPicks) {
      avgRankDiff += (pick.pickNumber - pick.selectedPlayer!.rank);
    }
    avgRankDiff = avgRankDiff / userPicks.length;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Draft grade
        Row(
          children: [
            Text(
              'Draft Grade: ${_calculateDraftGrade(avgRankDiff)}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Average Value: ${avgRankDiff.toStringAsFixed(1)}',
              style: TextStyle(
                color: avgRankDiff >= 0 ? Colors.green : Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        
        // Position breakdown
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (var entry in userPositionCounts.entries)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: _getPositionColor(entry.key).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _getPositionColor(entry.key),
                  ),
                ),
                child: Text(
                  '${entry.key}: ${entry.value}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _getPositionColor(entry.key),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
  
  int _calculatePicksTraded() {
    int count = 0;
    for (var trade in widget.executedTrades) {
      count += trade.picksOffered.length;
      count += 1; // Target pick
      count += trade.additionalTargetPicks.length;
    }
    return count;
  }
  
  String _calculateDraftGrade(double avgRankDiff) {
    if (avgRankDiff >= 15) return 'A+';
    if (avgRankDiff >= 10) return 'A';
    if (avgRankDiff >= 5) return 'B+';
    if (avgRankDiff >= 0) return 'B';
    if (avgRankDiff >= -5) return 'C+';
    if (avgRankDiff >= -10) return 'C';
    if (avgRankDiff >= -15) return 'D';
    return 'F';
  }
  
  Color _getPositionColor(String position) {
    // Different colors for different position groups
    if (['QB', 'RB', 'WR', 'TE'].contains(position)) {
      return Colors.blue.shade700; // Offensive skill positions
    } else if (['OT', 'IOL'].contains(position)) {
      return Colors.green.shade700; // Offensive line
    } else if (['EDGE', 'IDL', 'DT', 'DE'].contains(position)) {
      return Colors.red.shade700; // Defensive line
    } else if (['LB', 'ILB', 'OLB'].contains(position)) {
      return Colors.orange.shade700; // Linebackers
    } else if (['CB', 'S', 'FS', 'SS'].contains(position)) {
      return Colors.purple.shade700; // Secondary
    } else {
      return Colors.grey.shade700; // Special teams, etc.
    }
  }
  
      Color _getPickNumberColor(String round) {
    // Different colors for each round
    switch (round) {
      case '1':
        return Colors.blue.shade700;
      case '2':
        return Colors.green.shade700;
      case '3':
        return Colors.orange.shade700;
      case '4':
        return Colors.purple.shade700;
      case '5':
        return Colors.red.shade700;
      case '6':
        return Colors.teal.shade700;
      case '7':
        return Colors.brown.shade700;
      default:
        return Colors.grey.shade700;
    }
  }
}