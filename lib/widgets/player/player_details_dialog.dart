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
          _buildDialogHeader(context, headerColor, isDarkMode),
          _buildCompactStatsBanner(context, isDarkMode),
          _buildAdditionalMeasurementsBanner(context, isDarkMode),
          _buildDetailsContent(context, isDarkMode),
          _buildDialogFooter(context, isDarkMode),
        ],
      ),
    );
  }

  Widget _buildDialogHeader(BuildContext context, Color headerColor, bool isDarkMode) {
    return Container(
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
    );
  }

  Widget _buildCompactStatsBanner(BuildContext context, bool isDarkMode) {
    return Container(
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
    );
  }

  Widget _buildAdditionalMeasurementsBanner(BuildContext context, bool isDarkMode) {
  return LayoutBuilder(
    builder: (context, constraints) {
      // Determine how many items can fit based on available width
      const itemWidth = 80.0; // Estimated width for each stat item
      const separatorWidth = 1.0; // Width of separator
      const padding = 24.0; // Total horizontal padding
      
      int maxItems = ((constraints.maxWidth - padding) / (itemWidth + separatorWidth)).floor();
      
      // Ensure we have at least 3 items and at most all items
      maxItems = maxItems.clamp(3, 9);
      
      // Full list of measurements
      final measurements = [
        {'label': '10 Yd', 'value': player.formattedTenYardSplit},
        {'label': '20 Sh', 'value': player.formattedTwentyYardShuttle},
        {'label': '3 Cone', 'value': player.formattedThreeConeDrill},
        {'label': 'Arm', 'value': player.formattedArmLength},
        {'label': 'Bench', 'value': player.formattedBenchPress},
        {'label': 'Broad', 'value': player.formattedBroadJump},
        {'label': 'Vert', 'value': player.formattedVerticalJump},
        {'label': 'Hand', 'value': player.formattedHandSize},
        {'label': 'Wing', 'value': player.formattedWingspan},
      ];
      
      // Filter out 'N/A' measurements
      final validMeasurements = measurements
          .where((measurement) => measurement['value'] != 'N/A')
          .toList();
      
      // Create a list of widgets for the row
      List<Widget> createRowWidgets(List<Map<String, String>> rowMeasurements) {
        return rowMeasurements.expand((measurement) {
          return [
            _buildCompactStat(
              context,
              measurement['label'] as String,
              measurement['value'] as String,
              isDarkMode,
            ),
            if (measurement != rowMeasurements.last)
              Container(
                height: 24,
                width: 1,
                color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
              ),
          ];
        }).toList();
      }
      
      // Split measurements into two rows
      final firstRowMeasurements = validMeasurements.take(maxItems ~/ 2).toList();
      final secondRowMeasurements = validMeasurements.skip(maxItems ~/ 2).take(maxItems - firstRowMeasurements.length).toList();
      
      return Container(
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // First row
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: createRowWidgets(firstRowMeasurements),
                ),
              ),
              
              // Separator
              if (secondRowMeasurements.isNotEmpty)
                Container(
                  height: 1,
                  width: constraints.maxWidth - 24,
                  color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
                  margin: const EdgeInsets.symmetric(vertical: 4),
                ),
              
              // Second row
              if (secondRowMeasurements.isNotEmpty)
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: createRowWidgets(secondRowMeasurements),
                  ),
                ),
            ],
          ),
        ),
      );
    },
  );
}

  Widget _buildDetailsContent(BuildContext context, bool isDarkMode) {
    return Expanded(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Scouting Report
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
              
              // Strengths and Weaknesses
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
    );
  }

  Widget _buildDialogFooter(BuildContext context, bool isDarkMode) {
    return Container(
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
    );
  }

  // Helper methods
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

  // Position color helper
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
}