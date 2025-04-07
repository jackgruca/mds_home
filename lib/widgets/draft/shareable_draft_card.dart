import 'dart:math';

import 'package:flutter/material.dart';
import '../../models/draft_pick.dart';
import '../../models/team_need.dart';
import '../../utils/team_logo_utils.dart';
import '../../services/draft_pick_grade_service.dart';

import 'package:flutter/material.dart';
import '../../utils/constants.dart';

// Update the ShareableDraftCard class
class ShareableDraftCard extends StatelessWidget {
  final List<DraftPick> picks;
  final String? userTeam;
  final List<TeamNeed> teamNeeds;
  final String exportMode; // "your_picks", "first_round", or "full_draft"
  final GlobalKey cardKey;

  const ShareableDraftCard({
    super.key,
    required this.picks,
    this.userTeam,
    required this.teamNeeds,
    this.exportMode = "full_draft",
    required this.cardKey,
  });

  @override
  Widget build(BuildContext context) {
    // Filter picks based on exportMode
    List<DraftPick> filteredPicks = [];
    
    if (exportMode == "your_picks" && userTeam != null) {
      filteredPicks = picks.where((pick) => 
        pick.teamName == userTeam && pick.selectedPlayer != null
      ).toList();
    } else if (exportMode == "first_round") {
      filteredPicks = picks.where((pick) => 
        pick.round == '1' && pick.selectedPlayer != null
      ).toList();
    } else {
      filteredPicks = picks.where((pick) => 
        pick.selectedPlayer != null
      ).toList();
    }
    
    // Sort by pick number
    filteredPicks.sort((a, b) => a.pickNumber.compareTo(b.pickNumber));
    
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      color: isDarkMode ? Colors.grey.shade900 : Colors.white,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with logo and title
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.red.shade700,
                  Colors.red.shade900,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Row(
              children: [
                // Logo or Icon
                const Icon(
                  Icons.sports_football,
                  color: Colors.white,
                  size: 32,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getTitle(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                      Text(
                        "Draft Results by StickToTheModel",
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Content depends on export mode
          if (filteredPicks.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Center(
                child: Text(
                  "No picks available for this selection",
                  style: TextStyle(
                    fontSize: 16,
                    color: isDarkMode ? Colors.white70 : Colors.black54,
                  ),
                ),
              ),
            )
          else if (exportMode == "first_round") 
            _buildFirstRoundLayout(filteredPicks, context)
          else
            _buildPicksList(filteredPicks, context),
            
          // Footer - always include this
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.amber.shade300, // Warning stripe color
              border: const Border(
                top: BorderSide(
                  color: Colors.black,
                  width: 4,
                ),
                bottom: BorderSide(
                  color: Colors.black,
                  width: 4,
                ),
              ),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "STICKTOTHEMODEL.COM",
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Update the first round layout for better appearance
  Widget _buildFirstRoundLayout(List<DraftPick> picks, BuildContext context) {
    // Create two columns for better layout
    List<DraftPick> leftColumn = [];
    List<DraftPick> rightColumn = [];
    
    for (int i = 0; i < picks.length; i++) {
      if (i < 16) {
        leftColumn.add(picks[i]);
      } else {
        rightColumn.add(picks[i]);
      }
    }
    
    // Full-width container to ensure proper display
    return Container(
      width: double.infinity,
      color: Theme.of(context).brightness == Brightness.dark 
          ? Colors.grey.shade900 
          : Colors.grey.shade50,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left column - first 16 picks
            Expanded(
              child: Column(
                children: leftColumn.map((pick) => 
                  _buildFirstRoundPickCard(pick, context)
                ).toList(),
              ),
            ),
            
            // Small divider
            const SizedBox(width: 8),
            
            // Right column - remaining picks
            Expanded(
              child: Column(
                children: rightColumn.map((pick) => 
                  _buildFirstRoundPickCard(pick, context)
                ).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Optimized card for first round display
  Widget _buildFirstRoundPickCard(DraftPick pick, BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final isUserTeam = pick.teamName == userTeam;
    final valueDiff = pick.pickNumber - pick.selectedPlayer!.rank;
    final valueDiffText = valueDiff >= 0 ? "(+$valueDiff)" : "($valueDiff)";
    final valueDiffColor = valueDiff >= 0 ? Colors.green : Colors.red;
    
    // Grade calculation
    final gradeInfo = DraftPickGradeService.calculatePickGrade(pick, teamNeeds);
    final letterGrade = gradeInfo['letter'] as String;
    
    // Don't use transparency to avoid rendering issues
    final cardColor = isUserTeam
        ? (isDarkMode ? Colors.blue.shade900 : Colors.blue.shade50)
        : (isDarkMode ? Colors.grey.shade800 : Colors.white);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(6.0),
        child: Row(
          children: [
            // Pick number
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.blue.shade600,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  "${pick.pickNumber}",
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            
            // Team logo
            SizedBox(
              width: 24,
              height: 24,
              child: TeamLogoUtils.buildNFLTeamLogo(
                pick.teamName,
                size: 24,
              ),
            ),
            const SizedBox(width: 8),
            
            // Player details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Player name
                  Text(
                    pick.selectedPlayer!.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  // Position, school, rank
                  Row(
                    children: [
                      // Position badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        decoration: BoxDecoration(
                          color: _getPositionColor(pick.selectedPlayer!.position),
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: Text(
                          pick.selectedPlayer!.position,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      
                      // School
                      Text(
                        pick.selectedPlayer!.school,
                        style: TextStyle(
                          color: isDarkMode ? Colors.white70 : Colors.grey.shade700,
                          fontSize: 10,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      
                      const SizedBox(width: 4),
                      
                      // Rank display
                      Text(
                        "Rank: #${pick.selectedPlayer!.rank}",
                        style: TextStyle(
                          fontSize: 10,
                          color: valueDiffColor,
                        ),
                      ),
                      const SizedBox(width: 2),
                      Text(
                        valueDiffText,
                        style: TextStyle(
                          fontSize: 10,
                          color: valueDiffColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Grade badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: _getGradeColor(letterGrade).withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: _getGradeColor(letterGrade),
                  width: 1,
                ),
              ),
              child: Text(
                letterGrade,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: _getGradeColor(letterGrade),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getTitle() {
    if (exportMode == "your_picks" && userTeam != null) {
      return "$userTeam Draft Results";
    } else if (exportMode == "first_round") {
      return "First Round Draft Results";
    } else {
      return "NFL Draft Results";
    }
  }

  // Helper for position colors
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

  // Helper for grade colors
  Color _getGradeColor(String grade) {
    if (grade.startsWith('A')) return Colors.green.shade700;
    if (grade.startsWith('B')) return Colors.blue.shade700;
    if (grade.startsWith('C')) return Colors.orange.shade700;
    return Colors.red.shade700;
  }

  // Regular picks list for non-first round views
  Widget _buildPicksList(List<DraftPick> picks, BuildContext context) {
    return Container(
      width: double.infinity,
      color: Theme.of(context).brightness == Brightness.dark 
          ? Colors.grey.shade900 
          : Colors.grey.shade50,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: picks.map((pick) => 
            _buildPickCard(pick, context)
          ).toList(),
        ),
      ),
    );
  }

  // Regular pick card for non-first round views
  Widget _buildPickCard(DraftPick pick, BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final isUserTeam = pick.teamName == userTeam;
    final valueDiff = pick.pickNumber - pick.selectedPlayer!.rank;
    final valueDiffText = valueDiff >= 0 ? "(+$valueDiff)" : "($valueDiff)";
    final valueDiffColor = valueDiff >= 0 ? Colors.green : Colors.red;
    
    // Grade calculation
    final gradeInfo = DraftPickGradeService.calculatePickGrade(pick, teamNeeds);
    final letterGrade = gradeInfo['letter'] as String;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isUserTeam
            ? (isDarkMode ? Colors.blue.shade900 : Colors.blue.shade50)
            : (isDarkMode ? Colors.grey.shade800 : Colors.white),
        borderRadius: BorderRadius.circular(6),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          // Pick number
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _getPickNumberColor(pick.round),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                "${pick.pickNumber}",
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          
          // Team logo
          SizedBox(
            width: 32,
            height: 32,
            child: TeamLogoUtils.buildNFLTeamLogo(
              pick.teamName,
              size: 32,
            ),
          ),
          const SizedBox(width: 12),
          
          // Player details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  pick.selectedPlayer!.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: _getPositionColor(pick.selectedPlayer!.position),
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: Text(
                        pick.selectedPlayer!.position,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      pick.selectedPlayer!.school,
                      style: TextStyle(
                        color: isDarkMode ? Colors.white70 : Colors.grey.shade700,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "Rank: #${pick.selectedPlayer!.rank}",
                      style: TextStyle(
                        fontSize: 12,
                        color: valueDiffColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      valueDiffText,
                      style: TextStyle(
                        fontSize: 12,
                        color: valueDiffColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Grade
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _getGradeColor(letterGrade).withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: _getGradeColor(letterGrade),
                width: 1,
              ),
            ),
            child: Text(
              letterGrade,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: _getGradeColor(letterGrade),
              ),
            ),
          ),
        ],
      ),
    );
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
}