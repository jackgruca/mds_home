import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../models/fantasy/player_ranking.dart';
import 'package:flutter/foundation.dart';

class ESPNRankingsService {
  static const String _baseUrl = 'https://fantasy.espn.com/apis/v3/games/ffl';
  static const int _seasonId = 2024; // Update this each year

  Future<List<PlayerRanking>> fetchRankings() async {
    try {
      debugPrint('Fetching ESPN rankings...');
      const url = '$_baseUrl/seasons/$_seasonId/players?scoringPeriodId=0&view=kona_player_info';
      debugPrint('URL: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Accept': 'application/json',
          'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36',
          'x-fantasy-filter': json.encode({
            "players": {
              "limit": 300,
              "sortBy": {"value": "STANDARD_DRAFT_RANK", "sortAsc": true},
              "filterStatsForTopScoringPeriodIds": {"value": 1, "additionalValue": ["002024", "102024", "002023", "022024"]}
            }
          })
        },
      );

      debugPrint('Response status code: ${response.statusCode}');
      if (response.statusCode != 200) {
        debugPrint('Response body: ${response.body}');
        throw Exception('Failed to fetch ESPN rankings: ${response.statusCode}');
      }

      final dynamic jsonResponse = jsonDecode(response.body);
      debugPrint('Successfully decoded JSON response');
      
      if (jsonResponse is! List) {
        debugPrint('Unexpected response format. Expected List but got: ${jsonResponse.runtimeType}');
        debugPrint('Response preview: ${jsonResponse.toString().substring(0, min(200, jsonResponse.toString().length))}');
        throw Exception('Unexpected response format from ESPN API');
      }

      final List<dynamic> players = jsonResponse;
      debugPrint('Found ${players.length} players in response');

      final rankings = players.where((player) {
        final bool isValid = player['player'] != null && 
          player['player']['fullName'] != null &&
          player['player']['proTeam'] != null &&
          player['rankings'] != null &&
          player['rankings']['standard'] != null;
        
        if (!isValid && player['player'] != null) {
          debugPrint('Filtered out player: ${player['player']['fullName']} - missing required data');
        }
        return isValid;
      }).map((player) {
        final playerData = player['player'];
        final rankings = player['rankings']['standard'];
        
        String position = _convertPosition(playerData['defaultPositionId']);
        
        return PlayerRanking(
          id: playerData['id'].toString(),
          name: playerData['fullName'],
          position: position,
          team: _getTeamAbbreviation(playerData['proTeam']),
          rank: rankings['rank'],
          source: 'ESPN',
          lastUpdated: DateTime.now(),
        );
      }).toList();

      debugPrint('Successfully processed ${rankings.length} player rankings');
      return rankings;
    } catch (e, stackTrace) {
      debugPrint('Error fetching ESPN rankings: $e');
      debugPrint('Stack trace: $stackTrace');
      throw Exception('Error fetching ESPN rankings: $e');
    }
  }

  int min(int a, int b) => a < b ? a : b;

  String _convertPosition(int positionId) {
    switch (positionId) {
      case 1: return 'QB';
      case 2: return 'RB';
      case 3: return 'WR';
      case 4: return 'TE';
      case 5: return 'K';
      case 16: return 'DST';
      default: return 'FLEX';
    }
  }

  String _getTeamAbbreviation(int teamId) {
    const teams = {
      1: 'ATL', 2: 'BUF', 3: 'CHI', 4: 'CIN', 5: 'CLE', 6: 'DAL', 7: 'DEN', 
      8: 'DET', 9: 'GB', 10: 'TEN', 11: 'IND', 12: 'KC', 13: 'LV', 14: 'LAR', 
      15: 'MIA', 16: 'MIN', 17: 'NE', 18: 'NO', 19: 'NYG', 20: 'NYJ', 21: 'PHI',
      22: 'ARI', 23: 'PIT', 24: 'LAC', 25: 'SF', 26: 'SEA', 27: 'TB', 28: 'WSH',
      29: 'CAR', 30: 'JAX', 33: 'BAL', 34: 'HOU'
    };
    return teams[teamId] ?? 'FA';
  }
} 