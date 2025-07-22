import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../models/fantasy/player_ranking.dart';
import 'espn_rankings_service.dart';
import 'package:flutter/foundation.dart';

abstract class RankingsScraperService {
  Future<List<PlayerRanking>> fetchRankings();
}

// Mock data for testing
final List<Map<String, dynamic>> _mockPlayers = [
  {
    'id': '1',
    'name': 'Christian McCaffrey',
    'position': 'RB',
    'team': 'SF',
    'espn_rank': 1,
    'sleeper_rank': 1,
    'yahoo_rank': 1,
    'cbs_rank': 1,
  },
  {
    'id': '2',
    'name': 'Justin Jefferson',
    'position': 'WR',
    'team': 'MIN',
    'espn_rank': 2,
    'sleeper_rank': 3,
    'yahoo_rank': 2,
    'cbs_rank': 3,
  },
  {
    'id': '3',
    'name': "Ja'Marr Chase",
    'position': 'WR',
    'team': 'CIN',
    'espn_rank': 3,
    'sleeper_rank': 2,
    'yahoo_rank': 3,
    'cbs_rank': 2,
  },
  {
    'id': '4',
    'name': 'Tyreek Hill',
    'position': 'WR',
    'team': 'MIA',
    'espn_rank': 4,
    'sleeper_rank': 4,
    'yahoo_rank': 4,
    'cbs_rank': 4,
  },
  {
    'id': '5',
    'name': 'Bijan Robinson',
    'position': 'RB',
    'team': 'ATL',
    'espn_rank': 5,
    'sleeper_rank': 6,
    'yahoo_rank': 5,
    'cbs_rank': 7,
  },
  {
    'id': '6',
    'name': 'Travis Kelce',
    'position': 'TE',
    'team': 'KC',
    'espn_rank': 6,
    'sleeper_rank': 5,
    'yahoo_rank': 6,
    'cbs_rank': 5,
  },
  {
    'id': '7',
    'name': 'Saquon Barkley',
    'position': 'RB',
    'team': 'PHI',
    'espn_rank': 7,
    'sleeper_rank': 7,
    'yahoo_rank': 8,
    'cbs_rank': 6,
  },
  {
    'id': '8',
    'name': 'CeeDee Lamb',
    'position': 'WR',
    'team': 'DAL',
    'espn_rank': 8,
    'sleeper_rank': 8,
    'yahoo_rank': 7,
    'cbs_rank': 8,
  },
  {
    'id': '9',
    'name': 'Breece Hall',
    'position': 'RB',
    'team': 'NYJ',
    'espn_rank': 9,
    'sleeper_rank': 10,
    'yahoo_rank': 9,
    'cbs_rank': 10,
  },
  {
    'id': '10',
    'name': 'Amon-Ra St. Brown',
    'position': 'WR',
    'team': 'DET',
    'espn_rank': 10,
    'sleeper_rank': 9,
    'yahoo_rank': 10,
    'cbs_rank': 9,
  },
  // Add more mock players as needed
];

class ESPNScraperService extends RankingsScraperService {
  final ESPNRankingsService _espnService = ESPNRankingsService();

  @override
  Future<List<PlayerRanking>> fetchRankings() async {
    try {
      debugPrint('Attempting to fetch live ESPN rankings...');
      final rankings = await _espnService.fetchRankings();
      debugPrint('Successfully fetched ${rankings.length} live ESPN rankings');
      return rankings;
    } catch (e) {
      debugPrint('Failed to fetch live ESPN rankings: $e');
      debugPrint('Falling back to mock data...');
      // Fallback to mock data if API fails
      return _mockPlayers.map((data) => PlayerRanking(
        id: data['id'],
        name: data['name'],
        position: data['position'],
        team: data['team'],
        rank: data['espn_rank'],
        source: 'ESPN',
        lastUpdated: DateTime.now(),
      )).toList();
    }
  }
}

class SleeperScraperService extends RankingsScraperService {
  @override
  Future<List<PlayerRanking>> fetchRankings() async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));
    
    return _mockPlayers.map((data) => PlayerRanking(
      id: data['id'],
      name: data['name'],
      position: data['position'],
      team: data['team'],
      rank: data['sleeper_rank'],
      source: 'Sleeper',
      lastUpdated: DateTime.now(),
    )).toList();
  }
}

class YahooScraperService extends RankingsScraperService {
  @override
  Future<List<PlayerRanking>> fetchRankings() async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));
    
    return _mockPlayers.map((data) => PlayerRanking(
      id: data['id'],
      name: data['name'],
      position: data['position'],
      team: data['team'],
      rank: data['yahoo_rank'],
      source: 'Yahoo',
      lastUpdated: DateTime.now(),
    )).toList();
  }
}

class CBSScraperService extends RankingsScraperService {
  @override
  Future<List<PlayerRanking>> fetchRankings() async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));
    
    return _mockPlayers.map((data) => PlayerRanking(
      id: data['id'],
      name: data['name'],
      position: data['position'],
      team: data['team'],
      rank: data['cbs_rank'],
      source: 'CBS',
      lastUpdated: DateTime.now(),
    )).toList();
  }
}

// Factory to create scrapers
class RankingsScraperFactory {
  static RankingsScraperService getScraperForSource(String source) {
    switch (source.toLowerCase()) {
      case 'espn':
        return ESPNScraperService();
      case 'sleeper':
        return SleeperScraperService();
      case 'yahoo':
        return YahooScraperService();
      case 'cbs':
        return CBSScraperService();
      default:
        throw Exception('Unknown source: $source');
    }
  }
} 