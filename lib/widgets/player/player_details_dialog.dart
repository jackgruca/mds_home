// lib/widgets/player/player_details_dialog.dart
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../models/player.dart';
import '../../services/player_espn_id_service.dart';
import '../../utils/team_logo_utils.dart';

// In lib/widgets/player/player_details_dialog.dart
class PlayerDetailsDialog extends StatelessWidget {
  final Player player;
  final bool canDraft; // New parameter to determine if draft button should be shown
  final VoidCallback? onDraft; // New callback for when draft button is pressed
  
  const PlayerDetailsDialog({
    super.key,
    required this.player,
    this.canDraft = false, // Default to false
    this.onDraft,
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
  
  // Get player headshot URL
  String? headshotUrl;
  if (player.headshot != null && player.headshot!.isNotEmpty) {
    headshotUrl = player.headshot;
  } else {
    // Try to get ESPN ID for this player
    String? espnId = PlayerESPNIdService.getESPNId(player.name);
    if (espnId != null) {
      headshotUrl = PlayerESPNIdService.buildESPNImageUrl(espnId);
    }
  }
  
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
        // Header with player name, position and headshot
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
              // Player headshot - prioritize over school logo
              headshotUrl != null ? 
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CachedNetworkImage(
                    imageUrl: headshotUrl,
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      width: 80,
                      height: 80,
                      color: isDarkMode ? Colors.black12 : Colors.grey.shade200,
                      child: const Center(
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.0,
                          ),
                        ),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      width: 80,
                      height: 80,
                      color: isDarkMode ? Colors.black12 : Colors.grey.shade200,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.person,
                            size: 36,
                            color: isDarkMode ? Colors.grey.shade600 : Colors.grey.shade400,
                          ),
                          // Show small school logo as fallback
                          if (player.school.isNotEmpty)
                            SizedBox(
                              width: 24,
                              height: 24,
                              child: TeamLogoUtils.buildCollegeTeamLogo(
                                player.school,
                                size: 24,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ) : 
                // Fallback to school logo if no headshot
                SizedBox(
                  width: 80,
                  height: 80,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      color: isDarkMode ? Colors.black12 : Colors.grey.shade200,
                      padding: const EdgeInsets.all(4),
                      child: player.school.isNotEmpty
                        ? TeamLogoUtils.buildCollegeTeamLogo(
                            player.school,
                            size: 72.0,
                          )
                        : const SizedBox(
                            width: 72,
                            height: 72,
                            child: Icon(Icons.person, size: 48),
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
              
              // Vertical divider
              Container(
                height: 24,
                width: 1,
                color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
              ),
              
              // Height
              _buildCompactStat(
                context,
                'HT',
                player.formattedHeight,
                isDarkMode,
              ),
              
              // Vertical divider
              Container(
                height: 24,
                width: 1,
                color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
              ),
              
              // Weight
              _buildCompactStat(
                context,
                'WT',
                player.formattedWeight,
                isDarkMode,
              ),
              
              // Vertical divider
              Container(
                height: 24,
                width: 1,
                color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
              ),
              
              // 40 Time
              _buildCompactStat(
                context,
                '40',
                player.fortyTime != null && player.fortyTime!.isNotEmpty ? 
                  "${player.fortyTime}s" : "N/A",
                isDarkMode,
                valueColor: player.fortyTime != null ? 
                  _getFortyTimeColor(player.fortyTime!) : null,
              ),
              
              // Vertical divider
              Container(
                height: 24,
                width: 1,
                color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
              ),
              
              // RAS
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
        // Replace the current ExpansionTile showing "Athletic Measurements"
Container(
  width: double.infinity,
  decoration: BoxDecoration(
    color: isDarkMode ? Colors.grey.shade900 : Colors.grey.shade50,
    border: Border(
      bottom: BorderSide(
        color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
        width: 1,
      ),
    ),
  ),
  child: ExpansionTile(
    title: Text(
      'Athletic Measurements',
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: isDarkMode ? Colors.white : Colors.black87,
      ),
    ),
    tilePadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
    collapsedBackgroundColor:
        isDarkMode ? Colors.grey.shade900 : Colors.grey.shade50,
    backgroundColor:
        isDarkMode ? Colors.grey.shade900 : Colors.grey.shade50,
    children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildCompactStat(
            context,
            '10yd',
            player.formattedTenYardSplit,
            isDarkMode,
          ),
          Container(
            height: 24,
            width: 1,
            color:
                isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
          ),
          _buildCompactStat(
            context,
            '20yd',
            player.formattedTwentyYardShuttle,
            isDarkMode,
          ),
          Container(
            height: 24,
            width: 1,
            color:
                isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
          ),
          _buildCompactStat(
            context,
            '3-Cone',
            player.formattedThreeCone,
            isDarkMode,
          ),
          Container(
            height: 24,
            width: 1,
            color:
                isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
          ),
          _buildCompactStat(
            context,
            'Vertical',
            player.formattedVerticalJump,
            isDarkMode,
          ),
          Container(
            height: 24,
            width: 1,
            color:
                isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
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
            color:
                isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
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
            color:
                isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
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
            color:
                isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
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
            color:
                isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
          ),
          _buildCompactStat(
            context,
            'Wing',
            player.formattedWingspan,
            isDarkMode,
          ),
        ],
      ),
    ],
  ),
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
              // Text(
              //   'Draft Position: Not Selected',
              //   style: TextStyle(
              //     fontStyle: FontStyle.italic,
              //     color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade700,
              //   ),
              // ),
              Row(
                children: [
                  // Draft button (only show when canDraft is true)
                  if (canDraft && onDraft != null) 
                    Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: ElevatedButton(
                        onPressed: onDraft,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade600,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        ),
                        child: const Text('Draft'),
                      ),
                    ),
                  // Existing close button
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Text('Close'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

// Add this new helper method for compact stat display
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

// Player grade helper

  
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


// Helper method to get a rating value for the 40 time
}