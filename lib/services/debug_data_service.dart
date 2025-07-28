import 'dart:convert';
import 'package:csv/csv.dart';
import 'package:flutter/services.dart';

/// Debug service to test data loading
class DebugDataService {
  static Future<void> testDataLoading() async {
    print('=== DEBUG: Testing Data Loading ===');
    
    try {
      // Test game level stats
      print('Loading game level stats...');
      final gameStatsString = await rootBundle.loadString('assets/data/player_game_stats_2024.csv');
      final gameStatsTable = const CsvToListConverter().convert(gameStatsString);
      print('Game stats rows: ${gameStatsTable.length}');
      if (gameStatsTable.isNotEmpty) {
        print('Game stats headers: ${gameStatsTable[0]}');
        if (gameStatsTable.length > 1) {
          print('First data row: ${gameStatsTable[1]}');
        }
      }
      
      // Test player profiles
      print('\nLoading player profiles...');
      final profilesString = await rootBundle.loadString('assets/data/player_profiles.csv');
      final profilesTable = const CsvToListConverter().convert(profilesString);
      print('Profiles rows: ${profilesTable.length}');
      if (profilesTable.isNotEmpty) {
        print('Profiles headers: ${profilesTable[0]}');
        if (profilesTable.length > 1) {
          print('First profile row: ${profilesTable[1]}');
        }
      }
      
      // Test if we can find J.Conner
      final connerRows = gameStatsTable.where((row) => 
        row.length > 5 && row[5].toString().contains('Conner')).toList();
      print('\nJ.Conner game rows found: ${connerRows.length}');
      if (connerRows.isNotEmpty) {
        print('Conner row example: ${connerRows.first}');
        print('Conner player_id: ${connerRows.first[4]}');
      }
      
      // Check profile for same player
      final connerProfile = profilesTable.where((row) =>
        row.length > 1 && row[1].toString().contains('Williams')).toList();
      print('\nProfile matches found: ${connerProfile.length}');
      if (connerProfile.isNotEmpty) {
        print('Profile example: ${connerProfile.first}');
      }
      
    } catch (e) {
      print('ERROR loading data: $e');
    }
  }
  
  static Future<Map<String, dynamic>?> testPlayerProfileLoad(String playerId) async {
    print('=== DEBUG: Testing Player Profile Load for $playerId ===');
    
    try {
      // Load profiles
      final profilesString = await rootBundle.loadString('assets/data/player_profiles.csv');
      final profilesTable = const CsvToListConverter().convert(profilesString);
      
      print('Looking for player_id: $playerId');
      
      // Find matching profile
      for (int i = 1; i < profilesTable.length; i++) {
        final row = profilesTable[i];
        if (row.length > 0 && row[0].toString() == playerId) {
          print('Found profile match at row $i: $row');
          return {
            'player_id': row[0],
            'player_name': row[1],
            'position': row[2],
            'team': row[3],
            'height': row[4],
            'weight': row[5],
          };
        }
      }
      
      print('No profile found for player_id: $playerId');
      return null;
      
    } catch (e) {
      print('ERROR in testPlayerProfileLoad: $e');
      return null;
    }
  }
}