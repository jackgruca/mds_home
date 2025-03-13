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
  final List<TeamNeed> teamNeeds; // Add this property
  final String? userTeam;

  const DraftAnalyticsDashboard({
    super.key,
    required this.completedPicks,
    required this.draftedPlayers,
    required this.executedTrades,
    required this.teamNeeds, // Add this required parameter
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
        Row(
          children: [
            Expanded(
              child: TabBar(
                controller: _tabController,
                indicatorColor: Colors.blue,
                tabs: const [
                  Tab(text: 'Your Draft', icon: Icon(Icons.person)),
                  Tab(text: 'League Overview', icon: Icon(Icons.groups)),
                  Tab(text: 'Draft Trends', icon: Icon(Icons.analytics)),
                ],
              ),
            ),
            // Add refresh button
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Refresh Analytics',
              onPressed: () {
                setState(() {
                  _calculateAnalytics();
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Analytics refreshed")),
                );
              },
            ),
            // Add share button
            IconButton(
              icon: const Icon(Icons.share),
              tooltip: 'Share Analytics',
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Analytics sharing functionality would go here")),
                );
              },
            ),
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
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.person_off, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
            "No team selected",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          const Text(
            "Select a team to see your draft analysis",
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          
          // Add a navigation link to the League Overview tab
          _buildNavigationLinks(links: ['League Overview:1']),
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
  
  return RefreshIndicator(
    onRefresh: () async {
      // Simulated refresh
      setState(() {
        // Refresh analytics
      });
      return Future.delayed(const Duration(milliseconds: 500));
    },
    child: SingleChildScrollView(
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
          _buildSectionHeader("Draft Picks by Round", icon: Icons.format_list_numbered),
          _buildContentCard(
            child: _buildDraftPicksByRound(userPicks),
            isHighlighted: true,
          ),
          
          // Navigation links to related tabs
          Align(
            alignment: Alignment.centerRight,
            child: _buildNavigationLinks(links: ['League Overview:1', 'Draft Trends:2']),
          ),
          
          const SizedBox(height: 24),
          
          // Trade summary
          if (userTrades.isNotEmpty) ...[
            _buildSectionHeader("Trade Summary", icon: Icons.swap_horiz),
            _buildContentCard(
              child: _buildUserTradesSummary(userTrades),
            ),
            const SizedBox(height: 24),
          ],
          
          // Position breakdown for user picks
          _buildSectionHeader("Position Breakdown", icon: Icons.pie_chart),
          _buildContentCard(
            child: _buildUserPositionBreakdown(userPicks),
          ),
        ],
      ),
    ),
  );
}
void _shareAnalytics() {
  // In a real app, you'd implement proper sharing functionality
  // For now, just show a snackbar
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text("Analytics sharing functionality would go here")),
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

// Add this method to add consistent section headers throughout the dashboard
Widget _buildSectionHeader(String title, {IconData? icon}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 12.0),
    child: Row(
      children: [
        if (icon != null) ...[
          Icon(icon, size: 20, color: Colors.blue.shade700),
          const SizedBox(width: 8),
        ],
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.blue.shade700,
          ),
        ),
      ],
    ),
  );
}

// Add this method for consistent card styling throughout
Widget _buildContentCard({
  required Widget child, 
  bool isHighlighted = false, 
  double elevation = 2.0,
}) {
  return Card(
    elevation: elevation,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
      side: isHighlighted ? BorderSide(color: Colors.blue.shade700, width: 1) : BorderSide.none,
    ),
    margin: const EdgeInsets.only(bottom: 16),
    child: Padding(
      padding: const EdgeInsets.all(16.0),
      child: child,
    ),
  );
}
// Add this method for cross-tab navigation links
Widget _buildNavigationLinks({required List<String> links}) {
  return Wrap(
    spacing: 16,
    runSpacing: 8,
    children: links.map((link) {
      return InkWell(
        onTap: () {
          // Extract tab index from link format "Tab Name:index"
          final parts = link.split(':');
          if (parts.length == 2) {
            final tabIndex = int.tryParse(parts[1]);
            if (tabIndex != null) {
              _tabController.animateTo(tabIndex);
            }
          }
        },
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.arrow_forward, size: 14, color: Colors.blue),
            const SizedBox(width: 4),
            Text(
              link.split(':')[0],
              style: const TextStyle(
                color: Colors.blue,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
    }).toList(),
  );
}
// Add this method to optimize how we build lists with many items
Widget _buildOptimizedList<T>({
  required List<T> items,
  required Widget Function(T item, int index) itemBuilder,
  Widget? emptyStateWidget,
  int initialItemCount = 20, // Show only this many initially
}) {
  if (items.isEmpty) {
    return emptyStateWidget ?? const Center(child: Text("No data available"));
  }
  
  // For performance, initially show a smaller number of items with an option to show more
  final displayCount = min(initialItemCount, items.length);
  final hasMore = items.length > displayCount;
  
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      ...List.generate(displayCount, (index) => itemBuilder(items[index], index)),
      
      if (hasMore)
        TextButton.icon(
          onPressed: () {
            // In a StatefulWidget, you'd update the state to show more items
            // For simplicity, we'll just show a message
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("${items.length - displayCount} more items available")),
            );
          },
          icon: const Icon(Icons.expand_more),
          label: Text("Show ${items.length - displayCount} more"),
        ),
    ],
  );
}
// Add this method to create a refresh button
Widget _buildRefreshButton() {
  return IconButton(
    icon: const Icon(Icons.refresh),
    tooltip: 'Refresh Analytics',
    onPressed: () {
      // Recalculate analytics
      setState(() {
        _calculateAnalytics();
      });
      
      // Show confirmation
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Analytics refreshed")),
      );
    },
  );
}
// Add this method for consistent tooltips
Widget _buildInfoTooltip(String message) {
  return Tooltip(
    message: message,
    child: const Icon(
      Icons.info_outline,
      size: 16,
      color: Colors.grey,
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
  // Calculate position trends and analytics
  final positionAnalytics = _calculatePositionAnalytics();
  
  return SingleChildScrollView(
    padding: const EdgeInsets.all(16.0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Overall position distribution
        _buildPositionDistributionSection(positionAnalytics),
        
        const SizedBox(height: 24),
        
        // Position breakdown by round
        _buildPositionByRoundSection(positionAnalytics),
        
        const SizedBox(height: 24),
        
        // Position runs analysis
        _buildPositionRunsSection(positionAnalytics),
        
        const SizedBox(height: 24),
        
        // Value vs. need analysis
        _buildValueVsNeedSection(),
      ],
    ),
  );
}

// 1. Calculate position analytics
Map<String, dynamic> _calculatePositionAnalytics() {
  // Count positions drafted
  Map<String, int> positionCounts = {};
  // Count positions by round
  Map<String, Map<String, int>> positionsByRound = {};
  // Track position runs
  Map<String, List<int>> positionRuns = {};
  // Calculate position value metrics
  Map<String, double> positionAvgValue = {};
  Map<String, int> positionValueTotals = {};
  
  // Process each pick
  for (var pick in widget.completedPicks) {
    if (pick.selectedPlayer == null) continue;
    
    String position = pick.selectedPlayer!.position;
    String round = pick.round;
    
    // Update position counts
    positionCounts[position] = (positionCounts[position] ?? 0) + 1;
    
    // Update positions by round
    positionsByRound.putIfAbsent(round, () => {});
    positionsByRound[round]![position] = (positionsByRound[round]![position] ?? 0) + 1;
    
    // Update position value metrics
    int valueDiff = pick.pickNumber - pick.selectedPlayer!.rank;
    positionValueTotals[position] = (positionValueTotals[position] ?? 0) + valueDiff;
    
    // Track consecutive picks for position runs
    positionRuns.putIfAbsent(position, () => []);
    positionRuns[position]!.add(pick.pickNumber);
  }
  
  // Calculate average value by position
  for (var position in positionCounts.keys) {
    positionAvgValue[position] = positionValueTotals[position]! / positionCounts[position]!;
  }
  
  // Identify position runs (3+ picks of same position in short span)
  Map<String, List<Map<String, dynamic>>> significantRuns = {};
  for (var entry in positionRuns.entries) {
    String position = entry.key;
    List<int> pickNumbers = entry.value..sort();
    
    if (pickNumbers.length < 3) continue; // Need at least 3 picks to identify a run
    
    // Check for runs - 3+ picks within 10 picks of each other
    List<Map<String, dynamic>> runs = [];
    for (int i = 0; i < pickNumbers.length - 2; i++) {
      if (pickNumbers[i+2] - pickNumbers[i] <= 10) {
        // Found a run - get all picks in this run
        List<int> runPicks = [];
        int j = i;
        while (j < pickNumbers.length - 1 && pickNumbers[j+1] - pickNumbers[j] <= 5) {
          if (j == i) runPicks.add(pickNumbers[j]);
          runPicks.add(pickNumbers[j+1]);
          j++;
        }
        
        if (runPicks.length >= 3) {
          runs.add({
            'startPick': runPicks.first,
            'endPick': runPicks.last,
            'length': runPicks.length,
            'picks': runPicks,
          });
          
          // Skip ahead to avoid overlapping runs
          i = j;
        }
      }
    }
    
    if (runs.isNotEmpty) {
      significantRuns[position] = runs;
    }
  }
  
  return {
    'positionCounts': positionCounts,
    'positionsByRound': positionsByRound,
    'positionAvgValue': positionAvgValue,
    'significantRuns': significantRuns,
  };
}

// 2. Build position distribution section
Widget _buildPositionDistributionSection(Map<String, dynamic> analytics) {
  final positionCounts = analytics['positionCounts'] as Map<String, int>;
  
  // Sort positions by count
  List<MapEntry<String, int>> sortedPositions = positionCounts.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  
  // Group positions into categories
  Map<String, List<MapEntry<String, int>>> positionGroups = {
    'QB': [],
    'Offensive Skill': [],
    'Offensive Line': [],
    'Defensive Front': [],
    'Secondary': [],
    'Special Teams': [],
  };
  
  for (var entry in sortedPositions) {
    String position = entry.key;
    
    if (position == 'QB') {
      positionGroups['QB']!.add(entry);
    } else if (['RB', 'WR', 'TE', 'FB'].contains(position)) {
      positionGroups['Offensive Skill']!.add(entry);
    } else if (['OT', 'IOL', 'OL', 'G', 'C'].contains(position)) {
      positionGroups['Offensive Line']!.add(entry);
    } else if (['EDGE', 'IDL', 'DL', 'DT', 'DE', 'LB', 'ILB', 'OLB'].contains(position)) {
      positionGroups['Defensive Front']!.add(entry);
    } else if (['CB', 'S', 'FS', 'SS'].contains(position)) {
      positionGroups['Secondary']!.add(entry);
    } else {
      positionGroups['Special Teams']!.add(entry);
    }
  }
  
  // Group colors
  final groupColors = {
    'QB': Colors.red.shade700,
    'Offensive Skill': Colors.orange.shade700,
    'Offensive Line': Colors.amber.shade700,
    'Defensive Front': Colors.blue.shade700,
    'Secondary': Colors.indigo.shade700,
    'Special Teams': Colors.green.shade700,
  };
  
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        "Position Distribution",
        style: TextStyle(
          fontSize: 18, 
          fontWeight: FontWeight.bold,
        ),
      ),
      const SizedBox(height: 12),
      
      // Position distribution chart
      Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Total position breakdown
              Row(
                children: [
                  // Bar chart
                  Expanded(
                    flex: 3,
                    child: SizedBox(
                      height: 250,
                      child: _buildPositionBarChart(sortedPositions),
                    ),
                  ),
                  
                  const SizedBox(width: 24),
                  
                  // Legend and counts
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Position Counts",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        
                        // Position groups
                        ...positionGroups.entries
                            .where((entry) => entry.value.isNotEmpty)
                            .map((entry) {
                          String group = entry.key;
                          List<MapEntry<String, int>> positions = entry.value;
                          Color groupColor = groupColors[group]!;
                          
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Group header
                                Row(
                                  children: [
                                    Container(
                                      width: 12,
                                      height: 12,
                                      color: groupColor,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      group,
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                
                                // Positions in this group
                                ...positions.map((pos) => 
                                  Padding(
                                    padding: const EdgeInsets.only(left: 20.0, bottom: 4.0),
                                    child: Row(
                                      children: [
                                        Text(pos.key),
                                        const Spacer(),
                                        Text(
                                          "${pos.value}",
                                          style: const TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                      ],
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
                ],
              ),
            ],
          ),
        ),
      ),
    ],
  );
}

// 3. Helper method to build position bar chart
Widget _buildPositionBarChart(List<MapEntry<String, int>> sortedPositions) {
  // Find max count for scaling
  int maxCount = sortedPositions.isNotEmpty ? sortedPositions.first.value : 0;
  if (maxCount == 0) return const Center(child: Text("No data available"));
  
  return LayoutBuilder(
    builder: (context, constraints) {
      final availableWidth = constraints.maxWidth;
      final barWidth = min(30.0, availableWidth / (sortedPositions.length * 1.5));
      final spacing = min(20.0, availableWidth / (sortedPositions.length * 4));
      
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: sortedPositions.map((entry) {
          final position = entry.key;
          final count = entry.value;
          final percent = count / maxCount;
          
          return Padding(
            padding: EdgeInsets.symmetric(horizontal: spacing / 2),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Count label
                Text(
                  count.toString(),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
                const SizedBox(height: 4),
                
                // Bar
                Container(
                  width: barWidth,
                  height: 180 * percent,
                  decoration: BoxDecoration(
                    color: _getPositionColor(position),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(4),
                      topRight: Radius.circular(4),
                    ),
                  ),
                ),
                
                // Position label
                const SizedBox(height: 4),
                Text(
                  position,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      );
    },
  );
}

// 4. Build position by round section
Widget _buildPositionByRoundSection(Map<String, dynamic> analytics) {
  final positionsByRound = analytics['positionsByRound'] as Map<String, Map<String, int>>;
  
  // Get rounds in order
  List<String> rounds = positionsByRound.keys.toList()
    ..sort((a, b) => int.parse(a).compareTo(int.parse(b)));
  
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        "Position Breakdown by Round",
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
              // Round tabs
              DefaultTabController(
                length: rounds.length,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Round selector tabs
                    TabBar(
                      isScrollable: true,
                      tabs: rounds.map((round) => 
                        Tab(
                          child: Text(
                            "Round $round",
                            style: TextStyle(color: _getRoundColor(round)),
                          ),
                        ),
                      ).toList(),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Round content
                    SizedBox(
                      height: 250,
                      child: TabBarView(
                        children: rounds.map((round) {
                          // Get positions for this round
                          final positionCounts = positionsByRound[round]!;
                          
                          // Sort by count
                          List<MapEntry<String, int>> sortedPositions = 
                            positionCounts.entries.toList()
                              ..sort((a, b) => b.value.compareTo(a.value));
                          
                          if (sortedPositions.isEmpty) {
                            return const Center(child: Text("No picks in this round yet"));
                          }
                          
                          return Row(
                            children: [
                              // Pie chart
                              Expanded(
                                child: _buildRoundPieChart(sortedPositions, round),
                              ),
                              
                              // Legend
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    ...sortedPositions.map((entry) {
                                      String position = entry.key;
                                      int count = entry.value;
                                      Color color = _getPositionColor(position);
                                      
                                      return Padding(
                                        padding: const EdgeInsets.only(bottom: 8.0),
                                        child: Row(
                                          children: [
                                            Container(
                                              width: 12,
                                              height: 12,
                                              color: color,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(position),
                                            const Spacer(),
                                            Text(
                                              "$count",
                                              style: const TextStyle(fontWeight: FontWeight.bold),
                                            ),
                                          ],
                                        ),
                                      );
                                    }),
                                  ],
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ],
  );
}

// 5. Helper method to build round pie chart
Widget _buildRoundPieChart(List<MapEntry<String, int>> positions, String round) {
  // Simple pie chart made of stacked containers with rounded corners
  int total = positions.fold(0, (sum, entry) => sum + entry.value);
  
  return SizedBox(
    width: 200,
    height: 200,
    child: Stack(
      alignment: Alignment.center,
      children: [
        // Pie segments
        ...positions.map((entry) {
          String position = entry.key;
          int count = entry.value;
          double percent = count / total;
          Color color = _getPositionColor(position);
          
          return Center(
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color,
              ),
              child: Center(
                child: Text(
                  "${(percent * 100).toInt()}%",
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          );
        }).take(1), // For now, just show the largest segment
        
        // Center circle
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _getRoundColor(round),
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "Round",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                  ),
                ),
                Text(
                  round,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

// 6. Build position runs section
Widget _buildPositionRunsSection(Map<String, dynamic> analytics) {
  final significantRuns = analytics['significantRuns'] as Map<String, List<Map<String, dynamic>>>;
  
  // Sort positions by biggest run
  List<MapEntry<String, List<Map<String, dynamic>>>> sortedRuns = 
    significantRuns.entries.toList()
      ..sort((a, b) {
        int maxA = a.value.isEmpty ? 0 : a.value.map((run) => run['length'] as int).reduce(max);
        int maxB = b.value.isEmpty ? 0 : b.value.map((run) => run['length'] as int).reduce(max);
        return maxB.compareTo(maxA);
      });
  
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        "Position Run Analysis",
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Significant position runs (3+ picks of same position in short span)",
                style: TextStyle(fontStyle: FontStyle.italic, fontSize: 12),
              ),
              const SizedBox(height: 16),
              
              if (sortedRuns.isEmpty)
                const Text("No significant position runs detected yet")
              else
                ...sortedRuns.map((entry) {
                  String position = entry.key;
                  List<Map<String, dynamic>> runs = entry.value;
                  Color posColor = _getPositionColor(position);
                  
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Position header
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: posColor,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                position,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              "${runs.length} run${runs.length > 1 ? 's' : ''}",
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        
                        // Runs for this position
                        ...runs.map((run) {
                          int startPick = run['startPick'];
                          int endPick = run['endPick'];
                          int length = run['length'];
                          
                          return Padding(
                            padding: const EdgeInsets.only(left: 16.0, bottom: 8.0),
                            child: Row(
                              children: [
                                const Icon(Icons.trending_up, size: 16),
                                const SizedBox(width: 8),
                                Text(
                                  "$length picks between #$startPick and #$endPick",
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  "(${endPick - startPick + 1} pick span)",
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ],
                            ),
                          );
                        }),
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

// 7. Build value vs need section
Widget _buildValueVsNeedSection() {
  // This is a more complex analysis and would need team needs data to be comprehensive
  // Here we'll focus on finding where teams picked for need vs. value
  List<Map<String, dynamic>> valuePicksByNeeds = [];
  
  // Process all picks
  for (var pick in widget.completedPicks) {
    if (pick.selectedPlayer == null) continue;
    
    // Find team needs
    final teamNeed = _findTeamNeed(pick.teamName);
    if (teamNeed == null) continue;
    
    // Calculate value differential
    int valueDiff = pick.pickNumber - pick.selectedPlayer!.rank;
    
    // Determine if pick was for a need
    bool wasNeedPick = teamNeed.needs.contains(pick.selectedPlayer!.position);
    
    valuePicksByNeeds.add({
      'team': pick.teamName,
      'pickNumber': pick.pickNumber,
      'position': pick.selectedPlayer!.position,
      'valueDiff': valueDiff,
      'wasNeedPick': wasNeedPick,
    });
  }
  
  // Find best value need picks and best value BPA picks
  valuePicksByNeeds.sort((a, b) => b['valueDiff'].compareTo(a['valueDiff']));
  
  final bestValueNeedPicks = valuePicksByNeeds
      .where((pick) => pick['wasNeedPick'] && pick['valueDiff'] > 0)
      .take(5)
      .toList();
      
  final bestValueBPAPicks = valuePicksByNeeds
      .where((pick) => !pick['wasNeedPick'] && pick['valueDiff'] > 0)
      .take(5)
      .toList();
      
  // Find biggest reaches for needs
  valuePicksByNeeds.sort((a, b) => a['valueDiff'].compareTo(b['valueDiff']));
  
  final biggestReachesForNeeds = valuePicksByNeeds
      .where((pick) => pick['wasNeedPick'] && pick['valueDiff'] < 0)
      .take(5)
      .toList();
  
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        "Value vs. Need Analysis",
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Teams that got value while addressing needs",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              
              if (bestValueNeedPicks.isEmpty)
                const Text("No data available yet")
              else
                ...bestValueNeedPicks.map((pick) => 
                  _buildValueNeedListItem(
                    pick['team'], 
                    pick['position'], 
                    pick['pickNumber'], 
                    pick['valueDiff'], 
                    Colors.green.shade700
                  ),
                ),
                
              const SizedBox(height: 16),
              
              const Text(
                "Teams that reached for needs",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              
              if (biggestReachesForNeeds.isEmpty)
                const Text("No data available yet")
              else
                ...biggestReachesForNeeds.map((pick) => 
                  _buildValueNeedListItem(
                    pick['team'], 
                    pick['position'], 
                    pick['pickNumber'], 
                    pick['valueDiff'], 
                    Colors.red.shade700
                  ),
                ),
                
              const SizedBox(height: 16),
              
              const Text(
                "Best value regardless of need (BPA picks)",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              
              if (bestValueBPAPicks.isEmpty)
                const Text("No data available yet")
              else
                ...bestValueBPAPicks.map((pick) => 
                  _buildValueNeedListItem(
                    pick['team'], 
                    pick['position'], 
                    pick['pickNumber'], 
                    pick['valueDiff'], 
                    Colors.blue.shade700
                  ),
                ),
            ],
          ),
        ),
      ),
    ],
  );
}

// 8. Helper method to build value/need list item
Widget _buildValueNeedListItem(String team, String position, int pickNumber, int valueDiff, Color color) {
  bool isUserTeam = team == widget.userTeam;
  
  return Padding(
    padding: const EdgeInsets.only(bottom: 8.0),
    child: Row(
      children: [
        // Team name
        SizedBox(
          width: 120,
          child: Text(
            team,
            style: TextStyle(
              fontWeight: isUserTeam ? FontWeight.bold : FontWeight.normal,
              color: isUserTeam ? Colors.blue : null,
            ),
          ),
        ),
        
        // Position
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: _getPositionColor(position).withOpacity(0.2),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            position,
            style: TextStyle(
              fontSize: 12,
              color: _getPositionColor(position),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        
        const SizedBox(width: 8),
        
        // Pick number
        Text("Pick #$pickNumber"),
        
        const Spacer(),
        
        // Value difference
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: color),
          ),
          child: Text(
            "${valueDiff > 0 ? "+" : ""}$valueDiff",
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    ),
  );
}

// 9. Helper method to find team needs
TeamNeed? _findTeamNeed(String teamName) {
  try {
    return widget.teamNeeds.firstWhere((need) => need.teamName == teamName);
  } catch (e) {
    return null;
  }
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