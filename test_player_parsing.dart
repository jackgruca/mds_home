// Simple test to debug player data parsing
import 'dart:io';

void main() async {
  try {
    print('🔍 Testing player data parsing...');
    
    // Read the CSV file directly
    final file = File('data/processed/team_data/current_players_combined.csv');
    final lines = await file.readAsLines();
    
    print('📊 File has ${lines.length} lines');
    
    if (lines.length > 1) {
      // Parse header
      final header = lines[0].split(',');
      print('📋 Header has ${header.length} columns');
      
      // Try to parse first data row
      final firstDataRow = lines[1];
      print('🔍 First data row length: ${firstDataRow.length} characters');
      
      // Split by comma (simple split, not CSV-aware)
      final fields = firstDataRow.split(',');
      print('📊 Simple split gives ${fields.length} fields');
      
      // Show first 15 fields
      print('📋 First 15 fields:');
      for (int i = 0; i < 15 && i < fields.length; i++) {
        print('  [$i] ${fields[i]}');
      }
      
      // Check for any obvious issues
      if (fields.length < 87) {
        print('❌ Row has fewer fields than expected (${fields.length} vs 87)');
      } else {
        print('✅ Row has enough fields');
      }
      
      // Check for empty fields
      int emptyCount = 0;
      for (int i = 0; i < fields.length; i++) {
        if (fields[i].isEmpty || fields[i] == '""' || fields[i] == 'NA') {
          emptyCount++;
        }
      }
      print('📊 Empty/NA fields: $emptyCount');
    }
    
  } catch (e) {
    print('❌ Error: $e');
  }
}
