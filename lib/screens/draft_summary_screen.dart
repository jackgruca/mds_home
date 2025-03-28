// lib/screens/draft_summary_screen.dart
import 'package:flutter/material.dart';
import 'dart:math';
import '../models/draft_pick.dart';
import '../models/player.dart';
import '../models/team_need.dart';
import '../models/trade_package.dart';
import '../services/draft_value_service.dart';
import '../utils/constants.dart';
import '../utils/team_logo_utils.dart'; // Added for school logos
import '../services/draft_pick_grade_service.dart';
import '../widgets/common/export_button_widget.dart';


class DraftSummaryScreen extends StatefulWidget {
  final List<DraftPick> completedPicks;
  final List<Player> draftedPlayers;
  final List<TradePackage> executedTrades;
  final List<String> allTeams;
  final String? userTeam;
  final List<DraftPick> allDraftPicks;
  final String? initialFilter;
  final List<TeamNeed> teamNeeds; // Add this line

  const DraftSummaryScreen({
    super.key,
    required this.completedPicks,
    required this.draftedPlayers,
    required this.executedTrades,
    required this.allTeams,
    this.userTeam,
    required this.allDraftPicks,
    this.initialFilter,
    required this.teamNeeds, // Add this line
  });

  @override
  State<DraftSummaryScreen> createState() => _DraftSummaryScreenState();
}

class _DraftSummaryScreenState extends State<DraftSummaryScreen> {
  String? _selectedTeam;
  int _selectedRound = 1; 
  final GlobalKey _screenshotKey = GlobalKey(); // Add this line

  // Calculate pick grade based on value differential
Map<String, dynamic> _calculateDetailedPickGrade(DraftPick pick, List<TeamNeed> teamNeeds) {
  return DraftPickGradeService.calculatePickGrade(pick, teamNeeds);
}

  @override
  void initState() {
    super.initState();
    // Always use the initialFilter if provided
    _selectedTeam = widget.initialFilter ?? widget.userTeam ?? "All Teams";
  }

// In lib/screens/draft_summary_screen.dart

Widget _buildFirstRoundTwoColumnLayout() {
  // Filter picks for just the first round
  List<DraftPick> firstRoundPicks = widget.completedPicks
      .where((pick) => int.tryParse(pick.round) == 1)
      .toList();
  
  // Sort by pick number
  firstRoundPicks.sort((a, b) => a.pickNumber.compareTo(b.pickNumber));
  
  // If no picks in this round, show a message
  if (firstRoundPicks.isEmpty) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Center(
          child: Text(
            'No picks found for Round 1',
            style: TextStyle(fontStyle: FontStyle.italic),
          ),
        ),
      ),
    );
  }
  
  final isDarkMode = Theme.of(context).brightness == Brightness.dark;
  
  // Split picks into two columns
  List<DraftPick> leftColumnPicks = [];
  List<DraftPick> rightColumnPicks = [];
  
  for (int i = 0; i < firstRoundPicks.length; i++) {
    if (firstRoundPicks[i].pickNumber <= 16) {
      leftColumnPicks.add(firstRoundPicks[i]);
    } else {
      rightColumnPicks.add(firstRoundPicks[i]);
    }
  }
  
  return Card(
    elevation: 2,
    child: Padding(
      padding: const EdgeInsets.all(6.0), // Reduced from 8.0
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left column - Picks 1-16
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ...leftColumnPicks.map((pick) => 
                  Padding(
                    padding: const EdgeInsets.only(bottom: 2.0), // Reduced from 4.0
                    child: _buildCompactPickRow(pick, isDarkMode),
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
          
          // Right column - Picks 17-32
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ...rightColumnPicks.map((pick) => 
                  Padding(
                    padding: const EdgeInsets.only(bottom: 2.0), // Reduced from 4.0
                    child: _buildCompactPickRow(pick, isDarkMode),
                  )
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}


// Step 2: Add this helper method to create compact pick rows for the two-column layout
Widget _buildCompactPickRow(DraftPick pick, bool isDarkMode) {
  if (pick.selectedPlayer == null) {
    return const SizedBox(height: 0);
  }

  Map<String, dynamic> gradeInfo = _calculateDetailedPickGrade(pick, widget.teamNeeds);
  
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 2.0),
    margin: const EdgeInsets.only(bottom: 2.0),
    decoration: BoxDecoration(
      color: isDarkMode ? Colors.grey.shade800.withOpacity(0.5) : Colors.grey.shade100,
      borderRadius: BorderRadius.circular(3),
      border: Border.all(
        color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
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
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 9,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
              // Position and college logo in a row
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
                  const SizedBox(width: 2),
                  // Rank
                  Text(
                    '#${pick.selectedPlayer!.rank}',
                    style: TextStyle(
                      fontSize: 6,
                      color: _getValueColor(pick.pickNumber - pick.selectedPlayer!.rank),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 3),
                  // College logo if school is specified
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
          padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                _getGradientColor(gradeInfo['colorScore'], 0.2),
                _getGradientColor(gradeInfo['colorScore'], 0.3),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(2),
            border: Border.all(
              color: _getGradientColor(gradeInfo['colorScore'], 0.8),
              width: 0.5,
            ),
          ),
          child: Text(
            gradeInfo['letter'],
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 7,
              color: _getGradientColor(gradeInfo['colorScore'], 1.0),
            ),
          ),
        ),
      ],
    ),
  );
}

  // Replace the Dialog.fullscreen with this custom-sized dialog implementation
// in the DraftSummaryScreen build method

@override
Widget build(BuildContext context) {
  final screenSize = MediaQuery.of(context).size;
  final isDarkMode = Theme.of(context).brightness == Brightness.dark;
  
  // Calculate dialog size - 80% width, 70% height positioned at bottom
  final dialogWidth = screenSize.width * 0.9;
  final dialogHeight = screenSize.height * 0.90;
  
  return Dialog(
    insetPadding: EdgeInsets.only(
      top: screenSize.height - dialogHeight - 20, // Position from top
      bottom: 20, // Bottom margin
      left: (screenSize.width - dialogWidth) / 2, // Center horizontally
      right: (screenSize.width - dialogWidth) / 2,
    ),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16.0),
    ),
    elevation: 8,
    backgroundColor: isDarkMode ? Colors.grey.shade900 : Colors.white,
    child: RepaintBoundary( // Add this line
      key: _screenshotKey, // Add this line
      child: Container(
      width: dialogWidth,
      height: dialogHeight,
      padding: const EdgeInsets.all(0),
      child: Column(
        children: [
          // Custom header with title and close button
          Container(
  decoration: BoxDecoration(
    color: isDarkMode ? Colors.grey.shade800 : Colors.blue.shade50,
    borderRadius: const BorderRadius.only(
      topLeft: Radius.circular(16.0),
      topRight: Radius.circular(16.0),
    ),
  ),
  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
  child: Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      const Text(
        'Draft Summary',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16.0,
        ),
      ),
      Row(
        children: [
          // Add Export Button
          ExportButtonWidget(
            completedPicks: widget.completedPicks,
            teamNeeds: widget.teamNeeds,
            userTeam: widget.userTeam,
            executedTrades: widget.executedTrades,
            filterTeam: _selectedTeam,
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.close, size: 18),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: () => Navigator.of(context).pop(),
          ),
         ],
      ),
    ],
  ),
),
          
          // More compact team filter dropdown
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0), // Reduced padding
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end, // Move to right
              children: [
                Text(
                  'Team:', 
                  style: TextStyle(
                    fontSize: 12, // Smaller font
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.grey.shade300 : Colors.grey.shade700,
                  )
                ),
                const SizedBox(width: 8),
                DropdownButton<String>(
                  value: _selectedTeam,
                  isDense: true, // Makes the dropdown more compact
                  hint: const Text('Select a team', style: TextStyle(fontSize: 12)),
                  style: const TextStyle(fontSize: 12), // Smaller font
                  iconSize: 16, // Smaller icon
                  underline: Container(
                    height: 1,
                    color: isDarkMode ? Colors.grey.shade600 : Colors.grey.shade400,
                  ),
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedTeam = newValue;
                    });
                  },
                  items: [
                    // Add "All Teams" as first option
                    const DropdownMenuItem<String>(
                      value: "All Teams",
                      child: Text("All Teams", style: TextStyle(fontWeight: FontWeight.bold)),
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
    ),
  );
}
  
  // Add this method to build the round selector
  Widget _buildRoundSelector() {
  // Get screen width to adjust layout
  final screenWidth = MediaQuery.of(context).size.width;
  final bool isNarrowScreen = screenWidth < 360;
  
  return SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (int i = 1; i <= min(7, _getMaxRound()); i++)
          Padding(
            padding: EdgeInsets.symmetric(horizontal: isNarrowScreen ? 2.0 : 4.0),
            child: ChoiceChip(
              label: Text(
                'R$i', // Shorter text for round
                style: TextStyle(
                  fontSize: isNarrowScreen ? 11 : 12,
                ),
              ),
              selected: _selectedRound == i,
              visualDensity: VisualDensity.compact, // More compact chips
              labelPadding: EdgeInsets.symmetric(
                horizontal: isNarrowScreen ? 4 : 8,
                vertical: 0,
              ),
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
  );
}

// Helper to get the maximum round in the completed picks
int _getMaxRound() {
  int maxRound = 1;
  for (var pick in widget.completedPicks) {
    int round = int.tryParse(pick.round) ?? 1;
    if (round > maxRound) maxRound = round;
  }
  return maxRound;
}

Widget _buildRoundSummary(int round) {
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
            'No picks found for Round $round',
            style: const TextStyle(fontStyle: FontStyle.italic),
          ),
        ),
      ),
    );
  }
  
  final isDarkMode = Theme.of(context).brightness == Brightness.dark;
  
  // Increase grid columns for first round to see all 32 picks
  final int crossAxisCount = round == 1 ? 4 : 2;
  
  // Adjust child aspect ratio based on round
  final double childAspectRatio = round == 1 ? 2.2 : 3.5;
  
  return Card(
    elevation: 2,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 4.0),
      child: Column(
        children: [
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              childAspectRatio: childAspectRatio,
              crossAxisSpacing: 4.0,
              mainAxisSpacing: 4.0,
            ),
            itemCount: roundPicks.length,
            itemBuilder: (context, index) {
              if (index < roundPicks.length) {
                return _buildPickCard(roundPicks[index], isDarkMode, round == 1);
              }
              return const SizedBox();
            },
          ),
        ],
      ),
    ),
  );
}

  Widget _buildPickCard(DraftPick pick, bool isDarkMode, bool isFirstRound) {
  if (pick.selectedPlayer == null) {
    return const SizedBox();
  }
  
  // Calculate detailed pick grade
  Map<String, dynamic> gradeInfo = _calculateDetailedPickGrade(pick, widget.teamNeeds);
  String letterGrade = gradeInfo['letter'];
  int colorScore = gradeInfo['colorScore'];
  
  // More compact dimensions for first round picks
  final double pickNumSize = isFirstRound ? 16 : 20;
  final double logoSize = isFirstRound ? 16 : 24;
  final double nameTextSize = isFirstRound ? 9 : 11;
  final double posTextSize = isFirstRound ? 7 : 9;
  final double gradeTextSize = isFirstRound ? 8 : 10;
  
  return GestureDetector(
    onTap: () => _showPickGradeDetails(pick, gradeInfo),
    child: Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
          width: 0.5,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: isFirstRound ? 2.0 : 4.0,
          vertical: isFirstRound ? 2.0 : 6.0,
        ),
        child: Row(
          children: [
            // Pick number
            Container(
              width: pickNumSize,
              height: pickNumSize,
              decoration: BoxDecoration(
                color: _getPickNumberColor(pick.round),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '${pick.pickNumber}',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isFirstRound ? 7 : posTextSize,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            SizedBox(width: isFirstRound ? 1 : 4),
            
            // Team logo
            SizedBox(
              width: logoSize,
              height: logoSize,
              child: TeamLogoUtils.buildNFLTeamLogo(
                pick.teamName,
                size: logoSize,
              ),
            ),
            SizedBox(width: isFirstRound ? 1 : 4),
            
            // Player name and position
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    pick.selectedPlayer!.name,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: nameTextSize,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: isFirstRound ? 2 : 3, 
                      vertical: isFirstRound ? 0 : 1
                    ),
                    decoration: BoxDecoration(
                      color: _getPositionColor(pick.selectedPlayer!.position).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: Text(
                      pick.selectedPlayer!.position,
                      style: TextStyle(
                        fontSize: posTextSize,
                        color: _getPositionColor(pick.selectedPlayer!.position),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Grade badge with gradient background based on color score
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: isFirstRound ? 3 : 6, 
                vertical: isFirstRound ? 0 : 1,
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
                  fontSize: gradeTextSize,
                  color: _getGradientColor(colorScore, 1.0),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

// Add this helper method to get a color for the gradient based on the score
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


  // New method to build a list of all user picks, including future picks
  // Updated _buildUserPicksList method for more compact cards
  // In lib/screens/draft_summary_screen.dart

// In lib/screens/draft_summary_screen.dart
// Update the _buildUserPicksList method

Widget _buildUserPicksList() {
  final isDarkMode = Theme.of(context).brightness == Brightness.dark;
  
  // Filter all picks for the user team
  List<DraftPick> userPicks = widget.allDraftPicks
      .where((pick) => pick.teamName == _selectedTeam && pick.isActiveInDraft)
      .toList();
  
  // Sort by pick number
  userPicks.sort((a, b) => a.pickNumber.compareTo(b.pickNumber));

  if (userPicks.isEmpty) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Text(
            'No picks found for $_selectedTeam',
            style: const TextStyle(fontStyle: FontStyle.italic),
          ),
        ),
      ),
    );
  }

  return ListView.builder(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    itemCount: userPicks.length,
    itemBuilder: (context, index) {
      final pick = userPicks[index];
      final bool pickMade = pick.selectedPlayer != null;
      
      Map<String, dynamic> gradeInfo = _calculateDetailedPickGrade(pick, widget.teamNeeds);
      String letterGrade = gradeInfo['letter'];
      int colorScore = gradeInfo['colorScore'];

      return Card(
        margin: const EdgeInsets.only(bottom: 8),
        // Highlight picked vs unpicked differently
        color: pickMade ? 
            (isDarkMode ? Colors.grey.shade800 : Colors.white) : 
            (isDarkMode ? Colors.grey.shade900.withOpacity(0.7) : Colors.grey.shade100),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6.0),
          side: BorderSide(
            color: pickMade ? 
              (isDarkMode ? Colors.green.shade700 : Colors.green.shade300) : 
              (isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300),
            width: pickMade ? 1.0 : 0.5,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 8.0),
          child: Row(
            children: [
              // COMBINED: Pick number with team logo
              Stack(
                alignment: Alignment.center,
                children: [
                  // Team logo as background
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: Colors.transparent,
                    child: TeamLogoUtils.buildNFLTeamLogo(
                      _selectedTeam!,
                      size: 28,
                    ),
                  ),
                  // Pick number overlay
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: _getPickNumberColor(pick.round).withOpacity(0.85),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${pick.pickNumber}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 8),
              
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Title row
                    Row(
                      children: [
                        Expanded(
                          child: pickMade ? 
                            // If pick was made, show the player name
                            Text(
                              pick.selectedPlayer!.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ) : 
                            // If pick not yet made, show "Upcoming Pick"
                            Text(
                              'Upcoming Pick',
                              style: TextStyle(
                                fontStyle: FontStyle.italic,
                                fontSize: 13,
                                color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                              ),
                            ),
                        ),
                        
                        // Grade for completed picks
                        if (pickMade)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  _getGradientColor(colorScore, 0.2),
                                  _getGradientColor(colorScore, 0.3),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(3),
                              border: Border.all(
                                color: _getGradientColor(colorScore, 0.8),
                                width: 0.5,
                              ),
                            ),
                            child: Text(
                              letterGrade,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                                color: _getGradientColor(colorScore, 1.0),
                              ),
                            ),
                          ),
                      ],
                    ),
                    
                    const SizedBox(height: 2),
                    
                    // Subtitle row with position and college logo
                    pickMade ? 
                      // For completed picks, show position and college
                      Row(
                        children: [
                          // Position badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: _getPositionColor(pick.selectedPlayer!.position),
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: Text(
                              pick.selectedPlayer!.position,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          
                          // College logo
                          if (pick.selectedPlayer!.school.isNotEmpty)
                            SizedBox(
                              width: 18,
                              height: 18,
                              child: _buildSchoolLogo(pick.selectedPlayer!.school),
                            ),
                          
                          const Spacer(),
                          
                          // Rank and value info
                          Text(
                            'Rank: #${pick.selectedPlayer!.rank}',
                            style: TextStyle(
                              fontSize: 10,
                              color: _getValueColor(pick.pickNumber - pick.selectedPlayer!.rank),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _getValueText(pick.pickNumber - pick.selectedPlayer!.rank),
                            style: TextStyle(
                              fontSize: 10,
                              color: _getValueColor(pick.pickNumber - pick.selectedPlayer!.rank),
                            ),
                          ),
                        ],
                      ) : 
                      // For upcoming picks, show original position or a placeholder
                      Row(
                        children: [
                          // Round indicator
                          Text(
                            'Round ${pick.round}',
                            style: TextStyle(
                              fontSize: 10,
                              color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                            ),
                          ),
                          
                          const Spacer(),
                          
                          if (pick.originalPickNumber != null)
                            Text(
                              'Original Pick #${pick.originalPickNumber}',
                              style: TextStyle(
                                fontSize: 10,
                                color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                              ),
                            ),
                        ],
                      ),
                  ],
                ),
              ),
              
              // Trailing - Trade info
              if (pick.tradeInfo != null && pick.tradeInfo!.isNotEmpty && pickMade)
                Tooltip(
                  message: pick.tradeInfo!,
                  child: const Icon(Icons.swap_horiz, color: Colors.orange, size: 16),
                ),
            ],
          ),
        ),
      );
    },
  );
}

  // In lib/screens/draft_summary_screen.dart
// Modify the _buildSummaryContent method

Widget _buildSummaryContent() {
  if (_selectedTeam == null) {
    return const Center(
      child: Text('Please select a team to view draft summary'),
    );
  }
  
  // Handle "All Teams" selection
  if (_selectedTeam == "All Teams") {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        bottomLeft: Radius.circular(16),
        bottomRight: Radius.circular(16),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0), // Reduced padding
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // First Round Summary - 2 column layout (moved to top)
            const Text(
              'First Round Summary',
              style: TextStyle(
                fontSize: 16, // Smaller text
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6), // Reduced spacing
            _buildFirstRoundTwoColumnLayout(),
            
            const SizedBox(height: 12), // Reduced spacing
            
            // Team Grade Comparison
            const Text(
              'Team Grade Comparison',
              style: TextStyle(
                fontSize: 16, // Smaller text
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6), // Reduced spacing
            _buildTeamGradeComparison(),
            
            const SizedBox(height: 12), // Reduced spacing
            
            // Draft Overview
            _buildAllTeamsGradeBanner(),
            
            const SizedBox(height: 12), // Reduced spacing
            
            // Best Value Picks across all teams
            const Text(
              'Best Value Picks',
              style: TextStyle(
                fontSize: 16, // Smaller text
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6), // Reduced spacing
            _buildBestValuePicksList(),
            
            const SizedBox(height: 12), // Reduced spacing
            
            // Position breakdown across all teams
            const Text(
              'Overall Position Breakdown',
              style: TextStyle(
                fontSize: 16, // Smaller text
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6), // Reduced spacing
            _buildOverallPositionBreakdown(),
            
            // Add some bottom padding for scrolling
            const SizedBox(height: 12), // Reduced spacing
          ],
        ),
      ),
    );
  }

  // Filter picks for selected team
  final teamCompletedPicks = widget.completedPicks.where(
    (pick) => pick.teamName == _selectedTeam && pick.selectedPlayer != null
  ).toList();
  
  // Sort by pick number
  teamCompletedPicks.sort((a, b) => a.pickNumber.compareTo(b.pickNumber));
  
  // Filter trades involving selected team
  final teamTrades = widget.executedTrades.where(
    (trade) => trade.teamOffering == _selectedTeam || trade.teamReceiving == _selectedTeam
  ).toList();
  
  // Calculate overall grade based on completed picks
  final gradeInfo = _calculateTeamGrade(teamCompletedPicks, teamTrades);
  
  return ClipRRect(
    // Add rounded corners to the scroll view
    borderRadius: const BorderRadius.only(
      bottomLeft: Radius.circular(16),
      bottomRight: Radius.circular(16),
    ),
    child: SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0), // Reduced padding
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Compact grade header at top
          _buildCompactGradeHeader(gradeInfo),
          
          // Team picks section - both completed and upcoming
          const Text(
            'Your Draft Picks',
            style: TextStyle(
              fontSize: 16, // Smaller text
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6), // Reduced spacing
          _buildUserPicksList(),
          
          // Team trades section (if any)
          if (teamTrades.isNotEmpty) ...[
            const SizedBox(height: 12), // Reduced spacing
            const Text(
              'Trades',
              style: TextStyle(
                fontSize: 16, // Smaller text
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6), // Reduced spacing
            _buildTeamTradesList(teamTrades),
          ],
          
          // Position breakdown
          const SizedBox(height: 12), // Reduced spacing
          const Text(
            'Position Breakdown',
            style: TextStyle(
              fontSize: 16, // Smaller text
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6), // Reduced spacing
          _buildPositionBreakdown(teamCompletedPicks),
          
          // Stats section at the bottom
          const SizedBox(height: 12), // Reduced spacing
          _buildStatsSection(gradeInfo, teamTrades),
          
          // Add some bottom padding for scrolling
          const SizedBox(height: 12), // Reduced spacing
        ],
      ),
    ),
  );
}

void _showPickGradeDetails(DraftPick pick, Map<String, dynamic> gradeInfo) {
  final factors = gradeInfo['factors'];
  final letterGrade = gradeInfo['letter'];
  final colorScore = gradeInfo['colorScore'];
  
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Row(
        children: [
          Text('Pick Analysis: ${pick.selectedPlayer!.name}'),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _getGradientColor(colorScore, 0.2),
                  _getGradientColor(colorScore, 0.4),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: _getGradientColor(colorScore, 0.8),
                width: 1.0,
              ),
            ),
            child: Text(
              letterGrade,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: _getGradientColor(colorScore, 1.0),
              ),
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Basics
              _buildDetailRow('Team', pick.teamName),
              _buildDetailRow('Position', pick.selectedPlayer!.position),
              _buildDetailRow('Pick Number', '#${pick.pickNumber}'),
              _buildDetailRow('Player Rank', '#${pick.selectedPlayer!.rank}'),
              
              const Divider(),
              
              // Value analysis
              Text(
                'Value Analysis',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Theme.of(context).primaryColor,
                ),
              ),
              const SizedBox(height: 8),
              
              _buildDetailRow(
                'Base Value Diff', 
                '${factors['baseValueDiff'] > 0 ? '+' : ''}${factors['baseValueDiff'].toString()}',
                valueColor: factors['baseValueDiff'] >= 0 ? Colors.green : Colors.red,
              ),
              _buildDetailRow(
                'Adjusted Value', 
                '${factors['adjustedValueDiff'] > 0 ? '+' : ''}${factors['adjustedValueDiff'].toStringAsFixed(1)}',
                valueColor: factors['adjustedValueDiff'] >= 0 ? Colors.green : Colors.red,
              ),
              
              const Divider(),
              
              // Position value
              Text(
                'Position Analysis',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Theme.of(context).primaryColor,
                ),
              ),
              const SizedBox(height: 8),
              
              _buildDetailRow(
                'Position Value Coefficient', 
                '${factors['positionCoefficient'].toStringAsFixed(2)}x',
                valueColor: factors['positionCoefficient'] >= 1.0 ? Colors.green : Colors.orange,
              ),
              
              // Team needs
              const Divider(),
              
              Text(
                'Team Needs Analysis',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Theme.of(context).primaryColor,
                ),
              ),
              const SizedBox(height: 8),
              
              _buildDetailRow(
                'Need Priority', 
                factors['needIndex'] >= 0 ? '${factors['needIndex'] + 1}' : 'Not in top needs',
                valueColor: factors['needIndex'] >= 0 && factors['needIndex'] < 3 ? 
                    Colors.green : (factors['needIndex'] >= 0 ? Colors.orange : Colors.red),
              ),
              _buildDetailRow(
                'Need Factor', 
                '${factors['needFactor'].toStringAsFixed(2)}x',
                valueColor: factors['needFactor'] > 1.0 ? Colors.green : Colors.grey,
              ),
              
              // Draft value
              const Divider(),
              
              Text(
                'Draft Value Analysis',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Theme.of(context).primaryColor,
                ),
              ),
              const SizedBox(height: 8),
              
              _buildDetailRow(
                'Pick Value', 
                factors['pickValue'].toStringAsFixed(1),
              ),
              _buildDetailRow(
                'Projected Value', 
                factors['projectedPickValue'].toStringAsFixed(1),
              ),
              _buildDetailRow(
                'Value Differential', 
                '${factors['draftValueDiff'] > 0 ? '+' : ''}${factors['draftValueDiff'].toStringAsFixed(2)}',
                valueColor: factors['draftValueDiff'] >= 0 ? Colors.green : Colors.red,
              ),
              
              // Other factors
              const Divider(),
              
              Text(
                'Other Factors',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Theme.of(context).primaryColor,
                ),
              ),
              const SizedBox(height: 8),
              
              _buildDetailRow(
                'Round', 
                '${factors['round']}',
              ),
              _buildDetailRow(
                'Round Expectation Factor', 
                '${factors['roundFactor'].toStringAsFixed(2)}x',
              ),
              
              // Summary
              const Divider(),
              
              Text(
                'Summary',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Theme.of(context).primaryColor,
                ),
              ),
              const SizedBox(height: 8),
              
              Text(
                DraftPickGradeService.getGradeDescription(gradeInfo),
                style: const TextStyle(fontSize: 14),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    ),
  );
}

Widget _buildDetailRow(String label, String value, {Color? valueColor}) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 4.0),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: valueColor,
          ),
        ),
      ],
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

  // Replace the _buildEnhancedGradeBanner method with this compact version
  // In lib/screens/draft_summary_screen.dart

Widget _buildCompactGradeHeader(Map<String, dynamic> gradeInfo) {
  final grade = gradeInfo['grade'];
  final isDarkMode = Theme.of(context).brightness == Brightness.dark;
  
  // Determine color based on grade
  Color gradeColor;
  if (grade.startsWith('A')) {
    gradeColor = Colors.green.shade700;
  } else if (grade.startsWith('B')) {
    gradeColor = Colors.blue.shade700;
  } else if (grade.startsWith('C')) {
    gradeColor = Colors.orange.shade700;
  } else if (grade.startsWith('N/A')) {
    gradeColor = Colors.grey.shade700;
  } else {
    gradeColor = Colors.red.shade700;
  }
  
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0), // Reduced padding
    margin: const EdgeInsets.only(bottom: 10), // Reduced margin
    decoration: BoxDecoration(
      color: isDarkMode ? Colors.grey.shade900 : Colors.grey.shade50,
      borderRadius: BorderRadius.circular(8.0),
      // Removed the border property entirely
    ),
    child: Row(
      children: [
        // Team Logo - Made smaller
        SizedBox(
          width: 36.0, // Reduced from 48.0
          height: 36.0, // Reduced from 48.0
          child: TeamLogoUtils.buildNFLTeamLogo(
            _selectedTeam!,
            size: 36.0, // Reduced from 48.0
          ),
        ),
        const SizedBox(width: 10), // Reduced spacing
        
        // Team Name - Made more compact
        Expanded(
          child: Text(
            _selectedTeam!,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18.0, // Reduced from 20.0
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        
        // Grade Display
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5), // Reduced padding
          decoration: BoxDecoration(
            color: gradeColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12), // Reduced from 16
            border: Border.all(
              color: gradeColor,
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'GRADE:',
                style: TextStyle(
                  fontSize: 10, // Reduced from 12
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.grey.shade300 : Colors.grey.shade700,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                grade,
                style: TextStyle(
                  fontSize: 16, // Reduced from 18
                  fontWeight: FontWeight.bold,
                  color: gradeColor,
                ),
              ),
            ],
          ),
        ),
      ],
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
        margin: const EdgeInsets.only(bottom: 8), // Reduced from 12
        child: Padding(
          padding: const EdgeInsets.all(10.0), // Reduced from 12.0
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Trade header
              Row(
                children: [
                  Icon(
                    isTrading ? Icons.arrow_upward : Icons.arrow_downward,
                    color: isTrading ? Colors.orange : Colors.green,
                    size: 14, // Reduced from 16
                  ),
                  const SizedBox(width: 6), // Reduced from 8
                  Text(
                    isTrading 
                        ? "Traded Up with ${trade.teamReceiving}" 
                        : "Traded Down with ${trade.teamOffering}",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13, // Reduced from default
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3), // Reduced padding
                    decoration: BoxDecoration(
                      color: valueDiff >= 0 ? Colors.green.shade100 : Colors.red.shade100,
                      borderRadius: BorderRadius.circular(3), // Reduced from 4
                      border: Border.all(
                        color: valueDiff >= 0 ? Colors.green.shade700 : Colors.red.shade700,
                        width: 0.5, // Thinner border
                      ),
                    ),
                    child: Text(
                      "${valueDiff > 0 ? "+" : ""}${valueDiff.toStringAsFixed(0)} pts",
                      style: TextStyle(
                        fontSize: 10, // Reduced from 12
                        fontWeight: FontWeight.bold,
                        color: valueDiff >= 0 ? Colors.green.shade700 : Colors.red.shade700,
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 6), // Reduced from 8
              
              // Trade description
              Text(
                trade.tradeDescription, 
                style: const TextStyle(fontSize: 12)), // Reduced from 13
            ],
          ),
        ),
      );
    },
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
  
  // Get color for pick grade
  Color _getGradeColor(String grade) {
  if (grade.startsWith('A')) return Colors.green.shade700;
  if (grade.startsWith('B')) return Colors.blue.shade700;
  if (grade.startsWith('C')) return Colors.orange.shade700;
  return Colors.red.shade700;
}
  
  // Color method for pick number background - handles rounds properly
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
  
  // Color method for position badges
  Color _getPositionColor(String position) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    // Different colors for different position groups with dark mode adjustments
    if (['QB', 'RB', 'FB'].contains(position)) {
      return isDarkMode ? Colors.blue.shade600 : Colors.blue.shade700; // Backfield
    } else if (['WR', 'TE'].contains(position)) {
      return isDarkMode ? Colors.green.shade600 : Colors.green.shade700; // Receivers
    } else if (['OT', 'IOL', 'OL', 'G', 'C'].contains(position)) {
      return isDarkMode ? Colors.purple.shade600 : Colors.purple.shade700; // O-Line
    } else if (['EDGE', 'DL', 'IDL', 'DT', 'DE'].contains(position)) {
      return isDarkMode ? Colors.red.shade600 : Colors.red.shade700; // D-Line
    } else if (['LB', 'ILB', 'OLB'].contains(position)) {
      return isDarkMode ? Colors.orange.shade600 : Colors.orange.shade700; // Linebackers
    } else if (['CB', 'S', 'FS', 'SS'].contains(position)) {
      return isDarkMode ? Colors.teal.shade600 : Colors.teal.shade700; // Secondary
    } else {
      return isDarkMode ? Colors.grey.shade600 : Colors.grey.shade700; // Special teams, etc.
    }
  }
  
  // Color method for value comparison
  Color _getValueColor(int valueDiff) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    if (valueDiff >= 15) {
      return isDarkMode ? Colors.green.shade400 : Colors.green.shade800; // Excellent value
    } else if (valueDiff >= 5) {
      return isDarkMode ? Colors.green.shade300 : Colors.green.shade600; // Good value
    } else if (valueDiff >= -5) {
      return isDarkMode ? Colors.blue.shade300 : Colors.blue.shade600; // Fair value
    } else if (valueDiff >= -15) {
      return isDarkMode ? Colors.orange.shade300 : Colors.orange.shade600; // Slight reach
    } else {
      return isDarkMode ? Colors.red.shade300 : Colors.red.shade600; // Significant reach
    }
  }
  
  // Helper to format value difference text
  String _getValueText(int valueDiff) {
    if (valueDiff > 0) return "(+$valueDiff)";
    if (valueDiff < 0) return "($valueDiff)";
    return "(0)";
  }

  // Add this method to create the stats section at the bottom
Widget _buildStatsSection(Map<String, dynamic> gradeInfo, List<TradePackage> teamTrades) {
  final valuePerPick = gradeInfo['value'];
  final description = gradeInfo['description'];
  final totalPicks = gradeInfo['pickCount'] ?? 0;
  final totalValue = (valuePerPick ?? 0) * totalPicks;
  final tradeCount = teamTrades.length;
  final isDarkMode = Theme.of(context).brightness == Brightness.dark;
  
  // Calculate net trade value
  double tradeValue = 0;
  for (var trade in teamTrades) {
    if (trade.teamOffering == _selectedTeam) {
      tradeValue -= trade.valueDifferential;
    } else {
      tradeValue += trade.valueDifferential;
    }
  }
  
  return Card(
    elevation: 1,
    margin: const EdgeInsets.only(top: 8),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8.0),
    ),
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Draft description
          Text(
            description,
            style: TextStyle(
              fontStyle: FontStyle.italic,
              color: isDarkMode ? Colors.grey.shade300 : Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 12),
          
          // Stats grid in 2 columns
          Row(
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
        ],
      ),
    ),
  );
}
  
  // Helper to build school logo
  Widget _buildSchoolLogo(String schoolName) {
    return TeamLogoUtils.buildCollegeTeamLogo(
      schoolName,
      size: 24.0,
      placeholderBuilder: (String name) => Center(
        child: Text(
          name.isNotEmpty ? name.substring(0, min(2, name.length)) : '?',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).brightness == Brightness.dark ? 
              Colors.white : Colors.black,
          ),
        ),
      ),
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
}