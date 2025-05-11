// lib/widgets/draft/animated_draft_pick_card.dart
import 'dart:math';

import 'package:flutter/material.dart';
import '../../models/draft_pick.dart';
import '../../models/player.dart';
import '../../models/trade_package.dart';
import '../../services/draft_value_service.dart';
import '../../widgets/player/player_details_dialog.dart';
import '../../utils/mock_player_data.dart';
import '../../services/player_descriptions_service.dart';
import '../../utils/team_logo_utils.dart';

class AnimatedDraftPickCard extends StatefulWidget {
  final DraftPick draftPick;
  final bool isUserTeam;
  final bool isRecentPick;
  final List<String>? teamNeeds;
  final bool isCurrentPick; // New property to highlight current pick
  final List<DraftPick> allDraftPicks; // Add this line
  final Function(Player)? onSelect; // Add this line

  
  const AnimatedDraftPickCard({
    super.key,
    required this.draftPick,
    this.isUserTeam = false,
    this.isRecentPick = false,
    this.teamNeeds,
    this.isCurrentPick = false, // Default to false
    required this.allDraftPicks, 
    this.onSelect, 
  });

  @override
  State<AnimatedDraftPickCard> createState() => _AnimatedDraftPickCardState();
}

class _AnimatedDraftPickCardState extends State<AnimatedDraftPickCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  Map<int, TradePackage> executedTrades = {};
  
  @override
  void initState() {
    super.initState();
    
    // Initialize animation controller
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    );
    
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    );
    
    // Start animation if this is a recent pick
    if (widget.isRecentPick) {
      _controller.forward();
    } else {
      _controller.value = 1.0; // Skip animation for older picks
    }
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _showTradeDetails(BuildContext context, DraftPick pick, List<DraftPick> allDraftPicks) {
  final isDarkMode = Theme.of(context).brightness == Brightness.dark;
  
  // Parse trade info to extract details
  String tradeDetails = pick.tradeInfo ?? "No trade information";
  String fromTeam = "";
  
  // Extract team if available (assuming format like "From PHI")
  if (tradeDetails.contains("From ")) {
    final teamStart = tradeDetails.indexOf("From ") + 5;
    int teamEnd = tradeDetails.length;
    
    if (tradeDetails.contains("(")) {
      teamEnd = tradeDetails.indexOf("(");
    }
    
    fromTeam = tradeDetails.substring(teamStart, teamEnd).trim();
  }
  
  // Find all picks involved in this trade by looking at team names and trade info
  List<DraftPick> relatedPicks = allDraftPicks.where((p) => 
    (p.teamName == pick.teamName && p.tradeInfo?.contains(fromTeam) == true) || 
    (p.teamName == fromTeam && p.tradeInfo?.contains(pick.teamName) == true)
  ).toList();
  
  // Group picks by team
  List<DraftPick> receivingTeamPicks = relatedPicks.where((p) => p.teamName == pick.teamName).toList();
  List<DraftPick> sendingTeamPicks = relatedPicks.where((p) => p.teamName == fromTeam).toList();
  
  // Add the current pick to receiving team's picks if not already included
  if (!receivingTeamPicks.any((p) => p.pickNumber == pick.pickNumber)) {
    receivingTeamPicks.add(pick);
  }
  
  // Calculate total value for both sides
  double receivingTeamValue = receivingTeamPicks.fold(0.0, 
    (sum, p) => sum + DraftValueService.getValueForPick(p.pickNumber));
  
  double sendingTeamValue = sendingTeamPicks.fold(0.0, 
    (sum, p) => sum + DraftValueService.getValueForPick(p.pickNumber));
  
  // Calculate value ratio
  double valueRatio = 1.0;
  if (sendingTeamValue > 0) {
    valueRatio = receivingTeamValue / sendingTeamValue;
  }
  
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      contentPadding: EdgeInsets.zero,
      content: Container(
        width: min(MediaQuery.of(context).size.width * 0.9, 500),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with trade icon and title
            Row(
              children: [
                Icon(
                  Icons.swap_horiz,
                  color: isDarkMode ? Colors.orange.shade300 : Colors.orange.shade700,
                  size: 24,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Trade Details',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const Divider(),
            
            // Teams involved with logos
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // From team
                  Column(
                    children: [
                      TeamLogoUtils.buildNFLTeamLogo(
                        fromTeam,
                        size: 48.0,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        fromTeam,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  
                  // Arrows
                  Column(
                    children: [
                      Icon(
                        Icons.arrow_forward,
                        color: isDarkMode ? Colors.green.shade300 : Colors.green.shade600,
                      ),
                      Icon(
                        Icons.arrow_back,
                        color: isDarkMode ? Colors.amber.shade300 : Colors.amber.shade600,
                      ),
                    ],
                  ),
                  
                  // To team
                  Column(
                    children: [
                      TeamLogoUtils.buildNFLTeamLogo(
                        pick.teamName,
                        size: 48.0,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        pick.teamName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            // Capital exchanged - both teams
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Capital received by current pick's team
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "${pick.teamName} received:",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isDarkMode ? 
                            Colors.green.shade900.withOpacity(0.3) : 
                            Colors.green.shade50,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: isDarkMode ? 
                              Colors.green.shade700 : 
                              Colors.green.shade300,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Show all picks the current team received
                            for (var receivedPick in receivingTeamPicks)
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 2),
                                child: Row(
                                  children: [
                                    Text("Pick #${receivedPick.pickNumber}"),
                                    if (receivedPick.selectedPlayer != null) ...[
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          "→ ${receivedPick.selectedPlayer!.name} (${receivedPick.selectedPlayer!.position})",
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            // Add any future picks if mentioned in tradeInfo
                            if (pick.tradeInfo?.contains("future") == true ||
                                pick.tradeInfo?.contains("2026") == true)
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 2),
                                child: Text(
                                  "Future draft capital",
                                  style: TextStyle(
                                    fontStyle: FontStyle.italic,
                                    color: isDarkMode ? Colors.green.shade400 : Colors.green.shade700,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Value: ${DraftValueService.getValueDescription(receivingTeamValue)} points",
                        style: TextStyle(
                          fontSize: 12,
                          color: isDarkMode ? Colors.green.shade400 : Colors.green.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                
                // Capital received by the original team
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "$fromTeam received:",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isDarkMode ? 
                            Colors.amber.shade900.withOpacity(0.3) : 
                            Colors.amber.shade50,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: isDarkMode ? 
                              Colors.amber.shade700 : 
                              Colors.amber.shade300,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Show all picks the original team received
                            for (var sendingPick in sendingTeamPicks)
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 2),
                                child: Row(
                                  children: [
                                    Text("Pick #${sendingPick.pickNumber}"),
                                    if (sendingPick.selectedPlayer != null) ...[
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          "→ ${sendingPick.selectedPlayer!.name} (${sendingPick.selectedPlayer!.position})",
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            // Add any future picks if mentioned in trade info of other picks
                            if (sendingTeamPicks.any((p) => 
                              p.tradeInfo?.contains("future") == true ||
                              p.tradeInfo?.contains("2026") == true))
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 2),
                                child: Text(
                                  "Future draft capital",
                                  style: TextStyle(
                                    fontStyle: FontStyle.italic,
                                    color: isDarkMode ? Colors.amber.shade700 : Colors.amber.shade800,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Value: ${DraftValueService.getValueDescription(sendingTeamValue)} points",
                        style: TextStyle(
                          fontSize: 12,
                          color: isDarkMode ? Colors.amber.shade700 : Colors.amber.shade800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Value analysis
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Trade Value Analysis:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                // Value summary
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _getValueColor(valueRatio).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: _getValueColor(valueRatio),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              "Trade Value Ratio:",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: _getValueColor(valueRatio).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              "${(valueRatio * 100).toStringAsFixed(0)}%",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: _getValueColor(valueRatio),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        valueRatio >= 1.0 ?
                          "${pick.teamName} received ${((valueRatio - 1.0) * 100).toStringAsFixed(0)}% more value in this trade." :
                          "$fromTeam received ${((1.0 - valueRatio) * 100).toStringAsFixed(0)}% more value in this trade.",
                        style: TextStyle(
                          color: isDarkMode ? Colors.white : Colors.black87,
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

// Helper method to determine color based on value ratio
Color _getValueColor(double ratio) {
  if (ratio >= 1.1) return Colors.green;      // Good value (>10% surplus)
  if (ratio >= 0.95) return Colors.blue;      // Fair value
  if (ratio >= 0.85) return Colors.orange;    // Slightly below value
  return Colors.red;                          // Poor value
}


  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    // Determine the card color with dark mode support
    Color cardColor = widget.isUserTeam ? 
        (isDarkMode ? Colors.blue.shade900 : Colors.blue.shade50) : 
        (isDarkMode ? Colors.grey.shade800 : Colors.white);
    
    // Apply special highlight if this is the current pick
    if (widget.isCurrentPick) {
      cardColor = isDarkMode ? 
        Colors.green.shade900.withOpacity(0.3) : 
        Colors.green.shade50;
    }
    
    // Consistent height for all cards (important for scrolling calculation)
    const double cardHeight = 72.0;
    
    return FadeTransition(
      opacity: _fadeAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Card(
          elevation: widget.isCurrentPick ? 4.0 : 
                     widget.isRecentPick ? 1.5 : 1.0,
          margin: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 2.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.0),
            side: BorderSide(
              color: widget.isCurrentPick ? 
                  (isDarkMode ? Colors.green.shade700 : Colors.green.shade400) :
                  widget.isUserTeam ? 
                    (isDarkMode ? Colors.blue.shade700 : Colors.blue.shade300) : 
                    (isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300),
              width: widget.isCurrentPick ? 2.0 :
                     widget.isUserTeam ? 1.5 : 1.0,
            ),
          ),
          color: cardColor,
          child: InkWell(
            onTap: widget.draftPick.selectedPlayer != null 
                ? () => _showPlayerDetails(context, widget.draftPick.selectedPlayer!)
                : null,
            borderRadius: BorderRadius.circular(8.0),
            child: SizedBox(
              height: cardHeight, // Fixed height for all cards!
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Pick number circle
                    Container(
                      width: 30.0,
                      height: 30.0,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: widget.isCurrentPick ?
                          (isDarkMode ? Colors.green.shade600 : Colors.green.shade700) :
                          _getPickNumberColor(),
                      ),
                      child: Center(
                        child: Text(
                          '${widget.draftPick.pickNumber}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12.0,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8.0),
                    
                    // Team logo
                    _buildTeamLogo(widget.draftPick.teamName),
                    const SizedBox(width: 8.0),
                    
                    // Player info or Team Needs
                    Expanded(
                      child: widget.draftPick.selectedPlayer != null ? 
                        // Show player info if a player is selected
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Player name
                            Text(
                              widget.draftPick.selectedPlayer!.name,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14.0,
                                color: isDarkMode ? Colors.white : Colors.black,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            // School with logo
                            if (widget.draftPick.selectedPlayer!.school.isNotEmpty)
                              Row(
                                children: [
                                  // College Logo
                                  SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: TeamLogoUtils.buildCollegeTeamLogo(
                                      widget.draftPick.selectedPlayer!.school,
                                      size: 16,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  // School name
                                  Expanded(
                                    child: Text(
                                      widget.draftPick.selectedPlayer!.school,
                                      style: TextStyle(
                                        fontSize: 12.0,
                                        color: isDarkMode ? Colors.grey.shade300 : Colors.grey.shade600,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ) :
                        // Show team needs if no player selected
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Team name
                            Text(
                              widget.draftPick.teamName,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14.0,
                                color: isDarkMode ? Colors.white : Colors.black,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            // Team needs
                            if (widget.teamNeeds != null && widget.teamNeeds!.isNotEmpty)
                              Wrap(
                                spacing: 4.0,
                                children: widget.teamNeeds!.take(3).map((need) => 
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 1.0),
                                    margin: const EdgeInsets.only(top: 2.0),
                                    decoration: BoxDecoration(
                                      color: _getPositionColor(need).withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(3.0),
                                      border: Border.all(
                                        color: _getPositionColor(need).withOpacity(0.5),
                                        width: 1,
                                      ),
                                    ),
                                    child: Text(
                                      need,
                                      style: TextStyle(
                                        fontSize: 10.0,
                                        fontWeight: FontWeight.bold,
                                        color: _getPositionColor(need),
                                      ),
                                    ),
                                  )
                                ).toList(),
                              )
                            else
                              Text(
                                'No team needs data',
                                style: TextStyle(
                                  fontSize: 12.0,
                                  fontStyle: FontStyle.italic,
                                  color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                                ),
                              ),
                          ],
                        )
                    ),
                    
                    // Position badge for selected player
                    if (widget.draftPick.selectedPlayer != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        margin: const EdgeInsets.only(right: 4.0),
                        decoration: BoxDecoration(
                          color: _getPositionColor(widget.draftPick.selectedPlayer!.position).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: _getPositionColor(widget.draftPick.selectedPlayer!.position),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          widget.draftPick.selectedPlayer!.position,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: _getPositionColor(widget.draftPick.selectedPlayer!.position),
                          ),
                        ),
                      ),
                    
                    // Trade icon if applicable
                    if (widget.draftPick.tradeInfo != null && widget.draftPick.tradeInfo!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(right: 4.0),
                        child: InkWell(
                          onTap: () => _showTradeDetails(context, widget.draftPick, widget.allDraftPicks),
                          borderRadius: BorderRadius.circular(12),
                          child: Tooltip(
                            message: "View trade details",
                            child: Icon(
                              Icons.swap_horiz,
                              size: 16,
                              color: isDarkMode ? Colors.orange.shade300 : Colors.orange.shade700,
                            ),
                          ),
                        ),
                      ),
                        
                    // // Info icon for analysis (only show if player is selected)
                    // if (widget.draftPick.selectedPlayer != null)
                    //   IconButton(
                    //     padding: EdgeInsets.zero,
                    //     constraints: const BoxConstraints(),
                    //     visualDensity: VisualDensity.compact,
                    //     icon: Icon(
                    //       Icons.info_outline,
                    //       size: 16,
                    //       color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                    //     ),
                    //     onPressed: () => _showPlayerDetails(context, widget.draftPick.selectedPlayer!),
                    //   ),
                    
                    // Show rank info for selected players
                    if (widget.draftPick.selectedPlayer != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getRankColor(
                            widget.draftPick.selectedPlayer!.rank,
                            widget.draftPick.pickNumber,
                          ).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '#${widget.draftPick.selectedPlayer!.rank}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: _getRankColor(
                              widget.draftPick.selectedPlayer!.rank,
                              widget.draftPick.pickNumber,
                            ),
                          ),
                        ),
                      ),
                    
                    // Current pick indicator (small triangle/arrow on right side) 
                    if (widget.isCurrentPick)
                      Padding(
                        padding: const EdgeInsets.only(left: 4.0),
                        child: Container(
                          width: 12,
                          height: 24,
                          decoration: BoxDecoration(
                            color: isDarkMode ? Colors.green.shade700 : Colors.green.shade600,
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(4),
                              bottomLeft: Radius.circular(4),
                            ),
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.arrow_left,
                              size: 12,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
  
// In lib/widgets/player/player_details_dialog.dart or lib/widgets/draft/animated_draft_pick_card.dart
void _showPlayerDetails(BuildContext context, Player player) {
  // Attempt to get additional player information from our description service
  Map<String, String>? additionalInfo = PlayerDescriptionsService.getPlayerDescription(player.name);
  
  Player enrichedPlayer;
  
  if (additionalInfo != null) {
    // Parse height from string to double
    double? height;
    if (additionalInfo['height'] != null && additionalInfo['height']!.isNotEmpty) {
      String heightStr = additionalInfo['height']!;
      
      // Handle height in different formats
      if (heightStr.contains("'")) {
        // Format like 6'2"
        try {
          List<String> parts = heightStr.replaceAll('"', '').split("'");
          int feet = int.tryParse(parts[0]) ?? 0;
          int inches = int.tryParse(parts[1]) ?? 0;
          height = (feet * 12 + inches).toDouble();
        } catch (e) {
          height = null;
        }
      } else if (heightStr.contains("-")) {
        // Format like 6-1 for 6'1"
        try {
          List<String> parts = heightStr.split("-");
          int feet = int.tryParse(parts[0]) ?? 0;
          int inches = int.tryParse(parts[1]) ?? 0;
          height = (feet * 12 + inches).toDouble();
        } catch (e) {
          height = null;
        }
      } else {
        // Assume it's in inches
        height = double.tryParse(heightStr);
      }
    }
    
    // Parse weight
    double? weight;
    if (additionalInfo['weight'] != null && additionalInfo['weight']!.isNotEmpty) {
      weight = double.tryParse(additionalInfo['weight']!);
    }
    
    // Parse 40 time and RAS
    String? fortyTime = additionalInfo['fortyTime'];
    
    double? rasScore;
    if (additionalInfo['ras'] != null && additionalInfo['ras']!.isNotEmpty) {
      rasScore = double.tryParse(additionalInfo['ras']!);
    }
    
    // Parse all athletic measurements
    String? tenYardSplit = additionalInfo['tenYardSplit'];
    String? twentyYardShuttle = additionalInfo['twentyYardShuttle'];
    String? threeConeTime = additionalInfo['threeCone'];
    
    double? armLength;
    if (additionalInfo['armLength'] != null && additionalInfo['armLength']!.isNotEmpty) {
      armLength = double.tryParse(additionalInfo['armLength']!);
    }
    
    int? benchPress;
    if (additionalInfo['benchPress'] != null && additionalInfo['benchPress']!.isNotEmpty) {
      benchPress = int.tryParse(additionalInfo['benchPress']!);
    }
    
    double? broadJump;
    if (additionalInfo['broadJump'] != null && additionalInfo['broadJump']!.isNotEmpty) {
      broadJump = double.tryParse(additionalInfo['broadJump']!);
    }
    
    double? handSize;
    if (additionalInfo['handSize'] != null && additionalInfo['handSize']!.isNotEmpty) {
      handSize = double.tryParse(additionalInfo['handSize']!);
    }
    
    double? verticalJump;
    if (additionalInfo['verticalJump'] != null && additionalInfo['verticalJump']!.isNotEmpty) {
      verticalJump = double.tryParse(additionalInfo['verticalJump']!);
    }
    
    double? wingspan;
    if (additionalInfo['wingspan'] != null && additionalInfo['wingspan']!.isNotEmpty) {
      wingspan = double.tryParse(additionalInfo['wingspan']!);
    }
    
    enrichedPlayer = Player(
      id: player.id,
      name: player.name,
      position: player.position,
      rank: player.rank,
      school: player.school,
      notes: player.notes,
      height: height ?? player.height,
      weight: weight ?? player.weight,
      rasScore: rasScore ?? player.rasScore,
      description: additionalInfo['description'] ?? player.description,
      strengths: additionalInfo['strengths'] ?? player.strengths,
      weaknesses: additionalInfo['weaknesses'] ?? player.weaknesses,
      fortyTime: fortyTime ?? player.fortyTime,
      // Add all athletic measurements
      tenYardSplit: tenYardSplit,
      twentyYardShuttle: twentyYardShuttle,
      threeConeTime: threeConeTime,
      armLength: armLength,
      benchPress: benchPress,
      broadJump: broadJump,
      handSize: handSize,
      verticalJump: verticalJump,
      wingspan: wingspan,
    );
  } else {
    // Fall back to mock data for players without any description
    enrichedPlayer = MockPlayerData.enrichPlayerData(player);
  }
  
  // Determine if this is being shown during user's turn to pick
   bool canDraft = widget.isCurrentPick && widget.isUserTeam && widget.onSelect != null;
  VoidCallback? onDraftCallback;
  
  if (canDraft) {
    onDraftCallback = () {
      Navigator.of(context).pop(); // Close the dialog
      
      // Call the player selection callback
      if (widget.onSelect != null) {
        widget.onSelect!(player);
      }
    };
  }
  
  // Show the dialog with enriched player data
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return PlayerDetailsDialog(
        player: enrichedPlayer,
        canDraft: canDraft,
        onDraft: onDraftCallback,
      );
    },
  );
}

  Widget _buildTeamLogo(String teamName) {
    return TeamLogoUtils.buildNFLTeamLogo(
      teamName,
      size: 30.0,
    );
  }
  
  Color _getPickNumberColor() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // Get the round using the service method
    int round = DraftValueService.getRoundForPick(widget.draftPick.pickNumber);

    // Different colors for each round with dark mode adjustments
    switch (round) {
      case 1:
        return isDarkMode ? Colors.blue.shade600 : Colors.blue.shade700;
      case 2:
        return isDarkMode ? Colors.green.shade600 : Colors.green.shade700;
      case 3:
        return isDarkMode ? Colors.orange.shade600 : Colors.orange.shade700;
      case 4:
        return isDarkMode ? Colors.purple.shade600 : Colors.purple.shade700;
      case 5:
        return isDarkMode ? Colors.red.shade600 : Colors.red.shade700;
      case 6:
        return isDarkMode ? Colors.teal.shade600 : Colors.teal.shade700;
      case 7:
        return isDarkMode ? Colors.brown.shade600 : Colors.brown.shade700;
      default:
        return isDarkMode ? Colors.grey.shade600 : Colors.grey.shade700;
    }
  }
  
  Color _getPositionColor(String position) {
  final isDarkMode = Theme.of(context).brightness == Brightness.dark;
  
  // Different colors for different position groups with dark mode adjustments
  if (['QB', 'RB', 'FB'].contains(position)) {
    return isDarkMode ? Colors.blue.shade400 : Colors.blue.shade700; // Backfield
  } else if (['WR', 'TE'].contains(position)) {
    return isDarkMode ? Colors.green.shade400 : Colors.green.shade700; // Receivers
  } else if (['OT', 'IOL', 'OL', 'G', 'C'].contains(position)) {
    return isDarkMode ? Colors.purple.shade400 : Colors.purple.shade700; // Offensive line
  } else if (['EDGE', 'IDL', 'DT', 'DE'].contains(position)) {
    return isDarkMode ? Colors.red.shade400 : Colors.red.shade700; // Defensive line
  } else if (['LB', 'ILB', 'OLB'].contains(position)) {
    return isDarkMode ? Colors.orange.shade400 : Colors.orange.shade700; // Linebackers
  } else if (['CB', 'S', 'FS', 'SS'].contains(position)) {
    return isDarkMode ? Colors.teal.shade400 : Colors.teal.shade700; // Secondary
  } else {
    return isDarkMode ? Colors.grey.shade400 : Colors.grey.shade700; // Special teams, etc.
  }
}
  
  Color _getRankColor(int rank, int pickNumber) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    // Color based on difference between rank and pick number
    int diff = pickNumber - rank;
    
    if (diff >= 15) {
      return isDarkMode ? Colors.green.shade400 : Colors.green.shade800; // Excellent value
    } else if (diff >= 5) {
      return isDarkMode ? Colors.green.shade300 : Colors.green.shade600; // Good value
    } else if (diff >= -5) {
      return isDarkMode ? Colors.blue.shade300 : Colors.blue.shade600; // Fair value
    } else if (diff >= -15) {
      return isDarkMode ? Colors.orange.shade300 : Colors.orange.shade600; // Slight reach
    } else {
      return isDarkMode ? Colors.red.shade300 : Colors.red.shade600; // Significant reach
    }
  }
}