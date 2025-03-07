// lib/widgets/draft/animated_draft_pick_card.dart
import 'package:flutter/material.dart';
import '../../models/draft_pick.dart';
import '../../models/player.dart';
import '../../services/enhanced_player_selection.dart';
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
  
  final EnhancedPlayerSelection _playerAnalyzer = EnhancedPlayerSelection();
  
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

  Widget _buildTeamLogo(String teamName) {
  // First try to get the abbreviation from the mapping
  String? abbr = NFLTeamMappings.fullNameToAbbreviation[teamName];
  
  return _buildPlaceholderLogo(teamName);
}

Widget _buildPlaceholderLogo(String teamName) {
  // Get the first character of each word in the team name
  final initials = teamName.split(' ')
      .map((word) => word.isNotEmpty ? word[0] : '')
      .join('')
      .toUpperCase();
  
  return Container(
    width: 40.0,
    height: 40.0,
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
          fontSize: 14.0,
        ),
      ),
    ),
  );
}

  ImageProvider _getTeamLogoImage(String teamName) {
  // First try to get the abbreviation from the mapping
  String? abbr = NFLTeamMappings.fullNameToAbbreviation[teamName];
  
  if (abbr != null) {
    // If we have an abbreviation, use it to form the URL
    return NetworkImage(
      'https://a.espncdn.com/i/teamlogos/nfl/500/${abbr.toLowerCase()}.png',
    );
  } else {
    // If we don't have an abbreviation, use a generic NFL logo
    return const NetworkImage(
      'https://a.espncdn.com/i/teamlogos/nfl/500/nfl.png',
    );
    
    // Alternatively, if you have a local placeholder image:
    // return const AssetImage('assets/placeholder.png');
  }
}

  @override
  Widget build(BuildContext context) {
    // Determine the card color
    Color cardColor = _getCardColor();
    
    return FadeTransition(
      opacity: _fadeAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Card(
          elevation: widget.isRecentPick ? 4.0 : 1.0,
          margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
            side: BorderSide(
              color: widget.isUserTeam ? Colors.blue : Colors.transparent,
              width: widget.isUserTeam ? 2.0 : 0.0,
            ),
          ),
          color: cardColor,
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with pick number and team
                _buildHeader(),
                
                // Divider
                const Divider(height: 16.0),
                
                // Player info if selected
                if (widget.draftPick.selectedPlayer != null)
                  _buildPlayerInfo()
                else
                  const Text('Selection pending...', style: TextStyle(fontStyle: FontStyle.italic)),
                  
                // Trade information if applicable  
                if (widget.draftPick.tradeInfo != null && widget.draftPick.tradeInfo!.isNotEmpty)
                  _buildTradeInfo(),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildHeader() {
  return Row(
    children: [
      // Pick number with round indicator
      Container(
        width: 50.0,
        height: 50.0,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _getPickNumberColor(),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${widget.draftPick.pickNumber}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16.0,
                ),
              ),
              Text(
                'Rd ${widget.draftPick.round}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10.0,
                ),
              ),
            ],
          ),
        ),
      ),
      const SizedBox(width: 12.0),
      
      // Team logo and name
      Expanded(
        child: Row(
          children: [
            // Team Logo (using the new method)
            _buildTeamLogo(widget.draftPick.teamName),
            const SizedBox(width: 8.0),
            
            // Team Name
            Expanded(
              child: Text(
                widget.draftPick.teamName,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16.0,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    ],
  );
}
  
  Widget _buildPlayerInfo() {
    Player player = widget.draftPick.selectedPlayer!;
    
    // Mock analysis - would ideally use a real TeamNeed object
    TeamNeed mockNeed = TeamNeed(
      teamName: widget.draftPick.teamName,
      needs: [player.position],
    );
    
    Map<String, dynamic> analysis = _playerAnalyzer.analyzeSelection(
      player,
      widget.draftPick.teamName,
      widget.draftPick.pickNumber,
      mockNeed,
    );
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Player name and position
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    player.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18.0,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
                        decoration: BoxDecoration(
                          color: _getPositionColor(player.position),
                          borderRadius: BorderRadius.circular(4.0),
                        ),
                        child: Text(
                          player.position,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12.0,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8.0),
                      if (player.school.isNotEmpty)
                        Text(
                          player.school,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12.0,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Player rank
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Text(
                  'Rank',
                  style: TextStyle(
                    fontSize: 12.0,
                    color: Colors.grey,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(4.0),
                  decoration: BoxDecoration(
                    color: _getRankColor(player.rank, widget.draftPick.pickNumber),
                    borderRadius: BorderRadius.circular(4.0),
                  ),
                  child: Text(
                    '#${player.rank}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        
        const SizedBox(height: 8.0),
        
        // Pick analysis
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
              fontSize: 12.0,
              color: _getAnalysisColor(analysis),
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildTradeInfo() {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Row(
        children: [
          const Icon(
            Icons.swap_horiz,
            color: Colors.deepOrange,
            size: 16.0,
          ),
          const SizedBox(width: 4.0),
          Expanded(
            child: Text(
              widget.draftPick.tradeInfo!,
              style: const TextStyle(
                fontSize: 12.0,
                fontStyle: FontStyle.italic,
                color: Colors.deepOrange,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Color _getCardColor() {
    if (widget.isUserTeam) {
      return Colors.blue.shade50;
    } else if (widget.isRecentPick) {
      return Colors.amber.shade50;
    } else {
      return Colors.white;
    }
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
}