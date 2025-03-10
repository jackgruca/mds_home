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
    
    debugPrint("Available players CSV headers: $headers");
    
    // Skip the header row (index 0)
    List<Player> players = [];
    for (int i = 1; i < csvTable.length; i++) {
      try {
        Player player = Player.fromCsvRowWithHeaders(csvTable[i], columnIndices);
        players.add(player);
      } catch (e) {
        debugPrint("Error parsing player at row $i: $e");
      }
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