// lib/services/data_service.dart

import 'dart:math';

import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:csv/csv.dart';

import '../models/player.dart';
import '../models/draft_pick.dart';
import '../models/team_need.dart';

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

// Now check if live data exists and should be used
    if (useLiveData) {
      try {
        final liveDataPath = 'assets/$year/live_draft_picks.csv';
        final liveData = await rootBundle.loadString(liveDataPath);
        
        // Parse live data
        List<List<dynamic>> liveTable = const CsvToListConverter(eol: "\n").convert(liveData);
        
        // Skip the header row (index 0)
        if (liveTable.length > 1) {
          // Create mapping of column names to indices
          List<String> headers = liveTable[0].map<String>((dynamic col) => col.toString().toUpperCase()).toList();
          Map<String, int> columnIndices = {};
          for (int i = 0; i < headers.length; i++) {
            columnIndices[headers[i]] = i;
          }
          
          // Update draft picks with live data
          for (int i = 1; i < liveTable.length; i++) {
            var row = liveTable[i];
            
            // Find pick number to update
            int pickIndex = columnIndices['PICK'] ?? 0;
            if (pickIndex >= row.length) continue;
            
            int pickNumber = int.tryParse(row[pickIndex].toString()) ?? 0;
            if (pickNumber <= 0) continue;
            
            // Find matching pick in our draft order
            int draftPickIndex = draftPicks.indexWhere((p) => p.pickNumber == pickNumber);
            if (draftPickIndex < 0) continue;
            
            // Check if this is a locked pick
            bool isLocked = false;
            int lockedIndex = columnIndices['LOCKED'] ?? columnIndices['IS_LOCKED'] ?? -1;
            if (lockedIndex >= 0 && lockedIndex < row.length) {
              String lockedStr = row[lockedIndex].toString().trim().toLowerCase();
              isLocked = lockedStr == 'true' || lockedStr == '1' || lockedStr == 'yes';
            }
            
            // Only process if locked
            if (!isLocked) continue;
            
            // Get team name in case of trades
            int teamIndex = columnIndices['TEAM'] ?? 1;
            if (teamIndex < row.length) {
              String teamName = row[teamIndex].toString();
              if (teamName.isNotEmpty) {
                draftPicks[draftPickIndex].teamName = teamName;
              }
            }
            
            // Get player name and position to create selected player
            int selectionIndex = columnIndices['SELECTION'] ?? 2;
            int positionIndex = columnIndices['POSITION'] ?? 3;
            
            if (selectionIndex < row.length && positionIndex < row.length) {
              String playerName = row[selectionIndex].toString();
              String position = row[positionIndex].toString();
              
              if (playerName.isNotEmpty && position.isNotEmpty) {
                // Create a player object for this selection
                Player player = Player(
                  id: 10000 + pickNumber, // Use arbitrary ID for live picks
                  name: playerName,
                  position: position,
                  rank: pickNumber, // Use pick number as rank for simplicity
                  school: row.length > 5 ? row[5].toString() : "",
                );
                
                // Update the draft pick
                draftPicks[draftPickIndex].selectedPlayer = player;
                draftPicks[draftPickIndex].isLockedPick = true;
              }
            }
          }
        }
      } catch (e) {
        // Live data file may not exist yet - that's okay
        debugPrint("Note: Live draft data not loaded: $e");
      }
    }
    
    return draftPicks;
  } catch (e) {
    debugPrint("Error loading draft order for year $year: $e");
    return [];
  }
}

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
      
    // If we have locked picks, remove those players from available pool
  if (lockedPicks != null && lockedPicks.isNotEmpty) {
    // Get set of player names from locked picks (real selections)
    final Set<String> pickedPlayerNames = lockedPicks
        .where((pick) => pick.isLockedPick && pick.selectedPlayer != null)
        .map((pick) => pick.selectedPlayer!.name.toLowerCase())
        .toSet();
    
    // Remove those players
    players.removeWhere((player) => 
      pickedPlayerNames.contains(player.name.toLowerCase()));
  }
  
  return players;
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