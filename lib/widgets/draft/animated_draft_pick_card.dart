// lib/widgets/draft/animated_draft_pick_card.dart
import 'package:flutter/material.dart';
import '../../models/draft_pick.dart';
import '../../models/player.dart';
import '../../utils/constants.dart';
import '../../widgets/player/player_details_dialog.dart';
import '../../utils/mock_player_data.dart';
import '../../services/player_descriptions_service.dart';
import '../../utils/team_logo_utils.dart';

class AnimatedDraftPickCard extends StatefulWidget {
  final DraftPick draftPick;
  final bool isUserTeam;
  final bool isRecentPick;
  final List<String>? teamNeeds; // Parameter to pass team needs
  
  const AnimatedDraftPickCard({
    super.key,
    required this.draftPick,
    this.isUserTeam = false,
    this.isRecentPick = false,
    this.teamNeeds,
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
  
  return FadeTransition(
    opacity: _fadeAnimation,
    child: ScaleTransition(
      scale: _scaleAnimation,
      child: Card(
        elevation: widget.isRecentPick ? 1.5 : 1.0,
        margin: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 2.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0),
          side: BorderSide(
            color: widget.isUserTeam ? 
                (isDarkMode ? Colors.blue.shade700 : Colors.blue.shade300) : 
                (isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300),
            width: widget.isUserTeam ? 1.5 : 1.0,
          ),
        ),
        color: cardColor,
        child: InkWell(
          onTap: widget.draftPick.selectedPlayer != null 
              ? () => _showPlayerDetails(context, widget.draftPick.selectedPlayer!)
              : null,
          borderRadius: BorderRadius.circular(8.0),
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
                    color: _getPickNumberColor(),
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
                        // School
                        if (widget.draftPick.selectedPlayer!.school.isNotEmpty)
                          Text(
                            widget.draftPick.selectedPlayer!.school,
                            style: TextStyle(
                              fontSize: 12.0,
                              color: isDarkMode ? Colors.grey.shade300 : Colors.grey.shade600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ) :
                    // Show team needs if no player selected
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
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
                      onTap: () => _showTradeDetails(context),
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: Icon(
                          Icons.swap_horiz,
                          size: 16,
                          color: isDarkMode ? Colors.orange.shade300 : Colors.orange.shade700,
                        ),
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
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

void _showTradeDetails(BuildContext context) {
  final isDarkMode = Theme.of(context).brightness == Brightness.dark;
  
  if (widget.draftPick.tradeInfo == null || widget.draftPick.tradeInfo!.isEmpty) return;
  
  // Parse trade information to extract team names
  String tradeInfo = widget.draftPick.tradeInfo!;
  
  // These variables will hold the trade details
  String teamA = "";  // First team mentioned in the trade
  String teamB = "";  // Second team mentioned in the trade
  String teamAReceived = "";
  String teamBReceived = "";
  
  // Extract teams from trade info - common formats from your TradeService
  
  // If the trade info starts with a team name, extract it first
  // Common format: "X traded with Y: X received... Y received..."
  // or "X sent... to Y for..."
  
  // First, let's handle the "traded with" format
  if (tradeInfo.contains(" traded with ")) {
    final parts = tradeInfo.split(" traded with ");
    if (parts.length > 1) {
      teamA = parts[0].trim();
      
      // Get the second team
      int endIndex = parts[1].indexOf(":");
      if (endIndex > 0) {
        teamB = parts[1].substring(0, endIndex).trim();
      }
      
      // Get what each team received
      if (tradeInfo.contains("$teamA received")) {
        int startIdx = tradeInfo.indexOf("$teamA received") + ("$teamA received").length;
        int endIdx = tradeInfo.indexOf("$teamB received");
        if (endIdx > startIdx) {
          teamAReceived = tradeInfo.substring(startIdx, endIdx).trim();
          if (teamAReceived.endsWith(",")) {
            teamAReceived = teamAReceived.substring(0, teamAReceived.length - 1);
          }
        }
        
        // What team B received comes after
        if (tradeInfo.contains("$teamB received")) {
          startIdx = tradeInfo.indexOf("$teamB received") + ("$teamB received").length;
          teamBReceived = tradeInfo.substring(startIdx).trim();
          if (teamBReceived.endsWith(".")) {
            teamBReceived = teamBReceived.substring(0, teamBReceived.length - 1);
          }
        }
      }
    }
  }
  // Handle the "sent... to... for..." format
  else if (tradeInfo.contains(" sent ") && tradeInfo.contains(" to ") && tradeInfo.contains(" for ")) {
    final firstSpaceIndex = tradeInfo.indexOf(" ");
    if (firstSpaceIndex > 0) {
      teamA = tradeInfo.substring(0, firstSpaceIndex).trim();
      
      final toIndex = tradeInfo.indexOf(" to ");
      final forIndex = tradeInfo.indexOf(" for ");
      
      if (toIndex > 0 && forIndex > toIndex) {
        final toEndIdx = toIndex + 4; // Length of " to "
        teamB = tradeInfo.substring(toEndIdx, forIndex).trim();
        
        // What teamA sent (teamB received)
        final sentIndex = tradeInfo.indexOf(" sent ");
        if (sentIndex > 0) {
          teamBReceived = tradeInfo.substring(sentIndex + 6, toIndex).trim();
        }
        
        // What teamA received (what comes after "for")
        teamAReceived = tradeInfo.substring(forIndex + 5).trim();
        if (teamAReceived.endsWith(".")) {
          teamAReceived = teamAReceived.substring(0, teamAReceived.length - 1);
        }
      }
    }
  }
  // If no format matches, try to extract any team names we can find
  else {
    // Default to the current team as teamA
    teamA = widget.draftPick.teamName;
    
    // Try to find any team abbreviation patterns
    for (var entry in NFLTeamMappings.fullNameToAbbreviation.entries) {
      if (teamA.isEmpty && tradeInfo.contains(entry.key)) {
        teamA = entry.key;
      } else if (teamA.isNotEmpty && teamA != entry.key && tradeInfo.contains(entry.key)) {
        teamB = entry.key;
        break;
      }
    }
    
    // If we still don't have both teams, check for abbreviations directly
    if (teamA.isEmpty || teamB.isEmpty) {
      final words = tradeInfo.split(" ");
      for (var word in words) {
        // Check if the word is a 2-3 letter uppercase sequence
        final cleanWord = word.replaceAll(RegExp(r'[^\w\s]+'), '');
        if (cleanWord.length >= 2 && cleanWord.length <= 3) {
          // Check if it's all uppercase
          bool isAllUppercase = cleanWord == cleanWord.toUpperCase();
          bool containsOnlyLetters = RegExp(r'^[A-Z]+$').hasMatch(cleanWord);
          
          if (isAllUppercase && containsOnlyLetters) {
            if (teamA.isEmpty) {
              teamA = cleanWord;
            } else if (teamB.isEmpty && cleanWord != teamA) {
              teamB = cleanWord;
              break;
            }
          }
        }
      }
    }
  }
  
  // If we still don't have a team B, use "Trading Partner"
  if (teamB.isEmpty) {
    teamB = "Trading Partner";
  }
  
  // If we couldn't parse what was exchanged, use generic terms
  if (teamAReceived.isEmpty) {
    teamAReceived = "draft picks";
  }
  if (teamBReceived.isEmpty) {
    teamBReceived = "draft picks";
  }
  
  // Ensure current pick team is teamA
  if (widget.draftPick.teamName != teamA) {
    // Swap teams and what they received
    final tempTeam = teamA;
    teamA = teamB;
    teamB = tempTeam;
    
    final tempReceived = teamAReceived;
    teamAReceived = teamBReceived;
    teamBReceived = tempReceived;
  }
  
  // Use short abbreviations for display if available
  String teamADisplay = NFLTeamMappings.fullNameToAbbreviation[teamA] ?? teamA;
  String teamBDisplay = NFLTeamMappings.fullNameToAbbreviation[teamB] ?? teamB;
  
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Row(
        children: [
          Icon(Icons.swap_horiz, 
            color: isDarkMode ? Colors.orange.shade300 : Colors.orange.shade700),
          const SizedBox(width: 8),
          const Text('Trade Details'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Team logos and arrows showing the trade
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
                ),
              ),
              child: Column(
                children: [
                  // Team headers with logos
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      // Team A (Current Pick Team)
                      Column(
                        children: [
                          TeamLogoUtils.buildNFLTeamLogo(
                            teamA,
                            size: 48.0,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            teamADisplay,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                      
                      // Exchange arrows
                      Column(
                        children: [
                          Icon(
                            Icons.east,
                            color: isDarkMode ? Colors.green.shade300 : Colors.green.shade700,
                            size: 24,
                          ),
                          const SizedBox(height: 12),
                          Icon(
                            Icons.west,
                            color: isDarkMode ? Colors.red.shade300 : Colors.red.shade700,
                            size: 24,
                          ),
                        ],
                      ),
                      
                      // Team B (Other Team)
                      Column(
                        children: [
                          TeamLogoUtils.buildNFLTeamLogo(
                            teamB,
                            size: 48.0,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            teamBDisplay,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // What each team received
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isDarkMode ? 
                                Colors.green.shade900.withOpacity(0.3) : 
                                Colors.green.shade50,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: isDarkMode ? 
                                  Colors.green.shade700.withOpacity(0.5) : 
                                  Colors.green.shade200,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Received:",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: isDarkMode ? 
                                      Colors.green.shade300 : 
                                      Colors.green.shade800,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                teamAReceived,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDarkMode ? Colors.white : Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      const SizedBox(width: 8),
                      
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isDarkMode ? 
                                Colors.green.shade900.withOpacity(0.3) : 
                                Colors.green.shade50,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: isDarkMode ? 
                                  Colors.green.shade700.withOpacity(0.5) : 
                                  Colors.green.shade200,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Received:",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: isDarkMode ? 
                                      Colors.green.shade300 : 
                                      Colors.green.shade800,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                teamBReceived,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDarkMode ? Colors.white : Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Full trade description
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 16,
                        color: isDarkMode ? Colors.blue.shade300 : Colors.blue.shade700,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Trade Summary',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.draftPick.tradeInfo!,
                    style: TextStyle(
                      height: 1.4,
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Pick information
            if (widget.draftPick.selectedPlayer != null) ...[
              Text(
                'Selection Details:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.draftPick.selectedPlayer!.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Rank #${widget.draftPick.selectedPlayer!.rank} overall',
                style: TextStyle(
                  fontSize: 12,
                  color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'School: ${widget.draftPick.selectedPlayer!.school}',
                style: TextStyle(
                  fontSize: 12,
                  color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade700,
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
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
    
    // Attempt to parse weight from string to double
    double? weight;
    if (additionalInfo['weight'] != null && additionalInfo['weight']!.isNotEmpty) {
      weight = double.tryParse(additionalInfo['weight']!);
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
      rasScore: player.rasScore,
      description: additionalInfo['description'] ?? player.description,
      strengths: additionalInfo['strengths'] ?? player.strengths,
      weaknesses: additionalInfo['weaknesses'] ?? player.weaknesses,
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
    // Different colors for each round with dark mode adjustments
    switch (widget.draftPick.round) {
      case '1':
        return isDarkMode ? Colors.blue.shade600 : Colors.blue.shade700;
      case '2':
        return isDarkMode ? Colors.green.shade600 : Colors.green.shade700;
      case '3':
        return isDarkMode ? Colors.orange.shade600 : Colors.orange.shade700;
      case '4':
        return isDarkMode ? Colors.purple.shade600 : Colors.purple.shade700;
      case '5':
        return isDarkMode ? Colors.red.shade600 : Colors.red.shade700;
      case '6':
        return isDarkMode ? Colors.teal.shade600 : Colors.teal.shade700;
      case '7':
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