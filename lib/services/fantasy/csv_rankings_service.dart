import 'package:flutter/services.dart';
import 'package:csv/csv.dart';
import '../../models/fantasy/player_ranking.dart';

class CSVRankingsService {
  static const String _csvPath = 'assets/2025/FF_ranks.csv';

  num? _parseNum(dynamic value) {
    if (value == null) return null;
    final str = value.toString().trim();
    if (str == '#N/A' || str.isEmpty) return null;
    return num.tryParse(str);
  }

  Future<List<PlayerRanking>> fetchRankings() async {
    try {
      final String rawData = await rootBundle.loadString(_csvPath);
      final List<List<dynamic>> listData = const CsvToListConverter().convert(rawData);
      // Header: Name,Position,ESPN Rank,FantasyPro Rank,CBS Rank,Consensus,Consensus Rank
      return listData.skip(1).map((row) {
        return PlayerRanking(
          id: row[0].toString(),
          name: row[0].toString(),
          position: row[1].toString(),
          team: '', // No team in CSV
          rank: _parseNum(row[2])?.toInt() ?? 0, // ESPN Rank
          source: 'ESPN',
          lastUpdated: DateTime.now(),
          additionalRanks: {
            'FantasyPro': _parseNum(row[3]),
            'CBS': _parseNum(row[4]),
            'Consensus': _parseNum(row[5]),
            'Consensus Rank': _parseNum(row[6])?.toInt(),
          },
        );
      }).toList();
    } catch (e) {
      throw Exception('Error reading CSV rankings: $e');
    }
  }

  String _extractTeam(String name) {
    // This is a placeholder - you might want to add team information to your CSV
    // For now, we'll return a default value
    return 'FA';
  }
} 