import 'package:csv/csv.dart';
import 'package:flutter/services.dart';

/// Debug service to test different CSV parsing approaches
class CsvDebugService {
  static Future<void> debugCsvParsing() async {
    print('🔍 Starting CSV debug...');
    
    try {
      final csvString = await rootBundle.loadString('assets/data/player_stats_2024.csv');
      print('✅ File loaded: ${csvString.length} bytes');
      
      // Method 1: Count lines manually
      final lines = csvString.split('\n');
      print('📊 Manual line count: ${lines.length}');
      print('📋 First line: ${lines[0].substring(0, 100)}...');
      if (lines.length > 1) {
        print('📋 Second line: ${lines[1].substring(0, 100)}...');
      }
      
      // Method 2: Default CSV parser
      try {
        final csvTable1 = const CsvToListConverter().convert(csvString);
        print('✅ Default parser: ${csvTable1.length} rows');
      } catch (e) {
        print('❌ Default parser failed: $e');
      }
      
      // Method 3: Explicit settings
      try {
        final csvTable2 = const CsvToListConverter(
          fieldDelimiter: ',',
          textDelimiter: '"',
          eol: '\n'
        ).convert(csvString);
        print('✅ Explicit parser: ${csvTable2.length} rows');
      } catch (e) {
        print('❌ Explicit parser failed: $e');
      }
      
      // Method 4: Try with \r\n
      try {
        final csvTable3 = const CsvToListConverter(eol: '\r\n').convert(csvString);
        print('✅ CRLF parser: ${csvTable3.length} rows');
      } catch (e) {
        print('❌ CRLF parser failed: $e');
      }
      
      // Method 5: Manual parsing first few lines
      print('🔍 Manual parsing test:');
      for (int i = 0; i < 3 && i < lines.length; i++) {
        final line = lines[i];
        if (line.isNotEmpty) {
          try {
            final parsed = const CsvToListConverter().convert(line);
            print('  Line $i: ${parsed[0].length} fields');
          } catch (e) {
            print('  Line $i: Failed to parse - $e');
          }
        }
      }
      
    } catch (e) {
      print('❌ File loading failed: $e');
    }
  }
}