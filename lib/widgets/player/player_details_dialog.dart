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
  final isSmallScreen = screenSize.height < 600; // Adjust based on device height
  
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
        
        // Body with player details - make this scrollable
        Flexible(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Stats row - modified to include 40 time
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildStatCard(
                        context,
                        'Rank',
                        '#${player.rank}',
                        Icons.format_list_numbered,
                        isDarkMode,
                      ),
                      _buildStatCard(
                        context,
                        'Height',
                        player.formattedHeight,
                        Icons.height,
                        isDarkMode,
                      ),
                      _buildStatCard(
                        context,
                        'Weight',
                        player.formattedWeight,
                        Icons.fitness_center,
                        isDarkMode,
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // New row for 40 time and RAS
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildStatCard(
                        context,
                        '40 Time',
                        player.formatted40Time,
                        Icons.speed,
                        isDarkMode,
                        hasRating: player.fortyTime != null,
                        rating: player.fortyTime != null ? 
                          _getFortyTimeRating(player.fortyTime!) : null,
                        isInverted: true, // Lower 40 time is better
                      ),
                      _buildStatCard(
                        context,
                        'RAS',
                        player.formattedRAS,
                        Icons.fitness_center,
                        isDarkMode,
                        hasRating: player.rasScore != null,
                        rating: player.rasScore,
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Description/Analysis - make scrollable with a max height
                  Text(
                    'Scouting Report',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: isDarkMode ? Colors.black12 : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
                      ),
                    ),
                    padding: const EdgeInsets.all(12),
                    // Limit height and make it scrollable
                    constraints: BoxConstraints(
                      maxHeight: isSmallScreen ? 120 : 150,
                    ),
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Text(
                        player.description ?? player.getDefaultDescription(),
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.4,
                          color: isDarkMode ? Colors.grey.shade300 : Colors.grey.shade800,
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Strengths and weaknesses section
                  if (player.strengths != null || player.weaknesses != null) ...[
                    Row(
                      children: [
                        Expanded(
                          child: _buildStrengthsWeaknesses(
                            context,
                            'Strengths',
                            player.strengths ?? 'No specific strengths listed',
                            Icons.thumb_up,
                            Colors.green,
                            isDarkMode,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildStrengthsWeaknesses(
                            context,
                            'Weaknesses',
                            player.weaknesses ?? 'No specific weaknesses listed',
                            Icons.thumb_down,
                            Colors.red,
                            isDarkMode,
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
        ),
        
        // Footer actions
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
  );
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