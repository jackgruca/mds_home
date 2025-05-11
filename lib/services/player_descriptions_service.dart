// lib/services/player_descriptions_service.dart

import 'package:flutter/services.dart';
import 'package:csv/csv.dart';
import 'package:flutter/material.dart';

class PlayerDescriptionsService {
  static Map<String, Map<String, String>> _playerDescriptions = {};
  static bool _isInitialized = false;
  static List<String> _allPlayerNames = []; // Added to keep track of all names

// In lib/services/player_descriptions_service.dart

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
    _allPlayerNames = []; // Clear existing names
    
    // Process each row
    for (int i = startIdx; i < csvTable.length; i++) {
      if (csvTable[i].length >= 4) {
        String name = csvTable[i][0].toString().trim();
        _allPlayerNames.add(name.toLowerCase());
        
        String description = csvTable[i][1].toString().trim();
        String strengths = csvTable[i][2].toString().trim();
        String weaknesses = csvTable[i][3].toString().trim();
        
        // Get height and weight if available
        String height = csvTable[i].length > 4 ? csvTable[i][4].toString().trim() : "";
        String weight = csvTable[i].length > 5 ? csvTable[i][5].toString().trim() : "";
        
        // Get 40 time and RAS if available
        String fortyTime = csvTable[i].length > 6 ? csvTable[i][6].toString().trim() : "";
        String ras = csvTable[i].length > 7 ? csvTable[i][7].toString().trim() : "";
        
        // New athletic measurements
        String tenYardSplit = csvTable[i].length > 8 ? csvTable[i][8].toString().trim() : "";
        String twentyYardShuttle = csvTable[i].length > 9 ? csvTable[i][9].toString().trim() : "";
        String threeCone = csvTable[i].length > 10 ? csvTable[i][10].toString().trim() : "";
        String armLength = csvTable[i].length > 11 ? csvTable[i][11].toString().trim() : "";
        String benchPress = csvTable[i].length > 12 ? csvTable[i][12].toString().trim() : "";
        String broadJump = csvTable[i].length > 13 ? csvTable[i][13].toString().trim() : "";
        String handSize = csvTable[i].length > 14 ? csvTable[i][14].toString().trim() : "";
        String verticalJump = csvTable[i].length > 15 ? csvTable[i][15].toString().trim() : "";
        String wingspan = csvTable[i].length > 16 ? csvTable[i][16].toString().trim() : "";
        
        _playerDescriptions[name.toLowerCase()] = {
          'description': description,
          'strengths': strengths,
          'weaknesses': weaknesses,
          'height': height,
          'weight': weight,
          'fortyTime': fortyTime,
          'ras': ras,
          // New athletic measurements
          'tenYardSplit': tenYardSplit,
          'twentyYardShuttle': twentyYardShuttle,
          'threeCone': threeCone,
          'armLength': armLength,
          'benchPress': benchPress,
          'broadJump': broadJump,
          'handSize': handSize,
          'verticalJump': verticalJump,
          'wingspan': wingspan,
        };
      }
    }
    
    debugPrint("Loaded descriptions for ${_playerDescriptions.length} players");
    debugPrint("Sample of player names in CSV: ${_allPlayerNames.take(5).join(', ')}...");
    _isInitialized = true;
  } catch (e) {
    debugPrint("Error loading player descriptions: $e");
    _isInitialized = true; // Mark as initialized to avoid repeated attempts
  }
}

// Update the getPlayerDescription method to include height and weight

static Map<String, String>? getPlayerDescription(String playerName) {
  if (!_isInitialized) {
    debugPrint("Warning: Player descriptions not initialized");
    return null;
  }
  
  if (playerName.isEmpty) {
    return null;
  }
  
  // Debug information
  debugPrint("Looking for player: '$playerName'");
  
  // Normalize the player name for comparison
  String normalizedName = _normalizeName(playerName);
  
  // Try exact match first
  if (_playerDescriptions.containsKey(normalizedName)) {
    debugPrint("Found exact match for: $playerName ($normalizedName)");
    return _playerDescriptions[normalizedName];
  }
  
  // Try without period in names like "J.J. Watt" -> "JJ Watt"
  String noPeriodName = normalizedName.replaceAll(".", "");
  for (var entry in _playerDescriptions.entries) {
    String csvNameNoPeriod = entry.key.replaceAll(".", "");
    if (csvNameNoPeriod == noPeriodName) {
      debugPrint("Found match after removing periods: $playerName -> ${entry.key}");
      return entry.value;
    }
  }
  
  // Try to find the most similar name
  // String? bestMatch = _findBestMatch(normalizedName, _allPlayerNames);
  // if (bestMatch != null) {
  //   debugPrint("Found best match: $playerName -> $bestMatch (similarity: ${_calculateSimilarity(normalizedName, bestMatch)})");
  //   return _playerDescriptions[bestMatch];
  // }
  
  // // Try matching parts of the name (first name or last name)
  // for (var entry in _playerDescriptions.entries) {
  //   List<String> playerNameParts = normalizedName.split(' ');
  //   List<String> csvNameParts = entry.key.split(' ');
    
  //   // Check if last names match (usually more unique)
  //   if (playerNameParts.isNotEmpty && csvNameParts.isNotEmpty &&
  //       playerNameParts.last == csvNameParts.last) {
  //     debugPrint("Found match by last name: $playerName -> ${entry.key}");
  //     return entry.value;
  //   }
    
  //   // Check if first names match
  //   if (playerNameParts.isNotEmpty && csvNameParts.isNotEmpty &&
  //       playerNameParts.first == csvNameParts.first) {
  //     // Only use first name match if the names are otherwise similar
  //     double similarity = _calculateSimilarity(normalizedName, entry.key);
  //     if (similarity > 0.6) {
  //       debugPrint("Found match by first name with high similarity: $playerName -> ${entry.key}");
  //       return entry.value;
  //     }
  //   }
  // }
  
  debugPrint("No match found for player: $playerName");
  return null;
}
  
  /// Normalize a name for better matching
  static String _normalizeName(String name) {
    return name.toLowerCase()
        .trim()
        .replaceAll(RegExp(r'\s+'), ' '); // Normalize whitespace
  }
  
  
  
  
  /// Print all loaded player names for debugging
  static void debugPrintAllPlayerNames() {
    if (!_isInitialized) {
      debugPrint("Warning: Player descriptions not initialized");
      return;
    }
    
    debugPrint("All player names in CSV (${_allPlayerNames.length}):");
    for (var name in _allPlayerNames) {
      debugPrint("- $name");
    }
  }
}