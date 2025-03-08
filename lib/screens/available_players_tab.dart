// lib/screens/available_players_tab.dart
import 'package:flutter/material.dart';

class AvailablePlayersTab extends StatefulWidget {
  final List<List<dynamic>> availablePlayers;
  final bool selectionEnabled;
  final Function(int)? onPlayerSelected;
  final String? userTeam;
  final List<String> selectedPositions; // Add this to track selected positions

  const AvailablePlayersTab({
    required this.availablePlayers, 
    this.selectionEnabled = false,
    this.onPlayerSelected,
    this.userTeam,
    this.selectedPositions = const [], // Default to empty list
    super.key
  });

  @override
  _AvailablePlayersTabState createState() => _AvailablePlayersTabState();
}

class _AvailablePlayersTabState extends State<AvailablePlayersTab> {
  String _searchQuery = '';
  String _selectedPosition = '';
  
  // Track selected (crossed out) players locally
  Set<int> _selectedPlayerIds = {};

  // Offensive and defensive position groupings
  final List<String> _offensivePositions = ['QB', 'RB', 'WR', 'TE', 'OT', 'IOL', 'OL', 'G', 'C', 'FB'];
  final List<String> _defensivePositions = ['EDGE', 'DL', 'IDL', 'DT', 'DE', 'LB', 'ILB', 'OLB', 'CB', 'S', 'FS', 'SS'];

  @override
  void initState() {
    super.initState();
    
    // Initialize selected players from the draft picks
    _initializeSelectedPlayers();
  }
  
  @override
  void didUpdateWidget(AvailablePlayersTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Update if the selected positions list changed
    if (widget.selectedPositions != oldWidget.selectedPositions) {
      _initializeSelectedPlayers();
    }
  }
  
  void _initializeSelectedPlayers() {
    // This would ideally come from your draft picks data
    // For now we'll just use the selected positions list
    _selectedPlayerIds = {};
    
    // In a real implementation, you would load the selected player IDs
    // from your drafting data structure
  }

  @override
  Widget build(BuildContext context) {
    List<List<dynamic>> filteredPlayers = widget.availablePlayers.skip(1).where((player) {
      // Normalize text for comparison
      String playerName = player[1].toString().trim().toLowerCase();
      String searchQuery = _searchQuery.trim().toLowerCase();
      String playerPosition = player[2].toString().trim().toLowerCase();
      
      bool matchesSearch = searchQuery.isEmpty || playerName.contains(searchQuery);
      bool matchesPosition = _selectedPosition.isEmpty || playerPosition == _selectedPosition.toLowerCase();

      return matchesSearch && matchesPosition;
    }).toList();

    // Get all available positions for filters
    Set<String> availablePositions = widget.availablePlayers
        .skip(1)
        .map((player) => player[2].toString())
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
      padding: const EdgeInsets.all(8.0), // Reduced padding
      child: Column(
        children: [
          // Compact search and filter area
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0), // Reduced padding
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(8.0),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min, // Keep this section as small as possible
              children: [
                // Row with search bar and player count
                Row(
                  children: [
                    // Search bar - compact version
                    Expanded(
                      child: SizedBox(
                        height: 36, // Smaller height
                        child: TextField(
                          decoration: const InputDecoration(
                            hintText: 'Search Players',
                            prefixIcon: Icon(Icons.search, size: 18),
                            contentPadding: EdgeInsets.zero,
                            isDense: true, // Important for reducing text field height
                            border: OutlineInputBorder(),
                          ),
                          style: const TextStyle(fontSize: 14),
                          onChanged: (value) {
                            setState(() {
                              _searchQuery = value.trim().toLowerCase();
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
                    if (_selectedPosition.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.clear, size: 16),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        visualDensity: VisualDensity.compact,
                        onPressed: () {
                          setState(() {
                            _selectedPosition = '';
                          });
                        },
                        tooltip: 'Clear filter',
                      ),
                  ],
                ),
                
                const SizedBox(height: 4), // Very small gap
                
                // Compact position filters
                Row(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            // All positions chip
                            if (_selectedPosition.isEmpty)
                              _buildPositionChip('All', true, () {}),
                            if (_selectedPosition.isNotEmpty)
                              _buildPositionChip('All', false, () {
                                setState(() {
                                  _selectedPosition = '';
                                });
                              }),
                              
                            // Offensive positions
                            ...availableOffensive.map((position) => 
                              _buildPositionChip(
                                position, 
                                _selectedPosition == position, 
                                () {
                                  setState(() {
                                    _selectedPosition = _selectedPosition == position ? '' : position;
                                  });
                                },
                                isOffensive: true,
                              )
                            ),
                            
                            // Defensive positions
                            ...availableDefensive.map((position) => 
                              _buildPositionChip(
                                position, 
                                _selectedPosition == position, 
                                () {
                                  setState(() {
                                    _selectedPosition = _selectedPosition == position ? '' : position;
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
          
          const SizedBox(height: 6), // Small gap
          
          // Data Table with improved styling
          Expanded(
            child: Card(
              elevation: 2,
              margin: EdgeInsets.zero,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              child: Column(
                children: [
                  // Header row
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(8),
                        topRight: Radius.circular(8),
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                    child: Row(
                      children: [
                        const Expanded(
                          flex: 4,
                          child: Text("Player", style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                        const Expanded(
                          flex: 1,
                          child: Text("Pos", style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                        const Expanded(
                          flex: 1,
                          child: Text("Rank", style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                        if (widget.selectionEnabled)
                          const SizedBox(width: 60, child: Text("Draft", style: TextStyle(fontWeight: FontWeight.bold))),
                      ],
                    ),
                  ),
                  
                  // Player rows
                  Expanded(
                    child: ListView.builder(
                      itemCount: filteredPlayers.length,
                      itemBuilder: (context, i) {
                        // Get player ID and check if it's selected
                        int playerId = int.tryParse(filteredPlayers[i][0].toString()) ?? i;
                        bool isSelected = _selectedPlayerIds.contains(playerId);
                        
                        // Check if position has been drafted by the team
                        String position = filteredPlayers[i][2].toString();
                        bool positionDrafted = widget.selectedPositions.contains(position);
                        
                        // Apply cross-out styling if applicable
                        return Container(
                          decoration: BoxDecoration(
                            color: i.isEven ? Colors.white : Colors.grey[50],
                            border: Border(
                              bottom: BorderSide(color: Colors.grey[200]!),
                            ),
                          ),
                          child: Material(
                            type: MaterialType.transparency,
                            child: InkWell(
                              onTap: isSelected ? null : () {
                                // If in draft mode, draft the player
                                if (widget.selectionEnabled && widget.onPlayerSelected != null) {
                                  widget.onPlayerSelected!(playerId);
                                } else {
                                  // Otherwise just toggle selection for visual indication
                                  setState(() {
                                    if (_selectedPlayerIds.contains(playerId)) {
                                      _selectedPlayerIds.remove(playerId);
                                    } else {
                                      _selectedPlayerIds.add(playerId);
                                    }
                                  });
                                }
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                                child: Row(
                                  children: [
                                    // Player name and school with cross-out effect if selected
                                    Expanded(
                                      flex: 4,
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Stack(
                                            alignment: Alignment.center,
                                            children: [
                                              Text(
                                                filteredPlayers[i][1].toString(),
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: isSelected || positionDrafted ? Colors.grey : Colors.black,
                                                ),
                                              ),
                                              if (isSelected || positionDrafted)
                                                Positioned(
                                                  left: 0,
                                                  right: 0,
                                                  child: Container(
                                                    height: 1.5,
                                                    color: Colors.grey[700],
                                                  ),
                                                ),
                                            ],
                                          ),
                                          if (filteredPlayers[i].length > 3 && filteredPlayers[i][3].toString().isNotEmpty)
                                            Text(
                                              filteredPlayers[i][3].toString(),
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: isSelected || positionDrafted ? Colors.grey[400] : Colors.grey[600],
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    
                                    // Position with color coding
                                    Expanded(
                                      flex: 1,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: _getPositionColor(filteredPlayers[i][2].toString())
                                              .withOpacity(isSelected || positionDrafted ? 0.1 : 0.2),
                                          borderRadius: BorderRadius.circular(4),
                                          border: positionDrafted ? Border.all(
                                            color: Colors.grey[400]!,
                                            width: 1,
                                          ) : null,
                                        ),
                                        child: Text(
                                          filteredPlayers[i][2].toString(),
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                            color: isSelected || positionDrafted ? 
                                                Colors.grey : 
                                                _getPositionColor(filteredPlayers[i][2].toString()),
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    ),
                                    
                                    // Rank
                                    Expanded(
                                      flex: 1,
                                      child: Text(
                                        '#${filteredPlayers[i].last}',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: isSelected || positionDrafted ? Colors.grey : Colors.black,
                                        ),
                                      ),
                                    ),
                                    
                                    // Draft button
                                    if (widget.selectionEnabled)
                                      SizedBox(
                                        width: 60,
                                        child: ElevatedButton(
                                          onPressed: isSelected || positionDrafted ? null : () {
                                            if (widget.onPlayerSelected != null) {
                                              widget.onPlayerSelected!(playerId);
                                            }
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.green,
                                            disabledBackgroundColor: Colors.grey[300],
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                                            minimumSize: const Size(0, 30),
                                          ),
                                          child: const Text(
                                            'Draft',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
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