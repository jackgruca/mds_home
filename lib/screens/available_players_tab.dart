// lib/screens/available_players_tab.dart
import 'dart:math';

import 'package:flutter/material.dart';
import '../models/player.dart';
import '../services/player_descriptions_service.dart';
import '../utils/constants.dart';
import '../utils/team_logo_utils.dart';
import '../widgets/player/player_details_dialog.dart';
import '../utils/mock_player_data.dart';

class AvailablePlayersTab extends StatefulWidget {
  final List<List<dynamic>> availablePlayers;
  final bool selectionEnabled;
  final Function(int)? onPlayerSelected;
  final String? userTeam;
  final Map<String, List<String>> teamSelectedPositions;

  const AvailablePlayersTab({
    required this.availablePlayers, 
    this.selectionEnabled = false,
    this.onPlayerSelected,
    this.userTeam,
    this.teamSelectedPositions = const {},
    super.key
  });

  @override
  _AvailablePlayersTabState createState() => _AvailablePlayersTabState();
}

class _AvailablePlayersTabState extends State<AvailablePlayersTab> {
  final String _searchQuery = '';
  final Set<String> _selectedPositions = {};
  
  // Track selected (crossed out) players locally
  Set<int> _selectedPlayerIds = {};

  // Offensive and defensive position groupings
  final List<String> _offensivePositions = ['QB', 'RB', 'WR', 'TE', 'OT', 'IOL', 'OL', 'G', 'C', 'FB'];
  final List<String> _defensivePositions = ['EDGE', 'DL', 'IDL', 'DT', 'DE', 'LB', 'ILB', 'OLB', 'CB', 'S', 'FS', 'SS'];

  @override
  void initState() {
    super.initState();
    _initializeSelectedPlayers();
  }
  
  @override
  void didUpdateWidget(AvailablePlayersTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Reinitialize when positions or current team changes
    if (widget.teamSelectedPositions != oldWidget.teamSelectedPositions ||
        widget.userTeam != oldWidget.userTeam) {
      _initializeSelectedPlayers();
      
      // Debug logging
      if (widget.userTeam != oldWidget.userTeam) {
        debugPrint("Active team changed from ${oldWidget.userTeam} to ${widget.userTeam}");
        _debugPositionTrackingStatus();
      }
    }
  }
  
  void _initializeSelectedPlayers() {
    _selectedPlayerIds = {};
    debugPrint("Initialized player selection for team: ${widget.userTeam}");
    _debugPositionTrackingStatus();
  }

  // Check if a position has been drafted by the current team
  bool isPositionDraftedByCurrentTeam(String position) {
    if (widget.userTeam != null && 
        widget.teamSelectedPositions.containsKey(widget.userTeam)) {
      return widget.teamSelectedPositions[widget.userTeam]!.contains(position);
    }
    return false;
  }
  
  // Debug method to help trace position tracking issues
  void _debugPositionTrackingStatus() {
    debugPrint("==== POSITION TRACKING STATUS ====");
    debugPrint("Current picking team: ${widget.userTeam}");
    debugPrint("Teams with position data: ${widget.teamSelectedPositions.keys.join(", ")}");
    widget.teamSelectedPositions.forEach((team, positions) {
      debugPrint("$team drafted positions: ${positions.join(", ")}");
    });
    debugPrint("=================================");
  }

  @override
  Widget build(BuildContext context) {
    // Map column names to indices
    Map<String, int> columnIndices = {};
    if (widget.availablePlayers.isNotEmpty) {
      List<String> headers = widget.availablePlayers[0].map<String>((dynamic col) => col.toString().toUpperCase()).toList();
      for (int i = 0; i < headers.length; i++) {
        columnIndices[headers[i]] = i;
      }
    }
    
    // Get column indices
    int idIndex = columnIndices['ID'] ?? 0;
    int nameIndex = columnIndices["NAME"] ?? 1;
    int positionIndex = columnIndices["POSITION"] ?? 2;
    int schoolIndex = columnIndices['SCHOOL'] ?? 3;
    int rankIndex = columnIndices["RANK_COMBINED"] ?? widget.availablePlayers[0].length - 1;

    // Filter players
    List<Player> filteredPlayers = [];
    for (var row in widget.availablePlayers.skip(1)) {
      try {
        // Skip if we don't have enough elements
        if (row.length <= positionIndex) continue;
        
        // Extract data and create Player object
        Player player = Player.fromCsvRowWithHeaders(row, columnIndices);
        
        // Filter by position and search
        bool matchesPosition = _selectedPositions.isEmpty || _selectedPositions.contains(player.position);
        bool matchesSearch = _searchQuery.isEmpty || 
                          player.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                          player.school.toLowerCase().contains(_searchQuery.toLowerCase());
        
        if (matchesPosition && matchesSearch) {
          filteredPlayers.add(player);
        }
      } catch (e) {
        debugPrint("Error processing player row: $e");
      }
    }

    // Get all available positions for filters
    Set<String> availablePositions = filteredPlayers
        .map((player) => player.position)
        .toSet();
    
    // Split into offensive and defensive positions that are actually available
    List<String> availableOffensive = availablePositions
        .where((pos) => _offensivePositions.contains(pos))
        .toList();
    
    List<String> availableDefensive = availablePositions
        .where((pos) => _defensivePositions.contains(pos))
        .toList();
    
    // Sort positions alphabetically within each group
    availableOffensive.sort();
    availableDefensive.sort();

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          // Compact search and filter area
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark 
                  ? Colors.grey.shade800 
                  : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8.0),
              border: Border.all(
                color: Theme.of(context).brightness == Brightness.dark 
                    ? Colors.grey.shade700 
                    : Colors.grey.shade300,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Row with search bar and player count
                Row(
                  children: [
                    // Search bar - compact version
                    Expanded(
                      child: SizedBox(
                        height: 36,
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: 'Search Players',
                            prefixIcon: const Icon(Icons.search),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                            contentPadding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
                          ),
                          style: const TextStyle(fontSize: TextConstants.kSearchBarTextSize),
                          onChanged: (value) {
                            // search logic
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Player count
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Theme.of(context).brightness == Brightness.dark 
                            ? Colors.grey.shade700 
                            : Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${filteredPlayers.length} players',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).brightness == Brightness.dark 
                            ? Colors.white 
                            : Colors.grey.shade800,
                        ),
                      ),
                    ),
                    // Reset filter button
                  if (_selectedPositions.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.clear, size: 16),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      visualDensity: VisualDensity.compact,
                      onPressed: () {
                        setState(() {
                          _selectedPositions.clear();
                        });
                      },
                      tooltip: 'Clear filter',
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                
                // Compact position filters
                Row(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            // All positions chip
                            if (_selectedPositions.isEmpty)
                              _buildPositionChip('All', true, () {}, isDraftedByCurrentTeam: false),
                            if (_selectedPositions.isNotEmpty)
                              _buildPositionChip('All', false, () {
                                setState(() {
                                  _selectedPositions.clear();
                                });
                              }, isDraftedByCurrentTeam: false),
                              
                            // Offensive positions
                            ...availableOffensive.map((position) => 
                              _buildPositionChip(
                                position, 
                                _selectedPositions.contains(position), 
                                () {
                                  setState(() {
                                    if (_selectedPositions.contains(position)) {
                                      _selectedPositions.remove(position);
                                    } else {
                                      _selectedPositions.add(position);
                                    }
                                  });
                                },
                                isOffensive: true,
                                isDraftedByCurrentTeam: isPositionDraftedByCurrentTeam(position),
                              )
                            ),
                            
                            // Defensive positions
                            ...availableDefensive.map((position) => 
                              _buildPositionChip(
                                position, 
                                _selectedPositions.contains(position), 
                                () {
                                  setState(() {
                                    if (_selectedPositions.contains(position)) {
                                      _selectedPositions.remove(position);
                                    } else {
                                      _selectedPositions.add(position);
                                    }
                                  });
                                },
                                isOffensive: false,
                                isDraftedByCurrentTeam: isPositionDraftedByCurrentTeam(position),
                              )
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
          
          // Player List with Card-based Layout (similar to Draft Order)
          Expanded(
            child: ListView.builder(
              itemCount: filteredPlayers.length,
              itemBuilder: (context, index) {
                final player = filteredPlayers[index];
                final isDarkMode = Theme.of(context).brightness == Brightness.dark;
                
                // Check if player is selected or position has been drafted by current team
                bool isSelected = _selectedPlayerIds.contains(player.id);
                bool positionDrafted = isPositionDraftedByCurrentTeam(player.position);
                
                                                  // Debug current player and position status for this card
                                  if ((player.position == "QB" || player.position == "WR" || player.position == "RB") && widget.selectionEnabled) {
                                    debugPrint(
                                      "Position ${player.position} drafted by current team (${widget.userTeam})? " "${isPositionDraftedByCurrentTeam(player.position)}"
                                    );
                                  }
                                  
                                  return Card(
                  elevation: 1.0,
                  margin: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 2.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                    side: BorderSide(
                      color: isSelected ? 
                          Colors.transparent : 
                          (isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300),
                      width: 1.0,
                    ),
                  ),
                  // Apply visual styling for previously drafted positions
                  color: isSelected ? 
                      (isDarkMode ? Colors.grey.shade700 : Colors.grey.shade700) : 
                      (positionDrafted ? 
                        (isDarkMode ? Colors.grey.shade800.withOpacity(0.7) : Colors.grey.shade50) :
                        (isDarkMode ? Colors.grey.shade800 : Colors.white)),
                  child: InkWell(
                    // Always allow tapping the card for player details
                    onTap: () {
                      _showPlayerDetails(context, player);
                    },
                    borderRadius: BorderRadius.circular(8.0),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
                      child: Row(
                        children: [
                          // Rank number (like pick number in draft order)
                         Container(
                          width: 30.0,
                          height: 30.0,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.blue.shade700, // Consistent blue color for all rankings
                          ),
                          child: Center(
                            child: Text(
                              '#${player.rank}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12.0,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(width: 8.0),
                        
                        // School logo - make sure this is visible and given enough space
                        player.school.isNotEmpty
                          ? TeamLogoUtils.buildCollegeTeamLogo(
                              player.school,
                              size: 30.0,  // Slightly larger for better visibility
                            )
                          : const SizedBox(width: 30, height: 30),  // Placeholder space to maintain alignment
                        
                        const SizedBox(width: 8.0),
                        
                        // Player info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Player name
                              Text(
                                player.name,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14.0,
                                  // Apply gray text for previously drafted positions
                                  color: positionDrafted 
                                    ? Colors.grey 
                                    : (Theme.of(context).brightness == Brightness.dark 
                                        ? Colors.white 
                                        : Colors.black),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              // School and position
                              Row(
                                children: [
                                  if (player.school.isNotEmpty)
                                    Text(
                                      player.school,
                                      style: TextStyle(
                                        fontSize: 12.0,
                                        color: positionDrafted 
                                          ? Colors.grey.shade400 
                                          : (Theme.of(context).brightness == Brightness.dark 
                                              ? Colors.grey.shade300 
                                              : Colors.grey.shade600),
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                                  
                        // Position badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getPositionColor(player.position).withOpacity(positionDrafted ? 0.1 : 0.2),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: positionDrafted ? Colors.grey.shade400 : _getPositionColor(player.position),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            player.position,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: positionDrafted ? Colors.grey : _getPositionColor(player.position),
                            ),
                          ),
                        ),
                        
                        // Info Button
                        IconButton(
                          onPressed: () {
                            _showPlayerDetails(context, player);
                          },
                          icon: Icon(
                            Icons.info_outline,
                            size: 18,
                            color: isDarkMode ? Colors.grey.shade600 : Colors.grey.shade600,
                          ),
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.all(4),
                          constraints: const BoxConstraints(),
                          tooltip: 'Player Details',
                        ),
                        
                        // Draft button (if enabled)
                        if (widget.selectionEnabled && widget.userTeam != null)
                          Padding(
                            padding: const EdgeInsets.only(left: 4.0),
                            child: SizedBox(
                              width: 60,
                              height: 30,
                              child: ElevatedButton(
                                // Always allow drafting, even if position was already drafted
                                onPressed: () {
                                  if (widget.onPlayerSelected != null) {
                                    widget.onPlayerSelected!(player.id);
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  // Visual indication of previously drafted position
                                  backgroundColor: positionDrafted ? Colors.green : Colors.green,
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                                  minimumSize: const Size(0, 28),
                                ),
                                child: Text(
                                  // Change text to indicate if this is a duplicate position
                                  positionDrafted ? 'Draft' : 'Draft',
                                  style: TextStyle(
                                    color: positionDrafted ? Colors.white : Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
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
    enrichedPlayer = Player(
      id: player.id,
      name: player.name,
      position: player.position,
      rank: player.rank,
      school: player.school,
      notes: player.notes,
      description: "No detailed player information available yet for ${player.name}.",
      strengths: "Information not available",
      weaknesses: "Information not available",
    );
  }
  
  // Show the dialog with enriched player data
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return PlayerDetailsDialog(player: enrichedPlayer);
    },
  );
}

  Widget _buildPositionChip(
    String label, 
    bool isSelected, 
    VoidCallback onTap, 
    {bool isOffensive = true, bool isDraftedByCurrentTeam = false}
  ) {
    bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    Color getBgColor() {
      if (isDarkMode) {
        return isSelected 
            ? (isOffensive ? Colors.blue.shade800 : Colors.red.shade800) 
            : (isOffensive ? Colors.blue.shade900.withOpacity(0.3) : Colors.red.shade900.withOpacity(0.3));
      } else {
        return isSelected 
            ? (isOffensive ? Colors.blue.shade100 : Colors.red.shade100)
            : (isOffensive ? Colors.blue.shade50 : Colors.red.shade50);
      }
    }
  
    Color getTextColor() {
      if (isDarkMode) {
        return isOffensive ? Colors.blue.shade200 : Colors.red.shade200;
      } else {
        return isOffensive ? Colors.blue.shade700 : Colors.red.shade700;
      }
    }

    return Container(
      margin: const EdgeInsets.only(right: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: getBgColor(),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected 
                ? getTextColor()
                : Colors.transparent,
          ),
        ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: getTextColor(),
                ),
              ),
              // Only strike through if position drafted by current team
              if (isDraftedByCurrentTeam && label != 'All')
                Positioned(
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 1.5,
                    color: isDarkMode ? Colors.grey.shade500 : Colors.grey.shade700,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
  
  Color _getPositionColor(String position) {
    // Offensive position colors
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