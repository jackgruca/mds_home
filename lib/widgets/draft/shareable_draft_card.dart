import 'package:flutter/material.dart';
import '../../models/draft_pick.dart';
import '../../models/team_need.dart';
import '../../utils/team_logo_utils.dart';
import '../../services/draft_pick_grade_service.dart';

class ShareableDraftCard extends StatelessWidget {
  final List<DraftPick> picks;
  final String? userTeam;
  final List<TeamNeed> teamNeeds;
  final GlobalKey cardKey;

  const ShareableDraftCard({
    super.key,
    required this.picks,
    required this.userTeam,
    required this.teamNeeds,
    required this.cardKey,
  });

  @override
  Widget build(BuildContext context) {
    // Filter picks for the selected team if specified
    final filteredPicks = userTeam != null && userTeam != "All Teams"
        ? picks.where((p) => p.teamName == userTeam && p.selectedPlayer != null).toList()
        : picks.where((p) => p.selectedPlayer != null).take(10).toList();
    
    // Sort picks by pick number
    filteredPicks.sort((a, b) => a.pickNumber.compareTo(b.pickNumber));
    
    // Determine background color based on theme
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDarkMode ? const Color(0xFF121212) : Colors.white;
    
    return RepaintBoundary(
      key: cardKey,
      child: Container(
        width: 600, // Fixed width for consistent sharing
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Card header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDarkMode ? const Color(0xFF1E1E1E) : const Color(0xFFF5F5F5),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(8),
                  topRight: Radius.circular(8),
                ),
              ),
              child: Row(
                children: [
                  // Logo or icon
                  Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFFD50A0A), // NFL red color
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.sports_football,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Title
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          userTeam != null && userTeam != "All Teams"
                              ? "$userTeam Draft Results"
                              : "NFL Draft Results",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDarkMode ? Colors.white : Colors.black,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          "StickToTheModel Draft Simulator",
                          style: TextStyle(
                            fontSize: 12,
                            color: isDarkMode ? Colors.grey : Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // Picks list
            Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  for (int i = 0; i < filteredPicks.length; i++)
                    _buildPickRow(context, filteredPicks[i], i + 1),
                ],
              ),
            ),
            
            // Footer
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isDarkMode ? const Color(0xFF1E1E1E) : const Color(0xFFF5F5F5),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(8),
                  bottomRight: Radius.circular(8),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Generated with StickToTheModel",
                    style: TextStyle(
                      fontSize: 12,
                      color: isDarkMode ? Colors.grey : Colors.grey.shade700,
                    ),
                  ),
                  Text(
                    "yourdomain.com",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.white70 : Colors.black87,
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

  Widget _buildPickRow(BuildContext context, DraftPick pick, int index) {
    if (pick.selectedPlayer == null) return const SizedBox.shrink();
    
    // Calculate pick grade
    Map<String, dynamic> gradeInfo = DraftPickGradeService.calculatePickGrade(pick, teamNeeds);
    String letterGrade = gradeInfo['letter'];
    int colorScore = gradeInfo['colorScore'];
    
    // Value differential
    int valueDiff = pick.pickNumber - pick.selectedPlayer!.rank;
    
    // Determine if this is a user team pick
    final bool isUserTeam = userTeam != null && pick.teamName == userTeam;
    
    // Get theme brightness
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200,
            width: 1,
          ),
        ),
        color: isUserTeam 
            ? (isDarkMode ? Colors.blue.shade900.withOpacity(0.2) : Colors.blue.shade50) 
            : Colors.transparent,
      ),
      child: Row(
        children: [
          // Index number
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200,
            ),
            child: Center(
              child: Text(
                index.toString(),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : Colors.black,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          
          // Pick number and team info
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              "#${pick.pickNumber} ${pick.teamName}",
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : Colors.black,
              ),
            ),
          ),
          const SizedBox(width: 8),
          
          // Player info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  pick.selectedPlayer!.name,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.black,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color: _getPositionColor(pick.selectedPlayer!.position, isDarkMode).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: Text(
                        pick.selectedPlayer!.position,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: _getPositionColor(pick.selectedPlayer!.position, isDarkMode),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      pick.selectedPlayer!.school,
                      style: TextStyle(
                        fontSize: 10,
                        color: isDarkMode ? Colors.grey : Colors.grey.shade700,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Grade and value
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Grade
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
              const SizedBox(height: 2),
              // Value differential
              Text(
                "Value: ${valueDiff > 0 ? "+" : ""}$valueDiff",
                style: TextStyle(
                  fontSize: 10,
                  color: valueDiff >= 0 ? Colors.green : Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getPositionColor(String position, bool isDarkMode) {
    if (['QB', 'RB', 'FB'].contains(position)) {
      return isDarkMode ? Colors.blue.shade400 : Colors.blue.shade700;
    } else if (['WR', 'TE'].contains(position)) {
      return isDarkMode ? Colors.green.shade400 : Colors.green.shade700;
    } else if (['OT', 'IOL', 'OL', 'G', 'C'].contains(position)) {
      return isDarkMode ? Colors.purple.shade400 : Colors.purple.shade700;
    } else if (['EDGE', 'DL', 'IDL', 'DT', 'DE'].contains(position)) {
      return isDarkMode ? Colors.red.shade400 : Colors.red.shade700;
    } else if (['LB', 'ILB', 'OLB'].contains(position)) {
      return isDarkMode ? Colors.orange.shade400 : Colors.orange.shade700;
    } else if (['CB', 'S', 'FS', 'SS'].contains(position)) {
      return isDarkMode ? Colors.teal.shade400 : Colors.teal.shade700;
    } else {
      return isDarkMode ? Colors.grey.shade400 : Colors.grey.shade700;
    }
  }

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
}