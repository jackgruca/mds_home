// lib/models/player.dart
import 'package:flutter/material.dart';

class Player {
  final int id;
  final String name;
  final String position;
  final int rank;
  final String school;
  final String? notes;
  
  const Player({
    required this.id,
    required this.name,
    required this.position,
    required this.rank,
    this.school = '',
    this.notes,
  });
  
  // Create a Player from CSV row data
  factory Player.fromCsvRow(List<dynamic> row) {
  try {
    // Make sure row has enough elements
    if (row.length < 3) {
      debugPrint("Warning: Player row has insufficient columns: $row");
      return const Player(
        id: 0,
        name: "Unknown Player",
        position: "NA",
        rank: 999,
      );
    }
    
    // Parse ID safely
    int id = 0;
    try {
      id = int.tryParse(row[0].toString()) ?? 0;
    } catch (e) {
      debugPrint("Failed to parse player ID: ${row[0]}");
    }
    
    // Get name and position
    String name = row[1].toString();
    String position = row[2].toString();
    
    // Parse rank (which could be in different positions)
    int rank = 999;
    if (row.length > 3) {
      try {
        // Try to get rank from the last column
        rank = int.tryParse(row.last.toString()) ?? 999;
      } catch (e) {
        debugPrint("Failed to parse player rank from last column: ${row.last}");
      }
    }
    
    // Additional fields if available
    String school = row.length > 3 ? row[3].toString() : '';
    String? notes = row.length > 4 ? row[4].toString() : null;
    
    return Player(
      id: id,
      name: name,
      position: position,
      rank: rank,
      school: school,
      notes: notes,
    );
  } catch (e) {
    debugPrint("Error creating Player from row: $e");
    return const Player(
      id: 0,
      name: "Error Player",
      position: "NA",
      rank: 999,
    );
  }
}
// Add this method to the Player class
factory Player.fromCsvRowWithHeaders(List<dynamic> row, Map<String, int> columnIndices) {
  try {
    // Get column indices (with fallbacks)
    int idIndex = columnIndices['ID'] ?? 0;
    int nameIndex = columnIndices['Name'] ?? 1;
    int positionIndex = columnIndices['Position'] ?? 2;
    int schoolIndex = columnIndices['School'] ?? columnIndices.entries
        .firstWhere((entry) => entry.key.contains('School'), orElse: () => const MapEntry('', 3))
        .value;
    int notesIndex = columnIndices['NOTES'] ?? columnIndices.entries
        .firstWhere((entry) => entry.key.contains('NOTES'), orElse: () => const MapEntry('', -1))
        .value;
    
    // Find rank index - specifically look for combined_rank
    int rankIndex = -1;
    for (var entry in columnIndices.entries) {
      if (entry.key.contains('COMBINED_RANK') || entry.key.contains('RANK_COMBINED')) {
        rankIndex = entry.value;
        break;
      }
    }
    
    // If no combined rank found, try any rank column
    if (rankIndex == -1) {
      rankIndex = columnIndices.entries
          .firstWhere((entry) => entry.key.contains('RANK'), orElse: () => MapEntry('', row.length - 1))
          .value;
    }
    
    // Parse values safely
    int id = idIndex >= 0 && idIndex < row.length
        ? int.tryParse(row[idIndex].toString()) ?? 0
        : 0;
    
    String name = nameIndex >= 0 && nameIndex < row.length
        ? row[nameIndex].toString()
        : "Unknown Player";
    
    String position = positionIndex >= 0 && positionIndex < row.length
        ? row[positionIndex].toString()
        : "UNK";
    
    int rank = 999;
    if (rankIndex >= 0 && rankIndex < row.length) {
      String rankStr = row[rankIndex].toString().trim();
      if (rankStr.isNotEmpty) {
        rank = int.tryParse(rankStr) ?? 999;
      }
    }
    
    String school = schoolIndex >= 0 && schoolIndex < row.length
        ? row[schoolIndex].toString()
        : "";
    
    String? notes = notesIndex >= 0 && notesIndex < row.length
        ? row[notesIndex].toString()
        : null;
    
    return Player(
      id: id,
      name: name,
      position: position,
      rank: rank,
      school: school,
      notes: notes,
    );
  } catch (e) {
    debugPrint("Error creating Player from row with headers: $e");
    return const Player(
      id: 0,
      name: "Error Player",
      position: "UNK",
      rank: 999,
    );
  }
}
  
  // Convert player back to a list for compatibility with existing code
  List<dynamic> toList() {
    return [id.toString(), name, position, school, notes ?? '', rank.toString()];
  }
  
  @override
  String toString() => '$name ($position) - Rank: $rank';
}