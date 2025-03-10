import 'package:flutter/material.dart';
import '../models/draft_pick.dart';
import '../models/player.dart';
import '../models/trade_package.dart';
import '../widgets/analytics/draft_analytics_dashboard.dart';

class DraftSummaryScreen extends StatefulWidget {
  final List<DraftPick> completedPicks;
  final List<Player> draftedPlayers;
  final List<TradePackage> executedTrades;
  final String? userTeam;

  const DraftSummaryScreen({
    super.key,
    required this.completedPicks,
    required this.draftedPlayers,
    required this.executedTrades,
    this.userTeam,
  });

  @override
  State<DraftSummaryScreen> createState() => _DraftSummaryScreenState();
}

class _DraftSummaryScreenState extends State<DraftSummaryScreen> {
  @override
  Widget build(BuildContext context) {
    return Dialog.fullscreen(
      child: Scaffold(
        appBar: AppBar(
          title: Text('Draft Summary${widget.userTeam != null ? ' - ${widget.userTeam}' : ''}'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        ),
        body: _buildBody(),
      ),
    );
  }
  
  Widget _buildBody() {
    // Filter picks for user team if applicable
    final userPicks = widget.userTeam != null
        ? widget.completedPicks.where((pick) => pick.teamName == widget.userTeam).toList()
        : widget.completedPicks;
    
    final userDraftedPlayers = userPicks
        .where((pick) => pick.selectedPlayer != null)
        .map((pick) => pick.selectedPlayer!)
        .toList();
    
    final userTrades = widget.executedTrades
        .where((trade) => 
          trade.teamOffering == widget.userTeam || 
          trade.teamReceiving == widget.userTeam)
        .toList();
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Draft grade and summary banner
          _buildDraftGradeBanner(userPicks),
          
          const SizedBox(height: 24),
          
          // User picks section
          if (widget.userTeam != null) ...[
            _buildUserPicksSection(userDraftedPlayers),
            const SizedBox(height: 24),
          ],
          
          // Draft class breakdown - position distribution
          _buildDraftClassBreakdown(),
          
          const SizedBox(height: 24),
          
          // Trade summary if applicable
          if (userTrades.isNotEmpty) ...[
            _buildTradesSummary(userTrades),
            const SizedBox(height: 24),
          ],
          
          // View full analytics button
          Center(
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                // Parent widget will handle showing analytics tab
              },
              icon: const Icon(Icons.analytics),
              label: const Text('View Full Analytics Dashboard'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildDraftGradeBanner(List<DraftPick> userPicks) {
    // Calculate draft grade
    String grade = 'B';
    String gradeDescription = 'Solid draft with good value picks';
    Color gradeColor = Colors.green.shade600;
    
    if (widget.userTeam != null && userPicks.isNotEmpty) {
      // Calculate average value differential
      double totalDiff = 0;
      int count = 0;
      
      for (var pick in userPicks) {
        if (pick.selectedPlayer != null) {
          totalDiff += (pick.pickNumber - pick.selectedPlayer!.rank);
          count++;
        }
      }
      
      double avgDiff = count > 0 ? totalDiff / count : 0;
      
      // Determine grade based on average difference
      if (avgDiff >= 15) {
        grade = 'A+';
        gradeDescription = 'Outstanding draft with exceptional value';
        gradeColor = Colors.green.shade900;
      } else if (avgDiff >= 10) {
        grade = 'A';
        gradeDescription = 'Excellent draft with great value picks';
        gradeColor = Colors.green.shade800;
      } else if (avgDiff >= 5) {
        grade = 'B+';
        gradeDescription = 'Very good draft with solid value picks';
        gradeColor = Colors.green.shade700;
      } else if (avgDiff >= 0) {
        grade = 'B';
        gradeDescription = 'Solid draft with good value picks';
        gradeColor = Colors.green.shade600;
      } else if (avgDiff >= -5) {
        grade = 'C+';
        gradeDescription = 'Average draft with some reaches';
        gradeColor = Colors.orange.shade700;
      } else if (avgDiff >= -10) {
        grade = 'C';
        gradeDescription = 'Below average draft with several reaches';
        gradeColor = Colors.orange.shade800;
      } else {
        grade = 'D';
        gradeDescription = 'Poor draft with significant reaches';
        gradeColor = Colors.red.shade700;
      }
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
              Colors.blue.shade700,
              Colors.blue.shade900,
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
                color: Colors.white.withOpacity(0.9),
                border: Border.all(color: gradeColor, width: 3),
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
                    widget.userTeam != null 
                        ? 'Draft Grade for ${widget.userTeam}'
                        : 'Draft Complete!',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    gradeDescription,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Total Picks: ${userPicks.length}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),
          ],
        )
      ),
    );
  }
          
  
  Widget _buildUserPicksSection(List<Player> players) {
    if (players.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('No players drafted yet.'),
        ),
      );
    }
    
    // Group players by position
    Map<String, List<Player>> positionGroups = {};
    for (var player in players) {
      positionGroups.putIfAbsent(player.position, () => []);
      positionGroups[player.position]!.add(player);
    }
    
    // Sort positions by count
    List<MapEntry<String, List<Player>>> sortedGroups = positionGroups.entries.toList()
      ..sort((a, b) => b.value.length.compareTo(a.value.length));
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Your Draft Class',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        
        // Player cards by position
        for (var group in sortedGroups) ...[
          // Position header
          Padding(
            padding: const EdgeInsets.only(left: 8.0, top: 8.0, bottom: 4.0),
            child: Text(
              '${group.key} (${group.value.length})',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: _getPositionColor(group.key),
              ),
            ),
          ),
          
          // Player cards
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide(
                color: _getPositionColor(group.key).withOpacity(0.3),
                width: 1,
              ),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: group.value.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final player = group.value[index];
                final pickInfo = widget.completedPicks.firstWhere(
                  (pick) => pick.selectedPlayer?.id == player.id,
                  orElse: () => DraftPick(pickNumber: 0, teamName: '', round: ''),
                );
                
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: _getPositionColor(player.position),
                    child: Text(
                      '#${pickInfo.pickNumber}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(
                    player.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    '${player.school.isNotEmpty ? "${player.school} • " : ""}Round ${pickInfo.round}',
                    style: const TextStyle(
                      fontSize: 12,
                    ),
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getRankComparisonColor(player.rank, pickInfo.pickNumber).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: _getRankComparisonColor(player.rank, pickInfo.pickNumber),
                      ),
                    ),
                    child: Text(
                      _getRankDifferenceText(player.rank, pickInfo.pickNumber),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: _getRankComparisonColor(player.rank, pickInfo.pickNumber),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          
          const SizedBox(height: 16),
        ],
      ],
    );
  }
  
  Widget _buildDraftClassBreakdown() {
    // Get position counts
    Map<String, int> positionCounts = {};
    for (var pick in widget.completedPicks) {
      if (pick.selectedPlayer != null) {
        final position = pick.selectedPlayer!.position;
        positionCounts[position] = (positionCounts[position] ?? 0) + 1;
      }
    }
    
    // Group positions into categories
    Map<String, int> categoryTotals = {
      'Quarterback': 0,
      'Offensive Skill': 0,
      'Offensive Line': 0,
      'Defensive Front': 0,
      'Secondary': 0,
      'Special Teams': 0,
    };
    
    // Map positions to categories
    final positionCategories = {
      'QB': 'Quarterback',
      'RB': 'Offensive Skill',
      'WR': 'Offensive Skill',
      'TE': 'Offensive Skill',
      'FB': 'Offensive Skill',
      'OT': 'Offensive Line',
      'IOL': 'Offensive Line',
      'G': 'Offensive Line',
      'C': 'Offensive Line',
      'OL': 'Offensive Line',
      'EDGE': 'Defensive Front',
      'DL': 'Defensive Front',
      'DE': 'Defensive Front',
      'DT': 'Defensive Front',
      'IDL': 'Defensive Front',
      'LB': 'Defensive Front',
      'ILB': 'Defensive Front',
      'OLB': 'Defensive Front',
      'CB': 'Secondary',
      'S': 'Secondary',
      'FS': 'Secondary',
      'SS': 'Secondary',
      'K': 'Special Teams',
      'P': 'Special Teams',
      'LS': 'Special Teams',
    };
    
    // Sum up categories
    for (var entry in positionCounts.entries) {
      final category = positionCategories[entry.key] ?? 'Other';
      categoryTotals[category] = (categoryTotals[category] ?? 0) + entry.value;
    }
    
    // Colors for each category
    final categoryColors = {
      'Quarterback': Colors.red.shade700,
      'Offensive Skill': Colors.orange.shade700,
      'Offensive Line': Colors.amber.shade700,
      'Defensive Front': Colors.blue.shade700,
      'Secondary': Colors.indigo.shade700,
      'Special Teams': Colors.green.shade700,
    };
    
    // Calculate total drafted players
    final totalDrafted = categoryTotals.values.reduce((a, b) => a + b);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Draft Class Breakdown',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        
        Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Distribution bar
                SizedBox(
                  height: 40,
                  child: Row(
                    children: categoryTotals.entries.map((entry) {
                      // Skip categories with no players
                      if (entry.value == 0) return const SizedBox.shrink();
                      
                      final percentage = totalDrafted > 0 ? entry.value / totalDrafted : 0;
                      final color = categoryColors[entry.key] ?? Colors.grey;
                      
                      return Expanded(
                        flex: (percentage * 100).round(),
                        child: Container(
                          color: color,
                          child: Center(
                            child: percentage > 0.1 ? Text(
                              entry.value.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
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
                  children: categoryTotals.entries.map((entry) {
                    // Skip categories with no players
                    if (entry.value == 0) return const SizedBox.shrink();
                    
                    final color = categoryColors[entry.key] ?? Colors.grey;
                    final percentage = totalDrafted > 0 ? (entry.value / totalDrafted * 100).round() : 0;
                    
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: color),
                      ),
                      child: Text(
                        '${entry.key}: ${entry.value} ($percentage%)',
                        style: TextStyle(
                          fontSize: 12,
                          color: color,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                
                const SizedBox(height: 16),
                
                // Top drafted positions
                const Text(
                  'Top Drafted Positions',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                
                // Position breakdown
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: 5, // Show top 5 positions
                  itemBuilder: (context, index) {
                    // Sort positions by count
                    List<MapEntry<String, int>> sortedPositions = positionCounts.entries.toList()
                      ..sort((a, b) => b.value.compareTo(a.value));
                    
                    // Exit if we don't have enough positions
                    if (index >= sortedPositions.length) return const SizedBox.shrink();
                    
                    final entry = sortedPositions[index];
                    final percentage = totalDrafted > 0 ? (entry.value / totalDrafted * 100).round() : 0;
                    
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2.0),
                      child: Row(
                        children: [
                          // Position
                          SizedBox(
                            width: 50,
                            child: Text(
                              entry.key,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          
                          // Bar
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
                                  width: percentage * 3, // Scale to fit
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(4),
                                    color: _getPositionColor(entry.key),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          // Count
                          SizedBox(
                            width: 50,
                            child: Text(
                              '${entry.value} ($percentage%)',
                              textAlign: TextAlign.right,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
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
    );
  }
  
  Widget _buildTradesSummary(List<TradePackage> trades) {
    if (trades.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Trade Summary',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        
        Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Trade stats
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildTradeStatItem(
                      'Total Trades',
                      trades.length.toString(),
                      Icons.swap_horiz,
                      Colors.blue,
                    ),
                    _buildTradeStatItem(
                      'Value Gained',
                      _calculateNetTradingValue(trades),
                      Icons.trending_up,
                      Colors.green,
                    ),
                    _buildTradeStatItem(
                      'Picks Moved',
                      _calculatePicksTraded(trades).toString(),
                      Icons.sync_alt,
                      Colors.orange,
                    ),
                  ],
                ),
                
                const SizedBox(height: 24),
                
                // Recent trades list
                const Text(
                  'Your Trades',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: trades.length,
                  itemBuilder: (context, index) {
                    final trade = trades[index];
                    return Card(
                      elevation: 1,
                      margin: const EdgeInsets.only(bottom: 8),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Trade header
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.shade100,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    'Trade ${index + 1}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue.shade800,
                                    ),
                                  ),
                                ),
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: trade.isGreatTrade ? Colors.green.shade100 : Colors.orange.shade100,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    trade.isGreatTrade ? 'Great Value' : 'Fair Trade',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                      color: trade.isGreatTrade ? Colors.green.shade800 : Colors.orange.shade800,
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
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Text(
                                  'Value: ${trade.valueSummary}',
                                  style: TextStyle(
                                    fontStyle: FontStyle.italic,
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildTradeStatItem(String title, String value, IconData icon, Color color) {
    return Column(
      children: [
        CircleAvatar(
          radius: 20,
          backgroundColor: color.withOpacity(0.2),
          child: Icon(
            icon,
            color: color,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          title,
          style: const TextStyle(
            fontSize: 12,
          ),
        ),
      ],
    );
  }
  
  // Helper functions
  Color _getPositionColor(String position) {
    // Different colors for different position groups
    if (['QB', 'RB', 'WR', 'TE'].contains(position)) {
      return Colors.blue.shade700; // Offensive skill positions
    } else if (['OT', 'IOL', 'OL', 'G', 'C'].contains(position)) {
      return Colors.green.shade700; // Offensive line
    } else if (['EDGE', 'IDL', 'DT', 'DE', 'DL'].contains(position)) {
      return Colors.red.shade700; // Defensive line
    } else if (['LB', 'ILB', 'OLB'].contains(position)) {
      return Colors.orange.shade700; // Linebackers
    } else if (['CB', 'S', 'FS', 'SS'].contains(position)) {
      return Colors.purple.shade700; // Secondary
    } else {
      return Colors.grey.shade700; // Special teams, etc.
    }
  }
  
  Color _getRankComparisonColor(int rank, int pickNumber) {
    // Color based on difference between rank and pick number
    int diff = pickNumber - rank;
    
    if (diff >= 15) {
      return Colors.green.shade800; // Excellent value
    } else if (diff >= 5) {
      return Colors.green.shade600; // Good value
    } else if (diff >= -5) {
      return Colors.blue.shade600; // Fair value
    } else if (diff >= -15) {
      return Colors.orange.shade600; // Slight reach
    } else {
      return Colors.red.shade600; // Significant reach
    }
  }
  
  String _getRankDifferenceText(int rank, int pickNumber) {
    int diff = pickNumber - rank;
    
    if (diff > 0) {
      return "+$diff";
    } else if (diff < 0) {
      return "$diff";
    } else {
      return "0";
    }
  }
  
  String _calculateNetTradingValue(List<TradePackage> trades) {
    if (trades.isEmpty) return "0";
    
    double netValue = 0;
    for (var trade in trades) {
      if (trade.teamOffering == widget.userTeam) {
        // User team traded away picks
        netValue -= trade.valueDifferential;
      } else if (trade.teamReceiving == widget.userTeam) {
        // User team received picks
        netValue += trade.valueDifferential;
      }
    }
    
    String sign = netValue > 0 ? "+" : "";
    return "$sign${netValue.toStringAsFixed(0)}";
  }
  
  int _calculatePicksTraded(List<TradePackage> trades) {
    int count = 0;
    for (var trade in trades) {
      // Count picks offered
      count += trade.picksOffered.length;
      
      // Count target pick and additional target picks
      count += 1 + (trade.additionalTargetPicks.length);
      
      // Count future picks if applicable
      if (trade.includesFuturePick) {
        count += 1; // At least one future pick
        
        // Try to get more accurate count from description
        if (trade.futurePickDescription != null) {
          // Count commas to estimate multiple future picks
          count += trade.futurePickDescription!.split(',').length - 1;
        }
      }
    }
    return count;
  }
}