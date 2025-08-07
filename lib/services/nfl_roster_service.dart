// lib/services/nfl_roster_service.dart

import 'package:flutter/services.dart';
import '../models/nfl_trade/nfl_player.dart';

class NFLRosterService {
  static List<NFLPlayer>? _cachedPlayers;
  static const String _csvAssetPath = 'assets/nfl_roster_data.csv';

  /// Get players for a specific team with filtering and sorting options
  static Future<List<NFLPlayer>> getTeamRoster(
    String teamAbbreviation, {
    String? position,
    String season = '2024',
    int limit = 100,
    String sortBy = 'overallRating', // Default sort by rating
    bool ascending = false,
  }) async {
    try {
      // Load all players if not cached
      if (_cachedPlayers == null) {
        await _loadPlayersFromCSV();
      }
      
      List<NFLPlayer> players = _cachedPlayers ?? [];
      
      // Filter by team
      players = players.where((player) => player.team == teamAbbreviation).toList();
      
      // Filter by position if specified
      if (position != null && position != 'All') {
        players = players.where((player) => player.position == position).toList();
      }
      
      // Apply sorting
      players = _sortPlayers(players, sortBy, ascending);
      
      // Apply limit
      if (players.length > limit) {
        players = players.take(limit).toList();
      }
      
      return players;
      
    } catch (e) {
      // print('Error fetching team roster: $e');
      return [];
    }
  }

  /// Get all available positions for a team
  static Future<List<String>> getTeamPositions(String teamAbbreviation) async {
    try {
      // Load all players if not cached
      if (_cachedPlayers == null) {
        await _loadPlayersFromCSV();
      }
      
      List<NFLPlayer> players = _cachedPlayers ?? [];
      
      // Filter by team and get unique positions
      Set<String> positions = players
          .where((player) => player.team == teamAbbreviation)
          .map((player) => player.position)
          .where((pos) => pos.isNotEmpty)
          .toSet();
      
      List<String> sortedPositions = positions.toList()..sort();
      return ['All', ...sortedPositions];
      
    } catch (e) {
      // print('Error fetching team positions: $e');
      return ['All'];
    }
  }

  /// Load players from CSV file
  static Future<void> _loadPlayersFromCSV() async {
    try {
      final csvData = await rootBundle.loadString(_csvAssetPath);
      _cachedPlayers = await _parseCSVData(csvData);
    } catch (e) {
      // print('Error loading CSV data: $e');
      _cachedPlayers = [];
    }
  }

  /// Parse CSV data into NFLPlayer objects
  static Future<List<NFLPlayer>> _parseCSVData(String csvData) async {
    List<NFLPlayer> players = [];
    List<String> lines = csvData.split('\n');
    
    if (lines.isEmpty) return players;
    
    // Parse header row to get column indices
    List<String> headers = _parseCSVLine(lines[0]);
    Map<String, int> columnIndices = {};
    for (int i = 0; i < headers.length; i++) {
      columnIndices[headers[i]] = i;
    }
    
    // Parse data rows (skip header)
    for (int i = 1; i < lines.length; i++) {
      String line = lines[i].trim();
      if (line.isEmpty) continue;
      
      try {
        List<String> values = _parseCSVLine(line);
        if (values.length >= headers.length - 5) { // Allow some missing columns
          NFLPlayer player = _convertCSVRowToNFLPlayer(values, columnIndices);
          players.add(player);
        }
      } catch (e) {
        // Skip invalid rows
        continue;
      }
    }
    
    return players;
  }

  /// Parse a single CSV line handling quoted values
  static List<String> _parseCSVLine(String line) {
    List<String> result = [];
    bool inQuotes = false;
    StringBuffer current = StringBuffer();
    
    for (int i = 0; i < line.length; i++) {
      String char = line[i];
      
      if (char == '"') {
        inQuotes = !inQuotes;
      } else if (char == ',' && !inQuotes) {
        result.add(current.toString().trim());
        current.clear();
      } else {
        current.write(char);
      }
    }
    
    result.add(current.toString().trim());
    return result;
  }

  /// Convert CSV row to NFLPlayer object
  static NFLPlayer _convertCSVRowToNFLPlayer(List<String> values, Map<String, int> columnIndices) {
    String getValue(String columnName, [String defaultValue = '']) {
      int? index = columnIndices[columnName];
      if (index == null || index >= values.length) return defaultValue;
      return values[index].isEmpty ? defaultValue : values[index];
    }
    
    double getDoubleValue(String columnName, [double defaultValue = 0.0]) {
      String value = getValue(columnName);
      return double.tryParse(value) ?? defaultValue;
    }
    
    int getIntValue(String columnName, [int defaultValue = 0]) {
      String value = getValue(columnName);
      return int.tryParse(value) ?? defaultValue;
    }
    
    bool getBoolValue(String columnName, [bool defaultValue = false]) {
      String value = getValue(columnName).toLowerCase();
      return value == 'true' || value == '1';
    }
    // Extract basic info from CSV columns
    String playerId = getValue('playerId', 'unknown_player');
    String name = getValue('name', 'Unknown Player');
    String position = getValue('position', 'UNK');
    String team = getValue('team', 'UNK');
    int age = getIntValue('age', 25);
    int experience = getIntValue('experience', 0);
    
    // Get calculated values from CSV
    double marketValue = getDoubleValue('marketValue', 10.0);
    double overallRating = getDoubleValue('overallRating', 75.0);
    double annualSalary = getDoubleValue('annualSalary', 1.0);
    double positionImportance = getDoubleValue('positionImportance', 0.5);
    double durabilityScore = getDoubleValue('durabilityScore', 85.0);
    
    // Get contract info
    String contractStatus = getValue('contract_status', 'veteran');
    int contractYearsRemaining = getIntValue('contractYearsRemaining', 2);
    
    // Get flags
    bool hasInjuryConcerns = getBoolValue('hasInjuryConcerns', false);
    
    // Calculate age-adjusted value
    double ageAdjustedValue = marketValue * _getAgeFactor(age);
    
    return NFLPlayer(
      playerId: playerId,
      name: name,
      position: position,
      team: team,
      age: age,
      experience: experience,
      marketValue: marketValue,
      contractStatus: contractStatus,
      contractYearsRemaining: contractYearsRemaining,
      annualSalary: annualSalary,
      overallRating: overallRating,
      positionRank: _calculatePositionRank(overallRating),
      ageAdjustedValue: ageAdjustedValue,
      positionImportance: positionImportance,
      durabilityScore: durabilityScore,
      hasInjuryConcerns: hasInjuryConcerns,
    );
  }
  
  /// Sort players based on the specified criteria
  static List<NFLPlayer> _sortPlayers(List<NFLPlayer> players, String sortBy, bool ascending) {
    players.sort((a, b) {
      int comparison = 0;
      
      switch (sortBy) {
        case 'overallRating':
        case 'rating':
          comparison = a.overallRating.compareTo(b.overallRating);
          break;
        case 'marketValue':
        case 'value':
          comparison = a.marketValue.compareTo(b.marketValue);
          break;
        case 'age':
          comparison = a.age.compareTo(b.age);
          break;
        case 'name':
          comparison = a.name.compareTo(b.name);
          break;
        case 'position':
          comparison = a.position.compareTo(b.position);
          break;
        case 'salary':
        case 'annualSalary':
          comparison = a.annualSalary.compareTo(b.annualSalary);
          break;
        case 'experience':
          comparison = a.experience.compareTo(b.experience);
          break;
        default:
          comparison = a.overallRating.compareTo(b.overallRating);
      }
      
      return ascending ? comparison : -comparison;
    });
    
    return players;
  }

  /// Clear cached players (useful for testing or refreshing data)
  static void clearCache() {
    _cachedPlayers = null;
  }

  static double _getAgeFactor(int age) {
    if (age <= 25) return 1.1; // Young player premium
    if (age <= 28) return 1.0; // Prime years
    if (age <= 31) return 0.9; // Veteran discount
    return 0.7; // Aging player discount
  }


  static double _calculatePositionRank(double overallRating) {
    // Convert overall rating to percentile rank
    return ((overallRating - 60.0) / 40.0 * 100.0).clamp(0.0, 100.0);
  }

}