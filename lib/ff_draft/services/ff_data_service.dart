import 'package:flutter/services.dart';
import 'package:csv/csv.dart';
import '../models/ff_player.dart';

class FFDataService {
  static Future<List<FFPlayer>> loadPlayers() async {
    try {
      // Load the CSV file
      final rawData = await rootBundle.loadString('assets/2025/FF_ranks.csv');
      final List<List<dynamic>> listData = const CsvToListConverter().convert(rawData);
      
      // Skip header row and convert to players
      final players = listData.skip(1).map((row) {
        return FFPlayer(
          id: row[0].toString(),
          name: row[1].toString(),
          position: row[2].toString(),
          team: row[3].toString(),
          byeWeek: row[4].toString(),
          stats: {
            'rank': int.tryParse(row[5].toString()) ?? 0,
            'adp': double.tryParse(row[6].toString()) ?? 0.0,
            'projectedPoints': double.tryParse(row[7].toString()) ?? 0.0,
          },
        );
      }).toList();
      
      return players;
    } catch (e) {
      print('Error loading player data: $e');
      // Return sample data if file loading fails
      return _getSamplePlayers();
    }
  }

  static List<FFPlayer> _getSamplePlayers() {
    return [
      FFPlayer(
        id: '1',
        name: 'Christian McCaffrey',
        position: 'RB',
        team: 'SF',
        byeWeek: '9',
        stats: {
          'rank': 1,
          'adp': 1.0,
          'projectedPoints': 350.5,
        },
      ),
      FFPlayer(
        id: '2',
        name: 'Justin Jefferson',
        position: 'WR',
        team: 'MIN',
        byeWeek: '13',
        stats: {
          'rank': 2,
          'adp': 2.0,
          'projectedPoints': 320.0,
        },
      ),
      FFPlayer(
        id: '3',
        name: 'Ja\'Marr Chase',
        position: 'WR',
        team: 'CIN',
        byeWeek: '7',
        stats: {
          'rank': 3,
          'adp': 3.0,
          'projectedPoints': 315.0,
        },
      ),
      FFPlayer(
        id: '4',
        name: 'Bijan Robinson',
        position: 'RB',
        team: 'ATL',
        byeWeek: '12',
        stats: {
          'rank': 4,
          'adp': 4.0,
          'projectedPoints': 310.0,
        },
      ),
      FFPlayer(
        id: '5',
        name: 'Tyreek Hill',
        position: 'WR',
        team: 'MIA',
        byeWeek: '11',
        stats: {
          'rank': 5,
          'adp': 5.0,
          'projectedPoints': 305.0,
        },
      ),
      FFPlayer(
        id: '6',
        name: 'Travis Kelce',
        position: 'TE',
        team: 'KC',
        byeWeek: '10',
        stats: {
          'rank': 6,
          'adp': 6.0,
          'projectedPoints': 300.0,
        },
      ),
      FFPlayer(
        id: '7',
        name: 'CeeDee Lamb',
        position: 'WR',
        team: 'DAL',
        byeWeek: '7',
        stats: {
          'rank': 7,
          'adp': 7.0,
          'projectedPoints': 295.0,
        },
      ),
      FFPlayer(
        id: '8',
        name: 'Breece Hall',
        position: 'RB',
        team: 'NYJ',
        byeWeek: '12',
        stats: {
          'rank': 8,
          'adp': 8.0,
          'projectedPoints': 290.0,
        },
      ),
      FFPlayer(
        id: '9',
        name: 'Amon-Ra St. Brown',
        position: 'WR',
        team: 'DET',
        byeWeek: '9',
        stats: {
          'rank': 9,
          'adp': 9.0,
          'projectedPoints': 285.0,
        },
      ),
      FFPlayer(
        id: '10',
        name: 'Jonathan Taylor',
        position: 'RB',
        team: 'IND',
        byeWeek: '14',
        stats: {
          'rank': 10,
          'adp': 10.0,
          'projectedPoints': 280.0,
        },
      ),
    ];
  }
} 