// lib/widgets/draft/animated_draft_pick_card.dart
import 'package:flutter/material.dart';
import '../../models/draft_pick.dart';
import '../../models/player.dart';
import '../../services/draft_value_service.dart';
import '../../utils/constants.dart';
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
  
  const AnimatedDraftPickCard({
    super.key,
    required this.draftPick,
    this.isUserTeam = false,
    this.isRecentPick = false,
    this.teamNeeds,
    this.isCurrentPick = false, // Default to false
  });

  @override
  State<AnimatedDraftPickCard> createState() => _AnimatedDraftPickCardState();
}

class _AnimatedDraftPickCardState extends State<AnimatedDraftPickCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  
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
                        child: Tooltip(
                          message: widget.draftPick.tradeInfo!,
                          child: Icon(
                            Icons.swap_horiz,
                            size: 16,
                            color: isDarkMode ? Colors.orange.shade300 : Colors.orange.shade700,
                          ),
                        ),
                      ),
                        
                    // Info icon for analysis (only show if player is selected)
                    if (widget.draftPick.selectedPlayer != null)
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        visualDensity: VisualDensity.compact,
                        icon: Icon(
                          Icons.info_outline,
                          size: 16,
                          color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                        ),
                        onPressed: () => _showPlayerDetails(context, widget.draftPick.selectedPlayer!),
                      ),
                    
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
  
void _showPlayerDetails(BuildContext context, Player player) {
  // Attempt to get additional player information from our description service
  Map<String, String>? additionalInfo = PlayerDescriptionsService.getPlayerDescription(player.name);
  
  Player enrichedPlayer;
  
  if (additionalInfo != null) {
    // If we have additional info, use it for the player
    // Attempt to parse height from string to double
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
    );
  } else {
    // Fall back to mock data for players without description
    enrichedPlayer = MockPlayerData.enrichPlayerData(player);
  }
  
  // Show the dialog with enriched player data
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return PlayerDetailsDialog(player: enrichedPlayer);
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
      return isDarkMode ? Colors.blue.shade600 : Colors.blue.shade700; // Backfield
    } else if (['WR', 'TE'].contains(position)) {
      return isDarkMode ? Colors.green.shade600 : Colors.green.shade700; // Receivers
    } else if (['OT', 'IOL', 'OL', 'G', 'C'].contains(position)) {
      return isDarkMode ? Colors.purple.shade600 : Colors.purple.shade700; // Offensive line
    } else if (['EDGE', 'IDL', 'DT', 'DE'].contains(position)) {
      return isDarkMode ? Colors.red.shade600 : Colors.red.shade700; // Defensive line
    } else if (['LB', 'ILB', 'OLB'].contains(position)) {
      return isDarkMode ? Colors.orange.shade600 : Colors.orange.shade700; // Linebackers
    } else if (['CB', 'S', 'FS', 'SS'].contains(position)) {
      return isDarkMode ? Colors.teal.shade600 : Colors.teal.shade700; // Secondary
    } else {
      return isDarkMode ? Colors.grey.shade600 : Colors.grey.shade700; // Special teams, etc.
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