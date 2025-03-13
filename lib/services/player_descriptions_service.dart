// lib/services/player_descriptions_service.dart
import 'dart:math';

import 'package:flutter/services.dart';
import 'package:csv/csv.dart';
import 'package:flutter/material.dart';

class PlayerDescriptionsService {
  static Map<String, Map<String, String>> _playerDescriptions = {};
  static bool _isInitialized = false;
  static List<String> _allPlayerNames = []; // Added to keep track of all names

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
      _allPlayerNames = []; // Clear existing names
      
      // Process each row
      for (int i = startIdx; i < csvTable.length; i++) {
        if (csvTable[i].length >= 4) {
          String name = csvTable[i][0].toString().trim();
          _allPlayerNames.add(name.toLowerCase());
          
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
      debugPrint("Sample of player names in CSV: ${_allPlayerNames.take(5).join(', ')}...");
      _isInitialized = true;
    } catch (e) {
      debugPrint("Error loading player descriptions: $e");
      _isInitialized = true; // Mark as initialized to avoid repeated attempts
    }
  }
  
  /// Get player description data by name with enhanced matching
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
    String? bestMatch = _findBestMatch(normalizedName, _allPlayerNames);
    if (bestMatch != null) {
      debugPrint("Found best match: $playerName -> $bestMatch (similarity: ${_calculateSimilarity(normalizedName, bestMatch)})");
      return _playerDescriptions[bestMatch];
    }
    
    // Try matching parts of the name (first name or last name)
    for (var entry in _playerDescriptions.entries) {
      List<String> playerNameParts = normalizedName.split(' ');
      List<String> csvNameParts = entry.key.split(' ');
      
      // Check if last names match (usually more unique)
      if (playerNameParts.isNotEmpty && csvNameParts.isNotEmpty &&
          playerNameParts.last == csvNameParts.last) {
        debugPrint("Found match by last name: $playerName -> ${entry.key}");
        return entry.value;
      }
      
      // Check if first names match
      if (playerNameParts.isNotEmpty && csvNameParts.isNotEmpty &&
          playerNameParts.first == csvNameParts.first) {
        // Only use first name match if the names are otherwise similar
        double similarity = _calculateSimilarity(normalizedName, entry.key);
        if (similarity > 0.6) {
          debugPrint("Found match by first name with high similarity: $playerName -> ${entry.key}");
          return entry.value;
        }
      }
    }
    
    debugPrint("No match found for player: $playerName");
    return null;
  }
  
  /// Normalize a name for better matching
  static String _normalizeName(String name) {
    return name.toLowerCase()
        .trim()
        .replaceAll(RegExp(r'\s+'), ' '); // Normalize whitespace
  }
  
  /// Calculate similarity between two strings (0.0 to 1.0)
  static double _calculateSimilarity(String s1, String s2) {
    if (s1 == s2) return 1.0;
    if (s1.isEmpty || s2.isEmpty) return 0.0;
    
    // Calculate Levenshtein distance
    int distance = _levenshteinDistance(s1, s2);
    int maxLength = s1.length > s2.length ? s1.length : s2.length;
    
    // Convert to similarity (0.0 to 1.0)
    return 1.0 - (distance / maxLength);
  }
  
  /// Find the best matching name from a list of candidates
  static String? _findBestMatch(String name, List<String> candidates) {
    if (candidates.isEmpty) return null;
    
    String? bestMatch;
    double bestSimilarity = 0.5; // Threshold for a good match
    
    for (var candidate in candidates) {
      double similarity = _calculateSimilarity(name, candidate);
      if (similarity > bestSimilarity) {
        bestSimilarity = similarity;
        bestMatch = candidate;
      }
    }
    
    return bestMatch;
  }
  
  /// Calculate Levenshtein distance between two strings
  static int _levenshteinDistance(String s1, String s2) {
    if (s1 == s2) return 0;
    if (s1.isEmpty) return s2.length;
    if (s2.isEmpty) return s1.length;
    
    List<List<int>> d = List.generate(
      s1.length + 1, 
      (i) => List.generate(s2.length + 1, (j) => 0)
    );
    
    for (int i = 0; i <= s1.length; i++) {
      d[i][0] = i;
    }
    
    for (int j = 0; j <= s2.length; j++) {
      d[0][j] = j;
    }
    
    for (int j = 1; j <= s2.length; j++) {
      for (int i = 1; i <= s1.length; i++) {
        int cost = (s1[i - 1] == s2[j - 1]) ? 0 : 1;
        d[i][j] = [
          d[i - 1][j] + 1,      // deletion
          d[i][j - 1] + 1,      // insertion
          d[i - 1][j - 1] + cost // substitution
        ].reduce(min);
      }
    }
    
    return d[s1.length][s2.length];
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