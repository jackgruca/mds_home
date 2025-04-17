// lib/models/team_need.dart
import 'package:flutter/material.dart';

class TeamNeed {
  final String teamName;
  final List<String> needs;
  final List<String> selectedPositions = []; // Change from String? to List<String>
  
  TeamNeed({
    required this.teamName,
    required this.needs,
  });
  
  // Create a TeamNeed from CSV row data
  factory TeamNeed.fromCsvRow(List<dynamic> row) {
  try {
    if (row.length < 2) {
      debugPrint("Warning: TeamNeed row has insufficient columns: $row");
      return TeamNeed(
        teamName: "Unknown Team",
        needs: [],
      );
    }
    
    List<String> needsList = [];
    
    // Skip the first two columns (index, team name) and get all non-empty needs
    for (int i = 2; i < row.length; i++) {
      if (row[i] != null && row[i].toString().isNotEmpty && row[i].toString() != "-") {
        needsList.add(row[i].toString());
      }
    }
    
    return TeamNeed(
      teamName: row[1].toString(),
      needs: needsList,
    );
  } catch (e) {
    debugPrint("Error creating TeamNeed from row: $e");
    return TeamNeed(
      teamName: "Error Team",
      needs: [],
    );
  }
}
// Add this method to the TeamNeed class
factory TeamNeed.fromCsvRowWithHeaders(List<dynamic> row, Map<String, int> columnIndices) {
  try {
    // Get team index
    int teamIndex = columnIndices['TEAM'] ?? columnIndices.entries
        .firstWhere((entry) => entry.key.contains('TEAM'), orElse: () => const MapEntry('', 1))
        .value;
    
    // Get team name
    String teamName = teamIndex >= 0 && teamIndex < row.length
        ? row[teamIndex].toString()
        : "Unknown Team";
    
    // Collect all need positions
    List<String> needsList = [];
    
    // Look for columns that have "NEED" in their name
    for (var entry in columnIndices.entries) {
      if (entry.key.contains('NEED')) {
        int index = entry.value;
        if (index >= 0 && index < row.length) {
          String value = row[index].toString();
          if (value.isNotEmpty && value != "-") {
            needsList.add(value);
          }
        }
      }
    }
    
    // If no needs found by column name, try to extract them from positions after team column
    if (needsList.isEmpty) {
      for (int i = teamIndex + 1; i < row.length; i++) {
        if (row[i] != null && row[i].toString().isNotEmpty && row[i].toString() != "-") {
          needsList.add(row[i].toString());
        }
      }
    }
    
    return TeamNeed(
      teamName: teamName,
      needs: needsList,
    );
  } catch (e) {
    debugPrint("Error creating TeamNeed from row with headers: $e");
    return TeamNeed(
      teamName: "Error Team",
      needs: [],
    );
  }
}

  
  // Convert team need back to a list for compatibility with existing code
  List<dynamic> toList() {
    List<dynamic> result = [0, teamName]; // First column is usually an index
    
    // Add needs, ensuring at least 10 positions (empty strings for missing needs)
    final int needsToFill = 10 - needs.length;
    result.addAll(needs);
    if (needsToFill > 0) {
      result.addAll(List.filled(needsToFill, ''));
    }
    
    // Add the selected positions, joined by commas
    result.add(selectedPositions.join(", "));
    
    return result;
  }
  
  // Remove a position from needs when drafted and add to selected positions
  void removeNeed(String position) {
    needs.remove(position);
    selectedPositions.add(position); // Add to the list instead of replacing
  }

  void addNeedPosition(String position) {
  if (!needs.contains(position)) {
    needs.add(position);
  }
}
  
  // Check if this position is a need
  bool isPositionANeed(String position) {
    return needs.contains(position);
  }
  
  // Get the primary need (first in the list)
  String? get primaryNeed => needs.isNotEmpty ? needs.first : null;
  
  @override
  String toString() => '$teamName Needs: ${needs.join(", ")}';
}