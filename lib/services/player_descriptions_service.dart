// lib/services/player_descriptions_service.dart
import 'package:flutter/services.dart';
import 'package:csv/csv.dart';
import 'package:flutter/material.dart';

class PlayerDescriptionsService {
  static Map<String, Map<String, String>> _playerDescriptions = {};
  static bool _isInitialized = false;

  /// Load the player descriptions from CSV
  static Future<void> initialize({int year = 2025}) async {
    if (_isInitialized) return;
    
    try {
      final data = await rootBundle.loadString('assets/$year/player_descriptions.csv');
      
      List<List<dynamic>> csvTable = const CsvToListConverter(eol: "\n").convert(data);
      debugPrint("CSV parsed with ${csvTable.length} rows");
      
      // Check if header exists
      bool hasHeader = csvTable.isNotEmpty && 
                      csvTable[0].length >= 2 && 
                      csvTable[0][0].toString().toLowerCase() == "name";
      
      int startIdx = hasHeader ? 1 : 0;
      
      _playerDescriptions = {};
      
      // Process each row
      for (int i = startIdx; i < csvTable.length; i++) {
        if (csvTable[i].length >= 4) {
          String name = csvTable[i][0].toString().trim();
          String description = csvTable[i][1].toString().trim();
          String strengths = csvTable[i][2].toString().trim();
          String weaknesses = csvTable[i][3].toString().trim();
          
          _playerDescriptions[name.toLowerCase()] = {
            'description': description,
            'strengths': strengths,
            'weaknesses': weaknesses,
          };
        }
      }
      
      debugPrint("Loaded descriptions for ${_playerDescriptions.length} players");
      _isInitialized = true;
    } catch (e) {
      debugPrint("Error loading player descriptions: $e");
      _isInitialized = true; // Mark as initialized to avoid repeated attempts
    }
  }
  
  /// Get player description data by name
  static Map<String, String>? getPlayerDescription(String playerName) {
    if (!_isInitialized) {
      debugPrint("Warning: Player descriptions not initialized");
      return null;
    }
    
    // Try exact match first
    String normalizedName = playerName.toLowerCase();
    if (_playerDescriptions.containsKey(normalizedName)) {
      return _playerDescriptions[normalizedName];
    }
    
    // Try partial name matches
    for (var entry in _playerDescriptions.entries) {
      if (entry.key.contains(normalizedName) || normalizedName.contains(entry.key)) {
        debugPrint("Found partial match for player: $playerName -> ${entry.key}");
        return entry.value;
      }
    }
    
    return null;
  }
}