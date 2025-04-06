// lib/services/cache_service.dart
import 'package:flutter/foundation.dart';

class CacheService {
  static final Map<String, dynamic> _cache = {};
  static final Map<String, DateTime> _cacheTimestamps = {};
  
  static const Duration defaultCacheValidity = Duration(minutes: 15);
  
  static void setData(String key, dynamic data) {
    _cache[key] = data;
    _cacheTimestamps[key] = DateTime.now();
    debugPrint('Cache set: $key');
  }
  
  static dynamic getData(String key, {Duration validity = defaultCacheValidity}) {
    if (!_cache.containsKey(key)) return null;
    
    final timestamp = _cacheTimestamps[key]!;
    if (DateTime.now().difference(timestamp) > validity) {
      // Cache expired
      _cache.remove(key);
      _cacheTimestamps.remove(key);
      debugPrint('Cache expired: $key');
      return null;
    }
    
    debugPrint('Cache hit: $key');
    return _cache[key];
  }
  
  static void clearCache() {
    _cache.clear();
    _cacheTimestamps.clear();
    debugPrint('Cache cleared');
  }
  
  static void removeItem(String key) {
    _cache.remove(key);
    _cacheTimestamps.remove(key);
    debugPrint('Cache item removed: $key');
  }
  
  static bool hasValidCache(String key, {Duration validity = defaultCacheValidity}) {
    if (!_cache.containsKey(key)) return false;
    
    final timestamp = _cacheTimestamps[key]!;
    return DateTime.now().difference(timestamp) <= validity;
  }
  // Cache data with a specific key prefix and version
static void setCacheWithVersion(String keyPrefix, String version, dynamic data) {
  final key = "${keyPrefix}_v$version";
  setData(key, data);
  debugPrint('Cache set with version: $key');
}

// Get cached data with version check
static dynamic getCacheWithVersion(String keyPrefix, String version, {Duration validity = defaultCacheValidity}) {
  final key = "${keyPrefix}_v$version";
  return getData(key, validity: validity);
}

// Clear all cache with a specific prefix
static void clearCacheWithPrefix(String prefix) {
  final keysToRemove = _cache.keys.where((key) => key.startsWith(prefix)).toList();
  for (final key in keysToRemove) {
    _cache.remove(key);
    _cacheTimestamps.remove(key);
  }
  debugPrint('Cleared ${keysToRemove.length} cache items with prefix: $prefix');
}

// Get cache size estimate in KB
static int getCacheSizeEstimate() {
  int totalSize = 0;
  _cache.forEach((key, value) {
    // Rough estimate based on string representation
    totalSize += key.length;
    totalSize += value.toString().length;
  });
  return totalSize ~/ 1024; // Convert to KB
}
}