// lib/screens/available_players_tab.dart
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/player.dart';
import '../services/favorite_players_service.dart';
import '../services/player_descriptions_service.dart';
import '../services/player_espn_id_service.dart';
import '../utils/constants.dart';
import '../utils/team_logo_utils.dart';
import '../widgets/player/player_details_dialog.dart';
import '../utils/mock_player_data.dart';
import '../services/favorite_players_service.dart';  // Add this import

enum SortOption { 
  rank, 
  name, 
  position, 
  school, 
  ras, 
  height, 
  weight, 
  fortyTime, 
  verticalJump,
  // Add more as needed
}

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
  bool _showFavorites = false;
  final Set<int> _favoritePlayerIds = {};
  bool _debugMode = false;
  final Map<int, Player> _enrichedPlayerCache = {};



  
  // Basic filters
  double _minRasScore = 0.0;
  double _minHeight = 60.0;  // 5'0"
  double _maxHeight = 80.0;  // 6'8"
  bool _filterApplied = false;
  
  // Extended filters
  double? _minWeight;
  double? _maxWeight;
  String? _fortyTimeFilter;
  double? _minFortyTime;
  double? _maxFortyTime;
  double? _minVerticalJump;
  double? _maxVerticalJump;
  
  // Sorting options
  SortOption _sortOption = SortOption.rank;
  bool _sortAscending = true;
  
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
  
  // Initialize filter values
  _minRasScore = 0.0;
  _minHeight = 60.0;  // 5'0"
  _maxHeight = 80.0;  // 6'8"
  _minWeight = 150.0;
  _maxWeight = 350.0;
  _fortyTimeFilter = null;
  _minFortyTime = 4.3;
  _maxFortyTime = 5.0;
  _minVerticalJump = null;
  _maxVerticalJump = null;
  _filterApplied = false;
  
  // Initialize player data services
  PlayerDescriptionsService.initialize().then((_) {
    if (mounted) {
      setState(() {
        // Refresh after descriptions are loaded
      });
    }
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
  
  // Validate Player Attributes 
  void _validateAndCorrectPlayerData(List<Player> players) {
  for (var player in players) {
    // Validate RAS Score
    if (player.rasScore != null) {
      // Ensure it's in the expected range
      if (player.rasScore! < 0 || player.rasScore! > 10) {
        debugPrint('Correcting invalid RAS score for ${player.name}: ${player.rasScore}');
        player.rasScore = player.rasScore!.clamp(0.0, 10.0);
      }
    }
    
    // Validate Height
    if (player.height != null) {
      // Ensure it's in a reasonable range (5'0" to 6'8")
      if (player.height! < 60 || player.height! > 80) {
        debugPrint('Correcting invalid height for ${player.name}: ${player.height}');
        player.height = player.height!.clamp(60.0, 80.0);
      }
    }
    
    // Validate Weight
    if (player.weight != null) {
      // Ensure it's in a reasonable range (150-350 lbs)
      if (player.weight! < 150 || player.weight! > 350) {
        debugPrint('Correcting invalid weight for ${player.name}: ${player.weight}');
        player.weight = player.weight!.clamp(150.0, 350.0);
      }
    }
    
    // Validate 40 Time
    if (player.fortyTime != null && player.fortyTime!.isNotEmpty) {
      try {
        double time = double.parse(player.fortyTime!.replaceAll('s', ''));
        if (time < 4.0 || time > 6.0) {
          debugPrint('Correcting invalid 40 time for ${player.name}: ${player.fortyTime}');
          player.fortyTime = (time.clamp(4.0, 6.0)).toStringAsFixed(2);
        }
      } catch (e) {
        // If can't parse, leave as is
      }
    }
  }
}

void _enrichPlayerData(Player player) {
  // First check if this player is already in the cache
  if (_enrichedPlayerCache.containsKey(player.id)) {
    // Copy cached values to this player instance
    player.height = _enrichedPlayerCache[player.id]!.height;
    player.weight = _enrichedPlayerCache[player.id]!.weight;
    player.rasScore = _enrichedPlayerCache[player.id]!.rasScore;
    player.fortyTime = _enrichedPlayerCache[player.id]!.fortyTime;
    player.description = _enrichedPlayerCache[player.id]!.description;
    player.strengths = _enrichedPlayerCache[player.id]!.strengths;
    player.weaknesses = _enrichedPlayerCache[player.id]!.weaknesses;
    player.tenYardSplit = _enrichedPlayerCache[player.id]!.tenYardSplit;
    player.twentyYardShuttle = _enrichedPlayerCache[player.id]!.twentyYardShuttle;
    player.threeConeTime = _enrichedPlayerCache[player.id]!.threeConeTime;
    player.armLength = _enrichedPlayerCache[player.id]!.armLength;
    player.benchPress = _enrichedPlayerCache[player.id]!.benchPress;
    player.broadJump = _enrichedPlayerCache[player.id]!.broadJump;
    player.handSize = _enrichedPlayerCache[player.id]!.handSize;
    player.verticalJump = _enrichedPlayerCache[player.id]!.verticalJump;
    player.wingspan = _enrichedPlayerCache[player.id]!.wingspan;
    player.headshot = _enrichedPlayerCache[player.id]!.headshot;

    
    if (_debugMode) {
      debugPrint('Retrieved cached data for ${player.name} (ID: ${player.id})');
    }
    return;
  }

  // If not in cache, only try to get data from PlayerDescriptionsService
  // Attempt to get additional player information from description service
  Map<String, String>? additionalInfo = PlayerDescriptionsService.getPlayerDescription(player.name);
  
  if (additionalInfo != null && _debugMode) {
    debugPrint('Found description data for ${player.name}');
  }
  
  if (additionalInfo != null) {
    // Parse height
    if (player.height == null && additionalInfo['height'] != null && additionalInfo['height']!.isNotEmpty) {
      String heightStr = additionalInfo['height']!;
      
      if (heightStr.contains("'")) {
        // Format like 6'2" or 6-2
        try {
          List<String> parts = heightStr.replaceAll('"', '').split("'");
          int feet = int.tryParse(parts[0]) ?? 0;
          int inches = int.tryParse(parts[1]) ?? 0;
          player.height = (feet * 12 + inches).toDouble();
          if (_debugMode) debugPrint('  Parsed height: $heightStr as ${player.height} inches');
        } catch (e) {
          if (_debugMode) debugPrint('  Failed to parse height: $heightStr, error: $e');
        }
      } else if (heightStr.contains("-")) {
        // Format like 6-1 for 6'1"
        try {
          List<String> parts = heightStr.split("-");
          int feet = int.tryParse(parts[0]) ?? 0;
          int inches = int.tryParse(parts[1]) ?? 0;
          player.height = (feet * 12 + inches).toDouble();
          if (_debugMode) debugPrint('  Parsed height: $heightStr as ${player.height} inches');
        } catch (e) {
          if (_debugMode) debugPrint('  Failed to parse height: $heightStr, error: $e');
        }
      } else {
        // Try to parse as either just inches or in a different format
        try {
          player.height = double.tryParse(heightStr);
          if (_debugMode) debugPrint('  Parsed height: $heightStr as ${player.height} inches');
        } catch (e) {
          if (_debugMode) debugPrint('  Failed to parse height: $heightStr, error: $e');
        }
      }
    }
    
    // Parse weight
    if (player.weight == null && additionalInfo['weight'] != null && additionalInfo['weight']!.isNotEmpty) {
      try {
        player.weight = double.tryParse(additionalInfo['weight']!);
        if (_debugMode) debugPrint('  Parsed weight: ${additionalInfo['weight']} as ${player.weight} lbs');
      } catch (e) {
        if (_debugMode) debugPrint('  Failed to parse weight: ${additionalInfo['weight']}, error: $e');
      }
    }
    
    // Parse 40 time
    if ((player.fortyTime == null || player.fortyTime!.isEmpty) && 
        additionalInfo['fortyTime'] != null && additionalInfo['fortyTime']!.isNotEmpty) {
      player.fortyTime = additionalInfo['fortyTime'];
      if (_debugMode) debugPrint('  Set 40 time: ${player.fortyTime}');
    }
    
    // Parse RAS
    if (player.rasScore == null && additionalInfo['ras'] != null && additionalInfo['ras']!.isNotEmpty) {
      try {
        player.rasScore = double.tryParse(additionalInfo['ras']!);
        if (_debugMode) debugPrint('  Parsed RAS: ${additionalInfo['ras']} as ${player.rasScore}');
      } catch (e) {
        if (_debugMode) debugPrint('  Failed to parse RAS: ${additionalInfo['ras']}, error: $e');
      }
    }
    
    // Additional fields
    if ((player.description == null || player.description!.isEmpty) && 
        additionalInfo['description'] != null && additionalInfo['description']!.isNotEmpty) {
      player.description = additionalInfo['description'];
    }
    
    if ((player.strengths == null || player.strengths!.isEmpty) && 
        additionalInfo['strengths'] != null && additionalInfo['strengths']!.isNotEmpty) {
      player.strengths = additionalInfo['strengths'];
    }
    
    if ((player.weaknesses == null || player.weaknesses!.isEmpty) && 
        additionalInfo['weaknesses'] != null && additionalInfo['weaknesses']!.isNotEmpty) {
      player.weaknesses = additionalInfo['weaknesses'];
    }
    
    // Parse other athletic measurements
    if ((player.tenYardSplit == null || player.tenYardSplit!.isEmpty) && 
        additionalInfo['tenYardSplit'] != null && additionalInfo['tenYardSplit']!.isNotEmpty) {
      player.tenYardSplit = additionalInfo['tenYardSplit'];
    }
    
    if ((player.twentyYardShuttle == null || player.twentyYardShuttle!.isEmpty) && 
        additionalInfo['twentyYardShuttle'] != null && additionalInfo['twentyYardShuttle']!.isNotEmpty) {
      player.twentyYardShuttle = additionalInfo['twentyYardShuttle'];
    }
    
    if ((player.threeConeTime == null || player.threeConeTime!.isEmpty) && 
        additionalInfo['threeCone'] != null && additionalInfo['threeCone']!.isNotEmpty) {
      player.threeConeTime = additionalInfo['threeCone'];
    }
    
    if (player.armLength == null && additionalInfo['armLength'] != null && additionalInfo['armLength']!.isNotEmpty) {
      try {
        player.armLength = double.tryParse(additionalInfo['armLength']!);
      } catch (e) {
        if (_debugMode) debugPrint('  Failed to parse armLength: ${additionalInfo['armLength']}, error: $e');
      }
    }
    
    if (player.benchPress == null && additionalInfo['benchPress'] != null && additionalInfo['benchPress']!.isNotEmpty) {
      try {
        player.benchPress = int.tryParse(additionalInfo['benchPress']!);
      } catch (e) {
        if (_debugMode) debugPrint('  Failed to parse benchPress: ${additionalInfo['benchPress']}, error: $e');
      }
    }
    
    if (player.broadJump == null && additionalInfo['broadJump'] != null && additionalInfo['broadJump']!.isNotEmpty) {
      try {
        player.broadJump = double.tryParse(additionalInfo['broadJump']!);
      } catch (e) {
        if (_debugMode) debugPrint('  Failed to parse broadJump: ${additionalInfo['broadJump']}, error: $e');
      }
    }
    
    if (player.handSize == null && additionalInfo['handSize'] != null && additionalInfo['handSize']!.isNotEmpty) {
      try {
        player.handSize = double.tryParse(additionalInfo['handSize']!);
      } catch (e) {
        if (_debugMode) debugPrint('  Failed to parse handSize: ${additionalInfo['handSize']}, error: $e');
      }
    }
    
    if (player.verticalJump == null && additionalInfo['verticalJump'] != null && additionalInfo['verticalJump']!.isNotEmpty) {
      try {
        player.verticalJump = double.tryParse(additionalInfo['verticalJump']!);
      } catch (e) {
        if (_debugMode) debugPrint('  Failed to parse verticalJump: ${additionalInfo['verticalJump']}, error: $e');
      }
    }
    
    if (player.wingspan == null && additionalInfo['wingspan'] != null && additionalInfo['wingspan']!.isNotEmpty) {
      try {
        player.wingspan = double.tryParse(additionalInfo['wingspan']!);
      } catch (e) {
        if (_debugMode) debugPrint('  Failed to parse wingspan: ${additionalInfo['wingspan']}, error: $e');
      }
    }
  }
  
  // Add headshot URL from ESPN ID service
  if (player.headshot == null || player.headshot!.isEmpty) {
    player.headshot = PlayerESPNIdService.getPlayerImageUrl(player.name);
    if (_debugMode && player.headshot != null) {
      debugPrint('Found headshot for ${player.name}: ${player.headshot}');
    }
  }

  // Store the enriched player in the cache
  _enrichedPlayerCache[player.id] = player;
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
    
    // Add debugging to see raw player data before enrichment
    if (_debugMode) {
      debugPrint('Created player from CSV: ${player.name}, Position: ${player.position}, '
          'RAS: ${player.rasScore}, Height: ${player.height}, Weight: ${player.weight}');
    }
    
    // Enrich player with descriptions and mock data
    _enrichPlayerData(player);
    
    allPlayers.add(player);
  } catch (e) {
    debugPrint("Error processing player row: $e");
  }
}

void debugPlayerDescriptionsService() {
  debugPrint('===== DEBUGGING PLAYER DESCRIPTIONS SERVICE =====');
  
  // Check if service is initialized
  debugPrint('Attempting to get description for Travis Hunter...');
  Map<String, String>? hunterInfo = PlayerDescriptionsService.getPlayerDescription('Travis Hunter');
  
  if (hunterInfo != null) {
    debugPrint('Found data for Travis Hunter:');
    hunterInfo.forEach((key, value) {
      debugPrint('  $key: ${value.substring(0, min(30, value.length))}${value.length > 30 ? "..." : ""}');
    });
  } else {
    debugPrint('NO DATA FOUND for Travis Hunter - PlayerDescriptionsService not working correctly');
  }
  
  // Try a few more names
  List<String> sampleNames = ['Caleb Williams', 'Marvin Harrison Jr', 'Malik Nabers', 'Drake Maye'];
  for (String name in sampleNames) {
    Map<String, String>? playerInfo = PlayerDescriptionsService.getPlayerDescription(name);
    debugPrint('$name: ${playerInfo != null ? "Data Found" : "NO DATA FOUND"}');
  }
  
  debugPrint('=================================================');
}

// Validate player data before filtering and sorting
if (_debugMode) {
  _validateAndCorrectPlayerData(allPlayers);
}
    
    // Update filter logic for favorites
    List<Player> filteredPlayers = allPlayers.where((player) {
  // Debug print to check what's being filtered
  if (_filterApplied) {
    debugPrint('Filtering player: ${player.name}, Position: ${player.position}, '
        'RAS: ${player.rasScore}, Height: ${player.height}, Weight: ${player.weight}, '
        '40 Time: ${player.fortyTime}, Vertical: ${player.verticalJump}');
  }

  // Existing filters
  bool matchesSearch = _searchQuery.isEmpty || 
    player.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
    player.school.toLowerCase().contains(_searchQuery.toLowerCase()) ||
    player.position.toLowerCase().contains(_searchQuery.toLowerCase());
  
  bool matchesPosition = _selectedPositions.isEmpty || 
    _selectedPositions.contains(player.position);
  
  // Favorites filter
  bool matchesFavorites = !_showFavorites || 
    FavoritePlayersService.isFavorite(player.id);

  // RAS Score Filter - more lenient with null handling
  bool meetsRasFilter = true;
  if (_filterApplied && _minRasScore > 0) {
    if (player.rasScore == null) {
      // Only exclude nulls if filtering is really intended (e.g., above 5.0)
      meetsRasFilter = _minRasScore <= 1.0; // Keep nulls if filter is minimal
    } else {
      meetsRasFilter = player.rasScore! >= _minRasScore;
    }
  }
  
  // Height Filter - more lenient
  bool meetsHeightFilter = true;
  if (_filterApplied && (_minHeight > 60 || _maxHeight < 80)) {
    if (player.height == null) {
      // Keep players with unknown height unless the filter is very specific
      meetsHeightFilter = (_maxHeight - _minHeight) > 15;
    } else {
      // Add a small tolerance to the range
      meetsHeightFilter = player.height! >= (_minHeight - 0.5) && 
                         player.height! <= (_maxHeight + 0.5);
    }
  }

  // Weight Filter - more lenient
  bool meetsWeightFilter = true;
  if (_filterApplied && _minWeight != null && _maxWeight != null) {
    if (player.weight == null) {
      // Keep players with unknown weight unless the filter is very specific
      meetsWeightFilter = (_maxWeight! - _minWeight!) > 100;
    } else {
      // Add a tolerance to the range
      meetsWeightFilter = player.weight! >= (_minWeight! - 5) && 
                         player.weight! <= (_maxWeight! + 5);
    }
  }

  // 40 Yard Dash Filter - improved parsing
  bool meetsFortyFilter = true;
  if (_filterApplied && _fortyTimeFilter != null && _minFortyTime != null && _maxFortyTime != null) {
    if (player.fortyTime == null || player.fortyTime!.isEmpty) {
      // Only exclude if we're looking for a specific range
      meetsFortyFilter = (_maxFortyTime! - _minFortyTime!) > 0.5;
    } else {
      try {
        // Better parsing that handles different formats
        String cleaned = player.fortyTime!.replaceAll('s', '').trim();
        double fortyTime = double.parse(cleaned);
        // Add a small tolerance
        meetsFortyFilter = fortyTime >= (_minFortyTime! - 0.05) && 
                          fortyTime <= (_maxFortyTime! + 0.05);
      } catch (e) {
        debugPrint('Error parsing 40 time: ${player.fortyTime}, Error: $e');
        meetsFortyFilter = true; // Keep players with badly formatted times
      }
    }
  }

  // Vertical Jump Filter - more lenient
  bool meetsVerticalFilter = true;
  if (_filterApplied && _minVerticalJump != null && _maxVerticalJump != null) {
    if (player.verticalJump == null) {
      // Keep players with unknown vertical unless filter is very specific
      meetsVerticalFilter = (_maxVerticalJump! - _minVerticalJump!) > 10;
    } else {
      // Add tolerance
      meetsVerticalFilter = player.verticalJump! >= (_minVerticalJump! - 1) && 
                           player.verticalJump! <= (_maxVerticalJump! + 1);
    }
  }

  // Combine all filters
  bool meetsAllCriteria = matchesSearch && 
                          matchesPosition && 
                          matchesFavorites && 
                          meetsRasFilter && 
                          meetsHeightFilter &&
                          meetsWeightFilter &&
                          meetsFortyFilter &&
                          meetsVerticalFilter;

  // Debug filter results                          
  if (_filterApplied && !meetsAllCriteria) {
    debugPrint('Player ${player.name} filtered out by: ${!matchesSearch ? 'search ' : ''}${!matchesPosition ? 'position ' : ''}${!matchesFavorites ? 'favorites ' : ''}${!meetsRasFilter ? 'RAS ' : ''}${!meetsHeightFilter ? 'height ' : ''}${!meetsWeightFilter ? 'weight ' : ''}${!meetsFortyFilter ? '40time ' : ''}${!meetsVerticalFilter ? 'vertical ' : ''}');
  }
                          
  return meetsAllCriteria;
}).toList();
    
    // Apply sorting
    // Apply sorting
switch (_sortOption) {
  case SortOption.rank:
    filteredPlayers.sort((a, b) => a.rank.compareTo(b.rank));
    break;
  case SortOption.name:
    filteredPlayers.sort((a, b) => a.name.compareTo(b.name));
    break;
  case SortOption.position:
    filteredPlayers.sort((a, b) => a.position.compareTo(b.position));
    break;
  case SortOption.school:
    filteredPlayers.sort((a, b) => a.school.compareTo(b.school));
    break;
  case SortOption.ras:
    filteredPlayers.sort((a, b) {
      if (_debugMode) {
        debugPrint('Comparing RAS: ${a.name} (${a.rasScore}) vs ${b.name} (${b.rasScore})');
      }
      
      // Always put nulls at the bottom regardless of sort direction
      if (a.rasScore == null && b.rasScore == null) return 0;
      if (a.rasScore == null) return 1; // a goes to bottom
      if (b.rasScore == null) return -1; // b goes to bottom
      
      return a.rasScore!.compareTo(b.rasScore!);
    });
    break;
  case SortOption.height:
    filteredPlayers.sort((a, b) {
      // Always put nulls at the bottom regardless of sort direction
      if (a.height == null && b.height == null) return 0;
      if (a.height == null) return 1; // a goes to bottom 
      if (b.height == null) return -1; // b goes to bottom
      
      return a.height!.compareTo(b.height!);
    });
    break;
  case SortOption.weight:
    filteredPlayers.sort((a, b) {
      // Always put nulls at the bottom regardless of sort direction
      if (a.weight == null && b.weight == null) return 0;
      if (a.weight == null) return 1; // a goes to bottom
      if (b.weight == null) return -1; // b goes to bottom
      
      return a.weight!.compareTo(b.weight!);
    });
    break;
  case SortOption.fortyTime:
    filteredPlayers.sort((a, b) {
      // Always put nulls at the bottom regardless of sort direction
      if (a.fortyTime == null && b.fortyTime == null) return 0;
      if (a.fortyTime == null) return 1; // a goes to bottom
      if (b.fortyTime == null) return -1; // b goes to bottom
      
      try {
        double aTime = double.parse(a.fortyTime!.replaceAll('s', ''));
        double bTime = double.parse(b.fortyTime!.replaceAll('s', ''));
        return aTime.compareTo(bTime);
      } catch (e) {
        return 0;
      }
    });
    break;
  case SortOption.verticalJump:
    filteredPlayers.sort((a, b) {
      // Always put nulls at the bottom regardless of sort direction
      if (a.verticalJump == null && b.verticalJump == null) return 0;
      if (a.verticalJump == null) return 1; // a goes to bottom
      if (b.verticalJump == null) return -1; // b goes to bottom
      
      return a.verticalJump!.compareTo(b.verticalJump!);
    });
    break;
}

// Reverse the list for non-ascending order, BUT ONLY FOR PLAYERS WITH VALUES
if (!_sortAscending) {
  // For attributes that can have null values, we need to handle them specially
  if ([SortOption.ras, SortOption.height, SortOption.weight, 
      SortOption.fortyTime, SortOption.verticalJump].contains(_sortOption)) {
    
    // Split into players with values and nulls
    var playersWithValues = filteredPlayers.where(
      (p) {
        switch (_sortOption) {
          case SortOption.ras: return p.rasScore != null;
          case SortOption.height: return p.height != null;
          case SortOption.weight: return p.weight != null;
          case SortOption.fortyTime: return p.fortyTime != null && p.fortyTime!.isNotEmpty;
          case SortOption.verticalJump: return p.verticalJump != null;
          default: return true;
        }
      }
    ).toList();
    
    var playersWithNulls = filteredPlayers.where(
      (p) {
        switch (_sortOption) {
          case SortOption.ras: return p.rasScore == null;
          case SortOption.height: return p.height == null;
          case SortOption.weight: return p.weight == null;
          case SortOption.fortyTime: return p.fortyTime == null || p.fortyTime!.isEmpty;
          case SortOption.verticalJump: return p.verticalJump == null;
          default: return false;
        }
      }
    ).toList();
    
    // Only reverse players with values
    playersWithValues = playersWithValues.reversed.toList();
    
    // Combine them back
    filteredPlayers = [...playersWithValues, ...playersWithNulls];
  } else {
    // For other attributes (name, position, etc.), just reverse the whole list
    filteredPlayers = filteredPlayers.reversed.toList();
  }
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
            prefixIcon: const Icon(Icons.search, size: 20),
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
    
    // Sort dropdown - compact icon version
    Container(
      padding: EdgeInsets.zero,
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
      child: DropdownButtonHideUnderline(
        child: DropdownButton<SortOption>(
          value: _sortOption,
          isDense: true,
          icon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
                size: 14,
              ),
              const Icon(Icons.arrow_drop_down, size: 16),
            ],
          ),
          style: TextStyle(
            color: Theme.of(context).brightness == Brightness.dark 
                ? Colors.white 
                : Colors.black87,
            fontSize: 12,
          ),
          padding: EdgeInsets.zero,
          borderRadius: BorderRadius.circular(6.0),
          items: [
            _buildSortItem(SortOption.rank, 'Rank'),
            _buildSortItem(SortOption.name, 'Name'),
            _buildSortItem(SortOption.position, 'Position'),
            _buildSortItem(SortOption.school, 'School'),
            _buildSortItem(SortOption.ras, 'RAS'),
            _buildSortItem(SortOption.height, 'Height'),
            _buildSortItem(SortOption.weight, 'Weight'),
            _buildSortItem(SortOption.fortyTime, '40 Time'),
            _buildSortItem(SortOption.verticalJump, 'Vertical'),
          ],
          onChanged: (value) {
            if (value != null) {
              setState(() {
                if (_sortOption == value) {
                  _sortAscending = !_sortAscending;
                } else {
                  _sortOption = value;
                  switch (value) {
                    case SortOption.name:
                    case SortOption.position:
                    case SortOption.school:
                      _sortAscending = true;
                      break;
                    default:
                      _sortAscending = false;
                  }
                  if (value == SortOption.fortyTime || value == SortOption.rank) {
                    _sortAscending = true;
                  }
                }
              });
            }
          },
        ),
      ),
    ),

    // Filter button - icon with glow effect when active
Container(
  margin: const EdgeInsets.symmetric(horizontal: 8.0),
  decoration: BoxDecoration(
    borderRadius: BorderRadius.circular(6.0),
    boxShadow: _filterApplied
        ? [BoxShadow(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
            blurRadius: 4,
            spreadRadius: 1,
          )]
        : null,
  ),
  child: Tooltip(
  message: 'Filter Players',
  waitDuration: const Duration(milliseconds: 300),
  child: TextButton(
    onPressed: _showAdvancedFilterDialog,
    style: TextButton.styleFrom(
      backgroundColor: _filterApplied
          ? Theme.of(context).colorScheme.primary.withOpacity(0.3)
          : (Theme.of(context).brightness == Brightness.dark 
              ? Colors.grey.shade700 
              : Colors.grey.shade200),
      padding: const EdgeInsets.all(8.0),
      minimumSize: const Size(36, 36),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(6.0),
      ),
    ),
    child: Text(
      "🔍", // Unicode filter/settings symbol
      style: TextStyle(
        fontSize: 20,
        color: _filterApplied
            ? Theme.of(context).colorScheme.primary
            : (Theme.of(context).brightness == Brightness.dark 
                ? Colors.white70 
                : Colors.black54),
      ),
    ),
  ),
  ),
),


    
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
      
    // Only show in debug builds
    if (kDebugMode)
      Container(
        decoration: BoxDecoration(
          color: _debugMode 
              ? Colors.red.shade200 
              : Theme.of(context).brightness == Brightness.dark 
                  ? Colors.grey.shade700 
                  : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(6.0),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 4.0),
        child: IconButton(
          onPressed: () {
            setState(() {
              _debugMode = !_debugMode;
              if (_debugMode) {
                // Debug dump of all player data
                for (var player in allPlayers.take(5)) {
                  debugPrint('Player: ${player.name}, Position: ${player.position}, '
                      'RAS: ${player.rasScore}, Height: ${player.height}, Weight: ${player.weight}');
                }
              }
            });
          },
          icon: Icon(
            Icons.bug_report,
            color: _debugMode 
                ? Colors.red.shade900
                : Theme.of(context).brightness == Brightness.dark 
                    ? Colors.white70 
                    : Colors.black54,
            size: 20,
          ),
          tooltip: 'Toggle Debug Mode',
          constraints: const BoxConstraints(
            minWidth: 36,
            minHeight: 36,
          ),
        ),
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
      (isDarkMode ? Colors.grey.shade800 : Colors.white),
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
                      ? (isDarkMode ? Colors.grey.shade300 : Colors.grey.shade600)
                      : (isDarkMode ? Colors.white : Colors.black),
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
                              ? (isDarkMode ? Colors.grey.shade400 : Colors.grey.shade500)
                              : (isDarkMode ? Colors.grey.shade300 : Colors.grey.shade600),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
                    
          // Position badge - Update with lighter purple and white text
          Container(
  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
  decoration: BoxDecoration(
    // Transparent background (no fill)
    color: Colors.transparent,
    borderRadius: BorderRadius.circular(4),
    border: Border.all(
      color: _getPositionColor(player.position),
      width: 2, // Thicker border
    ),
  ),
  child: Text(
    player.position,
    style: TextStyle(
      fontWeight: FontWeight.bold, // Always bold
      fontSize: 12,
      // White in dark mode, black in light mode
      color: isDarkMode ? Colors.white : Colors.black,
    ),
  ),
),

          // Favorite Star - New Section
         GestureDetector(
  onTap: () {
    _toggleFavorite(player.id);
    setState(() {});
  },
  child: Padding(
    padding: const EdgeInsets.symmetric(horizontal: 8.0),
    child: Text(
      player.isFavorite ? "★" : "☆", // Unicode star symbols
      style: TextStyle(
        fontSize: 24,
        color: player.isFavorite
            ? (isDarkMode ? Colors.amber.shade300 : Colors.amber)
            : (isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600),
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
                                  backgroundColor: positionDrafted ? Colors.green : Colors.green,
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                                  minimumSize: const Size(0, 28),
                                ),
                                child: Text(
                                  positionDrafted ? 'Draft' : 'Draft',
                                  style: const TextStyle(
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
  // Attempt to get additional player information from description service
  Map<String, String>? additionalInfo = PlayerDescriptionsService.getPlayerDescription(player.name);
  
  // Try to get headshot URL if not already set
  String? headshotUrl = player.headshot;
  if (headshotUrl == null || headshotUrl.isEmpty) {
    headshotUrl = PlayerESPNIdService.getPlayerImageUrl(player.name);
  }

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
    
    // Parse all the athletic measurements
    String? tenYardSplit = additionalInfo['tenYardSplit'];
    String? twentyYardShuttle = additionalInfo['twentyYardShuttle'];
    String? threeConeTime = additionalInfo['threeCone'];
    
    double? armLength;
    if (additionalInfo['armLength'] != null && additionalInfo['armLength']!.isNotEmpty) {
      armLength = double.tryParse(additionalInfo['armLength']!);
    }
    
    int? benchPress;
    if (additionalInfo['benchPress'] != null && additionalInfo['benchPress']!.isNotEmpty) {
      benchPress = int.tryParse(additionalInfo['benchPress']!);
    }
    
    double? broadJump;
    if (additionalInfo['broadJump'] != null && additionalInfo['broadJump']!.isNotEmpty) {
      broadJump = double.tryParse(additionalInfo['broadJump']!);
    }
    
    double? handSize;
    if (additionalInfo['handSize'] != null && additionalInfo['handSize']!.isNotEmpty) {
      handSize = double.tryParse(additionalInfo['handSize']!);
    }
    
    double? verticalJump;
    if (additionalInfo['verticalJump'] != null && additionalInfo['verticalJump']!.isNotEmpty) {
      verticalJump = double.tryParse(additionalInfo['verticalJump']!);
    }
    
    double? wingspan;
    if (additionalInfo['wingspan'] != null && additionalInfo['wingspan']!.isNotEmpty) {
      wingspan = double.tryParse(additionalInfo['wingspan']!);
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
      // Add all athletic measurements
      tenYardSplit: tenYardSplit ?? player.tenYardSplit,
      twentyYardShuttle: twentyYardShuttle ?? player.twentyYardShuttle,
      threeConeTime: threeConeTime ?? player.threeConeTime,
      armLength: armLength ?? player.armLength,
      benchPress: benchPress ?? player.benchPress,
      broadJump: broadJump ?? player.broadJump,
      handSize: handSize ?? player.handSize,
      verticalJump: verticalJump ?? player.verticalJump,
      wingspan: wingspan ?? player.wingspan,
      headshot: headshotUrl ?? player.headshot,
      isFavorite: player.isFavorite,
    );
  } else {
    // Just use the player as is, don't add mock data
    enrichedPlayer = player;
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
              '⭐',
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
  double tempMinWeight = _minWeight ?? 150;
  double tempMaxWeight = _maxWeight ?? 350;
  String? tempFortyFilter = _fortyTimeFilter;
  double? tempMinFortyTime = _minFortyTime;
  double? tempMaxFortyTime = _maxFortyTime;
  double? tempMinVertical = _minVerticalJump;
  double? tempMaxVertical = _maxVerticalJump;
  
  // More filter variables can be defined here

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
                  const SizedBox(height: 16),
                  
                  // Weight Filter
                  const Text('Weight Range (lbs)'),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${tempMinWeight.toStringAsFixed(0)} lbs',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${tempMaxWeight.toStringAsFixed(0)} lbs',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  RangeSlider(
                    values: RangeValues(tempMinWeight, tempMaxWeight),
                    min: 150.0,
                    max: 350.0,
                    divisions: 40,
                    labels: RangeLabels(
                      '${tempMinWeight.toStringAsFixed(0)} lbs',
                      '${tempMaxWeight.toStringAsFixed(0)} lbs'
                    ),
                    onChanged: (values) => setState(() {
                      tempMinWeight = values.start;
                      tempMaxWeight = values.end;
                    }),
                  ),
                  const SizedBox(height: 16),
                  
                  // 40 Yard Dash Filter
                  const Text('40 Yard Dash (seconds)'),
                  Row(
                    children: [
                      Checkbox(
                        value: tempFortyFilter != null,
                        onChanged: (value) {
                          setState(() {
                            if (value == true) {
                              tempFortyFilter = "range";
                              tempMinFortyTime ??= 4.3;
                              tempMaxFortyTime ??= 5.0;
                            } else {
                              tempFortyFilter = null;
                            }
                          });
                        },
                      ),
                      const Text('Filter by 40 time'),
                    ],
                  ),
                  if (tempFortyFilter != null)
                    Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${tempMinFortyTime?.toStringAsFixed(2) ?? "4.30"}s',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              '${tempMaxFortyTime?.toStringAsFixed(2) ?? "5.00"}s',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        RangeSlider(
                          values: RangeValues(
                            tempMinFortyTime ?? 4.3,
                            tempMaxFortyTime ?? 5.0,
                          ),
                          min: 4.2,
                          max: 5.2,
                          divisions: 20,
                          labels: RangeLabels(
                            '${tempMinFortyTime?.toStringAsFixed(2) ?? "4.30"}s',
                            '${tempMaxFortyTime?.toStringAsFixed(2) ?? "5.00"}s'
                          ),
                          onChanged: (values) => setState(() {
                            tempMinFortyTime = values.start;
                            tempMaxFortyTime = values.end;
                          }),
                        ),
                      ],
                    ),
                  const SizedBox(height: 16),
                  
                  // Vertical Jump Filter
                  const Text('Vertical Jump (inches)'),
                  Row(
                    children: [
                      Checkbox(
                        value: tempMinVertical != null,
                        onChanged: (value) {
                          setState(() {
                            if (value == true) {
                              tempMinVertical = 28.0;
                              tempMaxVertical = 42.0;
                            } else {
                              tempMinVertical = null;
                              tempMaxVertical = null;
                            }
                          });
                        },
                      ),
                      const Text('Filter by vertical jump'),
                    ],
                  ),
                  if (tempMinVertical != null)
                    Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${tempMinVertical?.toStringAsFixed(1) ?? "28.0"}"',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              '${tempMaxVertical?.toStringAsFixed(1) ?? "42.0"}"',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        RangeSlider(
                          values: RangeValues(
                            tempMinVertical ?? 28.0,
                            tempMaxVertical ?? 42.0,
                          ),
                          min: 20.0,
                          max: 45.0,
                          divisions: 25,
                          labels: RangeLabels(
                            '${tempMinVertical?.toStringAsFixed(1) ?? "28.0"}"',
                            '${tempMaxVertical?.toStringAsFixed(1) ?? "42.0"}"'
                          ),
                          onChanged: (values) => setState(() {
                            tempMinVertical = values.start;
                            tempMaxVertical = values.end;
                          }),
                        ),
                      ],
                    ),
                  
                  // Additional filters can be added here
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
                    _minWeight = null;
                    _maxWeight = null;
                    _fortyTimeFilter = null;
                    _minFortyTime = null;
                    _maxFortyTime = null;
                    _minVerticalJump = null;
                    _maxVerticalJump = null;
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
                    _minWeight = tempMinWeight;
                    _maxWeight = tempMaxWeight;
                    _fortyTimeFilter = tempFortyFilter;
                    _minFortyTime = tempMinFortyTime;
                    _maxFortyTime = tempMaxFortyTime;
                    _minVerticalJump = tempMinVertical;
                    _maxVerticalJump = tempMaxVertical;
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
DropdownMenuItem<SortOption> _buildSortItem(SortOption option, String label) {
  return DropdownMenuItem(
    value: option,
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.sort, size: 12),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    ),
  );
}
// Helper method for brighter position colors
Color _getPositionColorBrighter(String position, bool isDarkMode) {
  // Offensive position colors
  if (['QB', 'RB', 'FB'].contains(position)) {
    return isDarkMode ? Colors.blue.shade500 : Colors.blue.shade700; // Backfield
  } else if (['WR', 'TE'].contains(position)) {
    return isDarkMode ? Colors.green.shade500 : Colors.green.shade700; // Receivers
  } else if (['OT', 'IOL', 'OL', 'G', 'C'].contains(position)) {
    return isDarkMode ? Colors.purple.shade300 : Colors.purple.shade700; // O-Line - lighter purple in dark mode
  } 
  // Defensive position colors
  else if (['EDGE', 'DL', 'IDL', 'DT', 'DE'].contains(position)) {
    return isDarkMode ? Colors.red.shade500 : Colors.red.shade700; // D-Line
  } else if (['LB', 'ILB', 'OLB'].contains(position)) {
    return isDarkMode ? Colors.orange.shade500 : Colors.orange.shade700; // Linebackers
  } else if (['CB', 'S', 'FS', 'SS'].contains(position)) {
    return isDarkMode ? Colors.teal.shade400 : Colors.teal.shade700; // Secondary
  }
  // Default color
  return isDarkMode ? Colors.grey.shade500 : Colors.grey.shade700;
}
}