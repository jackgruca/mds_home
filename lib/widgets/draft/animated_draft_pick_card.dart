// lib/widgets/draft/animated_draft_pick_card.dart
import 'package:flutter/material.dart';
import '../../models/draft_pick.dart';
import '../../models/player.dart';
import '../../models/team_need.dart';
import '../../utils/constants.dart';

class AnimatedDraftPickCard extends StatefulWidget {
  final DraftPick draftPick;
  final bool isUserTeam;
  final bool isRecentPick;
  
  const AnimatedDraftPickCard({
    super.key,
    required this.draftPick,
    this.isUserTeam = false,
    this.isRecentPick = false,
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
    // Determine the card color - no yellow highlight
    Color cardColor = widget.isUserTeam ? Colors.blue.shade50 : Colors.white;
    
    return FadeTransition(
      opacity: _fadeAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Card(
          elevation: widget.isRecentPick ? 4.0 : 1.0,
          margin: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 2.0), // Reduced margins
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.0), // Smaller border radius
            side: BorderSide(
              color: widget.isUserTeam ? Colors.blue : Colors.transparent,
              width: widget.isUserTeam ? 2.0 : 0.0,
            ),
          ),
          color: cardColor,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0), // Reduced padding
            child: Row(
              children: [
                // Pick number (smaller)
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
                        fontSize: 12.0, // Smaller font
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8.0),
                
                // Team logo
                _buildTeamLogo(widget.draftPick.teamName),
                const SizedBox(width: 8.0),
                
                // Player info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min, // Keep column tight
                    children: [
                      // Player name
                      Text(
                        widget.draftPick.selectedPlayer?.name ?? 'Pick pending',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14.0, // Smaller font
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      // Position and team
                      Row(
                        children: [
                          if (widget.draftPick.selectedPlayer != null)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 1.0), // Smaller padding
                              margin: const EdgeInsets.only(right: 4.0),
                              decoration: BoxDecoration(
                                color: _getPositionColor(widget.draftPick.selectedPlayer!.position),
                                borderRadius: BorderRadius.circular(3.0), // Smaller radius
                              ),
                              child: Text(
                                widget.draftPick.selectedPlayer!.position,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10.0, // Smaller font
                                ),
                              ),
                            ),
                          Text(
                            widget.draftPick.teamName,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 11.0, // Smaller font
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Right side widgets
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Trade icon if applicable (moved to the left)
                    if (widget.draftPick.tradeInfo != null && widget.draftPick.tradeInfo!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(right: 4.0),
                        child: Icon(
                          Icons.swap_horiz,
                          size: 16.0,
                          color: Colors.orange[700],
                        ),
                      ),
                      
                    // Info icon for analysis
                    if (widget.draftPick.selectedPlayer != null)
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        visualDensity: VisualDensity.compact,
                        icon: Icon(
                          Icons.info_outline,
                          size: 16.0,
                          color: Colors.grey[600],
                        ),
                        onPressed: () => _showAnalysisDialog(context),
                      ),
                    
                    const SizedBox(width: 4.0),
                    
                    // Player rank (instead of showing pick number)
                    if (widget.draftPick.selectedPlayer != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 2.0), // Smaller padding
                        decoration: BoxDecoration(
                          color: _getRankColor(
                            widget.draftPick.selectedPlayer!.rank,
                            widget.draftPick.pickNumber,
                          ).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(3.0), // Smaller radius
                        ),
                        child: Text(
                          '#${widget.draftPick.selectedPlayer!.rank}',
                          style: TextStyle(
                            color: _getRankColor(
                              widget.draftPick.selectedPlayer!.rank,
                              widget.draftPick.pickNumber,
                            ),
                            fontWeight: FontWeight.bold,
                            fontSize: 11.0, // Smaller font
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildTeamLogo(String teamName) {
  // Get team abbreviation using the same method as the team selection screen
  String? abbr = NFLTeamMappings.fullNameToAbbreviation[teamName];
  
  print('Team: $teamName, Abbreviation: $abbr'); // Debug info
  
  // If no abbreviation, return placeholder
  if (abbr == null) {
    return _buildPlaceholderLogo(teamName);
  }
  
  // Use EXACTLY the same URL format as your team selection screen
  final logoUrl = 'https://a.espncdn.com/i/teamlogos/nfl/500/${abbr.toLowerCase()}.png';
  
  return Container(
    width: 25.0,
    height: 25.0,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      image: DecorationImage(
        image: NetworkImage(logoUrl),
        fit: BoxFit.cover,
      ),
    ),
  );
}

  Widget _buildPlaceholderLogo(String teamName) {
    final initials = teamName.split(' ')
        .map((word) => word.isNotEmpty ? word[0] : '')
        .join('')
        .toUpperCase();
    
    return Container(
      width: 25.0, // Smaller logo
      height: 25.0, // Smaller logo
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.blue.shade700,
      ),
      child: Center(
        child: Text(
          initials.length > 2 ? initials.substring(0, 2) : initials,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 10.0, // Smaller font
          ),
        ),
      ),
    );
  }
  
  void _showAnalysisDialog(BuildContext context) {
    if (widget.draftPick.selectedPlayer == null) return;
    
    // Get player
    Player player = widget.draftPick.selectedPlayer!;
    
    // Create simple analysis
    Map<String, dynamic> analysis = _analyzeSelectionSimple(
      player,
      widget.draftPick.teamName,
      widget.draftPick.pickNumber,
    );
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Analysis: ${player.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Player details
            Text(
              '${player.position}${player.school.isNotEmpty ? ' - ${player.school}' : ''}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text('Pick #${widget.draftPick.pickNumber} - Rank #${player.rank}'),
            const SizedBox(height: 16),
            
            // Value assessment
            const Text(
              'Value Assessment:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                color: _getAnalysisColor(analysis).withOpacity(0.2),
                borderRadius: BorderRadius.circular(4.0),
                border: Border.all(
                  color: _getAnalysisColor(analysis),
                  width: 1.0,
                ),
              ),
              child: Text(
                analysis['analysis'],
                style: TextStyle(
                  color: _getAnalysisColor(analysis),
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            // Value differential
            Text(
              'Value Differential: ${analysis['valueGap'] > 0 ? '+' : ''}${analysis['valueGap']}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: analysis['valueGap'] >= 0 ? Colors.green : Colors.red,
              ),
            ),
            
            // Additional analysis could go here
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
  
  Color _getPickNumberColor() {
    // Different colors for each round
    switch (widget.draftPick.round) {
      case '1':
        return Colors.blue.shade700;
      case '2':
        return Colors.green.shade700;
      case '3':
        return Colors.orange.shade700;
      case '4':
        return Colors.purple.shade700;
      case '5':
        return Colors.red.shade700;
      case '6':
        return Colors.teal.shade700;
      case '7':
        return Colors.brown.shade700;
      default:
        return Colors.grey.shade700;
    }
  }
  
  Color _getPositionColor(String position) {
    // Different colors for different position groups
    if (['QB', 'RB', 'WR', 'TE'].contains(position)) {
      return Colors.blue.shade700; // Offensive skill positions
    } else if (['OT', 'IOL'].contains(position)) {
      return Colors.green.shade700; // Offensive line
    } else if (['EDGE', 'IDL', 'DT', 'DE'].contains(position)) {
      return Colors.red.shade700; // Defensive line
    } else if (['LB', 'ILB', 'OLB'].contains(position)) {
      return Colors.orange.shade700; // Linebackers
    } else if (['CB', 'S', 'FS', 'SS'].contains(position)) {
      return Colors.purple.shade700; // Secondary
    } else {
      return Colors.grey.shade700; // Special teams, etc.
    }
  }
  
  Color _getRankColor(int rank, int pickNumber) {
    // Color based on difference between rank and pick number
    int diff = pickNumber - rank;
    
    if (diff >= 15) {
      return Colors.green.shade800; // Excellent value
    } else if (diff >= 5) {
      return Colors.green.shade600; // Good value
    } else if (diff >= -5) {
      return Colors.blue.shade600; // Fair value
    } else if (diff >= -15) {
      return Colors.orange.shade600; // Slight reach
    } else {
      return Colors.red.shade600; // Significant reach
    }
  }
  
  Color _getAnalysisColor(Map<String, dynamic> analysis) {
    if (analysis['isSignificantValue'] && analysis['isNeed']) {
      return Colors.green.shade800; // Perfect pick
    } else if (analysis['isSignificantValue']) {
      return Colors.green.shade600; // Great value
    } else if (analysis['isValue'] && analysis['isNeed']) {
      return Colors.green.shade600; // Good pick
    } else if (analysis['isValue']) {
      return Colors.blue.shade600; // Decent pick
    } else if (analysis['isNeed'] && !analysis['isReach']) {
      return Colors.blue.shade600; // Addressing need
    } else if (analysis['isReach']) {
      return Colors.red.shade600; // Reach pick
    } else {
      return Colors.grey.shade600; // Standard pick
    }
  }
  
  // Simple analysis method that doesn't require EnhancedPlayerSelection
  Map<String, dynamic> _analyzeSelectionSimple(Player player, String teamName, int pickNumber) {
    // Basic value analysis
    bool isValue = player.rank < pickNumber;
    bool isSignificantValue = player.rank <= pickNumber - 10;
    bool isReach = player.rank > pickNumber + 10;
    
    int valueGap = pickNumber - player.rank;
    String analysisText;
    
    // Simplified analysis text
    if (isSignificantValue) {
      analysisText = 'Great value selection - ranked much higher than this pick';
    } else if (isValue) {
      analysisText = 'Good value selection at this pick';
    } else if (isReach) {
      analysisText = 'Reach pick - selected earlier than rank suggests';
    } else {
      analysisText = 'Standard pick - reasonable selection at this position';
    }
    
    return {
      'isValue': isValue,
      'isSignificantValue': isSignificantValue,
      'isReach': isReach,
      'isNeed': false, // We don't have team needs info in this simple version
      'valueGap': valueGap,
      'analysis': analysisText,
    };
  }
}