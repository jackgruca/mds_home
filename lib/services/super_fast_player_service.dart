// lib/services/super_fast_player_service.dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/nfl_player.dart';
import 'instant_player_cache.dart';
import 'nfl_player_service.dart';

class SuperFastPlayerService {
  static const String _playerCacheKey = 'super_fast_player_cache';
  static const Duration _cacheExpiration = Duration(hours: 6);
  static Map<String, NFLPlayer>? _memoryCache;
  static DateTime? _lastCacheTime;
  
  /// Initialize service with persistent cache
  static Future<void> initialize() async {
    await _loadFromDisk();
  }
  
  /// Get player with lightning speed - tries multiple sources
  static Future<NFLPlayer?> getFastPlayer(String playerName) async {
    // 1. Try instant cache first (0ms)
    final instantPlayer = InstantPlayerCache.getInstantPlayer(playerName);
    if (instantPlayer != null) {
      return instantPlayer;
    }
    
    // 2. Try memory cache (1-2ms)
    if (_memoryCache != null && _memoryCache!.containsKey(playerName)) {
      return _memoryCache![playerName];
    }
    
    // 3. Try disk cache (5-10ms)
    final cachedPlayer = await _getFromDisk(playerName);
    if (cachedPlayer != null) {
      _cacheInMemory(playerName, cachedPlayer);
      return cachedPlayer;
    }
    
    // 4. Fallback to API (slow but cache result)
    try {
      final apiPlayer = await NFLPlayerService.getPlayerByName(playerName, includeHistoricalStats: false);
      if (apiPlayer != null) {
        await _cacheToDisk(playerName, apiPlayer);
        _cacheInMemory(playerName, apiPlayer);
        return apiPlayer;
      }
    } catch (e) {
      // Silent fail for API calls
    }
    
    return null;
  }
  
  /// Preload common players in background
  static Future<void> preloadCommonPlayers() async {
    final commonNames = [
      'Josh Allen', 'Patrick Mahomes', 'Lamar Jackson', 'Joe Burrow',
      'Justin Jefferson', 'Tyreek Hill', 'Cooper Kupp', 'Davante Adams',
      'Christian McCaffrey', 'Derrick Henry', 'Travis Kelce', 'Mark Andrews',
      'Aaron Donald', 'T.J. Watt', 'Myles Garrett', 'CeeDee Lamb',
    ];
    
    for (final name in commonNames) {
      // Load in background without blocking
      getFastPlayer(name).catchError((_) => null);
    }
  }
  
  /// Cache player data to memory
  static void _cacheInMemory(String playerName, NFLPlayer player) {
    _memoryCache ??= {};
    _memoryCache![playerName] = player;
    
    // Limit memory cache size
    if (_memoryCache!.length > 100) {
      final keys = _memoryCache!.keys.toList();
      _memoryCache!.remove(keys.first);
    }
  }
  
  /// Load cache from persistent storage
  static Future<void> _loadFromDisk() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheJson = prefs.getString(_playerCacheKey);
      final cacheTime = prefs.getInt('${_playerCacheKey}_time');
      
      if (cacheJson != null && cacheTime != null) {
        final cacheDateTime = DateTime.fromMillisecondsSinceEpoch(cacheTime);
        if (DateTime.now().difference(cacheDateTime) < _cacheExpiration) {
          final cacheData = jsonDecode(cacheJson) as Map<String, dynamic>;
          _memoryCache = {};
          
          for (final entry in cacheData.entries) {
            try {
              final playerData = entry.value as Map<String, dynamic>;
              final player = NFLPlayer(
                playerName: playerData['playerName'],
                position: playerData['position'],
                team: playerData['team'],
                height: playerData['height']?.toDouble(),
                weight: playerData['weight']?.toDouble(),
                age: playerData['age']?.toInt(),
                college: playerData['college'],
                yearsExp: playerData['yearsExp']?.toInt(),
                headshotUrl: playerData['headshotUrl'],
              );
              _memoryCache![entry.key] = player;
            } catch (e) {
              // Skip corrupted entries
            }
          }
          _lastCacheTime = cacheDateTime;
        }
      }
    } catch (e) {
      // Failed to load cache, start fresh
      _memoryCache = {};
    }
  }
  
  /// Get player from disk cache
  static Future<NFLPlayer?> _getFromDisk(String playerName) async {
    if (_memoryCache == null) return null;
    return _memoryCache![playerName];
  }
  
  /// Save player to persistent cache
  static Future<void> _cacheToDisk(String playerName, NFLPlayer player) async {
    try {
      _cacheInMemory(playerName, player);
      
      // Save to disk periodically (not every time for performance)
      if (_lastCacheTime == null || 
          DateTime.now().difference(_lastCacheTime!).inMinutes > 5) {
        await _saveCacheToDisk();
      }
    } catch (e) {
      // Silent fail for cache saves
    }
  }
  
  /// Save entire cache to disk
  static Future<void> _saveCacheToDisk() async {
    if (_memoryCache == null || _memoryCache!.isEmpty) return;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheData = <String, Map<String, dynamic>>{};
      
      for (final entry in _memoryCache!.entries) {
        final player = entry.value;
        cacheData[entry.key] = {
          'playerName': player.playerName,
          'position': player.position,
          'team': player.team,
          'height': player.height,
          'weight': player.weight,
          'age': player.age,
          'college': player.college,
          'yearsExp': player.yearsExp,
          'headshotUrl': player.headshotUrl,
        };
      }
      
      await prefs.setString(_playerCacheKey, jsonEncode(cacheData));
      await prefs.setInt('${_playerCacheKey}_time', DateTime.now().millisecondsSinceEpoch);
      _lastCacheTime = DateTime.now();
    } catch (e) {
      // Silent fail
    }
  }
  
  /// Clear all caches
  static Future<void> clearCache() async {
    _memoryCache?.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_playerCacheKey);
    await prefs.remove('${_playerCacheKey}_time');
  }
}