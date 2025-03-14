// lib/screens/available_players_tab.dart
import 'dart:math';

import 'package:flutter/material.dart';
import '../models/player.dart';
import '../services/player_descriptions_service.dart';
import '../utils/team_logo_utils.dart';
import '../widgets/player/player_details_dialog.dart';
import '../utils/mock_player_data.dart';

class AvailablePlayersTab extends StatefulWidget {
  final List<List<dynamic>> availablePlayers;
  final bool selectionEnabled;
  final Function(int)? onPlayerSelected;
  final String? userTeam;
  final List<String> selectedPositions;

  const AvailablePlayersTab({
    required this.availablePlayers, 
    this.selectionEnabled = false,
    this.onPlayerSelected,
    this.userTeam,
    this.selectedPositions = const [],
    super.key
  });

  @override
  _AvailablePlayersTabState createState() => _AvailablePlayersTabState();
}

class _AvailablePlayersTabState extends State<AvailablePlayersTab> {
  String _searchQuery = '';
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
    
    if (widget.selectedPositions != oldWidget.selectedPositions) {
      _initializeSelectedPlayers();
    }
  }
  
  void _initializeSelectedPlayers() {
    _selectedPlayerIds = {};
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
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(8.0),
              border: Border.all(color: Colors.grey[300]!),
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
                          decoration: const InputDecoration(
                            hintText: 'Search Players',
                            prefixIcon: Icon(Icons.search, size: 18),
                            contentPadding: EdgeInsets.zero,
                            isDense: true,
                            border: OutlineInputBorder(),
                          ),
                          style: const TextStyle(fontSize: 14),
                          onChanged: (value) {
                            setState(() {
                              _searchQuery = value;
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Player count
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${filteredPlayers.length} players',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[800],
                        ),
                      ),
                    ),
                    // Reset filter button
                  if (_selectedPositions.isNotEmpty)  // Use the new Set
                    IconButton(
                      icon: const Icon(Icons.clear, size: 16),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      visualDensity: VisualDensity.compact,
                      onPressed: () {
                        setState(() {
                          _selectedPositions.clear();  // Clear the Set
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
                            if (_selectedPositions.isEmpty)  // Use the new Set
                              _buildPositionChip('All', true, () {}),
                            if (_selectedPositions.isNotEmpty)  // Use the new Set
                              _buildPositionChip('All', false, () {
                                setState(() {
                                  _selectedPositions.clear();  // Clear the Set with parentheses
                                });
                              }),
                              
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
          
          const SizedBox(height: 6),
          
          // Player List with Card-based Layout (similar to Draft Order)
          Expanded(
            child: ListView.builder(
              itemCount: filteredPlayers.length,
              itemBuilder: (context, index) {
                final player = filteredPlayers[index];
                final isDarkMode = Theme.of(context).brightness == Brightness.dark;
                
                // Check if player is selected or position has been drafted
                bool isSelected = _selectedPlayerIds.contains(player.id);
                bool positionDrafted = widget.selectedPositions.contains(player.position);
                
                return Card(
                  elevation: 1.0,
                  margin: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 2.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                    side: BorderSide(
                      color: isSelected || positionDrafted ? 
                          Colors.transparent : 
                          (isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300),
                      width: 1.0,
                    ),
                  ),
                  color: isSelected || positionDrafted ? 
                      (isDarkMode ? Colors.grey.shade700 : Colors.grey.shade100) : 
                      (isDarkMode ? Colors.grey.shade800 : Colors.white),
                  child: InkWell(
                    onTap: isSelected || positionDrafted ? null : () {
                      // Show the player details dialog when tapping on the card
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
                                  color: isSelected || positionDrafted ? Colors.grey : Colors.black,
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
                                        color: isSelected || positionDrafted ? Colors.grey.shade400 : Colors.grey.shade600,
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
                            color: _getPositionColor(player.position).withOpacity(isSelected || positionDrafted ? 0.1 : 0.2),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: isSelected || positionDrafted ? Colors.grey.shade400 : _getPositionColor(player.position),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            player.position,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: isSelected || positionDrafted ? Colors.grey : _getPositionColor(player.position),
                            ),
                          ),
                        ),
                        
                        // Info Button
                        if (!isSelected && !positionDrafted)
                          IconButton(
                            onPressed: () {
                              _showPlayerDetails(context, player);
                            },
                            icon: Icon(
                              Icons.info_outline,
                              size: 18,
                              color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                            ),
                            visualDensity: VisualDensity.compact,
                            padding: const EdgeInsets.all(4),
                            constraints: const BoxConstraints(),
                            tooltip: 'Player Details',
                          ),
                        
                        // Draft button (if enabled)
                        if (widget.selectionEnabled)
                          Padding(
                            padding: const EdgeInsets.only(left: 4.0),
                            child: SizedBox(
                              width: 60,
                              height: 30,
                              child: ElevatedButton(
                                onPressed: isSelected || positionDrafted ? null : () {
                                  if (widget.onPlayerSelected != null) {
                                    widget.onPlayerSelected!(player.id);
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  disabledBackgroundColor: Colors.grey[300],
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                                  minimumSize: const Size(0, 28),
                                ),
                                child: const Text(
                                  'Draft',
                                  style: TextStyle(
                                    color: Colors.white,
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
  // Add debug output
  debugPrint("Showing details for player: ${player.name}");
  
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

  Widget _buildPositionChip(String label, bool isSelected, VoidCallback onTap, {bool isOffensive = true}) {
    bool isPositionDrafted = widget.selectedPositions.contains(label);
    
    return Container(
      margin: const EdgeInsets.only(right: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: isSelected 
                ? (isOffensive ? Colors.blue[100] : Colors.red[100])
                : (isOffensive ? Colors.blue[50] : Colors.red[50]),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected 
                  ? (isOffensive ? Colors.blue[700]! : Colors.red[700]!)
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
                  color: isOffensive ? Colors.blue[700] : Colors.red[700],
                ),
              ),
              if (isPositionDrafted && label != 'All')
                Positioned(
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 1.5,
                    color: isOffensive ? Colors.blue[700]! : Colors.red[700]!,
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