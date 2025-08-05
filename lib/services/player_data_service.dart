import 'package:csv/csv.dart';
import 'package:flutter/services.dart';
import '../models/player_info.dart';

class PlayerDataService {
  static final PlayerDataService _instance = PlayerDataService._internal();
  factory PlayerDataService() => _instance;
  PlayerDataService._internal();

  List<PlayerInfo>? _cachedPlayers;
  Map<String, List<PlayerInfo>>? _playersByTeam;
  Map<String, PlayerInfo>? _playersById;

  Future<void> loadPlayerData() async {
    if (_cachedPlayers != null) {
      print('Player data already cached: ${_cachedPlayers!.length} players');
      return;
    }

    // Try paths in order of preference
    final pathsToTry = [
      'data_processing/assets/data/current_players_combined.csv',
      'current_players_combined.csv',  // Fallback
    ];

    for (String path in pathsToTry) {
      try {
        print('🔍 Trying to load CSV from: $path');
        
        // Load CSV file from assets
        final csvString = await rootBundle.loadString(path);
        print('✅ CSV loaded successfully from $path, length: ${csvString.length} characters');
        
        // Debug: show first 200 characters
        print('🔍 First 200 chars: ${csvString.substring(0, csvString.length > 200 ? 200 : csvString.length)}');
        
        // Debug: count line breaks
        final lines = csvString.split('\n');
        print('🔍 Line breaks found: ${lines.length - 1}');
        print('🔍 First 3 lines:');
        for (int i = 0; i < 3 && i < lines.length; i++) {
          print('   Line $i: ${lines[i].length} chars - ${lines[i].substring(0, lines[i].length > 50 ? 50 : lines[i].length)}...');
        }
        
        // Parse CSV with explicit configuration
        final List<List<dynamic>> csvTable = const CsvToListConverter(
          fieldDelimiter: ',',
          textDelimiter: '"',
          eol: '\n',
        ).convert(csvString);
        print('✅ CSV parsed successfully, ${csvTable.length} rows found');
        
        if (csvTable.isNotEmpty) {
          print('📋 CSV header (first 5 columns): ${csvTable[0].take(5).toList()}');
        }
        
        // Skip header row and convert to PlayerInfo objects
        _cachedPlayers = [];
        int successCount = 0;
        int errorCount = 0;
        
        for (int i = 1; i < csvTable.length; i++) {
          try {
            final player = PlayerInfo.fromCsvRow(csvTable[i]);
            _cachedPlayers!.add(player);
            successCount++;
            
            // Log first player for verification
            if (i == 1) {
              print('📊 First player parsed: ${player.fullName} (${player.team}, ${player.position})');
            }
          } catch (e) {
            print('❌ Error parsing row $i: $e');
            if (errorCount < 3) { // Only show first 3 errors to avoid spam
              print('   Row data: ${csvTable[i].take(10).toList()}...');
            }
            errorCount++;
          }
        }

        // Create indexes for fast lookups
        _buildIndexes();
        
        print('🎉 Successfully loaded $successCount players ($errorCount errors) from $path');
        
        if (_cachedPlayers!.isNotEmpty) {
          print('👤 Sample players:');
          for (int i = 0; i < 3 && i < _cachedPlayers!.length; i++) {
            final p = _cachedPlayers![i];
            print('   ${i+1}. ${p.fullName} (${p.team}, ${p.position}) - ${p.fantasyPpg} PPG');
          }
        }
        
        // Success! Break out of the loop
        return;
        
      } catch (e) {
        print('❌ Failed to load from $path: $e');
        continue;
      }
    }
    
    // If we get here, all paths failed
    print('💥 CRITICAL: All CSV loading attempts failed!');
    print('📁 Available paths in pubspec.yaml should include our CSV files');
    _cachedPlayers = [];
  }

  void _buildIndexes() {
    if (_cachedPlayers == null) return;

    // Group by team
    _playersByTeam = {};
    _playersById = {};
    
    for (final player in _cachedPlayers!) {
      // By team
      _playersByTeam!.putIfAbsent(player.team, () => []).add(player);
      
      // By ID
      _playersById![player.playerId] = player;
    }

    // Sort players within each team by position group and fantasy points
    _playersByTeam!.forEach((team, players) {
      players.sort((a, b) {
        // First sort by position group priority
        final positionOrder = ['QB', 'RB', 'WR', 'TE'];
        final aIndex = positionOrder.indexOf(a.positionGroup);
        final bIndex = positionOrder.indexOf(b.positionGroup);
        
        if (aIndex != bIndex) {
          if (aIndex == -1) return 1;
          if (bIndex == -1) return -1;
          return aIndex.compareTo(bIndex);
        }
        
        // Then by fantasy points
        return b.fantasyPointsPpr.compareTo(a.fantasyPointsPpr);
      });
    });
  }

  List<PlayerInfo> getAllPlayers() {
    return _cachedPlayers ?? [];
  }

  List<PlayerInfo> getPlayersByTeam(String team) {
    return _playersByTeam?[team] ?? [];
  }

  PlayerInfo? getPlayerById(String playerId) {
    return _playersById?[playerId];
  }

  List<String> getAllTeams() {
    if (_playersByTeam == null) return [];
    final teams = _playersByTeam!.keys.toList();
    teams.sort();
    return teams;
  }

  List<PlayerInfo> searchPlayers(String query) {
    if (_cachedPlayers == null || query.isEmpty) return [];
    
    return _cachedPlayers!
        .where((player) => player.matchesSearch(query))
        .toList();
  }

  List<PlayerInfo> getPlayersByPosition(String position) {
    if (_cachedPlayers == null) return [];
    
    return _cachedPlayers!
        .where((player) => player.position == position || player.positionGroup == position)
        .toList()
      ..sort((a, b) => b.fantasyPointsPpr.compareTo(a.fantasyPointsPpr));
  }

  // Get top players by fantasy points
  List<PlayerInfo> getTopPlayers({int limit = 50, String? position}) {
    if (_cachedPlayers == null) return [];
    
    var players = _cachedPlayers!;
    
    if (position != null) {
      players = players
          .where((p) => p.position == position || p.positionGroup == position)
          .toList();
    }
    
    players.sort((a, b) => b.fantasyPointsPpr.compareTo(a.fantasyPointsPpr));
    
    return players.take(limit).toList();
  }
}