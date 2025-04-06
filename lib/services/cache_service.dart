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
}