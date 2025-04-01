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
    
    debugPrint("Successfully loaded ${draftPicks.length} draft picks");
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