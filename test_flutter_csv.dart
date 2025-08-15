// Test CSV parsing like Flutter does
import 'dart:io';
import 'package:csv/csv.dart';

void main() async {
  try {
    print('🔍 Testing Flutter-style CSV parsing...');
    
    // Read the CSV file
    final file = File('data/processed/team_data/current_players_combined.csv');
    final csvString = await file.readAsString();
    
    print('📊 CSV loaded, length: ${csvString.length}');
    
    // Parse CSV with same settings as Flutter app
    final List<List<dynamic>> csvTable = const CsvToListConverter(
      fieldDelimiter: ',',
      textDelimiter: '"',
      eol: '\n',
    ).convert(csvString);
    
    print('📊 CSV parsed: ${csvTable.length} rows');
    
    if (csvTable.isNotEmpty) {
      print('📋 Header row has ${csvTable[0].length} columns');
      
      if (csvTable.length > 1) {
        print('📋 First data row has ${csvTable[1].length} columns');
        
        // Try to access the fields that PlayerInfo.fromCsvRow would access
        final row = csvTable[1];
        print('🔍 Testing field access:');
        print('  [0] player_id: ${row[0]}');
        print('  [1] full_name: ${row[1]}');
        print('  [11] displayName: ${row[11]}');
        print('  [25] fantasy_points_ppr: ${row[25]}');
        print('  [61] fantasy_ppg: ${row[61]}');
        print('  [66] total_epa: ${row[66]}');
        print('  [86] ngs_avg_yac_above_expectation: ${row[86]}');
        
        // Test parsing numbers
        try {
          final fantasyPpg = double.tryParse(row[61].toString()) ?? 0.0;
          print('✅ fantasy_ppg parsed as: $fantasyPpg');
        } catch (e) {
          print('❌ Error parsing fantasy_ppg: $e');
        }
        
        // Count successful rows
        int successCount = 0;
        int errorCount = 0;
        
        for (int i = 1; i < csvTable.length && i < 10; i++) { // Test first 10 rows
          try {
            final testRow = csvTable[i];
            if (testRow.length >= 87) {
              // Test key field access
              final playerId = testRow[0].toString();
              final fullName = testRow[1].toString();
              final fantasyPpg = double.tryParse(testRow[61].toString()) ?? 0.0;
              
              if (playerId.isNotEmpty && fullName.isNotEmpty) {
                successCount++;
              } else {
                print('❌ Row $i has empty key fields');
                errorCount++;
              }
            } else {
              print('❌ Row $i has insufficient columns: ${testRow.length}');
              errorCount++;
            }
          } catch (e) {
            print('❌ Error testing row $i: $e');
            errorCount++;
          }
        }
        
        print('📊 Test results: $successCount successful, $errorCount errors');
      }
    }
    
  } catch (e) {
    print('❌ Error: $e');
  }
}
