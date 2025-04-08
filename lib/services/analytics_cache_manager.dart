// lib/services/analytics_cache_manager.dart
import 'package:flutter/foundation.dart';

class AnalyticsCacheManager {
  static final Map<String, dynamic> _cache = {};
  static final Map<String, DateTime> _cacheTimestamps = {};
  
  /// Get data from cache or use fetcher function to retrieve it
  static Future<T> getCachedData<T>(
    String key, 
    Future<T> Function() fetcher, {
    Duration expiry = const Duration(minutes: 30),
  }) async {
    final now = DateTime.now();
    
    // Check if data exists in cache and is not expired
    if (_cache.containsKey(key) && _cacheTimestamps.containsKey(key)) {
      final timestamp = _cacheTimestamps[key]!;
      if (now.difference(timestamp) < expiry) {
        debugPrint('Using cached data for key: $key');
        return _cache[key] as T;
      }
      debugPrint('Cache expired for key: $key');
    }
    
    // Fetch fresh data
    debugPrint('Fetching fresh data for key: $key');
    final data = await fetcher();
    
    // Update cache
    _cache[key] = data;
    _cacheTimestamps[key] = now;
    
    return data;
  }
  
  /// Clear all cached data
  static void clearCache() {
    _cache.clear();
    _cacheTimestamps.clear();
    debugPrint('Analytics cache cleared');
  }
  
  /// Clear specific cached item
  static void clearCachedItem(String key) {
    _cache.remove(key);
    _cacheTimestamps.remove(key);
    debugPrint('Cleared cached item: $key');
  }
  
  /// Check if a key exists in cache and is fresh
  static bool isCacheFresh(String key, {Duration expiry = const Duration(minutes: 30)}) {
    if (_cache.containsKey(key) && _cacheTimestamps.containsKey(key)) {
      final now = DateTime.now();
      final timestamp = _cacheTimestamps[key]!;
      return now.difference(timestamp) < expiry;
    }
    return false;
  }
}