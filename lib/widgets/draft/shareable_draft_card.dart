import 'dart:math';

import 'package:flutter/material.dart';
import '../../models/draft_pick.dart';
import '../../models/team_need.dart';
import '../../utils/team_logo_utils.dart';
import '../../services/draft_pick_grade_service.dart';

import 'package:flutter/material.dart';
import '../../utils/constants.dart';

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
  
  // Calculate the height based on the number of picks and mode
  double cardHeight;
  if (exportMode == "first_round") {
    // Height for first round layout (accommodates 32 picks in 2 columns)
    cardHeight = min(900.0, 200.0 + filteredPicks.length * 28.0);
  } else if (exportMode == "your_picks") {
    // Height for user picks (taller cards)
    cardHeight = min(800.0, 200.0 + filteredPicks.length * 60.0);
  } else {
    // Height for full draft (could be very long)
    cardHeight = min(1200.0, 200.0 + filteredPicks.length * 20.0);
  }
  
  return RepaintBoundary(
    key: cardKey,
    child: Container(
      width: 800, // Fixed width
      height: cardHeight, // Calculated height
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey.shade900 : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
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
            
            // Footer
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Generated by StickToTheModel",
                    style: TextStyle(
                      color: isDarkMode ? Colors.white70 : Colors.black54,
                      fontSize: 11,
                    ),
                  ),
                  Text(
                    "yourdomain.com",
                    style: TextStyle(
                      color: isDarkMode ? Colors.white70 : Colors.black54,
                      fontSize: 11,
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

  String _getTitle() {
    if (exportMode == "your_picks" && userTeam != null) {
      return "$userTeam Draft Results";
    } else if (exportMode == "first_round") {
      return "First Round Draft Results";
    } else {
      return "2025 NFL Draft Results";
    }
  }

  // In shareable_draft_card.dart=
  // Update the ShareableDraftCard build method for first round layout
Widget _buildFirstRoundLayout(List<DraftPick> picks, BuildContext context) {
  // Create a two-column layout for first round picks
  List<DraftPick> leftColumn = [];
  List<DraftPick> rightColumn = [];
  
  for (int i = 0; i < picks.length; i++) {
    if (i < 16) {
      leftColumn.add(picks[i]);
    } else {
      rightColumn.add(picks[i]);
    }
  }
  
  // Make the layout scrollable if needed
  return ConstrainedBox(
    constraints: const BoxConstraints(
      maxHeight: 900, // Limit maximum height
    ),
    child: SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0), // Reduced padding
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                children: leftColumn.map((pick) => _buildCompactPickCard(pick, context)).toList(),
              ),
            ),
            const SizedBox(width: 8), // Reduced spacing
            Expanded(
              child: Column(
                children: rightColumn.map((pick) => _buildCompactPickCard(pick, context)).toList(),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

// Add a more compact card design specifically for the first round view
Widget _buildCompactPickCard(DraftPick pick, BuildContext context) {
  final isDarkMode = Theme.of(context).brightness == Brightness.dark;
  final isUserTeam = pick.teamName == userTeam;
  final valueDiff = pick.pickNumber - pick.selectedPlayer!.rank;
  
  // Get grade info
  final gradeInfo = DraftPickGradeService.calculatePickGrade(pick, teamNeeds);
  final letterGrade = gradeInfo['letter'];
  
  return Container(
    margin: const EdgeInsets.only(bottom: 4), // Reduced margin
    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8), // Reduced padding
    decoration: BoxDecoration(
      color: isUserTeam 
          ? (isDarkMode ? Colors.blue.shade900.withOpacity(0.2) : Colors.blue.shade50) 
          : (isDarkMode ? Colors.grey.shade800 : Colors.grey.shade100),
      borderRadius: BorderRadius.circular(6),
      border: Border.all(
        color: isUserTeam 
            ? (isDarkMode ? Colors.blue.shade700 : Colors.blue.shade200) 
            : (isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300),
        width: isUserTeam ? 1.0 : 0.5,
      ),
    ),
    child: Row(
      children: [
        // Pick number circle (smaller)
        Container(
          width: 28, // Smaller size
          height: 28, // Smaller size
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
                fontSize: 12, // Smaller font
              ),
            ),
          ),
        ),
        const SizedBox(width: 6), // Reduced spacing
        
        // Team logo (smaller)
        SizedBox(
          width: 24, // Smaller size
          height: 24, // Smaller size
          child: TeamLogoUtils.buildNFLTeamLogo(
            pick.teamName,
            size: 24,
          ),
        ),
        const SizedBox(width: 6), // Reduced spacing
        
        // Player details
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                pick.selectedPlayer!.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12, // Smaller font
                ),
                overflow: TextOverflow.ellipsis,
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1), // Smaller padding
                    decoration: BoxDecoration(
                      color: _getPositionColor(pick.selectedPlayer!.position),
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: Text(
                      pick.selectedPlayer!.position,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9, // Smaller font
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4), // Reduced spacing
                  Text(
                    pick.selectedPlayer!.school,
                    style: TextStyle(
                      color: isDarkMode ? Colors.white70 : Colors.black54,
                      fontSize: 9, // Smaller font
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(width: 4), // Reduced spacing
                  Text(
                    "Rank: #${pick.selectedPlayer!.rank}",
                    style: TextStyle(
                      fontSize: 9, // Smaller font
                      color: valueDiff >= 0 ? Colors.green : Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 2), // Reduced spacing
                  Text(
                    valueDiff >= 0 ? "(+$valueDiff)" : "($valueDiff)",
                    style: TextStyle(
                      fontSize: 9, // Smaller font
                      color: valueDiff >= 0 ? Colors.green : Colors.red,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        
        // Grade
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), // Smaller padding
          decoration: BoxDecoration(
            color: _getGradeColor(letterGrade).withOpacity(0.2),
            borderRadius: BorderRadius.circular(3),
            border: Border.all(color: _getGradeColor(letterGrade), width: 0.5), // Thinner border
          ),
          child: Text(
            letterGrade,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 10, // Smaller font
              color: _getGradeColor(letterGrade),
            ),
          ),
        ),
      ],
    ),
  );
}

  Widget _buildPicksList(List<DraftPick> picks, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: picks.map((pick) => _buildPickCard(pick, context)).toList(),
      ),
    );
  }

  Widget _buildPickCard(DraftPick pick, BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final isUserTeam = pick.teamName == userTeam;
    
    // Get grade info
    final gradeInfo = DraftPickGradeService.calculatePickGrade(pick, teamNeeds);
    final letterGrade = gradeInfo['letter'];
    final colorScore = gradeInfo['colorScore'];
    
    // Calculate value differential
    final valueDiff = pick.pickNumber - pick.selectedPlayer!.rank;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: isUserTeam 
            ? (isDarkMode ? Colors.blue.shade900.withOpacity(0.2) : Colors.blue.shade50) 
            : (isDarkMode ? Colors.grey.shade800 : Colors.grey.shade100),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isUserTeam 
              ? (isDarkMode ? Colors.blue.shade700 : Colors.blue.shade200) 
              : (isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300),
          width: isUserTeam ? 1.0 : 0.5,
        ),
      ),
      child: Row(
        children: [
          // Pick number circle
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
                        borderRadius: BorderRadius.circular(4),
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
                        color: isDarkMode ? Colors.white70 : Colors.black54,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "Rank: #${pick.selectedPlayer!.rank}",
                      style: TextStyle(
                        fontSize: 12,
                        color: valueDiff >= 0 ? Colors.green : Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 2),
                    Text(
                      valueDiff >= 0 ? "(+$valueDiff)" : "($valueDiff)",
                      style: TextStyle(
                        fontSize: 12,
                        color: valueDiff >= 0 ? Colors.green : Colors.red,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Grade
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _getGradeColor(letterGrade).withOpacity(0.2),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: _getGradeColor(letterGrade)),
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

  Color _getGradeColor(String grade) {
    if (grade.startsWith('A')) return Colors.green.shade700;
    if (grade.startsWith('B')) return Colors.blue.shade700;
    if (grade.startsWith('C')) return Colors.orange.shade700;
    return Colors.red.shade700;
  }
}