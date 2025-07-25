import 'dart:convert';
import 'package:flutter/services.dart';

/// More robust CSV parser that handles various edge cases
class RobustCsvParser {
  static Future<List<Map<String, dynamic>>> parsePlayerStats() async {
    try {
      // Load the raw file
      final csvString = await rootBundle.loadString('assets/data/player_stats_2024.csv');
      print('🔍 Raw file size: ${csvString.length} bytes');
      
      // Normalize line endings to \n
      final normalizedCsv = csvString.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
      print('🔍 After normalization: ${normalizedCsv.length} bytes');
      
      // Split into lines
      final lines = normalizedCsv.split('\n').where((line) => line.trim().isNotEmpty).toList();
      print('🔍 Non-empty lines: ${lines.length}');
      
      if (lines.length < 2) {
        throw Exception('CSV must have at least header + 1 data row, found ${lines.length} lines');
      }
      
      // Parse header manually
      final headerLine = lines[0];
      final headers = _parseCsvLine(headerLine);
      print('🔍 Headers: ${headers.length} columns');
      print('🔍 First 5 headers: ${headers.take(5).join(", ")}');
      
      // Parse data rows
      final data = <Map<String, dynamic>>[];
      for (int i = 1; i < lines.length; i++) {
        try {
          final rowData = _parseCsvLine(lines[i]);
          
          // Create row object
          final row = <String, dynamic>{};
          for (int j = 0; j < headers.length; j++) {
            final value = j < rowData.length ? rowData[j] : '';
            row[headers[j]] = _convertValue(value);
          }
          
          data.add(row);
        } catch (e) {
          print('⚠️ Failed to parse line ${i + 1}: $e');
          // Skip bad lines but continue
        }
      }
      
      print('✅ Parsed ${data.length} records successfully');
      return data;
      
    } catch (e) {
      print('❌ CSV parsing failed: $e');
      rethrow;
    }
  }
  
  /// Parse a single CSV line handling quoted fields
  static List<String> _parseCsvLine(String line) {
    final fields = <String>[];
    final buffer = StringBuffer();
    bool inQuotes = false;
    bool escapeNext = false;
    
    for (int i = 0; i < line.length; i++) {
      final char = line[i];
      
      if (escapeNext) {
        buffer.write(char);
        escapeNext = false;
      } else if (char == '"') {
        if (inQuotes && i + 1 < line.length && line[i + 1] == '"') {
          // Escaped quote
          buffer.write('"');
          i++; // Skip next quote
        } else {
          // Toggle quote state
          inQuotes = !inQuotes;
        }
      } else if (char == ',' && !inQuotes) {
        // Field separator
        fields.add(buffer.toString());
        buffer.clear();
      } else {
        buffer.write(char);
      }
    }
    
    // Add last field
    fields.add(buffer.toString());
    
    return fields;
  }
  
  /// Convert string values to appropriate types
  static dynamic _convertValue(String value) {
    // Remove surrounding quotes if present
    String cleanValue = value;
    if (cleanValue.startsWith('"') && cleanValue.endsWith('"')) {
      cleanValue = cleanValue.substring(1, cleanValue.length - 1);
    }
    
    // Handle empty values
    if (cleanValue.isEmpty || cleanValue.toLowerCase() == 'null') {
      return null;
    }
    
    // Try to parse as number
    final numValue = num.tryParse(cleanValue);
    if (numValue != null) {
      return numValue;
    }
    
    // Return as string
    return cleanValue;
  }
  
  /// Quick test to verify parsing works
  static Future<bool> testParsing() async {
    try {
      final data = await parsePlayerStats();
      
      if (data.isEmpty) {
        print('❌ No data parsed');
        return false;
      }
      
      print('✅ Test successful: ${data.length} records');
      
      // Check a few sample records
      final sample = data.first;
      print('📋 Sample record keys: ${sample.keys.take(10).join(", ")}');
      print('📋 Sample values: ${sample.values.take(5).join(", ")}');
      
      // Look for QBs
      final qbs = data.where((p) => p['position'] == 'QB').toList();
      print('📊 Found ${qbs.length} QBs');
      
      return true;
    } catch (e) {
      print('❌ Test failed: $e');
      return false;
    }
  }
}