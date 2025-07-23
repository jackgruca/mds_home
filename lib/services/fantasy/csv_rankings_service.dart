import 'package:flutter/services.dart';
import 'package:csv/csv.dart';
import '../../models/fantasy/player_ranking.dart';

class CSVRankingsService {
  static const String _csvPath = 'assets/2026/available_players.csv';

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
      
      // Headers: "","Name","Team Abbreviation","Position","consensus_rank","PFF_rank","cbs_rank","espn_rank","fftoday_rank","footballguys_rank","yahoo_rank","nfl_rank","Position Rank","Bye Week","ADP","Projected Points","Auction Value"
      return listData.skip(1).map((row) {
        return PlayerRanking(
          id: row[1].toString(), // Name
          name: row[1].toString(),
          team: row[2].toString(),
          position: row[3].toString(),
          rank: _parseNum(row[4])?.toInt() ?? 0, // consensus_rank
          source: 'Consensus', 
          lastUpdated: DateTime.now(),
          additionalRanks: {
            'Consensus': _parseNum(row[4]),
            'Consensus Rank': _parseNum(row[4])?.toInt(),
            'PFF': _parseNum(row[5]),
            'CBS': _parseNum(row[6]),
            'ESPN': _parseNum(row[7]),
            'FFToday': _parseNum(row[8]),
            'FootballGuys': _parseNum(row[9]),
            'Yahoo': _parseNum(row[10]),
            'NFL': _parseNum(row[11]),
            'Pos. Rank': _parseNum(row[12])?.toInt(),
            'Bye': _parseNum(row[13])?.toInt(),
            'ADP': _parseNum(row[14]),
            'Auction Value': _parseAuction(row[16]),
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