import 'package:flutter/services.dart';
import 'package:csv/csv.dart';
import '../../models/fantasy/player_ranking.dart';

class CSVRankingsService {
  static const String _csvPath = 'assets/2025/FF_ranks.csv';

  num? _parseNum(dynamic value) {
    if (value == null) return null;
    final str = value.toString().trim();
    if (str == 'NA' || str == '#N/A' || str.isEmpty) return null;
    return num.tryParse(str);
  }

  num? _parseAuction(dynamic value) {
    if (value == null) return null;
    final str = value.toString().trim().replaceAll('"', '').replaceAll('\$', '');
    if (str == 'N/A' || str.isEmpty) return null;
    return num.tryParse(str);
  }

  Future<List<PlayerRanking>> fetchRankings() async {
    try {
      final String rawData = await rootBundle.loadString(_csvPath);
      final List<List<dynamic>> listData = const CsvToListConverter().convert(rawData);
      
      // Headers from FF_ranks.csv: "","Name","Team Abbreviation","Position","consensus_rank","PFF_rank","cbs_rank","espn_rank","fftoday_rank","footballguys_rank","yahoo_rank","nfl_rank","Position Rank","Bye Week","ADP","Projected Points","Auction Value"
      return listData.skip(1).map((row) {
        if (row.length < 17) return null; // Skip rows that don't have enough columns
        
        return PlayerRanking(
          id: row[1].toString(), // Name as ID
          name: row[1].toString(), // Name
          team: row[2].toString(), // Team Abbreviation
          position: row[3].toString(), // Position
          rank: _parseNum(row[4])?.toInt() ?? 0, // consensus_rank
          source: 'Consensus', 
          lastUpdated: DateTime.now(),
          additionalRanks: {
            'Consensus': _parseNum(row[4]),
            'Consensus Rank': _parseNum(row[4])?.toInt(),
            'PFF': _parseNum(row[5]), // PFF_rank
            'CBS': _parseNum(row[6]), // cbs_rank
            'ESPN': _parseNum(row[7]), // espn_rank
            'FFToday': _parseNum(row[8]), // fftoday_rank
            'FootballGuys': _parseNum(row[9]), // footballguys_rank
            'Yahoo': _parseNum(row[10]), // yahoo_rank
            'NFL': _parseNum(row[11]), // nfl_rank
            'Position Rank': _parseNum(row[12])?.toInt(), // Position Rank
            'Bye': _parseNum(row[13])?.toInt(), // Bye Week
            'ADP': _parseNum(row[14]), // ADP
            'Projected Points': _parseNum(row[15]), // Projected Points
            'Auction Value': _parseAuction(row[16]), // Auction Value
          },
        );
      }).whereType<PlayerRanking>().toList(); // Filter out null values
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