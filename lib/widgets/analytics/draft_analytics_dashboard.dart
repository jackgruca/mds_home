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
    _tabController = TabController(length: 4, vsync: this);
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
            Tab(text: 'Summary', icon: Icon(Icons.dashboard)),
            Tab(text: 'Positions', icon: Icon(Icons.people)),
            Tab(text: 'Teams', icon: Icon(Icons.groups)),
            Tab(text: 'Trades', icon: Icon(Icons.swap_horiz)),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildSummaryTab(),
              _buildPositionsTab(),
              _buildTeamsTab(),
              _buildTradesTab(),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildSummaryTab() {
    // Get some simple stats
    int picksMade = widget.completedPicks.length;
    int tradesExecuted = widget.executedTrades.length;
    
    // Calculate average rank difference to see if teams are reaching or getting value
    double avgRankDiff = 0;
    int rankCount = 0;
    for (var pick in widget.completedPicks) {
      if (pick.selectedPlayer != null) {
        avgRankDiff += (pick.pickNumber - pick.selectedPlayer!.rank);
        rankCount++;
      }
    }
    avgRankDiff = rankCount > 0 ? avgRankDiff / rankCount : 0;
    
    // Calculate user team stats if applicable
    List<DraftPick> userPicks = [];
    int userValueDiff = 0;
    if (widget.userTeam != null) {
      userPicks = widget.completedPicks
          .where((pick) => pick.teamName == widget.userTeam && pick.selectedPlayer != null)
          .toList();
      
      for (var pick in userPicks) {
        userValueDiff += (pick.pickNumber - pick.selectedPlayer!.rank);
      }
    }
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Main stats cards
          Row(
            children: [
              _buildStatCard(
                title: 'Picks Made',
                value: '$picksMade',
                icon: Icons.done,
                color: Colors.blue,
              ),
              const SizedBox(width: 16),
              _buildStatCard(
                title: 'Trades Made',
                value: '$tradesExecuted',
                icon: Icons.swap_horiz,
                color: Colors.orange,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildStatCard(
                title: 'Avg. Value',
                value: avgRankDiff.toStringAsFixed(1),
                subtitle: avgRankDiff > 0 ? 'Teams getting value' : 'Teams reaching',
                icon: avgRankDiff > 0 ? Icons.trending_up : Icons.trending_down,
                color: avgRankDiff > 0 ? Colors.green : Colors.red,
              ),
              const SizedBox(width: 16),
              if (widget.userTeam != null)
                _buildStatCard(
                  title: 'Your Picks',
                  value: '${userPicks.length}',
                  subtitle: userValueDiff > 0 ? 'Good value (+$userValueDiff)' : 'Reached ($userValueDiff)',
                  icon: userValueDiff > 0 ? Icons.thumb_up : Icons.thumb_down,
                  color: userValueDiff > 0 ? Colors.green : Colors.orange,
                ),
            ],
          ),
          
          const SizedBox(height: 24),
          const Text(
            'Position Breakdown',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          // Simple position breakdown bar
          SizedBox(
            height: 40,
            child: _buildPositionBreakdownBar(),
          ),
          
          const SizedBox(height: 24),
          const Text(
            'Most Recent Picks',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          // Recent picks list
          _buildRecentPicksList(),
          
          const SizedBox(height: 24),
          const Text(
            'Trade Activity',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          // Trade activity chart
          _buildTradeActivityChart(),
          
          if (widget.userTeam != null) ...[
            const SizedBox(height: 24),
            Text(
              'Your ${widget.userTeam} Draft',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            _buildUserTeamSummary(),
          ],
        ],
      ),
    );
  }
  
  Widget _buildPositionsTab() {
    // Sort positions by counts
    List<MapEntry<String, int>> sortedPositions = _positionCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    // Calculate tiers
    Map<String, List<String>> positionTiers = {
      'Premium': ['QB', 'OT', 'EDGE', 'CB', 'WR'],
      'Secondary': ['DT', 'S', 'TE', 'LB', 'IOL'],
      'Tertiary': ['RB', 'G', 'C', 'FB', 'P', 'K', 'LS'],
    };
    
    // Count positions by round
    Map<String, Map<String, int>> positionsByRound = {};
    for (var pick in widget.completedPicks) {
      if (pick.selectedPlayer != null) {
        String position = pick.selectedPlayer!.position;
        String round = pick.round;
        
        positionsByRound.putIfAbsent(round, () => {});
        positionsByRound[round]![position] = 
          (positionsByRound[round]![position] ?? 0) + 1;
      }
    }
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Position counts bar chart
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Positions Drafted',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 200,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: sortedPositions.length,
                      itemBuilder: (context, index) {
                        final entry = sortedPositions[index];
                        final position = entry.key;
                        final count = entry.value;
                        final maxCount = sortedPositions.first.value.toDouble();
                        
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: Column(
                            children: [
                              Expanded(
                                child: Container(
                                  width: 40,
                                  alignment: Alignment.bottomCenter,
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 500),
                                    curve: Curves.easeOutCubic,
                                    width: 40,
                                    height: (count / maxCount) * 150,
                                    decoration: BoxDecoration(
                                      color: _getPositionColor(position),
                                      borderRadius: const BorderRadius.vertical(
                                        top: Radius.circular(4),
                                      ),
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      count.toString(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                position,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
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
          
          // Position tiers analysis
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Position Tiers Analysis',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  for (var tier in positionTiers.entries) ...[
                    Text(
                      '${tier.key} Positions',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (var position in tier.value)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: _getPositionColor(position).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: _getPositionColor(position),
                              ),
                            ),
                            child: Text(
                              '$position: ${_positionCounts[position] ?? 0}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: _getPositionColor(position),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Positions by round
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Positions by Round',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  for (var i = 1; i <= 7; i++) ...[
                    if (positionsByRound.containsKey(i.toString())) ...[
                      Text(
                        'Round $i',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (var entry in positionsByRound[i.toString()]!.entries)
                            Chip(
                              label: Text('${entry.key}: ${entry.value}'),
                              backgroundColor: _getPositionColor(entry.key).withOpacity(0.2),
                              side: BorderSide(
                                color: _getPositionColor(entry.key),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
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