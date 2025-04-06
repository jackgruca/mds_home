// lib/widgets/draft/shareable_draft_card.dart
import 'package:flutter/material.dart';
import '../../models/draft_pick.dart';
import '../../utils/team_logo_utils.dart';
import '../../services/draft_pick_grade_service.dart';
import '../../models/team_need.dart';

class ShareableDraftCard extends StatelessWidget {
  final List<DraftPick> picks;
  final String? userTeam;
  final List<TeamNeed> teamNeeds;
  final GlobalKey cardKey;
  
  const ShareableDraftCard({
    super.key,
    required this.picks,
    this.userTeam,
    required this.teamNeeds,
    required this.cardKey,
  });
  
  @override
  Widget build(BuildContext context) {
    // Filter to user team picks or top picks overall
    final displayPicks = userTeam != null 
        ? picks.where((p) => p.teamName == userTeam && p.selectedPlayer != null).take(6).toList()
        : picks.where((p) => p.selectedPlayer != null).take(5).toList();
    
    // Get most common draft positions for header stats
    final positionCounts = _getPositionCounts(picks);
    final topPositions = positionCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return RepaintBoundary(
      key: cardKey,
      child: Container(
        width: 600,  // Card width
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFD50A0A),  // NFL red
              Color(0xFF002244),  // NFL navy
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              children: [
                const Text(
                  "2025 NFL MOCK DRAFT",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                  ),
                ),
                const Spacer(),
                Text(
                  "StickToTheModel",
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // User team section if applicable
            if (userTeam != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 32,
                      height: 32,
                      child: TeamLogoUtils.buildNFLTeamLogo(
                        userTeam!,
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      userTeam!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const Spacer(),
                    // Top drafted position
                    if (topPositions.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getPositionColor(topPositions.first.key).withOpacity(0.8),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          "${topPositions.first.key}: ${topPositions.first.value}",
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
            ],
            
            // Draft picks
            ...displayPicks.map((pick) => _buildPickRow(pick, context)),
            
            // Footer
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.phone_android, color: Colors.white, size: 14),
                  const SizedBox(width: 6),
                  Text(
                    "Create your own mock draft at yourdomain.com",
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
    );
  }
  
  Widget _buildPickRow(DraftPick pick, BuildContext context) {
    // Calculate grade for this pick
    Map<String, dynamic> gradeInfo = DraftPickGradeService.calculatePickGrade(pick, teamNeeds);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          // Pick number
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                "${pick.pickNumber}",
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          
          // Player information
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  pick.selectedPlayer!.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  overflow: TextOverflow.ellipsis,
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
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      pick.selectedPlayer!.school,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 12,
                      ),
                      overflow: TextOverflow.ellipsis,
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
              color: _getGradeColor(gradeInfo['letter']).withOpacity(0.2),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: _getGradeColor(gradeInfo['letter']).withOpacity(0.7),
                width: 1,
              ),
            ),
            child: Text(
              gradeInfo['letter'],
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Map<String, int> _getPositionCounts(List<DraftPick> picks) {
    Map<String, int> counts = {};
    for (var pick in picks) {
      if (pick.selectedPlayer != null) {
        String position = pick.selectedPlayer!.position;
        counts[position] = (counts[position] ?? 0) + 1;
      }
    }
    return counts;
  }
  
  Color _getPositionColor(String position) {
    // Return color based on position
    switch (position.toUpperCase()) {
      case 'QB': case 'RB': case 'FB': 
        return Colors.blue.shade700;
      case 'WR': case 'TE': 
        return Colors.green.shade700;
      case 'OT': case 'IOL': case 'OL': case 'G': case 'C': 
        return Colors.purple.shade700;
      case 'EDGE': case 'DL': case 'IDL': case 'DT': case 'DE': 
        return Colors.red.shade700;
      case 'LB': case 'ILB': case 'OLB': 
        return Colors.orange.shade700;
      case 'CB': case 'S': case 'FS': case 'SS': 
        return Colors.teal.shade700;
      default: 
        return Colors.grey.shade700;
    }
  }
  
  Color _getGradeColor(String grade) {
    // Return color based on grade
    if (grade.startsWith('A+')) return Colors.green.shade700;
    if (grade.startsWith('A')) return Colors.green.shade600;
    if (grade.startsWith('B+')) return Colors.blue.shade700;
    if (grade.startsWith('B')) return Colors.blue.shade600;
    if (grade.startsWith('C+')) return Colors.orange.shade700;
    if (grade.startsWith('C')) return Colors.orange.shade600;
    if (grade.startsWith('D')) return Colors.deepOrange.shade700;
    return Colors.red.shade700; // F
  }
}