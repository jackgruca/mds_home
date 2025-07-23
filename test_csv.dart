import 'dart:io';
import 'package:csv/csv.dart';

List<List<dynamic>> parseCSVManually(String csvData) {
  try {
    final lines = csvData.split('\n');
    final result = <List<dynamic>>[];
    
    for (String line in lines) {
      if (line.trim().isEmpty) continue;
      
      // Simple CSV parsing - split on commas but handle quoted values
      final row = <dynamic>[];
      bool inQuotes = false;
      String currentValue = '';
      
      for (int i = 0; i < line.length; i++) {
        final char = line[i];
        
        if (char == '"') {
          inQuotes = !inQuotes;
        } else if (char == ',' && !inQuotes) {
          row.add(currentValue.trim());
          currentValue = '';
        } else {
          currentValue += char;
        }
      }
      
      // Add the last value
      if (currentValue.isNotEmpty || row.isNotEmpty) {
        row.add(currentValue.trim());
      }
      
      if (row.isNotEmpty) {
        result.add(row);
      }
    }
    
    return result;
  } catch (e) {
    print('Manual parsing failed: $e');
    return [];
  }
}

void main() async {
  try {
    // Test direct file reading
    final file = File('assets/2026/available_players.csv');
    if (!file.existsSync()) {
      print('CSV file does not exist at: ${file.path}');
      return;
    }
    
    final content = await file.readAsString();
    print('File exists and has ${content.length} characters');
    
    // Try manual parsing
    final parsedData = parseCSVManually(content);
    print('Manual parsing resulted in ${parsedData.length} rows');
    
    if (parsedData.isNotEmpty) {
      print('Header: ${parsedData.first}');
      if (parsedData.length > 1) {
        print('First data row: ${parsedData[1]}');
        print('Row has ${parsedData[1].length} columns');
        
        if (parsedData.length > 2) {
          print('Second data row: ${parsedData[2]}');
          print('Player name: ${parsedData[2][1]}');
        }
      }
    }
    
  } catch (e) {
    print('Error: $e');
  }
}