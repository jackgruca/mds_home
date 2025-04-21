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
  bool forceRefresh = false,
}) async {
  final now = DateTime.now();
  
  // Check if force refresh is requested
  if (forceRefresh) {
    debugPrint('Force refreshing data for key: $key');
  }
  // Check if data exists in cache and is not expired
  else if (_cache.containsKey(key) && _cacheTimestamps.containsKey(key)) {
    final timestamp = _cacheTimestamps[key]!;
    if (now.difference(timestamp) < expiry) {
      debugPrint('Using cached data for key: $key');
      return _cache[key] as T;
    }
    debugPrint('Cache expired for key: $key');
  }
  
  // Fetch fresh data with retry mechanism
  debugPrint('Fetching fresh data for key: $key');
  T? data;
  Exception? lastError;
  
  // Try up to 3 times with increasing delays
  for (int attempt = 0; attempt < 3; attempt++) {
    try {
      data = await fetcher();
      lastError = null;
      break;
    } catch (e) {
      lastError = e is Exception ? e : Exception(e.toString());
      debugPrint('Error fetching data on attempt ${attempt + 1}/3: $e');
      
      // Wait before retrying (exponential backoff)
      if (attempt < 2) {
        await Future.delayed(Duration(milliseconds: 500 * (1 << attempt)));
      }
    }
  }
  
  // If all attempts failed, throw the last error or use cached data if available
  if (data == null) {
    if (_cache.containsKey(key)) {
      debugPrint('Using stale cached data for key: $key after failed refresh');
      return _cache[key] as T;
    }
    throw lastError ?? Exception('Failed to fetch data after multiple attempts');
  }
  
  // Update cache
  _cache[key] = data;
  _cacheTimestamps[key] = now;
  
  return data;
}

/// Force refresh a specific cached item
static Future<T> forceRefresh<T>(String key, Future<T> Function() fetcher) {
  return getCachedData(key, fetcher, forceRefresh: true);
}

/// Force refresh all cached analytics data
static Future<void> refreshAllAnalytics() async {
  // Clear all analytics-related cache entries
  final analyticsKeys = _cache.keys
      .where((key) => 
          key.startsWith('position_') || 
          key.startsWith('team_') || 
          key.startsWith('player_'))
      .toList();
  
  for (final key in analyticsKeys) {
    _cache.remove(key);
    _cacheTimestamps.remove(key);
  }
  
  debugPrint('Cleared ${analyticsKeys.length} analytics cache entries');
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