// lib/screens/available_players_tab.dart
import 'dart:math';

import 'package:flutter/material.dart';
import '../models/player.dart';
import '../services/favorite_players_service.dart';
import '../services/player_descriptions_service.dart';
import '../utils/constants.dart';
import '../utils/team_logo_utils.dart';
import '../widgets/player/player_details_dialog.dart';
import '../utils/mock_player_data.dart';
import '../services/favorite_players_service.dart';  // Add this import



enum SortOption { rank, ras }

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
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  final Set<String> _selectedPositions = {};
  bool _showFavorites = false; // Add this line for favorites filter
  final Set<int> _favoritePlayerIds = {}; // Store favorite player IDs
  double _minRasScore = 0.0;
  double _maxHeight = 80.0;  // 6'8"
  double _minHeight = 60.0;  // 5'0"
  bool _filterApplied = false;
  final bool _isFilterActive = false;

  // Add sort options
  SortOption _sortOption = SortOption.rank; // Default sort by rank
  
  // Track selected (crossed out) players locally
  Set<int> _selectedPlayerIds = {};

  // Offensive and defensive position groupings
  final List<String> _offensivePositions = ['QB', 'RB', 'WR', 'TE', 'OT', 'IOL', 'OL', 'G', 'C', 'FB'];
  final List<String> _defensivePositions = ['EDGE', 'DL', 'IDL', 'DT', 'DE', 'LB', 'ILB', 'OLB', 'CB', 'S', 'FS', 'SS'];

  @override
  void initState() {
    super.initState();
    _initializeSelectedPlayers();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
    
    // Initialize favorites service
    FavoritePlayersService.initialize();
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
  
  
  // Toggle player favorite status
  void _toggleFavorite(int playerId) async {
    final isFavorite = await FavoritePlayersService.toggleFavorite(playerId);
    setState(() {
      // Just trigger rebuild to update UI
    });
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
    int rasIndex = columnIndices["RAS"] ?? -1; // Add index for RAS score

   // Create Player objects from the raw data
    List<Player> allPlayers = [];
    for (var row in widget.availablePlayers.skip(1)) {
      try {
        // Skip if we don't have enough elements
        if (row.length <= positionIndex) continue;
        
        // Extract data and create Player object
        Player player = Player.fromCsvRowWithHeaders(row, columnIndices);
        
        // Check if this player is favorited - use the service now
        player.isFavorite = FavoritePlayersService.isFavorite(player.id);
        
        allPlayers.add(player);
      } catch (e) {
        debugPrint("Error processing player row: $e");
      }
    }
    
    // Update filter logic for favorites
List<Player> filteredPlayers = allPlayers.where((player) {
  // Existing filters
  bool matchesSearch = _searchQuery.isEmpty || 
    player.name.toLowerCase().contains(_searchQuery) ||
    player.school.toLowerCase().contains(_searchQuery);
  
  bool matchesPosition = _selectedPositions.isEmpty || 
    _selectedPositions.contains(player.position);
  
  // Favorites filter
  bool matchesFavorites = !_showFavorites || 
    FavoritePlayersService.isFavorite(player.id);

  // RAS Score Filter (robust null handling)
  bool meetsRasFilter = true;
  if (_filterApplied && _minRasScore > 0) {
    // If player has no RAS score and we're filtering by RAS, exclude them
    if (player.rasScore == null) {
      meetsRasFilter = false;
    } else {
      meetsRasFilter = player.rasScore! >= _minRasScore;
    }
  }
  
  // Height Filter (convert to inches and handle null)
  bool meetsHeightFilter = true;
  if (_filterApplied && (_minHeight > 60 || _maxHeight < 80)) {
    // If player has no height and we're filtering by height, exclude them
    if (player.height == null) {
      meetsHeightFilter = false;
    } else {
      meetsHeightFilter = player.height! >= _minHeight && player.height! <= _maxHeight;
    }
  }

  return matchesSearch && 
         matchesPosition && 
         matchesFavorites && 
         meetsRasFilter && 
         meetsHeightFilter;
}).toList();
    
    // Sort filtered players
    switch (_sortOption) {
      case SortOption.rank:
        // Sort by rank (ascending)
        filteredPlayers.sort((a, b) => a.rank.compareTo(b.rank));
        break;
      case SortOption.ras:
        // Sort by RAS (descending), null values at the bottom
        filteredPlayers.sort((a, b) {
          if (a.rasScore == null && b.rasScore == null) return 0;
          if (a.rasScore == null) return 1;
          if (b.rasScore == null) return -1;
          return b.rasScore!.compareTo(a.rasScore!);
        });
        break;
    }

    // Get all available positions for filters
    Set<String> availablePositions = allPlayers
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
                // Row with search bar, sort dropdown, and player count
Row(
  children: [
    // Search bar - compact version
    Expanded(
      child: SizedBox(
        height: 36,
        child: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Search Players',
            prefixIcon: const Icon(Icons.search),
            // Remove the suffixIcon that contains the filter icon
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
          ),
          style: const TextStyle(fontSize: TextConstants.kSearchBarTextSize),
        ),
      ),
    ),
    const SizedBox(width: 8),
    
    // Sort dropdown
    Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 0),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark 
            ? Colors.grey.shade700 
            : Colors.grey.shade200,
        borderRadius: BorderRadius.circular(6.0),
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark 
              ? Colors.grey.shade600 
              : Colors.grey.shade400,
        ),
      ),
      child: DropdownButton<SortOption>(
        value: _sortOption,
        isDense: true,
        underline: Container(),
        icon: const Icon(Icons.arrow_drop_down, size: 20),
        style: TextStyle(
          color: Theme.of(context).brightness == Brightness.dark 
              ? Colors.white 
              : Colors.black87,
          fontSize: 12,
        ),
        items: const [
          DropdownMenuItem(
            value: SortOption.rank,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.sort, size: 14),
                SizedBox(width: 4),
                Text('Rank'),
              ],
            ),
          ),
          DropdownMenuItem(
            value: SortOption.ras,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.sort, size: 14),
                SizedBox(width: 4),
                Text('RAS'),
              ],
            ),
          ),
        ],
        onChanged: (value) {
          if (value != null) {
            setState(() {
              _sortOption = value;
            });
          }
        },
      ),
    ),

    // Make the filter button more visible
    Container(
  decoration: BoxDecoration(
    color: Theme.of(context).brightness == Brightness.dark 
        ? Colors.grey.shade700 
        : Colors.grey.shade200,
    borderRadius: BorderRadius.circular(6.0),
  ),
  margin: const EdgeInsets.symmetric(horizontal: 8.0),
  child: TextButton(
    onPressed: _showAdvancedFilterDialog,
    style: TextButton.styleFrom(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      minimumSize: const Size(10, 10),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    ),
    child: Text(
      'Filter',
      style: TextStyle(
        color: Theme.of(context).brightness == Brightness.dark 
            ? Colors.white 
            : Colors.black87,
        fontSize: 12,
      ),
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
    if (_filterApplied)
      Padding(
        padding: const EdgeInsets.only(left: 8.0),
        child: Chip(
          label: const Text('Filters Applied'),
          backgroundColor: Colors.blue.shade100,
          deleteIcon: const Icon(Icons.close, size: 18),
          onDeleted: () {
            setState(() {
              _filterApplied = false;
              _minRasScore = 0.0;
              _minHeight = 60.0;
              _maxHeight = 80.0;
            });
          },
        ),
      ),
    // Reset filter button
    if (_selectedPositions.isNotEmpty || _showFavorites)
      IconButton(
        icon: const Icon(Icons.clear, size: 16),
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
        visualDensity: VisualDensity.compact,
        onPressed: () {
          setState(() {
            _selectedPositions.clear();
            _showFavorites = false;
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
                // Favorites filter
                _buildPositionChip(
                '⭐', // Add the text "Favorites" after the star
                _showFavorites,
                () {
                  setState(() {
                    _showFavorites = !_showFavorites;
                  });
                },
                isOffensive: false,
                isDraftedByCurrentTeam: false,
                isSpecial: true,
              ),                           
                            // All positions chip
                            if (_selectedPositions.isEmpty && !_showFavorites)
                              _buildPositionChip('All', true, () {}, isDraftedByCurrentTeam: false)
                            else
                              _buildPositionChip('All', false, () {
                                setState(() {
                                  _selectedPositions.clear();
                                  _showFavorites = false;
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
          
          // No players message if filteredPlayers is empty
          if (filteredPlayers.isEmpty)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _showFavorites ? Icons.star_border : Icons.search_off,
                      size: 64,
                      color: Theme.of(context).brightness == Brightness.dark 
                          ? Colors.grey.shade700 
                          : Colors.grey.shade400,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _showFavorites ? 'No favorite players yet' : 'No players match your filters',
                      style: TextStyle(
                        fontSize: 18,
                        color: Theme.of(context).brightness == Brightness.dark 
                            ? Colors.grey.shade400 
                            : Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _showFavorites 
                          ? 'Tap the star icon on players to add them to favorites' 
                          : 'Try adjusting your search or filters',
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).brightness == Brightness.dark 
                            ? Colors.grey.shade500 
                            : Colors.grey.shade600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          else
            // Player List with Card-based Layout
            Expanded(
              child: ListView.builder(
                itemCount: filteredPlayers.length,
                itemBuilder: (context, index) {
                  final player = filteredPlayers[index];
                  final isDarkMode = Theme.of(context).brightness == Brightness.dark;
                  
                  // Check if player is selected or position has been drafted by current team
                  bool isSelected = _selectedPlayerIds.contains(player.id);
                  bool positionDrafted = isPositionDraftedByCurrentTeam(player.position);
                  
                  // Replace the existing player row section with this
// In the ListView.builder itemBuilder method
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
  color: isSelected ? 
      (isDarkMode ? Colors.grey.shade700 : Colors.grey.shade700) : 
      (positionDrafted ? 
        (isDarkMode ? Colors.grey.shade800.withOpacity(0.7) : Colors.grey.shade50) :
        (isDarkMode ? Colors.grey.shade800 : Colors.white)),
  child: InkWell(
    onTap: () {
      _showPlayerDetails(context, player);
    },
    borderRadius: BorderRadius.circular(8.0),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
      child: Row(
        children: [
          // Existing rank container remains the same
          Container(
            width: 30.0,
            height: 30.0,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.blue.shade700,
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
          
          // School logo
          player.school.isNotEmpty
            ? TeamLogoUtils.buildCollegeTeamLogo(
                player.school,
                size: 30.0,
              )
            : const SizedBox(width: 30, height: 30),
          
          const SizedBox(width: 8.0),
          
          // Player info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  player.name,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14.0,
                    color: positionDrafted 
                      ? Colors.grey 
                      : (Theme.of(context).brightness == Brightness.dark 
                          ? Colors.white 
                          : Colors.black),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Row(
                  children: [
                    if (player.school.isNotEmpty)
                      Flexible(
                        child: Text(
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

          // Favorite Star - New Section
          Padding(
  padding: const EdgeInsets.only(left: 4),
  child: Container(
  margin: const EdgeInsets.only(left: 4),
  child: IconButton(
    onPressed: () {
      _toggleFavorite(player.id);
      setState(() {});
    },
    icon: player.isFavorite
        ? const Icon(Icons.star, color: Colors.amber)
        : const Icon(Icons.star_border, color: Colors.grey),
    padding: EdgeInsets.zero,
    constraints: const BoxConstraints(),
    visualDensity: VisualDensity.compact,
    iconSize: 28,
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
  // Attempt to get additional player information from description service
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
      isFavorite: player.isFavorite,
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

  Widget _buildPositionChip(
    String label, 
    bool isSelected, 
    VoidCallback onTap, 
    {bool isOffensive = true, bool isDraftedByCurrentTeam = false, bool isSpecial = false}
  ) {
    bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    // Special styling for Favorites filter
    if (isSpecial) {
  return Container(
    margin: const EdgeInsets.only(right: 6),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected 
              ? (isDarkMode ? Colors.amber.shade900 : Colors.amber.shade100)
              : (isDarkMode ? Colors.amber.shade900.withOpacity(0.3) : Colors.amber.shade50),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected 
                ? (isDarkMode ? Colors.amber.shade200 : Colors.amber.shade800)
                : Colors.transparent,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Favorites',
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected 
                    ? (isDarkMode ? Colors.amber.shade200 : Colors.amber.shade800)
                    : (isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

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
  
  // Helper method for position colors
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
  
  // Helper method for RAS rating colors
  Color _getRasColor(double ras) {
    if (ras >= 9.5) return Colors.green.shade700;      // Elite
    if (ras >= 8.5) return Colors.green.shade600;      // Great
    if (ras >= 7.5) return Colors.green.shade500;      // Good
    if (ras >= 6.5) return Colors.blue.shade600;       // Above Average
    if (ras >= 5.5) return Colors.blue.shade500;       // Average
    if (ras >= 4.5) return Colors.orange.shade600;     // Below Average
    if (ras >= 3.5) return Colors.orange.shade700;     // Poor
    return Colors.red.shade600;                        // Very Poor
  }

  void _showAdvancedFilterDialog() {
  // Store temporary values for the dialog
  double tempMinRas = _minRasScore;
  double tempMinHeight = _minHeight;
  double tempMaxHeight = _maxHeight;

  showDialog(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Row(
              children: [
                Icon(
                  Icons.filter_alt,
                  color: Theme.of(context).colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 8),
                const Text('Advanced Player Filters'),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // RAS Score Filter with color indication
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Minimum RAS Score:'),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: _getRasColor(tempMinRas).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: _getRasColor(tempMinRas),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          tempMinRas.toStringAsFixed(1),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: _getRasColor(tempMinRas),
                          ),
                        ),
                      ),
                    ],
                  ),
                  Slider(
                    value: tempMinRas,
                    min: 0.0,
                    max: 10.0,
                    divisions: 100,
                    label: tempMinRas.toStringAsFixed(1),
                    onChanged: (value) => setState(() => tempMinRas = value),
                  ),
                  const SizedBox(height: 16),

                  // Height Filter with feet and inches
                  const Text('Height Range'),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${(tempMinHeight ~/ 12)}\' ${(tempMinHeight % 12).toStringAsFixed(0)}"',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${(tempMaxHeight ~/ 12)}\' ${(tempMaxHeight % 12).toStringAsFixed(0)}"',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  RangeSlider(
                    values: RangeValues(tempMinHeight, tempMaxHeight),
                    min: 60.0,  // 5'0"
                    max: 80.0,  // 6'8"
                    divisions: 20,
                    labels: RangeLabels(
                      '${(tempMinHeight ~/ 12)}\' ${(tempMinHeight % 12).toStringAsFixed(0)}"',
                      '${(tempMaxHeight ~/ 12)}\' ${(tempMaxHeight % 12).toStringAsFixed(0)}"'
                    ),
                    onChanged: (values) => setState(() {
                      tempMinHeight = values.start;
                      tempMaxHeight = values.end;
                    }),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  this.setState(() {
                    _minRasScore = 0.0;
                    _minHeight = 60.0;
                    _maxHeight = 80.0;
                    _filterApplied = false;
                  });
                },
                child: const Text('Reset'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  this.setState(() {
                    _minRasScore = tempMinRas;
                    _minHeight = tempMinHeight;
                    _maxHeight = tempMaxHeight;
                    _filterApplied = true;
                  });
                },
                child: const Text('Apply'),
              ),
            ],
          );
        },
      );
    },
  );
}
}