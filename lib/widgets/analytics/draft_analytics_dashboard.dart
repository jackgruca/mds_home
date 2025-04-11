// lib/widgets/analytics/draft_analytics_dashboard.dart
import 'dart:math';

import 'package:flutter/material.dart';
import '../../models/draft_pick.dart';
import '../../models/player.dart';
import '../../models/trade_package.dart';
import '../../services/draft_grade_service.dart';
import '../../services/draft_value_service.dart';
import '../../models/team_need.dart';
import '../../services/draft_pick_grade_service.dart';
import '../../utils/constants.dart';
import '../../utils/team_logo_utils.dart';
import '../common/export_button_widget.dart';
import '../draft/shareable_draft_card.dart';
import 'community_analytics_dashboard.dart';



// In the DraftAnalyticsDashboard class constructor
class DraftAnalyticsDashboard extends StatefulWidget {
  final List<DraftPick> completedPicks;
  final List<Player> draftedPlayers;
  final List<TradePackage> executedTrades;
  final List<TeamNeed> teamNeeds;
  final String? userTeam;
  final int draftYear; // Add this line

  const DraftAnalyticsDashboard({
    super.key,
    required this.completedPicks,
    required this.draftedPlayers,
    required this.executedTrades,
    required this.teamNeeds,
    this.userTeam,
    this.draftYear = 2025, // Add default value
  });

  @override
  State<DraftAnalyticsDashboard> createState() => _DraftAnalyticsDashboardState();
}

class _DraftAnalyticsDashboardState extends State<DraftAnalyticsDashboard> with TickerProviderStateMixin {
  // Analytics data
  Map<String, int> _positionCounts = {};
  final String _selectedTeam = 'All Teams'; // Add this line to define _selectedTeam
  Map<String, Map<String, dynamic>> _teamGrades = {};
  List<Map<String, dynamic>> _valuePicks = [];
  List<Map<String, dynamic>> _reachPicks = [];
  List<Map<String, dynamic>> _positionRuns = [];
  int _selectedRound = 1; // Add this line

  late TabController _tabController;
  final GlobalKey _shareableCardKey = GlobalKey();


  @override
  void initState() {
    super.initState();
    _calculateAnalytics();
      _tabController = TabController(length: 2, vsync: this);
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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

Widget _buildRoundSummary() {
  // Get the maximum round in the completed picks
  int maxRound = 1;
  for (var pick in widget.completedPicks) {
    int round = int.tryParse(pick.round) ?? 1;
    if (round > maxRound) maxRound = round;
  }

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // Round selector tabs - MODIFIED to include the export button
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // This Row contains all the round selector buttons
            Row(
              children: [
                for (int i = 1; i <= maxRound; i++)
                  Padding(
                    padding: const EdgeInsets.only(right: 6.0), // Reduced from 8.0
                    child: ChoiceChip(
                      label: Text(
                        'Round $i',
                        style: const TextStyle(fontSize: 12), // Reduced default size
                      ),
                      selected: _selectedRound == i,
                      visualDensity: VisualDensity.compact, // Make chips more compact
                      labelPadding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 0,
                      ), // Reduced padding
                      onSelected: (bool selected) {
                        if (selected) {
                          setState(() {
                            _selectedRound = i;
                          });
                        }
                      },
                    ),
                  ),
              ],
            ),
            
            // Add the Export button here, with matching styling
            ExportButtonWidget(
              completedPicks: widget.completedPicks,
              teamNeeds: widget.teamNeeds,
              userTeam: widget.userTeam,
              executedTrades: widget.executedTrades,
              filterTeam: _selectedTeam,
              shareableCardKey: _shareableCardKey,
            ),
          ],
        ),
      ),
      const SizedBox(height: 10), // Reduced from 16
      
      // Round picks display
      _buildRoundPicksGrid(_selectedRound),
    ],
  );
}

Widget _buildRoundPicksGrid(int round) {
  // Filter picks by the selected round
  List<DraftPick> roundPicks = widget.completedPicks
      .where((pick) => int.tryParse(pick.round) == round)
      .toList();
  
  // Sort by pick number
  roundPicks.sort((a, b) => a.pickNumber.compareTo(b.pickNumber));
  
  // If no picks in this round, show a message
  if (roundPicks.isEmpty) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Text(
            'No picks made yet in Round $round',
            style: const TextStyle(fontStyle: FontStyle.italic),
          ),
        ),
      ),
    );
  }
  
  final isDarkMode = Theme.of(context).brightness == Brightness.dark;
  
  return Card(
    elevation: 2,
    child: Padding(
      padding: const EdgeInsets.all(8.0), // Reduced from 12.0
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // First vs Rest columns based on round number
          _roundLayoutBuilder(roundPicks, round, isDarkMode),
        ],
      ),
    ),
  );
}

Widget _roundLayoutBuilder(List<DraftPick> picks, int round, bool isDarkMode) {
  // For round 1, we split into 2 columns: picks 1-16 and 17-32
  if (round == 1) {
    return _buildTwoColumnLayout(picks, isDarkMode);
  } 
  // For rounds 2-3, we do 3 columns
  else if (round <= 3) {
    return _buildTwoColumnLayout(picks, isDarkMode);
  }
  // For later rounds, do 4 columns for more compact display
  else {
    return _buildTwoColumnLayout(picks, isDarkMode);
  }
}

Widget _buildTwoColumnLayout(List<DraftPick> picks, bool isDarkMode) {
  // Create row with two columns
  List<DraftPick> leftColumnPicks = [];
  List<DraftPick> rightColumnPicks = [];
  
  // Determine the midpoint
  int midpoint = (picks.length / 2).ceil();
  
  // Split the picks
  for (int i = 0; i < picks.length; i++) {
    if (i < midpoint) {
      leftColumnPicks.add(picks[i]);
    } else {
      rightColumnPicks.add(picks[i]);
    }
  }
  
  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // Left column
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ...leftColumnPicks.map((pick) => 
              Padding(
                padding: const EdgeInsets.only(bottom: 2.0), // Reduced from 4.0
                child: _buildPickRow(pick, isDarkMode),
              )
            ),
          ],
        ),
      ),
      
      // Divider
      Container(
        margin: const EdgeInsets.symmetric(horizontal: 4.0), // Reduced from 8.0
        width: 1,
        color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
      ),
      
      // Right column
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ...rightColumnPicks.map((pick) => 
              Padding(
                padding: const EdgeInsets.only(bottom: 2.0), // Reduced from 4.0
                child: _buildPickRow(pick, isDarkMode),
              )
            ),
          ],
        ),
      ),
    ],
  );
}

Widget _buildMultiColumnLayout(List<DraftPick> picks, int columns, bool isDarkMode) {
  // Calculate items per column, ensuring equal distribution
  int itemsPerColumn = (picks.length / columns).ceil();
  
  // Create list of columns
  List<List<DraftPick>> columnPicks = List.generate(columns, (index) => []);
  
  // Distribute picks across columns
  for (int i = 0; i < picks.length; i++) {
    int columnIndex = i ~/ itemsPerColumn;
    if (columnIndex < columns) {
      columnPicks[columnIndex].add(picks[i]);
    }
  }
  
  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      for (int i = 0; i < columns; i++) ...[
        if (i > 0)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 4.0),
            width: 1,
            color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
          ),
        
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (columnPicks[i].isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0, left: 4.0),
                  child: Text(
                    'Picks ${columnPicks[i].first.pickNumber} - ${columnPicks[i].last.pickNumber}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: isDarkMode ? Colors.grey.shade300 : Colors.grey.shade700,
                    ),
                  ),
                ),
              ...columnPicks[i].map((pick) => 
                Padding(
                  padding: const EdgeInsets.only(bottom: 4.0),
                  child: _buildPickRow(pick, isDarkMode),
                )
              ),
            ],
          ),
        ),
      ],
    ],
  );
}

Widget _buildPickRow(DraftPick pick, bool isDarkMode) {
  if (pick.selectedPlayer == null) {
    return const SizedBox(height: 0);
  }
  
  // Calculate detailed pick grade
  Map<String, dynamic> gradeInfo = _calculatePickGradeInfo(pick);
  String letterGrade = gradeInfo['letter'];
  int colorScore = gradeInfo['colorScore'];
  
  final bool isUserTeam = pick.teamName == widget.userTeam;
  
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 2.0),
    margin: const EdgeInsets.only(bottom: 2.0),
    decoration: BoxDecoration(
      color: isUserTeam 
          ? (isDarkMode ? Colors.blue.shade900.withOpacity(0.3) : Colors.blue.shade50) 
          : (isDarkMode ? Colors.grey.shade800.withOpacity(0.5) : Colors.grey.shade100),
      borderRadius: BorderRadius.circular(3),
      border: Border.all(
        color: isUserTeam
            ? (isDarkMode ? Colors.blue.shade700 : Colors.blue.shade300)
            : (isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300),
        width: 0.5,
      ),
    ),
    child: Row(
      children: [
        // Pick number and team logo in a block layout
        Container(
          height: 24,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: isDarkMode ? Colors.grey.shade600 : Colors.grey.shade300,
              width: 0.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Pick number
              Container(
                width: 18,
                height: 24,
                decoration: BoxDecoration(
                  color: _getPickNumberColor(pick.round),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(3.5),
                    bottomLeft: Radius.circular(3.5),
                  ),
                ),
                child: Center(
                  child: Text(
                    '${pick.pickNumber}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              // Team logo
              SizedBox(
                width: 20,
                height: 24,
                child: Center(
                  child: TeamLogoUtils.buildNFLTeamLogo(
                    pick.teamName,
                    size: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 3),
        
        // Player name, position, and college logo
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Player name
              Text(
                pick.selectedPlayer!.name,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 9,
                  color: isUserTeam ? Theme.of(context).primaryColor : null,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
              // Position and college in a row
              Row(
                children: [
                  // Position
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 0),
                    decoration: BoxDecoration(
                      color: _getPositionColor(pick.selectedPlayer!.position).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: Text(
                      pick.selectedPlayer!.position,
                      style: TextStyle(
                        fontSize: 6,
                        color: _getPositionColor(pick.selectedPlayer!.position),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 3),
                  // College name or logo
                  if (pick.selectedPlayer!.school.isNotEmpty)
                    SizedBox(
                      width: 10,
                      height: 10,
                      child: TeamLogoUtils.buildCollegeTeamLogo(
                        pick.selectedPlayer!.school,
                        size: 10,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
        
        // Grade badge (keep the same)
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 3,
            vertical: 1,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                _getGradientColor(colorScore, 0.2),
                _getGradientColor(colorScore, 0.3),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(2),
            border: Border.all(
              color: _getGradientColor(colorScore, 0.8),
              width: 0.5,
            ),
          ),
          child: Text(
            letterGrade,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 7,
              color: _getGradientColor(colorScore, 1.0),
            ),
          ),
        ),
      ],
    ),
  );
}

// Add this helper method for gradient colors
Color _getGradientColor(int score, double opacity) {
  // A grades (green)
  if (score > 95) return Colors.green.shade700.withOpacity(opacity);  // A+
  if (score == 95) return Colors.green.shade600.withOpacity(opacity);  // A
  if (score >= 90) return Colors.green.shade500.withOpacity(opacity);  // A-
  
  // B grades (blue)
  if (score > 85) return Colors.blue.shade700.withOpacity(opacity);   // B+
  if (score == 85) return Colors.blue.shade600.withOpacity(opacity);   // B
  if (score >= 80) return Colors.blue.shade500.withOpacity(opacity);   // B-
  
  // C grades (yellow)
  if (score > 75) return Colors.amber.shade500.withOpacity(opacity);  // C+
  if (score == 75) return Colors.amber.shade600.withOpacity(opacity);  // C
  if (score >= 70) return Colors.amber.shade700.withOpacity(opacity);  // C-

  // D grades (orange)
  if (score >= 60) return Colors.amber.shade900.withOpacity(opacity);  // C-

  // F grades (red)
  if (score >= 30) return Colors.red.shade600.withOpacity(opacity);    // D+/D
  return Colors.red.shade700.withOpacity(opacity);                     // F
}

// Helper method for calculating grade based on value differential
Map<String, dynamic> _calculatePickGradeInfo(DraftPick pick) {
  return DraftPickGradeService.calculatePickGrade(pick, widget.teamNeeds);
}

void _findValueAndReachPicks() {
  _valuePicks = [];
  _reachPicks = [];
  
  for (var pick in widget.completedPicks) {
    if (pick.selectedPlayer == null) continue;
    
    // Use the new grading system
    Map<String, dynamic> gradeInfo = DraftPickGradeService.calculatePickGrade(pick, widget.teamNeeds);    double score = gradeInfo['grade'];
    
    // Store relevant information
    Map<String, dynamic> pickData = {
      'team': pick.teamName,
      'player': pick.selectedPlayer!.name,
      'position': pick.selectedPlayer!.position,
      'pick': pick.pickNumber,
      'rank': pick.selectedPlayer!.rank,
      'diff': pick.pickNumber - pick.selectedPlayer!.rank,
      'score': score,
      'grade': gradeInfo['letter'],
      'colorScore': gradeInfo['colorScore'],
      'isUserTeam': pick.teamName == widget.userTeam,
    };
    
    // Categorize as value pick or reach
    if (score >= 7) {  // A-range and above
      _valuePicks.add(pickData);
    } else if (score <= -5) {  // C- and below
      _reachPicks.add(pickData);
    }
  }
  
  // Sort by grade score
  _valuePicks.sort((a, b) => b['score'].compareTo(a['score']));
  _reachPicks.sort((a, b) => a['score'].compareTo(b['score'])); // Most significant reaches first
}

// Helper method for pick number color
Color _getPickNumberColor(String round) {
  final isDarkMode = Theme.of(context).brightness == Brightness.dark;
  
  // Different colors for each round with dark mode adjustments
  switch (round) {
    case '1':
      return isDarkMode ? Colors.blue.shade600 : Colors.blue.shade700;
    case '2':
      return isDarkMode ? Colors.green.shade600 : Colors.green.shade700;
    case '3':
      return isDarkMode ? Colors.orange.shade600 : Colors.orange.shade700;
    case '4':
      return isDarkMode ? Colors.purple.shade600 : Colors.purple.shade700;
    case '5':
      return isDarkMode ? Colors.red.shade600 : Colors.red.shade700;
    case '6':
      return isDarkMode ? Colors.teal.shade600 : Colors.teal.shade700;
    case '7':
      return isDarkMode ? Colors.brown.shade600 : Colors.brown.shade700;
    default:
      return isDarkMode ? Colors.grey.shade600 : Colors.grey.shade700;
  }
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
  
  // Calculate grade for each team using the service
  for (var entry in teamPicks.entries) {
    String team = entry.key;
    List<DraftPick> picks = entry.value;
    
    // Get trades for this team
    List<TradePackage> teamTrades = widget.executedTrades.where(
      (trade) => trade.teamOffering == team || trade.teamReceiving == team
    ).toList();
    
    // Use the service for calculation
    Map<String, dynamic> gradeInfo = DraftGradeService.calculateTeamGrade(
      picks,
      teamTrades,
      widget.teamNeeds,
      debug: true
    );
    
    // Store team metrics (adapted to match the service output)
    _teamGrades[team] = {
      'grade': gradeInfo['grade'],
      'avgDiff': gradeInfo['value'],
      'combinedValue': gradeInfo['value'],
      'pickCount': picks.length,
      'isUserTeam': team == widget.userTeam,
    };
  }
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

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
            Padding(
        padding: const EdgeInsets.fromLTRB(16.0, 12.0, 16.0, 4.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Draft Analytics",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
            ),
            // Add the export button here
            ExportButtonWidget(
              completedPicks: widget.completedPicks,
              teamNeeds: widget.teamNeeds,
              userTeam: widget.userTeam,
              executedTrades: widget.executedTrades,
              filterTeam: _selectedTeam,
              shareableCardKey: _shareableCardKey,
            ),
          ],
        ),
      ),
      // Add TabBar for Draft Results and Community Analytics
      TabBar(
  controller: _tabController,
  tabs: const [
    Tab(text: 'Draft Results'),
    Tab(text: 'Community Analytics'),
  ],
  // Add these properties to control the color in both dark and light modes
  labelColor: Theme.of(context).brightness == Brightness.dark 
      ? Colors.white 
      : Colors.black, // Black text for selected tab in light mode
  unselectedLabelColor: Theme.of(context).brightness == Brightness.dark 
      ? Colors.white70 
      : Colors.black54, // Grey text for unselected tabs
  indicatorColor: Theme.of(context).primaryColor, // Keep the indicator color
),
      
      // TabBarView with both tabs
      Expanded(
        child: TabBarView(
          controller: _tabController,
          children: [
            // First tab: Existing draft analytics
            SingleChildScrollView(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Round Summary
                  _buildSectionHeader("Round-by-Round Summary"),
                  _buildRoundSummary(),
                  
                  const SizedBox(height: 16),
                  
                  // Team Grades Section
                  _buildSectionHeader("Team Draft Grades"),
                  _buildTeamGradesTable(),
                  
                  const SizedBox(height: 16),
                  
                  // Value Picks Section
                  _buildSectionHeader("Best Value Picks"),
                  _buildValuePicksList(true), // true for value picks
                  
                  const SizedBox(height: 16),
                  
                  // Reach Picks Section
                  _buildSectionHeader("Biggest Reaches"),
                  _buildValuePicksList(false), // false for reach picks
                  
                  const SizedBox(height: 16),
                  
                  // Position Runs Section
                  _buildSectionHeader("Position Runs"),
                  _buildPositionRunsList(),
                  
                  const SizedBox(height: 16),
                  
                  // Position Distribution
                  _buildSectionHeader("Position Distribution"),
                  _buildPositionDistribution(),
                  Offstage(
  offstage: true, // Hide it from view but still render it
  child: ShareableDraftCard(
    picks: widget.completedPicks,
    userTeam: _selectedTeam == 'All Teams' ? widget.userTeam : _selectedTeam,
    teamNeeds: widget.teamNeeds,
    cardKey: _shareableCardKey,
  ),
),
                ],
              ),
            ),
            
            // Second tab: Community analytics
            widget.userTeam != null
                ? CommunityAnalyticsDashboard(
                    userTeam: widget.userTeam!,
                    draftYear: widget.draftYear,
                    allTeams: _getAllTeams(), // Add this line
                  )
                : const Center(
                    child: Text('Please select a team to view community analytics'),
                  ),
          ],
        ),
      ),
    ],
  );
}
  
Widget _buildSectionHeader(String title, {bool showExportButton = false}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 6.0),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).primaryColor,
          ),
        ),
        // Add the export button if this is the Round-by-Round Summary section
        if (title == "Round-by-Round Summary")
          ExportButtonWidget(
            completedPicks: widget.completedPicks,
            teamNeeds: widget.teamNeeds,
            userTeam: widget.userTeam,
            executedTrades: widget.executedTrades,
            filterTeam: _selectedTeam,
            shareableCardKey: _shareableCardKey,
          ),
      ],
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
            final letterGrade = pick['grade'];
            final colorScore = pick['colorScore'];
            
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
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Value differential
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: (diff >= 0 ? Colors.green : Colors.red).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(3),
                      border: Border.all(
                        color: (diff >= 0 ? Colors.green : Colors.red).withOpacity(0.5),
                        width: 0.5,
                      ),
                    ),
                    child: Text(
                      diff >= 0 ? '+$diff' : '$diff',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: diff >= 0 ? Colors.green.shade700 : Colors.red.shade700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  
                  // Grade
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          _getGradientColor(colorScore, 0.2),
                          _getGradientColor(colorScore, 0.3),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: _getGradientColor(colorScore, 0.8),
                        width: 0.5,
                      ),
                    ),
                    child: Text(
                      letterGrade,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: _getGradientColor(colorScore, 1.0),
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

  List<String> _getAllTeams() {
  // Extract all unique team names from draft picks
  final teams = widget.completedPicks
      .map((pick) => pick.teamName)
      .toSet()
      .toList();
  
  // Sort alphabetically
  teams.sort();
  
  return teams;
}
}