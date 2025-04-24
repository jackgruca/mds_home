// lib/services/data_service.dart

import 'dart:math';

import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:csv/csv.dart';

import '../models/player.dart';
import '../models/draft_pick.dart';
import '../models/team_need.dart';
import 'draft_value_service.dart';

/// Service responsible for loading and parsing data from CSV files
class DataService {

static Future<List<DraftPick>> loadDraftOrder({required int year}) async {
  try {
    final data = await rootBundle.loadString('assets/$year/draft_order.csv');
    
    // Use column headers for parsing
    List<List<dynamic>> csvTable = const CsvToListConverter(eol: "\n").convert(data);
    
    if (csvTable.isEmpty) {
      debugPrint("Error: Empty CSV table for draft order");
      return [];
    }
    
    // Extract the header row to map column names to indices
    List<String> headers = csvTable[0].map<String>((dynamic col) => col.toString().toUpperCase()).toList();
    
    // Create index mappings for column names
    Map<String, int> columnIndices = {};
    for (int i = 0; i < headers.length; i++) {
      columnIndices[headers[i]] = i;
    }
    
    debugPrint("Draft order CSV headers: $headers");
    
    // Skip the header row (index 0)
    List<DraftPick> draftPicks = [];
    for (int i = 1; i < csvTable.length; i++) {
      try {
        DraftPick pick = DraftPick.fromCsvRowWithHeaders(csvTable[i], columnIndices);
        if (pick.pickNumber > 0) {
          draftPicks.add(pick);
        }
      } catch (e) {
        debugPrint("Error parsing draft pick at row $i: $e");
      }
    }
    
    debugPrint("Successfully loaded ${draftPicks.length} draft picks");
    return draftPicks;
  } catch (e) {
    debugPrint("Error loading draft order for year $year: $e");
    return [];
  }
}

/// Load actual draft picks from CSV
static Future<List<DraftPick>> loadActualPicks({required int year}) async {
  try {
    // Try to load the actual picks CSV
    final data = await rootBundle.loadString('assets/$year/actual_picks_2025.csv');
    
    // Parse the CSV
    List<List<dynamic>> csvTable = const CsvToListConverter(eol: "\n").convert(data);
    
    if (csvTable.isEmpty || csvTable.length <= 1) {
      debugPrint("No actual picks data found or only header row present");
      return [];
    }
    
    // Extract the header row to map column names to indices
    List<String> headers = csvTable[0].map<String>((dynamic col) => col.toString().toLowerCase()).toList();
    
    // Create index mappings for column names
    Map<String, int> columnIndices = {};
    for (int i = 0; i < headers.length; i++) {
      columnIndices[headers[i]] = i;
    }
    
    // Skip the header row (index 0)
    List<DraftPick> actualPicks = [];
    for (int i = 1; i < csvTable.length; i++) {
      try {
        var row = csvTable[i];
        
        // Get pick number
        int pickNumber = 0;
        if (columnIndices.containsKey('pick') && columnIndices['pick']! < row.length) {
          pickNumber = int.tryParse(row[columnIndices['pick']!].toString()) ?? 0;
        }
        
        // Get team name
        String teamName = "";
        if (columnIndices.containsKey('team') && columnIndices['team']! < row.length) {
          teamName = row[columnIndices['team']!].toString();
        }
        
        // Skip if we don't have valid pick data
        if (pickNumber <= 0 || teamName.isEmpty) continue;
        
        // Get player data
        String playerName = "";
        String position = "";
        String school = "";
        
        if (columnIndices.containsKey('player') && columnIndices['player']! < row.length) {
          playerName = row[columnIndices['player']!].toString();
        }
        
        if (columnIndices.containsKey('position') && columnIndices['position']! < row.length) {
          position = row[columnIndices['position']!].toString();
        }
        
        if (columnIndices.containsKey('school') && columnIndices['school']! < row.length) {
          school = row[columnIndices['school']!].toString();
        }
        
        // Get original team for trade detection
        String originalTeam = "";
        if (columnIndices.containsKey('original_team') && columnIndices['original_team']! < row.length) {
          originalTeam = row[columnIndices['original_team']!].toString();
        } else {
          originalTeam = teamName; // Default to current team if not specified
        }
        
        // Create draft pick
        DraftPick pick = DraftPick(
          pickNumber: pickNumber,
          teamName: teamName,
          round: DraftValueService.getRoundForPick(pickNumber).toString(),
        );
        
        // If we have player data, create and assign the player
        if (playerName.isNotEmpty) {
          // Find player in available players by name and position (approximate match)
          Player? selectedPlayer;
          
          // First look for exact match
          try {
            selectedPlayer = _availablePlayers.firstWhere(
              (player) => player.name.toLowerCase() == playerName.toLowerCase() && 
                          player.position.toLowerCase() == position.toLowerCase()
            );
          } catch (e) {
            // If no exact match, try to find closest match
            try {
              selectedPlayer = _availablePlayers.firstWhere(
                (player) => player.name.toLowerCase().contains(playerName.toLowerCase().split(' ').last) &&
                            player.position.toLowerCase() == position.toLowerCase()
              );
            } catch (e) {
              // If still no match, create a new player
              selectedPlayer = Player(
                id: 10000 + pickNumber, // Use high ID to avoid conflicts
                name: playerName,
                position: position,
                rank: pickNumber, // Use pick number as rank
                school: school,
              );
            }
          }
          
          pick.selectedPlayer = selectedPlayer;
        }
        
        // If this is a traded pick, add trade info
        if (teamName != originalTeam) {
          pick.tradeInfo = "From $originalTeam";
        }
        
        actualPicks.add(pick);
      } catch (e) {
        debugPrint("Error parsing actual pick at row $i: $e");
      }
    }
    
    debugPrint("Successfully loaded ${actualPicks.length} actual picks");
    return actualPicks;
  } catch (e) {
    // If the file doesn't exist or there's an error, return empty list
    debugPrint("No actual picks data found: $e");
    return [];
  }
}

// Add a static _availablePlayers field to store cached player data
static final List<Player> _availablePlayers = [];

// Updated part of the loadAvailablePlayers method in DataService
static Future<List<Player>> loadAvailablePlayers({required int year}) async {
  try {
    final data = await rootBundle.loadString('assets/$year/available_players.csv');
    
    // Use column headers for parsing
    List<List<dynamic>> csvTable = const CsvToListConverter(eol: "\n").convert(data);
    
    if (csvTable.isEmpty) {
      debugPrint("Error: Empty CSV table for available players");
      return [];
    }
    
    // Extract the header row to map column names to indices
    List<String> headers = csvTable[0].map<String>((dynamic col) => col.toString().toUpperCase()).toList();
    
    // Create index mappings for column names
    Map<String, int> columnIndices = {};
    for (int i = 0; i < headers.length; i++) {
      columnIndices[headers[i]] = i;
    }
    
    // Debug the headers to see what's available
    debugPrint("Available players CSV headers: $headers");
    
    // Get the exact index for "RANK_COMBINED" - must match exactly
    int rankIndex = -1;
    if (columnIndices.containsKey("RANK_COMBINED")) {
      rankIndex = columnIndices["RANK_COMBINED"]!;
      debugPrint("Found RANK_COMBINED column at index $rankIndex");
    } else {
      // If uppercase doesn't work, try the original case
      for (int i = 0; i < headers.length; i++) {
        if (headers[i].toUpperCase() == "RANK_COMBINED" || 
            headers[i] == "Rank_combined") {
          rankIndex = i;
          debugPrint("Found Rank_combined column at index $rankIndex");
          break;
        }
      }
    }
    
    // If still not found, notify in logs but continue with last column as fallback
    if (rankIndex == -1) {
      rankIndex = headers.length - 1;
      debugPrint("ERROR: RANK_COMBINED column not found! Defaulting to last column at index $rankIndex");
    }
    
    // Skip the header row (index 0)
    List<Player> players = [];
    for (int i = 1; i < csvTable.length; i++) {
      try {
        // Get the row data
        var row = csvTable[i];
        
        // Make sure we have enough data
        if (row.length <= 2 || row.length <= rankIndex) {
          debugPrint("Row $i has insufficient columns: $row");
          continue;
        }
        
        // Get player ID
        int id = 0;
        if (columnIndices.containsKey('ID') && columnIndices['ID']! < row.length) {
          id = int.tryParse(row[columnIndices['ID']!].toString()) ?? i; // Use row index as fallback
        } else {
          id = i; // Use row index as ID
        }
        
        // Get player name
        String name = "";
        if (columnIndices.containsKey('NAME') && columnIndices['NAME']! < row.length) {
          name = row[columnIndices['NAME']!].toString();
        } else if (row.length > 1) {
          name = row[1].toString(); // Fallback to second column
        }
        
        // Get player position
        String position = "";
        if (columnIndices.containsKey('POSITION') && columnIndices['POSITION']! < row.length) {
          position = row[columnIndices['POSITION']!].toString();
        } else if (row.length > 2) {
          position = row[2].toString(); // Fallback to third column
        }
        
        // Get Rank_combined value with proper error handling
        int rank = 999;
        if (rankIndex >= 0 && rankIndex < row.length) {
          String rankStr = row[rankIndex].toString().trim();
          if (rankStr.isNotEmpty) {
            rank = int.tryParse(rankStr) ?? 999;
          }
        }
        
        // Get school info if available
        String school = "";
        if (columnIndices.containsKey('SCHOOL') && columnIndices['SCHOOL']! < row.length) {
          school = row[columnIndices['SCHOOL']!].toString();
        } else if (row.length > 3) {
          school = row[3].toString(); // Fallback to fourth column
        }
        
        // Create player and add to list
        if (name.isNotEmpty && position.isNotEmpty) {
          players.add(Player(
            id: id,
            name: name,
            position: position,
            rank: rank,
            school: school,
          ));
        }
      } catch (e) {
        debugPrint("Error parsing player at row $i: $e");
      }
    }
    
    // Sort players by rank to ensure consistent ordering
    players.sort((a, b) => a.rank.compareTo(b.rank));
    
    // Log the top 10 players for debugging
    debugPrint("Top 10 players by rank:");
    for (int i = 0; i < min(10, players.length); i++) {
      debugPrint("Player #${i+1}: ${players[i].name} - Rank: ${players[i].rank}");
    }
    
    debugPrint("Successfully loaded ${players.length} players");
    return players;
  } catch (e) {
    debugPrint("Error loading available players for year $year: $e");
    return [];
  }
}

static Future<List<TeamNeed>> loadTeamNeeds({required int year}) async {
  try {
    final data = await rootBundle.loadString('assets/$year/team_needs.csv');
    
    // Use column headers for parsing
    List<List<dynamic>> csvTable = const CsvToListConverter(eol: "\n").convert(data);
    
    if (csvTable.isEmpty) {
      debugPrint("Error: Empty CSV table for team needs");
      return [];
    }
    
    // Extract the header row to map column names to indices
    List<String> headers = csvTable[0].map<String>((dynamic col) => col.toString().toUpperCase()).toList();
    
    // Create index mappings for column names
    Map<String, int> columnIndices = {};
    for (int i = 0; i < headers.length; i++) {
      columnIndices[headers[i]] = i;
    }
    
    debugPrint("Team needs CSV headers: $headers");
    
    // Skip the header row (index 0)
    List<TeamNeed> teamNeeds = [];
    for (int i = 1; i < csvTable.length; i++) {
      try {
        TeamNeed teamNeed = TeamNeed.fromCsvRowWithHeaders(csvTable[i], columnIndices);
        teamNeeds.add(teamNeed);
      } catch (e) {
        debugPrint("Error parsing team need at row $i: $e");
      }
    }
    
    debugPrint("Successfully loaded ${teamNeeds.length} team needs");
    return teamNeeds;
  } catch (e) {
    debugPrint("Error loading team needs for year $year: $e");
    return [];
  }
}

  /// Convert models back to CSV-like lists for compatibility with existing UI
  static List<List<dynamic>> playersToLists(List<Player> players) {
    // Create header row based on your CSV structure
    List<dynamic> header = ['ID', 'Name', 'Position', 'School', 'Notes', 'Rank'];
    
    // Convert each player to a list
    List<List<dynamic>> result = [header];
    result.addAll(players.map((player) => player.toList()).toList());
    
    return result;
  }

  /// Convert draft picks back to CSV-like lists
  static List<List<dynamic>> draftPicksToLists(List<DraftPick> draftPicks) {
    // Create header row based on your CSV structure
    List<dynamic> header = ['Pick', 'Team', 'Selection', 'Position', 'Round', 'Trade'];
    
    // Convert each draft pick to a list
    List<List<dynamic>> result = [header];
    result.addAll(draftPicks.map((pick) => pick.toList()).toList());
    
    return result;
  }

  /// Convert team needs back to CSV-like lists
  static List<List<dynamic>> teamNeedsToLists(List<TeamNeed> teamNeeds) {
    // Create header row based on your CSV structure
    List<dynamic> header = ['ID', 'Team', 'Need1', 'Need2', 'Need3', 'Need4', 'Need5', 
                           'Need6', 'Need7', 'Need8', 'Need9', 'Need10', 'Selected'];
    
    // Convert each team need to a list
    List<List<dynamic>> result = [header];
    result.addAll(teamNeeds.map((need) => need.toList()).toList());
    
    return result;
  }
}