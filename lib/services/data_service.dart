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
  /// Load and parse the available players CSV
 static Future<List<Player>> loadAvailablePlayers({required int year}) async {
  try {
    final data = await rootBundle.loadString('assets/$year/available_players.csv');
    List<List<dynamic>> csvTable = const CsvToListConverter(eol: "\n").convert(data);
    
    // Skip the header row (index 0)
    return csvTable
        .skip(1)
        .map((row) => Player.fromCsvRow(row))
        .toList();
  } catch (e) {
    debugPrint("Error loading available players for year $year: $e");
    return [];
  }
}

  /// Load and parse the draft order CSV
  static Future<List<DraftPick>> loadDraftOrder({required int year}) async {
  try {
    final data = await rootBundle.loadString('assets/$year/draft_order.csv');
    List<List<dynamic>> csvTable = const CsvToListConverter(eol: "\n").convert(data);
    
    // Skip the header row (index 0)
    return csvTable
        .skip(1)
        .map((row) => DraftPick.fromCsvRow(row))
        .toList();
  } catch (e) {
    debugPrint("Error loading draft order for year $year: $e");
    return [];
  }
}

  /// Load and parse the team needs CSV
  static Future<List<TeamNeed>> loadTeamNeeds({required int year}) async {
  try {
    final data = await rootBundle.loadString('assets/$year/team_needs.csv');
    List<List<dynamic>> csvTable = const CsvToListConverter(eol: "\n").convert(data);
    
    // Skip the header row (index 0)
    return csvTable
        .skip(1)
        .map((row) => TeamNeed.fromCsvRow(row))
        .toList();
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