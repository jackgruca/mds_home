// lib/services/nfl_player_service.dart
import 'package:cloud_functions/cloud_functions.dart';
import '../models/nfl_player.dart';
import 'player_headshot_service.dart';
import 'instant_player_cache.dart';

class NFLPlayerService {
  static final FirebaseFunctions _functions = FirebaseFunctions.instance;

  // Cache for player data to avoid repeated API calls
  static final Map<String, NFLPlayer> _playerCache = {};
  static final Map<String, DateTime> _cacheTimestamps = {};
  static const Duration _cacheExpiration = Duration(minutes: 15);

  /// Get player data by name - used for creating modals from player names in tables
  static Future<NFLPlayer?> getPlayerByName(String playerName, {bool includeHistoricalStats = true}) async {
    print('🔍 NFLPlayerService.getPlayerByName called for: "$playerName"');
    
    try {
      // Check cache first
      final cachedPlayer = _getCachedPlayer(playerName);
      if (cachedPlayer != null) {
        print('✅ Found cached player data for: $playerName');
        return cachedPlayer;
      }

      print('📡 Searching for player: $playerName');
      
      // Use getPlayerStats function which has proper player search functionality
      final HttpsCallable playerStatsCallable = _functions.httpsCallable('getPlayerStats');
      final playerParams = {
        'searchQuery': playerName.trim(),
        'limit': 1,
      };
      
      print('📤 Calling getPlayerStats with params: $playerParams');
      final playerResult = await playerStatsCallable.call(playerParams);
      
      print('📥 getPlayerStats response: ${playerResult.data}');
      print('📥 Response type: ${playerResult.data.runtimeType}');
      
      if (playerResult.data != null) {
        print('📊 Player result keys: ${playerResult.data.keys}');
        
        if (playerResult.data['data'] != null) {
          final List<dynamic> playerData = playerResult.data['data'];
          print('📋 Player data length: ${playerData.length}');
          
          if (playerData.isNotEmpty) {
            final foundPlayer = playerData.first as Map<String, dynamic>;
            print('👤 Found player data keys: ${foundPlayer.keys.toList()}');
            
            // Extract player info with proper field mapping
            final playerDisplayName = foundPlayer['player_display_name'] ?? playerName;
            final position = foundPlayer['position'];
            final recentTeam = foundPlayer['recent_team'];
            
            print('👤 Player display name: $playerDisplayName');
            print('👤 Player position: $position');
            print('👤 Player recent team: $recentTeam');
            
            // Get current season stats (use the data we already have)
            Map<String, dynamic>? currentStats = foundPlayer;
            print('📊 Using current player stats data');
            
            // Get historical stats for other seasons (optional for performance)
            Map<int, Map<String, dynamic>>? historicalStats;
            if (includeHistoricalStats) {
              try {
                print('📈 Fetching historical stats for: $playerDisplayName');
                final HttpsCallable histCallable = _functions.httpsCallable('getPlayerSeasonStats');
                final histParams = {
                  'filters': {
                    'player_display_name': playerDisplayName,
                  },
                  'limit': 20, // Get multiple seasons
                  'orderBy': 'season',
                  'orderDirection': 'desc',
                };
                print('📤 Calling getPlayerSeasonStats with params: $histParams');
                final histResult = await histCallable.call(histParams);
                print('📥 Historical stats response length: ${histResult.data?['data']?.length ?? 0}');
                
                if (histResult.data != null && histResult.data['data'] != null) {
                  final List<dynamic> histData = histResult.data['data'];
                  historicalStats = <int, Map<String, dynamic>>{};
                  for (final seasonData in histData) {
                    final season = seasonData['season'] as int?;
                    if (season != null) {
                      historicalStats[season] = Map<String, dynamic>.from(seasonData);
                    }
                  }
                  print('📈 Historical stats seasons found: ${historicalStats.keys.toList()}');
                }
              } catch (histError) {
                print('❌ Error fetching historical stats: $histError');
              }
            } else {
              print('⚡ Skipping historical stats for faster loading');
            }

            // Get headshot URL (async, don't block modal loading)
            String? headshotUrl;
            if (includeHistoricalStats) {
              // Only fetch headshot for full profile page, not for quick modal
              print('🖼️ Fetching headshot for: $playerDisplayName');
              headshotUrl = await PlayerHeadshotService.getPlayerHeadshot(
                playerDisplayName,
                position: position,
                team: recentTeam,
              );
              print('🖼️ Headshot URL: $headshotUrl');
            } else {
              print('⚡ Skipping headshot fetch for faster modal loading');
            }

            // Try to get cached basic data for missing fields
            final cachedPlayer = InstantPlayerCache.getInstantPlayer(playerDisplayName);
            
            // Create player object from available data, filling gaps from cache
            final player = NFLPlayer(
              gsisId: foundPlayer['gsis_id'],
              playerId: foundPlayer['player_id'],
              esbId: foundPlayer['esb_id'],
              pfrId: foundPlayer['pfr_id'],
              playerName: playerDisplayName,
              position: position,
              team: recentTeam,
              jerseyNumber: foundPlayer['jersey_number']?.toInt(),
              status: foundPlayer['status'],
              height: foundPlayer['height']?.toDouble() ?? cachedPlayer?.height,
              weight: foundPlayer['weight']?.toDouble() ?? cachedPlayer?.weight,
              birthDate: foundPlayer['birth_date'],
              age: foundPlayer['age']?.toInt() ?? cachedPlayer?.age,
              college: foundPlayer['college'] ?? cachedPlayer?.college,
              highSchool: foundPlayer['high_school'],
              entryYear: foundPlayer['entry_year']?.toInt(),
              rookieYear: foundPlayer['rookie_year']?.toInt(),
              draftClub: foundPlayer['draft_club'],
              draftNumber: foundPlayer['draft_number']?.toInt(),
              draftRound: foundPlayer['draft_round']?.toInt(),
              yearsExp: foundPlayer['years_exp']?.toInt() ?? cachedPlayer?.yearsExp,
              currentSeasonStats: currentStats,
              historicalStats: historicalStats,
              headshotUrl: headshotUrl ?? InstantPlayerCache.getInstantHeadshot(playerDisplayName),
            );
            
            print('✅ Successfully created NFLPlayer object for: ${player.playerName}');
            _cachePlayer(playerName, player);
            return player;
          } else {
            print('❌ No player data found for: $playerName');
          }
        } else {
          print('❌ No data field in player response');
        }
      } else {
        print('❌ Null response from getPlayerStats');
      }
    } catch (e) {
      print('❌ Error fetching player data for $playerName: $e');
      print('❌ Error type: ${e.runtimeType}');
      print('❌ Error details: $e');
    }
    
    // Fallback: return minimal player object with just the name
    print('⚠️ Returning fallback player object for: $playerName');
    return NFLPlayer(
      playerName: playerName,
      position: null,
      team: null,
    );
  }

  /// Get player data by ID - for direct player lookups
  static Future<NFLPlayer?> getPlayerById(String playerId) async {
    print('🔍 NFLPlayerService.getPlayerById called for: "$playerId"');
    
    try {
      // Check cache first
      final cachedPlayer = _getCachedPlayer(playerId);
      if (cachedPlayer != null) {
        print('✅ Found cached player data for ID: $playerId');
        return cachedPlayer;
      }

      // Try to find player by ID using direct filter
      final HttpsCallable playerStatsCallable = _functions.httpsCallable('getPlayerStats');
      final playerParams = {
        'filters': {
          'player_id': playerId.trim(),
        },
        'limit': 1,
      };
      
      print('📤 Calling getPlayerStats for ID search with params: $playerParams');
      final playerResult = await playerStatsCallable.call(playerParams);
      
      if (playerResult.data != null && playerResult.data['data'] != null) {
        final List<dynamic> playerData = playerResult.data['data'];
        
        if (playerData.isNotEmpty) {
          final data = playerData.first;
          final playerName = data['player_display_name'] as String?;
          if (playerName != null) {
            print('✅ Found player name for ID $playerId: $playerName');
            return await getPlayerByName(playerName);
          }
        }
      }
    } catch (e) {
      print('❌ Error in getPlayerById for $playerId: $e');
      // Fallback: try to get by name if the playerId looks like a name
      if (playerId.contains(' ') || playerId.contains('%20')) {
        // Decode URL-encoded names
        final decodedName = Uri.decodeComponent(playerId);
        print('⚠️ Treating ID as name: $decodedName');
        return getPlayerByName(decodedName);
      }
    }
    
    print('❌ No player found for ID: $playerId');
    return null;
  }

  /// Search for players by name (for autocomplete, etc.)
  static Future<List<NFLPlayer>> searchPlayers(String query) async {
    print('🔍 NFLPlayerService.searchPlayers called for: "$query"');
    
    try {
      // Use getPlayerStats function for search
      final HttpsCallable callable = _functions.httpsCallable('getPlayerStats');
      final result = await callable.call({
        'searchQuery': query.trim(),
        'limit': 10,
      });

      if (result.data != null && result.data['data'] != null) {
        final List<dynamic> playerData = result.data['data'];
        final players = <NFLPlayer>[];
        
        for (final data in playerData) {
          final player = NFLPlayer(
            gsisId: data['gsis_id'],
            playerId: data['player_id'],
            esbId: data['esb_id'],
            pfrId: data['pfr_id'],
            playerName: data['player_display_name'],
            position: data['position'],
            team: data['recent_team'],
            jerseyNumber: data['jersey_number']?.toInt(),
            status: data['status'],
            height: data['height']?.toDouble(),
            weight: data['weight']?.toDouble(),
            birthDate: data['birth_date'],
            age: data['age']?.toInt(),
            college: data['college'],
            highSchool: data['high_school'],
            entryYear: data['entry_year']?.toInt(),
            rookieYear: data['rookie_year']?.toInt(),
            draftClub: data['draft_club'],
            draftNumber: data['draft_number']?.toInt(),
            draftRound: data['draft_round']?.toInt(),
            yearsExp: data['years_exp']?.toInt(),
            currentSeasonStats: Map<String, dynamic>.from(data),
          );
          players.add(player);
        }
        
        print('✅ Found ${players.length} players for query: $query');
        return players;
      }
    } catch (e) {
      print('❌ Error searching players for query $query: $e');
    }
    
    return [];
  }

  /// Resolve player ID from various possible identifiers (name, gsis_id, etc.)
  static Future<String?> resolvePlayerId(dynamic identifier) async {
    if (identifier == null) return null;
    
    // If it's already a proper ID format, return it
    if (identifier is String && identifier.length > 10) {
      return identifier;
    }
    
    // Try to find the player and return their gsis_id
    try {
      final player = await getPlayerByName(identifier.toString());
      return player?.gsisId;
    } catch (e) {
      print('❌ Error resolving player ID for $identifier: $e');
      return null;
    }
  }

  /// Check cache for player data
  static NFLPlayer? _getCachedPlayer(String key) {
    final timestamp = _cacheTimestamps[key];
    if (timestamp != null && 
        DateTime.now().difference(timestamp) < _cacheExpiration &&
        _playerCache.containsKey(key)) {
      return _playerCache[key];
    }
    
    // Remove expired cache entry
    _playerCache.remove(key);
    _cacheTimestamps.remove(key);
    return null;
  }

  /// Cache player data with timestamp
  static void _cachePlayer(String key, NFLPlayer player) {
    _playerCache[key] = player;
    _cacheTimestamps[key] = DateTime.now();
    
    // Clean up old cache entries (keep max 100 entries)
    if (_playerCache.length > 100) {
      final oldestKey = _cacheTimestamps.entries
          .reduce((a, b) => a.value.isBefore(b.value) ? a : b)
          .key;
      _playerCache.remove(oldestKey);
      _cacheTimestamps.remove(oldestKey);
    }
  }

  /// Clear the cache (useful for testing or memory management)
  static void clearCache() {
    _playerCache.clear();
    _cacheTimestamps.clear();
  }

  /// Extract player name from data row - handles various field name formats
  static String? extractPlayerName(Map<String, dynamic> row) {
    // Try common field names for player names
    final possibleFields = [
      'player_display_name',
      'player_name',
      'playerName', 
      'name',
      'passer_player_name',
      'rusher_player_name', 
      'receiver_player_name',
      'fantasy_player_name',
      'player',
    ];
    
    for (final field in possibleFields) {
      final value = row[field];
      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString().trim();
      }
    }
    
    return null;
  }

  /// Check if a data row contains player data that would warrant a modal
  static bool hasPlayerData(Map<String, dynamic> row) {
    final playerName = extractPlayerName(row);
    return playerName != null && 
           playerName.isNotEmpty && 
           playerName.toLowerCase() != 'null' &&
           playerName.toLowerCase() != 'unknown';
  }
}