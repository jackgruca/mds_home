// lib/services/fast_analytics_loader.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class FastAnalyticsLoader {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _aggregatedCollectionName = 'aggregated_analytics';
  static const String _localStoragePrefix = 'fastanalytics_';
  
  // Cache expiration (24 hours)
  static const Duration _cacheValidity = Duration(hours: 24);
  
  // Instance variables
  static Map<String, dynamic>? _cachedQuickAccessData;
  static DateTime? _quickAccessLoadTime;
  
  /// Initialize the loader - call this early in app lifecycle
  static Future<void> initialize() async {
    debugPrint('Initializing FastAnalyticsLoader');
    
    // Try to load data from local storage first
    await _loadFromLocalStorage();
    
    // If no data in local storage, try to load from Firestore
    if (_cachedQuickAccessData == null) {
      await loadQuickAccessData(forceRefresh: false);
    }
  }
  
  /// Load data from local storage
  static Future<void> _loadFromLocalStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Check when the data was last saved
      final lastSaveTimeStr = prefs.getString('${_localStoragePrefix}last_save_time');
      if (lastSaveTimeStr != null) {
        final lastSaveTime = DateTime.parse(lastSaveTimeStr);
        
        // If cache is still valid
        if (DateTime.now().difference(lastSaveTime) < _cacheValidity) {
          // Load the quick access data
          final jsonData = prefs.getString('${_localStoragePrefix}quick_access');
          if (jsonData != null) {
            _cachedQuickAccessData = jsonDecode(jsonData);
            _quickAccessLoadTime = lastSaveTime;
            
            debugPrint('Loaded analytics data from local storage (saved ${DateTime.now().difference(lastSaveTime).inHours} hours ago)');
            return;
          }
        }
      }
    } catch (e) {
      debugPrint('Error loading from local storage: $e');
    }
  }
  
  /// Save data to local storage
  static Future<void> _saveToLocalStorage() async {
    if (_cachedQuickAccessData == null) return;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Save the quick access data
      await prefs.setString('${_localStoragePrefix}quick_access', jsonEncode(_cachedQuickAccessData));
      
      // Save the current time
      await prefs.setString('${_localStoragePrefix}last_save_time', DateTime.now().toIso8601String());
      
      debugPrint('Saved analytics data to local storage');
    } catch (e) {
      debugPrint('Error saving to local storage: $e');
    }
  }
  
  /// Load position trends data for a specific round
  static Future<List<Map<String, dynamic>>> getPositionTrends(String round) async {
    // For round 1, use quick access data if available
    if (round == '1' && _cachedQuickAccessData != null && _cachedQuickAccessData!.containsKey('firstRoundTrends')) {
      return List<Map<String, dynamic>>.from(_cachedQuickAccessData!['firstRoundTrends']);
    }
    
    // For other rounds, load specifically
    try {
      final doc = await _firestore.collection(_aggregatedCollectionName).doc('position_trends_$round').get();
      
      if (doc.exists && doc.data()!.containsKey('data')) {
        return List<Map<String, dynamic>>.from(doc.data()!['data']);
      }
    } catch (e) {
      debugPrint('Error loading position trends for round $round: $e');
    }
    
    return [];
  }
  
  /// Get team needs consensus data
  static Future<Map<String, List<String>>> getConsensusNeeds() async {
    if (_cachedQuickAccessData != null && _cachedQuickAccessData!.containsKey('consensusNeeds')) {
      final needsData = _cachedQuickAccessData!['consensusNeeds'];
      
      // Convert to correct format
      Map<String, List<String>> result = {};
      needsData.forEach((team, needs) {
        if (needs is List) {
          result[team] = List<String>.from(needs);
        }
      });
      
      return result;
    }
    
    try {
      final doc = await _firestore.collection(_aggregatedCollectionName).doc('consensus_needs').get();
      
      if (doc.exists && doc.data()!.containsKey('needs')) {
        final needsData = doc.data()!['needs'];
        
        // Convert to correct format
        Map<String, List<String>> result = {};
        needsData.forEach((team, needs) {
          if (needs is List) {
            result[team] = List<String>.from(needs);
          }
        });
        
        return result;
      }
    } catch (e) {
      debugPrint('Error loading consensus needs: $e');
    }
    
    return {};
  }
  
  /// Get player value analysis
  static Future<Map<String, List<Map<String, dynamic>>>> getPlayerValueAnalysis() async {
    if (_cachedQuickAccessData != null && _cachedQuickAccessData!.containsKey('topValuePlayers')) {
      final valueData = _cachedQuickAccessData!['topValuePlayers'];
      
      return {
        'risers': List<Map<String, dynamic>>.from(valueData['risers']),
        'fallers': List<Map<String, dynamic>>.from(valueData['fallers']),
      };
    }
    
    try {
      final doc = await _firestore.collection(_aggregatedCollectionName).doc('player_value_analysis').get();
      
      if (doc.exists) {
        return {
          'risers': List<Map<String, dynamic>>.from(doc.data()!['risers'] ?? []),
          'fallers': List<Map<String, dynamic>>.from(doc.data()!['fallers'] ?? []),
        };
      }
    } catch (e) {
      debugPrint('Error loading player value analysis: $e');
    }
    
    return {'risers': [], 'fallers': []};
  }
  
  /// Get all analytics data in a single call (most efficient)
  static Future<Map<String, dynamic>?> loadQuickAccessData({bool forceRefresh = false}) async {
    // If data is already loaded and we're not forcing a refresh, return it
    if (!forceRefresh && _cachedQuickAccessData != null) {
      return _cachedQuickAccessData;
    }
    
    try {
      // Try to get the JSON string version first (fastest)
      final jsonDoc = await _firestore.collection(_aggregatedCollectionName).doc('quick_access_json').get();
      
      if (jsonDoc.exists && jsonDoc.data()!.containsKey('json')) {
        // Parse the JSON string
        _cachedQuickAccessData = jsonDecode(jsonDoc.data()!['json']);
      } else {
        // Fall back to regular document
        final doc = await _firestore.collection(_aggregatedCollectionName).doc('quick_access').get();
        
        if (doc.exists) {
          _cachedQuickAccessData = doc.data();
        }
      }
      
      // Save successful load time
      _quickAccessLoadTime = DateTime.now();
      
      // Save to local storage for next app start
      _saveToLocalStorage();
      
      return _cachedQuickAccessData;
    } catch (e) {
      debugPrint('Error loading quick access data: $e');
      return null;
    }
  }
  
  /// Check if data needs refresh
  static bool get needsRefresh {
    if (_quickAccessLoadTime == null) return true;
    return DateTime.now().difference(_quickAccessLoadTime!) > _cacheValidity;
  }
  
  /// Clear local cache
  static Future<void> clearLocalCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Clear all items with prefix
      final allKeys = prefs.getKeys();
      for (final key in allKeys) {
        if (key.startsWith(_localStoragePrefix)) {
          await prefs.remove(key);
        }
      }
      
      // Clear in-memory cache
      _cachedQuickAccessData = null;
      _quickAccessLoadTime = null;
      
      debugPrint('Local analytics cache cleared');
    } catch (e) {
      debugPrint('Error clearing local cache: $e');
    }
  }
}