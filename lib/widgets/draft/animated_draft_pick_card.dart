// lib/widgets/draft/animated_draft_pick_card.dart
import 'package:flutter/material.dart';
import '../../models/draft_pick.dart';
import '../../models/player.dart';
import '../../utils/constants.dart';

class AnimatedDraftPickCard extends StatefulWidget {
  final DraftPick draftPick;
  final bool isUserTeam;
  final bool isRecentPick;
  final List<String>? teamNeeds; // Add this parameter to pass team needs
  
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
          elevation: widget.isRecentPick ? 4.0 : 1.0,
          margin: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 2.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.0),
            side: BorderSide(
              color: widget.isUserTeam ? 
                  (isDarkMode ? Colors.blue.shade300 : Colors.blue) : 
                  Colors.transparent,
              width: widget.isUserTeam ? 2.0 : 0.0,
            ),
          ),
          color: cardColor,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
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
                        // Position and team
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 1.0),
                              margin: const EdgeInsets.only(right: 4.0),
                              decoration: BoxDecoration(
                                color: _getPositionColor(widget.draftPick.selectedPlayer!.position),
                                borderRadius: BorderRadius.circular(3.0),
                              ),
                              child: Text(
                                widget.draftPick.selectedPlayer!.position,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10.0,
                                ),
                              ),
                            ),
                            Text(
                              widget.draftPick.teamName,
                              style: TextStyle(
                                color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                                fontSize: 11.0,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
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
                        // Team needs on a single row
                        Row(
                          children: [
                            // "Team Needs:" label
                            const Text(
                              'Team Needs: ',
                              style: TextStyle(
                                fontSize: 11.0, 
                                fontStyle: FontStyle.italic,
                                color: Colors.grey,
                              ),
                            ),
                            // Display needs
                            if (widget.teamNeeds != null && widget.teamNeeds!.isNotEmpty)
                              Expanded(
                                child: Wrap(
                                  spacing: 4.0,
                                  runSpacing: 4.0, // Add some vertical spacing if wrapping occurs
                                  children: widget.teamNeeds!.take(3).map((need) => 
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 1.0),
                                      decoration: BoxDecoration(
                                        color: _getPositionColor(need).withOpacity(
                                          isDarkMode ? 0.5 : 0.7
                                        ),
                                        borderRadius: BorderRadius.circular(3.0),
                                      ),
                                      child: Text(
                                        need,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 10.0,
                                        ),
                                      ),
                                    )
                                  ).toList(),
                                ),
                              )
                            else
                              Text(
                                'No team needs data',
                                style: TextStyle(
                                  color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                                  fontSize: 11.0,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                          ],
                        ),
                      ],
                    )
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
                          color: isDarkMode ? Colors.orange[300] : Colors.orange[700],
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
                          color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                        ),
                        onPressed: () => _showAnalysisDialog(context),
                      ),
                    
                    const SizedBox(width: 4.0),
                    
                    // Player rank clearly labeled
                    if (widget.draftPick.selectedPlayer != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 2.0),
                        decoration: BoxDecoration(
                          color: _getRankColor(
                            widget.draftPick.selectedPlayer!.rank,
                            widget.draftPick.pickNumber,
                          ).withOpacity(isDarkMode ? 0.4 : 0.2),
                          borderRadius: BorderRadius.circular(3.0),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Rank: ',
                              style: TextStyle(
                                color: isDarkMode ? Colors.white : Colors.black87,
                                fontSize: 10.0,
                              ),
                            ),
                            Text(
                              '#${widget.draftPick.selectedPlayer!.rank}',
                              style: TextStyle(
                                color: isDarkMode ? 
                                    Colors.white : 
                                    _getRankColor(
                                      widget.draftPick.selectedPlayer!.rank,
                                      widget.draftPick.pickNumber,
                                    ),
                                fontWeight: FontWeight.bold,
                                fontSize: 11.0,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildTeamLogo(String teamName) {
    // First try to find the abbreviation in the mapping
    String? abbr = NFLTeamMappings.fullNameToAbbreviation[teamName];
    
    // If we can't find it in the mapping, check if it's already an abbreviation
    if (abbr == null && teamName.length <= 3) {
      abbr = teamName;
    }
    
    // If we still don't have an abbreviation, create a placeholder
    if (abbr == null) {
      return _buildPlaceholderLogo(teamName);
    }
    
    // Convert abbreviation to lowercase for URL
    final logoUrl = 'https://a.espncdn.com/i/teamlogos/nfl/500/${abbr.toLowerCase()}.png';
    
    // Handle the image with error fallback
    return Container(
      width: 25.0,
      height: 25.0,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
      ),
      child: ClipOval(
        child: Image.network(
          logoUrl,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            // On error, return the placeholder
            return _buildPlaceholderLogo(teamName);
          },
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
      width: 25.0,
      height: 25.0,
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
            fontSize: 10.0,
          ),
        ),
      ),
    );
  }
  
  void _showAnalysisDialog(BuildContext context) {
    if (widget.draftPick.selectedPlayer == null) return;
    
    // Get player
    Player player = widget.draftPick.selectedPlayer!;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    // Create simple analysis
    Map<String, dynamic> analysis = _analyzeSelectionSimple(
      player,
      widget.draftPick.teamName,
      widget.draftPick.pickNumber,
    );
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDarkMode ? Colors.grey.shade800 : Colors.white,
        title: Text(
          'Analysis: ${player.name}',
          style: TextStyle(
            color: isDarkMode ? Colors.white : Colors.black
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Player details
            Text(
              '${player.position}${player.school.isNotEmpty ? ' - ${player.school}' : ''}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : Colors.black
              ),
            ),
            Text(
              'Pick #${widget.draftPick.pickNumber} - Rank #${player.rank}',
              style: TextStyle(
                color: isDarkMode ? Colors.grey.shade300 : Colors.black87
              ),
            ),
            const SizedBox(height: 16),
            
            // Value assessment
            Text(
              'Value Assessment:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : Colors.black
              ),
            ),
            const SizedBox(height: 4),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                color: _getAnalysisColor(analysis).withOpacity(isDarkMode ? 0.3 : 0.2),
                borderRadius: BorderRadius.circular(4.0),
                border: Border.all(
                  color: _getAnalysisColor(analysis),
                  width: 1.0,
                ),
              ),
              child: Text(
                analysis['analysis'],
                style: TextStyle(
                  color: isDarkMode ? Colors.white : _getAnalysisColor(analysis),
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
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Close',
              style: TextStyle(
                color: isDarkMode ? Colors.blue.shade300 : Colors.blue
              ),
            ),
          ),
        ],
      ),
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
    if (['QB', 'RB', 'WR', 'TE'].contains(position)) {
      return isDarkMode ? Colors.blue.shade600 : Colors.blue.shade700; // Offensive skill positions
    } else if (['OT', 'IOL'].contains(position)) {
      return isDarkMode ? Colors.green.shade600 : Colors.green.shade700; // Offensive line
    } else if (['EDGE', 'IDL', 'DT', 'DE'].contains(position)) {
      return isDarkMode ? Colors.red.shade600 : Colors.red.shade700; // Defensive line
    } else if (['LB', 'ILB', 'OLB'].contains(position)) {
      return isDarkMode ? Colors.orange.shade600 : Colors.orange.shade700; // Linebackers
    } else if (['CB', 'S', 'FS', 'SS'].contains(position)) {
      return isDarkMode ? Colors.purple.shade600 : Colors.purple.shade700; // Secondary
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
  
  Color _getAnalysisColor(Map<String, dynamic> analysis) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    if (analysis['isSignificantValue'] && analysis['isNeed']) {
      return isDarkMode ? Colors.green.shade400 : Colors.green.shade800; // Perfect pick
    } else if (analysis['isSignificantValue']) {
      return isDarkMode ? Colors.green.shade300 : Colors.green.shade600; // Great value
    } else if (analysis['isValue'] && analysis['isNeed']) {
      return isDarkMode ? Colors.green.shade300 : Colors.green.shade600; // Good pick
    } else if (analysis['isValue']) {
      return isDarkMode ? Colors.blue.shade300 : Colors.blue.shade600; // Decent pick
    } else if (analysis['isNeed'] && !analysis['isReach']) {
      return isDarkMode ? Colors.blue.shade300 : Colors.blue.shade600; // Addressing need
    } else if (analysis['isReach']) {
      return isDarkMode ? Colors.red.shade300 : Colors.red.shade600; // Reach pick
    } else {
      return isDarkMode ? Colors.grey.shade300 : Colors.grey.shade600; // Standard pick
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