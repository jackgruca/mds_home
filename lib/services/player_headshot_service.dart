import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class PlayerHeadshotService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'playerHeadshots';
  
  // In-memory cache for headshot URLs
  static final Map<String, String> _headshotCache = {};
  static final Map<String, String?> _negativeCache = {}; // Cache misses to avoid repeated queries
  
  // Track ongoing requests to prevent duplicates
  static final Map<String, Future<String?>> _ongoingRequests = {};
  
  // Queue for managing concurrent requests
  static const int _maxConcurrentRequests = 10;
  static int _activeRequests = 0;
  
  // Cache statistics for debugging
  static int _cacheHits = 0;
  static int _cacheMisses = 0;
  static int _firebaseQueries = 0;

  /// Get player headshot URL by player name and optional position
  /// Returns null if no headshot is found
  static Future<String?> getPlayerHeadshot(
    String playerName, {
    String? position,
    String? team,
  }) async {
    if (playerName.trim().isEmpty) return null;
    
    final normalizedName = _normalizePlayerName(playerName);
    final cacheKey = _generateCacheKey(normalizedName, position, team);
    
    // Check positive cache first
    if (_headshotCache.containsKey(cacheKey)) {
      _cacheHits++;
      return _headshotCache[cacheKey];
    }
    
    // Check negative cache to avoid repeated failed queries
    if (_negativeCache.containsKey(cacheKey)) {
      _cacheHits++;
      return null;
    }
    
    // Check if request is already in progress
    if (_ongoingRequests.containsKey(cacheKey)) {
      debugPrint('⏳ Waiting for existing request: $playerName');
      return _ongoingRequests[cacheKey];
    }
    
    // Create a new request and track it
    final requestFuture = _executeRequest(playerName, normalizedName, cacheKey, position, team);
    _ongoingRequests[cacheKey] = requestFuture;
    
    try {
      final result = await requestFuture;
      return result;
    } finally {
      // Clean up ongoing request tracking
      _ongoingRequests.remove(cacheKey);
    }
  }
  
  /// Execute the actual request with queue management
  static Future<String?> _executeRequest(
    String playerName,
    String normalizedName,
    String cacheKey,
    String? position,
    String? team,
  ) async {
    // Wait if too many concurrent requests
    while (_activeRequests >= _maxConcurrentRequests) {
      await Future.delayed(const Duration(milliseconds: 50));
    }
    
    _activeRequests++;
    _cacheMisses++;
    
    debugPrint('🔍 Fetching headshot for $playerName from Firestore');
    
    try {
      final headshotUrl = await _queryHeadshotFromFirestore(
        normalizedName, 
        position: position, 
        team: team,
      ).timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          debugPrint('⏰ Timeout fetching headshot for $playerName');
          return null;
        },
      );
      
      if (headshotUrl != null) {
        _headshotCache[cacheKey] = headshotUrl;
        // Remove from negative cache if it was there
        _negativeCache.remove(cacheKey);
        debugPrint('✅ Found headshot for $playerName: ${headshotUrl.substring(0, 50)}...');
      } else {
        // Only add to negative cache after all strategies fail
        _negativeCache[cacheKey] = null;
        debugPrint('❌ No headshot found for $playerName');
      }
      
      return headshotUrl;
      
    } catch (e) {
      debugPrint('💥 Error fetching headshot for $playerName: $e');
      // Don't cache errors - allow retry
      return null;
    } finally {
      _activeRequests--;
    }
  }

  /// Query headshot from Firestore with multiple fallback strategies
  static Future<String?> _queryHeadshotFromFirestore(
    String normalizedName, {
    String? position,
    String? team,
  }) async {
    _firebaseQueries++;
    
    // Strategy 1: Exact lookup_name match (most precise)
    String? result = await _queryByLookupName(normalizedName);
    if (result != null) return result;
    
    // Strategy 2: Exact lookup_name with position filter
    if (position != null) {
      result = await _queryByLookupNameAndPosition(normalizedName, position);
      if (result != null) return result;
    }
    
    // Strategy 3: Fuzzy name search using contains
    result = await _queryByFuzzyName(normalizedName);
    if (result != null) return result;
    
    // Strategy 4: Search by first and last name components
    result = await _queryByNameComponents(normalizedName);
    if (result != null) return result;
    
    return null;
  }

  /// Query by exact lookup_name match
  static Future<String?> _queryByLookupName(String normalizedName) async {
    try {
      debugPrint('📍 Querying Firebase for lookup_name_no_punct: "$normalizedName"');
      
      // First try with lookup_name_no_punct which is more normalized
      var querySnapshot = await _firestore
          .collection(_collection)
          .where('lookup_name_no_punct', isEqualTo: normalizedName)
          .limit(1)
          .get();
      
      // If not found, try with regular lookup_name (preserves some punctuation)
      if (querySnapshot.docs.isEmpty) {
        debugPrint('🔄 Trying with lookup_name field...');
        querySnapshot = await _firestore
            .collection(_collection)
            .where('lookup_name', isEqualTo: normalizedName)
            .limit(1)
            .get();
      }
      
      debugPrint('📊 Query result: ${querySnapshot.docs.length} documents found');
      
      if (querySnapshot.docs.isNotEmpty) {
        final data = querySnapshot.docs.first.data();
        debugPrint('✅ Found player: ${data['full_name']} (${data['player_id']})');
        return data['headshot_url'] as String?;
      }
    } catch (e) {
      debugPrint('❌ Error in lookup_name query: $e');
    }
    return null;
  }

  /// Query by lookup_name and position
  static Future<String?> _queryByLookupNameAndPosition(String normalizedName, String position) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('lookup_name', isEqualTo: normalizedName)
          .where('position', isEqualTo: position.toUpperCase())
          .limit(1)
          .get();
      
      if (querySnapshot.docs.isNotEmpty) {
        return querySnapshot.docs.first.data()['headshot_url'] as String?;
      }
    } catch (e) {
      debugPrint('Error in lookup_name + position query: $e');
    }
    return null;
  }

  /// Query using fuzzy name matching
  static Future<String?> _queryByFuzzyName(String normalizedName) async {
    try {
      // Use prefix matching for more flexible search
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('lookup_name', isGreaterThanOrEqualTo: normalizedName)
          .where('lookup_name', isLessThan: normalizedName + '\uf8ff')
          .limit(5)
          .get();
      
      // Find the best match
      for (final doc in querySnapshot.docs) {
        final data = doc.data();
        final dbName = data['lookup_name'] as String?;
        if (dbName != null && _isNameMatch(normalizedName, dbName)) {
          return data['headshot_url'] as String?;
        }
      }
    } catch (e) {
      debugPrint('Error in fuzzy name query: $e');
    }
    return null;
  }

  /// Query by name components (first + last name)
  static Future<String?> _queryByNameComponents(String normalizedName) async {
    try {
      final nameParts = normalizedName.split(' ');
      if (nameParts.length < 2) return null;
      
      final firstName = nameParts.first;
      final lastName = nameParts.last;
      
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('first_name', isEqualTo: _capitalizeFirst(firstName))
          .where('last_name', isEqualTo: _capitalizeFirst(lastName))
          .limit(1)
          .get();
      
      if (querySnapshot.docs.isNotEmpty) {
        return querySnapshot.docs.first.data()['headshot_url'] as String?;
      }
    } catch (e) {
      debugPrint('Error in name components query: $e');
    }
    return null;
  }

  /// Get multiple player headshots efficiently
  static Future<Map<String, String?>> getMultiplePlayerHeadshots(
    List<String> playerNames, {
    String? position,
  }) async {
    final results = <String, String?>{};
    
    // Process in parallel with limited concurrency to avoid overwhelming Firestore
    const batchSize = 5; // Reduced for better stability
    for (int i = 0; i < playerNames.length; i += batchSize) {
      final batch = playerNames.skip(i).take(batchSize);
      final futures = batch.map((name) => getPlayerHeadshot(name, position: position));
      
      // Use Future.wait with error handling
      final batchResults = await Future.wait(
        futures,
        eagerError: false, // Continue even if some fail
      );
      
      for (int j = 0; j < batch.length; j++) {
        results[batch.elementAt(j)] = batchResults[j];
      }
      
      // Small delay between batches to prevent overwhelming the system
      if (i + batchSize < playerNames.length) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
    }
    
    return results;
  }

  /// Preload headshots for a list of players (useful for big boards)
  static Future<void> preloadHeadshots(
    List<String> playerNames, {
    String? position,
    Map<String, String>? playerTeams, // Optional team mapping for better accuracy
  }) async {
    if (playerNames.isEmpty) return;
    
    debugPrint('🔄 Preloading headshots for ${playerNames.length} players');
    
    // Filter out players already in cache
    final uncachedPlayers = <String>[];
    for (final name in playerNames) {
      final normalizedName = _normalizePlayerName(name);
      final team = playerTeams?[name];
      final cacheKey = _generateCacheKey(normalizedName, position, team);
      
      if (!_headshotCache.containsKey(cacheKey) && !_negativeCache.containsKey(cacheKey)) {
        uncachedPlayers.add(name);
      }
    }
    
    if (uncachedPlayers.isEmpty) {
      debugPrint('✅ All ${playerNames.length} players already cached');
      return;
    }
    
    debugPrint('📥 Loading ${uncachedPlayers.length} uncached players');
    
    // Load uncached players
    if (playerTeams != null) {
      // Load with team info for better accuracy
      const batchSize = 5;
      for (int i = 0; i < uncachedPlayers.length; i += batchSize) {
        final batch = uncachedPlayers.skip(i).take(batchSize);
        final futures = batch.map((name) => getPlayerHeadshot(
          name, 
          position: position,
          team: playerTeams[name],
        ));
        
        await Future.wait(futures, eagerError: false);
        
        if (i + batchSize < uncachedPlayers.length) {
          await Future.delayed(const Duration(milliseconds: 50));
        }
      }
    } else {
      await getMultiplePlayerHeadshots(uncachedPlayers, position: position);
    }
    
    debugPrint('✅ Headshot preloading complete');
  }

  /// Clear all caches
  static void clearCache() {
    _headshotCache.clear();
    _negativeCache.clear();
    _cacheHits = 0;
    _cacheMisses = 0;
    _firebaseQueries = 0;
    debugPrint('🧹 PlayerHeadshotService cache cleared');
  }

  /// Get cache statistics for debugging
  static Map<String, dynamic> getCacheStats() {
    final totalRequests = _cacheHits + _cacheMisses;
    final hitRate = totalRequests > 0 ? (_cacheHits / totalRequests * 100).toStringAsFixed(1) : '0.0';
    
    return {
      'cache_hits': _cacheHits,
      'cache_misses': _cacheMisses,
      'firebase_queries': _firebaseQueries,
      'hit_rate_percent': hitRate,
      'positive_cache_size': _headshotCache.length,
      'negative_cache_size': _negativeCache.length,
    };
  }

  /// Print cache statistics to debug console
  static void printCacheStats() {
    final stats = getCacheStats();
    debugPrint('📊 PlayerHeadshotService Cache Stats:');
    debugPrint('   Cache Hits: ${stats['cache_hits']}');
    debugPrint('   Cache Misses: ${stats['cache_misses']}');
    debugPrint('   Firebase Queries: ${stats['firebase_queries']}');
    debugPrint('   Hit Rate: ${stats['hit_rate_percent']}%');
    debugPrint('   Positive Cache Size: ${stats['positive_cache_size']}');
    debugPrint('   Negative Cache Size: ${stats['negative_cache_size']}');
  }

  // MARK: - Private Helper Methods

  /// Normalize player name for consistent lookups
  static String _normalizePlayerName(String name) {
    // First, handle common suffixes that might be missing in the database
    String processedName = name;
    
    // Remove Jr., Sr., III, etc. suffixes as they're often inconsistent
    processedName = processedName
        .replaceAll(RegExp(r'\s+(Jr\.?|Sr\.?|III|II|IV)$', caseSensitive: false), '');
    
    // Now normalize the name
    return processedName
        .toLowerCase()
        .trim()
        .replaceAll(RegExp(r'[^\w\s]'), '') // Remove punctuation
        .replaceAll(RegExp(r'\s+'), ' '); // Normalize whitespace
  }

  /// Generate cache key for consistent caching
  static String _generateCacheKey(String normalizedName, String? position, String? team) {
    final parts = [normalizedName];
    if (position?.isNotEmpty == true) parts.add(position!.toLowerCase());
    if (team?.isNotEmpty == true) parts.add(team!.toLowerCase());
    return parts.join('|');
  }

  /// Check if two normalized names are a match
  static bool _isNameMatch(String searchName, String dbName) {
    // Exact match
    if (searchName == dbName) return true;
    
    // Check if search name is contained in db name or vice versa
    if (searchName.contains(dbName) || dbName.contains(searchName)) {
      return true;
    }
    
    // Check Levenshtein distance for typos (basic implementation)
    return _calculateLevenshteinDistance(searchName, dbName) <= 2;
  }

  /// Calculate Levenshtein distance for fuzzy matching
  static int _calculateLevenshteinDistance(String s1, String s2) {
    if (s1.length < s2.length) {
      return _calculateLevenshteinDistance(s2, s1);
    }
    
    if (s2.isEmpty) {
      return s1.length;
    }
    
    List<int> previousRow = List.generate(s2.length + 1, (i) => i);
    
    for (int i = 0; i < s1.length; i++) {
      List<int> currentRow = [i + 1];
      
      for (int j = 0; j < s2.length; j++) {
        int insertions = previousRow[j + 1] + 1;
        int deletions = currentRow[j] + 1;
        int substitutions = previousRow[j] + (s1[i] != s2[j] ? 1 : 0);
        
        currentRow.add([insertions, deletions, substitutions].reduce((a, b) => a < b ? a : b));
      }
      
      previousRow = currentRow;
    }
    
    return previousRow.last;
  }

  /// Capitalize first letter of a word
  static String _capitalizeFirst(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }
}