import 'package:flutter/services.dart';
import 'package:csv/csv.dart';

class CSVRankingsService {
  // Helper method to parse numeric values
  num? _parseNum(dynamic value) {
    if (value == null) return null;
    final str = value.toString().trim();
    if (str == 'NA' || str == '#N/A' || str.isEmpty || str == 'null') return null;
    return num.tryParse(str);
  }

  // Helper method to parse string values
  String _parseString(dynamic value) {
    if (value == null) return '';
    final str = value.toString().trim();
    if (str == 'NA' || str == '#N/A' || str == 'null') return '';
    return str;
  }

  // Generic method to fetch rankings for any position
  Future<List<Map<String, dynamic>>> fetchRankings(String position) async {
    try {
      final String csvPath = 'assets/rankings/${position.toLowerCase()}_rankings.csv';
      final String rawData = await rootBundle.loadString(csvPath);
      
      final List<List<dynamic>> listData = const CsvToListConverter(
        fieldDelimiter: ',',
        textDelimiter: '"',
        eol: '\n',
        shouldParseNumbers: false,
      ).convert(rawData);
      
      if (listData.isEmpty) {
        throw Exception('No data found in $csvPath');
      }

      // Get headers from first row
      final List<String> headers = listData.first.map((e) => e.toString()).toList();
      
      // Convert each data row to a map
      final rankings = listData.skip(1).map((row) {
        final Map<String, dynamic> rankingData = {};
        
        for (int i = 0; i < headers.length && i < row.length; i++) {
          final header = headers[i];
          final value = row[i];
          
          // Parse common fields consistently
          switch (header) {
            case 'fantasy_player_id':
            case 'passer_player_id': // QB specific
            case 'receiver_player_id': // WR/TE specific
              rankingData['fantasy_player_id'] = _parseString(value);
              break;
            case 'fantasy_player_name':
            case 'passer_player_name': // QB specific
            case 'receiver_player_name': // WR/TE specific
              rankingData['fantasy_player_name'] = _parseString(value);
              break;
            case 'team':
            case 'posteam':
            case 'player_position':
              rankingData[header] = _parseString(value);
              break;
            case 'season':
            case 'numGames':
            case 'myRankNum':
              rankingData[header] = _parseNum(value)?.toInt();
              break;
            case 'tier':
            case 'rbTier': // For RB rankings
            case 'qbTier': // For QB rankings  
            case 'wrTier': // For WR rankings
            case 'teTier': // For TE rankings
              rankingData['tier'] = _parseNum(value)?.toInt(); // Normalize to 'tier'
              break;
            case 'myRank':
            case 'totalEPA':
            case 'totalTD':
            case 'run_share':
            case 'tgt_share':
            case 'YPG':
            case 'cYPG':
            case 'conversion':
            case 'explosive_rate':
            case 'third_down_rate':
            case 'avg_eff':
            case 'avg_RYOE_perAtt':
            case 'cTDperGame':
            case 'intPerGame':
            case 'cthirdConvert':
              rankingData[header] = _parseNum(value);
              break;
            default:
              // For rank fields and other numeric fields, try to parse as number
              if (header.contains('rank') || header.contains('Rank') || 
                  header.contains('_num') || _isNumericField(header)) {
                final numValue = _parseNum(value);
                rankingData[header] = numValue;
              } else {
                rankingData[header] = _parseString(value);
              }
              break;
          }
        }
        
        return rankingData;
      }).where((ranking) => ranking.isNotEmpty).toList();
      
      return rankings;
      
    } catch (e) {
      throw Exception('Error loading $position rankings: $e');
    }
  }

  // Helper to identify numeric fields
  bool _isNumericField(String fieldName) {
    final numericPatterns = [
      'EPA', 'TD', 'YPG', 'share', 'rate', 'eff', 'RYOE', 
      'CPOE', 'actualization', 'third', 'conversion', 'explosive',
      'Games', 'yacOE', 'numRec'
    ];
    
    return numericPatterns.any((pattern) => 
      fieldName.toLowerCase().contains(pattern.toLowerCase()));
  }

  // Specific methods for each position
  Future<List<Map<String, dynamic>>> fetchQBRankings() async {
    return fetchRankings('qb');
  }

  Future<List<Map<String, dynamic>>> fetchRBRankings() async {
    return fetchRankings('rb');
  }

  Future<List<Map<String, dynamic>>> fetchWRRankings() async {
    return fetchRankings('wr');
  }

  Future<List<Map<String, dynamic>>> fetchTERankings() async {
    return fetchRankings('te');
  }

  Future<List<Map<String, dynamic>>> fetchPassOffenseRankings() async {
    return fetchRankings('pass_offense');
  }

  Future<List<Map<String, dynamic>>> fetchRunOffenseRankings() async {
    return fetchRankings('run_offense');
  }

  // Get available seasons from rankings data
  Future<List<int>> getAvailableSeasons(String position) async {
    try {
      final rankings = await fetchRankings(position);
      final seasons = rankings
          .map((r) => r['season'] as int?)
          .where((s) => s != null)
          .cast<int>()
          .toSet()
          .toList();
      seasons.sort((a, b) => b.compareTo(a)); // Latest first
      return seasons;
    } catch (e) {
      return [2024, 2023, 2022, 2021, 2020]; // Default fallback
    }
  }

  // Get available tiers from rankings data
  Future<List<int>> getAvailableTiers(String position) async {
    try {
      final rankings = await fetchRankings(position);
      final tiers = rankings
          .map((r) => (r['tier'] ?? r['rbTier']) as int?)
          .where((t) => t != null)
          .cast<int>()
          .toSet()
          .toList();
      tiers.sort();
      return tiers;
    } catch (e) {
      return [1, 2, 3, 4, 5]; // Default fallback
    }
  }
}