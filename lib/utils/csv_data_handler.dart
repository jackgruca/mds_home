import 'package:flutter/material.dart';
import 'package:csv/csv.dart';

/// A utility class to handle CSV data with robust error handling
/// and flexible field access for compatibility across different formats
class CsvDataHandler {
  /// Safely converts CSV string data to a List<List<dynamic>> with error handling
  /// Uses standardized field conversion and handles format variations
  static List<List<dynamic>> parseCsvData(String csvData, {bool standardizeFields = true}) {
    try {
      // Parse the CSV data
      List<List<dynamic>> csvTable = const CsvToListConverter(eol: "\n").convert(csvData);
      
      // Convert all cells to strings for consistency
      List<List<dynamic>> processedData = csvTable.map((row) {
        return row.map((cell) => cell?.toString() ?? "").toList();
      }).toList();
      
      if (standardizeFields && processedData.isNotEmpty) {
        // Log the header row for debugging
        debugPrint("CSV Header Row: ${processedData[0]}");
      }
      
      return processedData;
    } catch (e) {
      debugPrint("❌ Error parsing CSV data: $e");
      // Return an empty list with header row as fallback
      return [[]];
    }
  }
  
  /// Safely accesses a value from a row with a fallback value
  /// This helps with compatibility across different CSV formats
  static String safeAccess(List<dynamic> row, int index, {String fallback = ""}) {
    if (index < 0 || index >= row.length) {
      return fallback;
    }
    return row[index]?.toString() ?? fallback;
  }

  /// Finds a field value in the first row (header) and returns the corresponding index
  /// This allows for flexible field access even when column order changes
  static int findFieldIndex(List<List<dynamic>> data, String fieldName) {
    if (data.isEmpty || data[0].isEmpty) {
      return -1;
    }
    
    final header = data[0];
    for (int i = 0; i < header.length; i++) {
      if (header[i].toString().toLowerCase() == fieldName.toLowerCase()) {
        return i;
      }
    }
    
    return -1; // Field not found
  }
  
  /// Finds a team in the teams list by name with fuzzy matching
  /// This helps handle slight variations in team names between different year formats
  static int findTeamIndex(List<List<dynamic>> teams, String teamName) {
    if (teams.isEmpty || teamName.isEmpty) {
      return -1;
    }
    
    // Try exact match first
    for (int i = 1; i < teams.length; i++) {
      if (teams[i][1].toString().toLowerCase() == teamName.toLowerCase()) {
        return i;
      }
    }
    
    // Try partial match if exact match fails
    for (int i = 1; i < teams.length; i++) {
      if (teams[i][1].toString().toLowerCase().contains(teamName.toLowerCase()) ||
          teamName.toLowerCase().contains(teams[i][1].toString().toLowerCase())) {
        return i;
      }
    }
    
    return -1; // Team not found
  }
}