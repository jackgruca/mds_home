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
// Modify the filtering logic in the build method
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
  bool meetsRasFilter = !_filterApplied || 
    (player.rasScore ?? 0) >= _minRasScore;
  
  // Height Filter (convert to inches and handle null)
  bool meetsHeightFilter = !_filterApplied || 
    (player.height ?? 0) >= _minHeight && 
    (player.height ?? 0) <= _maxHeight;

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
    suffixIcon: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Explicitly styled filter icon
        Container(
          margin: const EdgeInsets.only(right: 8),
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark 
              ? Colors.grey.shade700 
              : Colors.grey.shade200,
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: Icon(
              Icons.filter_list, 
              size: 20,
              color: Theme.of(context).brightness == Brightness.dark 
                ? Colors.white 
                : Colors.black87,
            ),
            onPressed: _showAdvancedFilterDialog,
            tooltip: 'Advanced Filters',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ),
      ],
    ),
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

                    // Add the new IconButton right here:
                    IconButton(
                      icon: const Icon(Icons.filter_list),
                      onPressed: _showAdvancedFilterDialog,
                      tooltip: 'Advanced Filters',
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
                  '⭐ Favorites',
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
                                      
                                    // RAS score if available and sorting by RAS
                                    if (_sortOption == SortOption.ras && player.rasScore != null)
                                      Padding(
                                        padding: const EdgeInsets.only(left: 8.0),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: _getRasColor(player.rasScore!).withOpacity(0.2),
                                            borderRadius: BorderRadius.circular(4),
                                            border: Border.all(
                                              color: _getRasColor(player.rasScore!).withOpacity(0.5),
                                              width: 1,
                                            ),
                                          ),
                                          child: Text(
                                            'RAS: ${player.rasScore!.toStringAsFixed(1)}',
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: _getRasColor(player.rasScore!),
                                            ),
                                          ),
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
                          
                          // Favorite Button
                          Container(
  width: 36,
  height: 36,
  margin: const EdgeInsets.only(left: 4),
  child: IconButton(
    onPressed: () {
      _toggleFavorite(player.id);
      setState(() {});
    },
    icon: Icon(
      player.isFavorite ? Icons.star : Icons.star_border,
      size: 24,
      color: player.isFavorite ? 
          (isDarkMode ? Colors.blue.shade300 : Colors.amber.shade600) : 
          (isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600),
    ),
    padding: EdgeInsets.zero,
    constraints: const BoxConstraints(),
    style: ButtonStyle(
      backgroundColor: WidgetStateProperty.all(
        player.isFavorite ? 
            (isDarkMode ? Colors.blue.shade900.withOpacity(0.2) : Colors.amber.shade50) : 
            Colors.transparent
      ),
      shape: WidgetStateProperty.all(
        CircleBorder(
          side: BorderSide(
            color: player.isFavorite ? 
                (isDarkMode ? Colors.blue.shade400 : Colors.amber.shade600) : 
                (isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300),
            width: 1.0,
          ),
        ),
      ),
    ),
  ),
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
  // First enrich the player data (similar to what's done elsewhere in your app)
  Player enrichedPlayer = MockPlayerData.enrichPlayerData(player);
  
  // Now show the player details dialog
  showDialog(
    context: context,
    builder: (context) => PlayerDetailsDialog(
      player: enrichedPlayer,
    ),
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
          child: Icon(
            Icons.star,
            color: isSelected 
                ? (isDarkMode ? Colors.amber.shade200 : Colors.amber.shade800)
                : (isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600),
            size: 20,
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
  showDialog(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Advanced Player Filters'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // RAS Score Filter
                  Text('Minimum RAS Score: ${_minRasScore.toStringAsFixed(1)}'),
                  Slider(
                    value: _minRasScore,
                    min: 0.0,
                    max: 10.0,
                    divisions: 100,
                    label: _minRasScore.toStringAsFixed(1),
                    onChanged: (value) => setState(() => _minRasScore = value),
                  ),

                  // Height Filter with feet and inches
                  const Text('Height Range'),
                  RangeSlider(
                    values: RangeValues(_minHeight, _maxHeight),
                    min: 60.0,  // 5'0"
                    max: 80.0,  // 6'8"
                    divisions: 20,
                    labels: RangeLabels(
                      '${(_minHeight ~/ 12)}\' ${(_minHeight % 12).toStringAsFixed(0)}"',
                      '${(_maxHeight ~/ 12)}\' ${(_maxHeight % 12).toStringAsFixed(0)}"'
                    ),
                    onChanged: (values) => setState(() {
                      _minHeight = values.start;
                      _maxHeight = values.end;
                    }),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  setState(() {
                    _filterApplied = true;
                  });
                  // Force a rebuild to apply filters
                  this.setState(() {});
                },
                child: const Text('Apply'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  setState(() {
                    _minRasScore = 0.0;
                    _minHeight = 60.0;
                    _maxHeight = 80.0;
                    _filterApplied = false;
                  });
                  // Force a rebuild to reset filters
                  this.setState(() {});
                },
                child: const Text('Reset'),
              ),
            ],
          );
        },
      );
    },
  );
}

// Add these state variables at the top of _AvailablePlayersTabState
double _rasMinFilter = 0.0;
RangeValues _heightRangeFilter = const RangeValues(60.0, 80.0);

void _applyAdvancedFilters() {
  setState(() {
    // Modify the filtering logic in the build method
  });
}

void _resetAdvancedFilters() {
  setState(() {
    _rasMinFilter = 0.0;
    _heightRangeFilter = const RangeValues(60.0, 80.0);
  });
}

}