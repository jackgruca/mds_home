import 'package:flutter/services.dart';
import 'package:csv/csv.dart';
import '../../models/draft/draft_player.dart';

class CSVDraftService {
  static const String _csvPath = 'data/processed/draft_sim/2026/available_players.csv';

  num? _parseNum(dynamic value) {
    if (value == null) return null;
    final str = value.toString().trim();
    if (str == 'NA' || str == '#N/A' || str.isEmpty) return null;
    return num.tryParse(str);
  }

  Future<List<DraftPlayer>> fetchDraftPlayers() async {
    try {
      print('CSVDraftService: Starting to load CSV from $_csvPath');
      final String rawData = await rootBundle.loadString(_csvPath);
      print('CSVDraftService: Raw data loaded, length: ${rawData.length}');
      
      // Parse CSV with custom settings to handle multiline values
      final List<List<dynamic>> listData = const CsvToListConverter(
        fieldDelimiter: ',',
        textDelimiter: '"',
        eol: '\n',
        allowInvalid: true,
      ).convert(rawData);
      print('CSVDraftService: CSV converted to list, rows: ${listData.length}');
      
      // If we still get only one row, try parsing manually by splitting on actual row breaks
      List<List<dynamic>> parsedData = listData;
      if (listData.length == 1 && listData.first.length > 50) {
        print('CSVDraftService: Detected single-row issue, attempting manual parsing');
        parsedData = _parseCSVManually(rawData);
        print('CSVDraftService: Manual parsing resulted in ${parsedData.length} rows');
      }
      
      if (parsedData.isEmpty) {
        print('CSVDraftService: No data found in CSV');
        return [];
      }
      
      // Log the header row for debugging
      if (parsedData.isNotEmpty) {
        print('CSVDraftService: Header row: ${parsedData.first}');
      }
      
      // Headers: "","Name","Position","School","mddRank","tankRank","buzz_rank","Rank_average","Rank_combined"
      final players = <DraftPlayer>[];
      
      for (int i = 1; i < parsedData.length; i++) {
        final row = parsedData[i];
        
        if (row.length < 9) {
          print('CSVDraftService: Skipping row $i - insufficient columns (${row.length}): $row');
          continue;
        }
        
        try {
          final player = DraftPlayer(
            name: row[1].toString().trim(), // Name
            position: row[2].toString().trim(), // Position
            school: row[3].toString().trim(), // School
            rank: _parseNum(row[8])?.toInt() ?? i, // Rank_combined (overall rank) - use row index as fallback
            source: 'Consensus', 
            lastUpdated: DateTime.now(),
            additionalRanks: {
              'Consensus': _parseNum(row[8]), // Rank_combined
              'MDD Rank': _parseNum(row[4]), // mddRank
              'Tank Rank': _parseNum(row[5]), // tankRank  
              'Buzz Rank': _parseNum(row[6]), // buzz_rank
              'Average Rank': _parseNum(row[7]), // Rank_average
            },
          );
          players.add(player);
        } catch (e) {
          print('CSVDraftService: Error parsing row $i: $e');
          print('CSVDraftService: Row data: $row');
        }
      }
      
      print('CSVDraftService: Successfully parsed ${players.length} players');
      return players;
    } catch (e) {
      print('CSVDraftService: Exception occurred: $e');
      throw Exception('Error reading CSV draft data: $e');
    }
  }

  List<List<dynamic>> _parseCSVManually(String csvData) {
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
      print('CSVDraftService: Manual parsing failed: $e');
      return [];
    }
  }
}