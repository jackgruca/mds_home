import 'package:flutter/services.dart';
import 'package:csv/csv.dart';

void main() async {
  try {
    print('🔍 Testing player data loading...');
    
    final csvString = await rootBundle.loadString('data/processed/team_data/current_players_combined.csv');
    print('✅ CSV loaded, length: ${csvString.length}');
    
    final List<List<dynamic>> csvTable = const CsvToListConverter(
      fieldDelimiter: ',',
      textDelimiter: '"',
      eol: '\n',
    ).convert(csvString);
    
    print('📊 CSV parsed: ${csvTable.length} rows');
    
    if (csvTable.isNotEmpty) {
      print('📋 Headers (${csvTable[0].length} columns):');
      for (int i = 0; i < csvTable[0].length && i < 20; i++) {
        print('  [$i] ${csvTable[0][i]}');
      }
      
      if (csvTable.length > 1) {
        print('\n📋 First data row (first 10 values):');
        for (int i = 0; i < 10 && i < csvTable[1].length; i++) {
          print('  [$i] ${csvTable[1][i]}');
        }
        
        // Try to parse first player
        try {
          print('\n🧪 Testing PlayerInfo.fromCsvRow...');
          // We can't actually import PlayerInfo here, but we can check the data structure
          print('Row length: ${csvTable[1].length}');
          print('Expected: 87 columns');
          
          if (csvTable[1].length >= 87) {
            print('✅ Row has enough columns');
          } else {
            print('❌ Row missing columns: has ${csvTable[1].length}, needs 87');
          }
        } catch (e) {
          print('❌ Error testing row: $e');
        }
      }
    }
    
  } catch (e) {
    print('❌ Error: $e');
  }
}
