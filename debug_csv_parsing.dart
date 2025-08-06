import 'package:csv/csv.dart';
import 'dart:io';

void main() async {
  print('Testing CSV parsing...');
  
  final file = File('/Users/jackgruca/Documents/GitHub/mds_home/data_processing/assets/data/adp/adp_analysis_ppr.csv');
  final csvString = await file.readAsString();
  
  // Check first few characters and line breaks
  print('First 200 characters: ${csvString.substring(0, 200)}');
  print('Contains \\n: ${csvString.contains('\n')}');
  print('Contains \\r\\n: ${csvString.contains('\r\n')}');
  print('Contains \\r: ${csvString.contains('\r')}');
  
  final rows = const CsvToListConverter().convert(csvString, eol: '\n');
  print('Total rows: ${rows.length}');
  
  if (rows.isEmpty) {
    print('No rows found');
    return;
  }
  
  final headers = rows[0].map((e) => e.toString()).toList();
  print('Headers (${headers.length}): ${headers.take(10)}...');
  
  // Test parsing first few data rows
  for (int i = 1; i < 6 && i < rows.length; i++) {
    final row = rows[i];
    print('\nRow $i data (${row.length} columns):');
    print('Player: ${row.length > 0 ? row[0] : 'N/A'}');
    print('Season: ${row.length > 2 ? row[2] : 'N/A'}');
    print('Avg Rank: ${row.length > 12 ? row[12] : 'N/A'}');
    print('Points PPR: ${row.length > 20 ? row[20] : 'N/A'}');
    
    // Create row map
    final Map<String, dynamic> rowMap = {};
    for (int j = 0; j < headers.length && j < row.length; j++) {
      rowMap[headers[j]] = row[j];
    }
    
    // Test specific fields
    print('avg_rank_num: ${rowMap['avg_rank_num']}');
    print('points_ppr: ${rowMap['points_ppr']}');
    print('season: ${rowMap['season']}');
  }
}