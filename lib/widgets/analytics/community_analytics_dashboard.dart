// lib/widgets/analytics/community_analytics_dashboard.dart
import 'package:flutter/material.dart';
import '../../services/analytics_query_service.dart';
import '../../utils/constants.dart';
import '../../utils/team_logo_utils.dart';

class CommunityAnalyticsDashboard extends StatefulWidget {
  final String userTeam;
  final int draftYear;

  const CommunityAnalyticsDashboard({
    super.key,
    required this.userTeam,
    required this.draftYear,
  });

  @override
  _CommunityAnalyticsDashboardState createState() => _CommunityAnalyticsDashboardState();
}

class _CommunityAnalyticsDashboardState extends State<CommunityAnalyticsDashboard>
    with AutomaticKeepAliveClientMixin {
  bool _isLoading = true;
  String _selectedTab = 'Team Trends';
  int _selectedRound = 1;

  // Data states
  List<Map<String, dynamic>> _popularPicks = [];
  Map<String, dynamic> _positionBreakdown = {'total': 0, 'positions': {}};
  List<Map<String, dynamic>> _rankDeviations = [];

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
      // Load popular picks for the user's team first round
      final popularPicks = await AnalyticsQueryService.getMostPopularPicksByTeam(
        team: widget.userTeam,
        round: _selectedRound,
        year: widget.draftYear,
        limit: 10,
      );

      // Load position breakdown for the first 3 rounds
      final positionBreakdown = await AnalyticsQueryService.getPositionBreakdownByTeam(
        team: widget.userTeam,
        rounds: [1, 2, 3],
        year: widget.draftYear,
      );

      // Load significant rank deviations
      final rankDeviationsData = await AnalyticsQueryService.getPlayerRankDeviations(
        year: widget.draftYear,
        limit: 10,
      );
      List<Map<String, dynamic>> rankDeviations = 
          List<Map<String, dynamic>>.from(rankDeviationsData['players'] ?? []);

      setState(() {
        _popularPicks = popularPicks;
        _positionBreakdown = positionBreakdown;
        _rankDeviations = rankDeviations;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading community analytics: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshData() async {
    if (_selectedTab == 'Team Trends') {
      // Reload popular picks for the selected round
      final popularPicks = await AnalyticsQueryService.getMostPopularPicksByTeam(
        team: widget.userTeam,
        round: _selectedRound,
        year: widget.draftYear,
        limit: 10,
      );
      
      setState(() {
        _popularPicks = popularPicks;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Tab selector
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Row(
            children: [
              _buildTabButton('Team Trends', isDarkMode),
              const SizedBox(width: 12),
              _buildTabButton('Position Analysis', isDarkMode),
              const SizedBox(width: 12),
              _buildTabButton('Player Ranking Trends', isDarkMode),
            ],
          ),
        ),

        // Round selector for Team Trends
        if (_selectedTab == 'Team Trends')
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                const Text('Round:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(width: 8),
                ...List.generate(7, (index) {
                  int round = index + 1;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ChoiceChip(
                      label: Text('R$round'),
                      selected: _selectedRound == round,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            _selectedRound = round;
                          });
                          _refreshData();
                        }
                      },
                    ),
                  );
                }),
              ],
            ),
          ),

        // Tab content
        Expanded(
          child: _buildTabContent(isDarkMode),
        ),
      ],
    );
  }

  Widget _buildTabButton(String title, bool isDarkMode) {
    final isSelected = _selectedTab == title;
    
    return InkWell(
      onTap: () {
        setState(() {
          _selectedTab = title;
        });
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDarkMode ? Colors.blue.shade900 : Colors.blue.shade100)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? (isDarkMode ? Colors.blue.shade400 : Colors.blue.shade300)
                : (isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300),
          ),
        ),
        child: Text(
          title,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected
                ? (isDarkMode ? Colors.white : Colors.blue.shade800)
                : (isDarkMode ? Colors.grey.shade300 : Colors.grey.shade700),
          ),
        ),
      ),
    );
  }

  Widget _buildTabContent(bool isDarkMode) {
    switch (_selectedTab) {
      case 'Team Trends':
        return _buildTeamTrendsTab(isDarkMode);
      case 'Position Analysis':
        return _buildPositionAnalysisTab(isDarkMode);
      case 'Player Ranking Trends':
        return _buildPlayerRankingTab(isDarkMode);
      default:
        return const Center(
          child: Text('Select a tab to view analytics'),
        );
    }
  }

  Widget _buildTeamTrendsTab(bool isDarkMode) {
    if (_popularPicks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.analytics_outlined,
              size: 64,
              color: isDarkMode ? Colors.grey.shade600 : Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'No data available yet for ${widget.userTeam} in Round $_selectedRound',
              style: TextStyle(
                fontSize: 16,
                color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
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
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Most Popular Picks for ${widget.userTeam} in Round $_selectedRound',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _popularPicks.length,
                    itemBuilder: (context, index) {
                      final pick = _popularPicks[index];
                      
                      return ListTile(
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: _getPositionColor(pick['position']),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              pick['position'],
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                        title: Text(
                          pick['name'],
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          '${pick['school']} • Consensus Rank: #${pick['rank']}',
                        ),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: isDarkMode ? Colors.blue.shade900 : Colors.blue.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            pick['percentage'],
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isDarkMode ? Colors.white : Colors.blue.shade800,
                            ),
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
      ),
    );
  }

  Widget _buildPositionAnalysisTab(bool isDarkMode) {
    final positions = _positionBreakdown['positions'] as Map<String, dynamic>;
    final total = _positionBreakdown['total'] as int;
    
    if (total == 0) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.analytics_outlined,
              size: 64,
              color: isDarkMode ? Colors.grey.shade600 : Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'No position data available yet for ${widget.userTeam}',
              style: TextStyle(
                fontSize: 16,
                color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    // Convert positions to sorted list
    final positionsList = positions.entries
        .map((e) => {
              'position': e.key,
              'count': e.value['count'],
              'percentage': e.value['percentage'],
            })
        .toList();
    
    positionsList.sort((a, b) => (b['count'] as int).compareTo(a['count'] as int));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Position Breakdown for ${widget.userTeam} (Rounds 1-3)',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Position Bar Chart
                  SizedBox(
                    height: 40,
                    child: Row(
                      children: positionsList.map((position) {
                        final count = position['count'] as int;
                        final percent = count / total;
                        
                        return Expanded(
                          flex: (percent * 100).round(),
                          child: Container(
                            color: _getPositionColor(position['position'] as String),
                            child: Center(
                              child: percent > 0.1 ? Text(
                                position['position'] as String,
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
                  
                  // Position Legend
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: positionsList.map((position) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: _getPositionColor(position['position'] as String).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: _getPositionColor(position['position'] as String)),
                        ),
                        child: Text(
                          '${position['position']}: ${position['percentage']}',
                          style: TextStyle(
                            fontSize: 12,
                            color: _getPositionColor(position['position'] as String),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerRankingTab(bool isDarkMode) {
    if (_rankDeviations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.analytics_outlined,
              size: 64,
              color: isDarkMode ? Colors.grey.shade600 : Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'No player ranking data available yet',
              style: TextStyle(
                fontSize: 16,
                color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
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
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Players Most Consistently Drafted Away From Consensus Rank',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _rankDeviations.length,
                    itemBuilder: (context, index) {
                      final player = _rankDeviations[index];
                      final deviation = double.parse(player['avgDeviation'] as String);
                      final isEarlier = deviation < 0;
                      final deviationStr = deviation.abs().toStringAsFixed(1);
                      
                      return ListTile(
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: _getPositionColor(player['position'] as String),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              player['position'] as String,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                        title: Text(
                          player['name'] as String,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          'Based on ${player['sampleSize']} mock drafts',
                          style: const TextStyle(fontSize: 12),
                        ),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: isEarlier 
                                ? (isDarkMode ? Colors.red.shade900 : Colors.red.shade100)
                                : (isDarkMode ? Colors.green.shade900 : Colors.green.shade100),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            isEarlier 
                                ? '$deviationStr spots earlier'
                                : '$deviationStr spots later',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isEarlier
                                  ? (isDarkMode ? Colors.red.shade100 : Colors.red.shade800)
                                  : (isDarkMode ? Colors.green.shade100 : Colors.green.shade800),
                            ),
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

  @override
  bool get wantKeepAlive => true; // Keep the state when tab changes
}