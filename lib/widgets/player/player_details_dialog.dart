// lib/widgets/player/player_details_dialog.dart
import 'package:flutter/material.dart';
import '../../models/player.dart';
import '../../utils/team_logo_utils.dart';
import '../../utils/constants.dart';

class PlayerDetailsDialog extends StatelessWidget {
  final Player player;
  
  const PlayerDetailsDialog({
    super.key,
    required this.player,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: contentBox(context, isDarkMode),
    );
  }


Widget contentBox(BuildContext context, bool isDarkMode) {
  final headerColor = _getPositionColor(player.position);
  final screenSize = MediaQuery.of(context).size;
  
  return Container(
    padding: EdgeInsets.zero,
    decoration: BoxDecoration(
      shape: BoxShape.rectangle,
      color: isDarkMode ? Colors.grey.shade800 : Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.3),
          offset: const Offset(0, 10),
          blurRadius: 10,
        ),
      ],
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        // Header with player name and position
        Container(
          decoration: BoxDecoration(
            color: headerColor.withOpacity(isDarkMode ? 0.7 : 0.2),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
          ),
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // School logo
              SizedBox(
                width: 60,
                height: 60,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    color: isDarkMode ? Colors.black12 : Colors.grey.shade200,
                    padding: const EdgeInsets.all(4),
                    child: player.school.isNotEmpty
                      ? TeamLogoUtils.buildCollegeTeamLogo(
                          player.school,
                          size: 52.0,
                        )
                      : const SizedBox(
                          width: 52,
                          height: 52,
                          child: Icon(Icons.school_outlined, size: 32),
                        ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              
              // Player name and position
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      player.name,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: headerColor.withOpacity(isDarkMode ? 0.3 : 0.5),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            player.position,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            player.school,
                            style: TextStyle(
                              fontSize: 14,
                              color: isDarkMode ? Colors.grey.shade300 : Colors.grey.shade700,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Close button
              IconButton(
                icon: Icon(
                  Icons.close,
                  color: isDarkMode ? Colors.white70 : Colors.grey.shade700,
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        ),
        
        // NEW COMPACT STATS BANNER
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          decoration: BoxDecoration(
            color: isDarkMode ? Colors.grey.shade900 : Colors.grey.shade50,
            border: Border(
              bottom: BorderSide(
                color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
                width: 1,
              ),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Rank
              _buildCompactStat(
            context,
            'Rank',
            '#${player.rank}',
            isDarkMode,
          ),
          
          Container(
            height: 24,
            width: 1,
            color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
          ),
          
          _buildCompactStat(
            context,
            'HT',
            player.formattedHeight,
            isDarkMode,
          ),
          
          Container(
            height: 24,
            width: 1,
            color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
          ),
          
          _buildCompactStat(
            context,
            'WT',
            player.formattedWeight,
            isDarkMode,
          ),
          
          Container(
            height: 24,
            width: 1,
            color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
          ),
          
          _buildCompactStat(
            context,
            '40',
            player.fortyTime != null && player.fortyTime!.isNotEmpty ? 
              "${player.fortyTime}s" : "N/A",
            isDarkMode,
            valueColor: player.fortyTime != null ? 
              _getFortyTimeColor(player.fortyTime!) : null,
          ),
          
          Container(
            height: 24,
            width: 1,
            color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
          ),
          
          _buildCompactStat(
            context,
            'RAS',
            player.formattedRAS,
            isDarkMode,
            valueColor: player.rasScore != null ? 
              _getRasColor(player.rasScore!) : null,
          ),
        ],
      ),
    ),
    
    // New row for additional measurements
    Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade100,
        border: Border(
          bottom: BorderSide(
            color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
            width: 1,
          ),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildCompactStat(
              context,
              '10 Yd',
              player.formattedTenYardSplit,
              isDarkMode,
            ),
            
            Container(
              height: 24,
              width: 1,
              color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
            ),
            
            _buildCompactStat(
              context,
              '20 Sh',
              player.formattedTwentyYardShuttle,
              isDarkMode,
            ),
            
            Container(
              height: 24,
              width: 1,
              color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
            ),
            
            _buildCompactStat(
              context,
              '3 Cone',
              player.formattedThreeConeDrill,
              isDarkMode,
            ),
            
            Container(
              height: 24,
              width: 1,
              color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
            ),
            
            _buildCompactStat(
              context,
              'Arm',
              player.formattedArmLength,
              isDarkMode,
            ),
            
            Container(
              height: 24,
              width: 1,
              color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
            ),
            
            _buildCompactStat(
              context,
              'Bench',
              player.formattedBenchPress,
              isDarkMode,
            ),
            
            Container(
              height: 24,
              width: 1,
              color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
            ),
            
            _buildCompactStat(
              context,
              'Broad',
              player.formattedBroadJump,
              isDarkMode,
            ),
            
            Container(
              height: 24,
              width: 1,
              color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
            ),
            
            _buildCompactStat(
              context,
              'Vert',
              player.formattedVerticalJump,
              isDarkMode,
            ),
            
            Container(
              height: 24,
              width: 1,
              color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
            ),
            
            _buildCompactStat(
              context,
              'Hand',
              player.formattedHandSize,
              isDarkMode,
            ),
            
            Container(
              height: 24,
              width: 1,
              color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
            ),
            
            _buildCompactStat(
              context,
              'Wing',
              player.formattedWingspan,
              isDarkMode,
            ),
          ],
        ),
      ),
    ),
  ],
),
        
        // Single scrollable content area
        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Scouting Report - Main description
                  const Text(
                    'Scouting Report',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDarkMode ? Colors.black12 : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
                      ),
                    ),
                    child: Text(
                      player.description ?? player.getDefaultDescription(),
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.5,
                        color: isDarkMode ? Colors.grey.shade300 : Colors.grey.shade800,
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Strengths and Weaknesses section in a single box
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Strengths
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.thumb_up,
                                  size: 16,
                                  color: Colors.green.shade700,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Strengths',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green.shade700,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(isDarkMode ? 0.1 : 0.05),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.green.withOpacity(isDarkMode ? 0.3 : 0.2),
                                ),
                              ),
                              child: Text(
                                player.strengths ?? 'No specific strengths listed',
                                style: TextStyle(
                                  fontSize: 13,
                                  height: 1.4,
                                  color: isDarkMode ? Colors.grey.shade300 : Colors.grey.shade800,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(width: 12),
                      
                      // Weaknesses
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.thumb_down,
                                  size: 16,
                                  color: Colors.red.shade700,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Weaknesses',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red.shade700,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(isDarkMode ? 0.1 : 0.05),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.red.withOpacity(isDarkMode ? 0.3 : 0.2),
                                ),
                              ),
                              child: Text(
                                player.weaknesses ?? 'No specific weaknesses listed',
                                style: TextStyle(
                                  fontSize: 13,
                                  height: 1.4,
                                  color: isDarkMode ? Colors.grey.shade300 : Colors.grey.shade800,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        
                // Footer
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDarkMode ? Colors.grey.shade900 : Colors.grey.shade50,
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(16),
              bottomRight: Radius.circular(16),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Draft Position: Not Selected',
                style: TextStyle(
                  fontStyle: FontStyle.italic,
                  color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade700,
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('Close'),
              ),
            ],
          ),
        ),
      ],
    ),
  )
}

Widget _buildCompactStat(
  BuildContext context, 
  String label, 
  String value, 
  bool isDarkMode,
  {Color? valueColor}
) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 4),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.normal,
            color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: valueColor ?? (isDarkMode ? Colors.white : Colors.black87),
          ),
        ),
      ],
    ),
  );
}

// Add these new helper methods at the end of the PlayerDetailsDialog class:

// New helper method for grid-style stat items
Widget _buildGridStatItem(
  BuildContext context, 
  String label, 
  String value, 
  bool isDarkMode, 
  {Color? ratingColor}
) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
    decoration: BoxDecoration(
      color: isDarkMode ? Colors.grey.shade800 : Colors.white,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(
        color: ratingColor != null 
            ? ratingColor.withOpacity(0.5) 
            : (isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300),
        width: ratingColor != null ? 1.5 : 1.0,
      ),
    ),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.normal,
            color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: ratingColor ?? (isDarkMode ? Colors.white : Colors.black87),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    ),
  );
}

// Helper for 40 time color
Color _getFortyTimeColor(String fortyTime) {
  double time = double.tryParse(fortyTime.replaceAll('s', '')) ?? 5.0;
  
  if (time <= 4.3) return Colors.green.shade700;
  if (time <= 4.4) return Colors.green.shade600;
  if (time <= 4.5) return Colors.green.shade500;
  if (time <= 4.6) return Colors.blue.shade600;
  if (time <= 4.7) return Colors.blue.shade500;
  if (time <= 4.8) return Colors.orange.shade600;
  if (time <= 4.9) return Colors.orange.shade700;
  return Colors.red.shade600;
}

// Helper for RAS color
Color _getRasColor(double ras) {
  if (ras >= 9.5) return Colors.green.shade700;
  if (ras >= 9.0) return Colors.green.shade600;
  if (ras >= 8.0) return Colors.green.shade500;
  if (ras >= 7.0) return Colors.blue.shade600;
  if (ras >= 6.0) return Colors.blue.shade500;
  if (ras >= 5.0) return Colors.orange.shade600;
  if (ras < 5.0) return Colors.red.shade600;
  return Colors.grey.shade700;
}

// Helper for grade color
Color _getGradeColor(String grade) {
  if (grade.startsWith('A+')) return Colors.green.shade700;
  if (grade.startsWith('A')) return Colors.green.shade600;
  if (grade.startsWith('B+')) return Colors.blue.shade700;
  if (grade.startsWith('B')) return Colors.blue.shade600;
  if (grade.startsWith('C+')) return Colors.orange.shade700;
  if (grade.startsWith('C')) return Colors.orange.shade600;
  if (grade.startsWith('D')) return Colors.red.shade600;
  return Colors.red.shade700;
}

// Player grade helper
String _getPlayerGrade(Player player) {
  // Simple algorithm based on rank and position importance
  if (player.rank <= 10) return 'A+';
  if (player.rank <= 20) return 'A';
  if (player.rank <= 32) return 'B+';
  if (player.rank <= 50) return 'B';
  if (player.rank <= 75) return 'C+';
  if (player.rank <= 100) return 'C';
  if (player.rank <= 150) return 'D';
  return 'F';
}

Widget _buildStrengthsWeaknesses(
  BuildContext context,
  String title,
  String content,
  IconData icon,
  Color color,
  bool isDarkMode,
) {
  return Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: color.withOpacity(isDarkMode ? 0.1 : 0.05),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(
        color: color.withOpacity(isDarkMode ? 0.3 : 0.2),
      ),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              color: color.withOpacity(isDarkMode ? 0.8 : 1.0),
              size: 16,
            ),
            const SizedBox(width: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color.withOpacity(isDarkMode ? 0.9 : 1.0),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Make this area scrollable with a fixed height
        SizedBox(
          height: 80, // Fixed height for scrollable area
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Text(
              content,
              style: TextStyle(
                fontSize: 12,
                height: 1.4,
                color: isDarkMode ? Colors.grey.shade300 : Colors.grey.shade800,
              ),
            ),
          ),
        ),
      ],
    ),
  );
}
  
  Color _getPositionColor(String position) {
    // Different colors for different position groups
    if (['QB', 'RB', 'FB'].contains(position)) {
      return Colors.blue.shade700; // Backfield
    } else if (['WR', 'TE'].contains(position)) {
      return Colors.green.shade700; // Receivers
    } else if (['OT', 'IOL', 'OL', 'G', 'C'].contains(position)) {
      return Colors.purple.shade700; // O-Line
    } 
    // Defensive position colors
    else if (['EDGE', 'DL', 'IDL', 'DT', 'DE'].contains(position)) {
      return Colors.red.shade700; // D-Line
    } else if (['LB', 'ILB', 'OLB'].contains(position)) {
      return Colors.orange.shade700; // Linebackers
    } else if (['CB', 'S', 'FS', 'SS'].contains(position)) {
      return Colors.teal.shade700; // Secondary
    }
    // Default color
    return Colors.grey.shade700;
  }

  Widget _buildStatCard(
  BuildContext context,
  String label,
  String value,
  IconData icon,
  bool isDarkMode, {
  bool hasRating = false,
  double? rating,
  bool isInverted = false,
}) {
  Color getColorForRating(double rating, bool isInverted) {
    if (isInverted) {
      // For 40 time, lower is better
      if (label == '40 Time') {
        double time = double.tryParse(value.replaceAll('s', '')) ?? 0;
        if (time <= 4.3) return Colors.green.shade800;
        if (time <= 4.4) return Colors.green.shade600;
        if (time <= 4.5) return Colors.green.shade400;
        if (time <= 4.6) return Colors.blue.shade500;
        if (time <= 4.7) return Colors.blue.shade300;
        if (time <= 4.8) return Colors.orange.shade400;
        if (time <= 4.9) return Colors.orange.shade600;
        return Colors.red.shade400;
      }
    } else {
      // For RAS and other ratings, higher is better
      if (rating >= 9.0) return Colors.green.shade800;
      if (rating >= 8.0) return Colors.green.shade600;
      if (rating >= 7.0) return Colors.green.shade400;
      if (rating >= 6.0) return Colors.blue.shade500;
      if (rating >= 5.0) return Colors.blue.shade300;
      if (rating >= 4.0) return Colors.orange.shade400;
      if (rating >= 3.0) return Colors.orange.shade600;
      return Colors.red.shade400;
    }
    return isDarkMode ? Colors.white70 : Colors.grey.shade700;
  }
  
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
    decoration: BoxDecoration(
      color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade100,
      borderRadius: BorderRadius.circular(8),
    ),
    child: Column(
      children: [
        Icon(
          icon,
          color: hasRating && rating != null 
              ? getColorForRating(rating, isInverted) 
              : (isDarkMode ? Colors.white70 : Colors.grey.shade700),
          size: 20,
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: hasRating && rating != null 
              ? getColorForRating(rating, isInverted) 
              : (isDarkMode ? Colors.white : Colors.black87),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isDarkMode ? Colors.grey.shade300 : Colors.grey.shade700,
          ),
        ),
      ],
    ),
  );
}

// Helper method to get a rating value for the 40 time
double _getFortyTimeRating(String fortyTime) {
  // Convert string to double, handling errors
  double time = double.tryParse(fortyTime.replaceAll('s', '')) ?? 5.0;
  
  // Map 40 time to a 0-10 scale where:
  // 4.2s = 10.0 (exceptional)
  // 5.0s = 0.0 (poor)
  if (time <= 4.2) return 10.0;
  if (time >= 5.0) return 0.0;
  
  // Linear mapping from 4.2-5.0 to 10.0-0.0
  return 10.0 - ((time - 4.2) * (10.0 / 0.8));
}
}