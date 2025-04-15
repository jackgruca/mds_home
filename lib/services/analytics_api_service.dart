// lib/services/analytics_api_service.dart
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import '../services/analytics_cache_manager.dart';
import '../services/firebase_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// lib/services/analytics_api_service.dart (update)

class AnalyticsApiService {
  // Add a client-side cache
  static final Map<String, dynamic> _memoryCache = {};
  static final Map<String, DateTime> _cacheExpiry = {};
  
  /// Get data from the cached analytics API with optimized caching
  static Future<Map<String, dynamic>> getAnalyticsData({
    required String dataType,
    Map<String, dynamic>? filters,
    bool useCache = true,
    Duration localCacheDuration = const Duration(minutes: 5),
  }) async {
    // Create cache key for local memory cache
    final cacheKey = _createCacheKey(dataType, filters);
    
    // Check local memory cache first
    if (useCache && _memoryCache.containsKey(cacheKey)) {
      final expiry = _cacheExpiry[cacheKey];
      if (expiry != null && expiry.isAfter(DateTime.now())) {
        debugPrint('Using memory cache for $dataType');
        return {'data': _memoryCache[cacheKey], 'fromCache': true};
      }
    }
    
    try {
      // Prepare for Firebase function call
      final callable = FirebaseFunctions.instance.httpsCallable('getAnalyticsData');
      
      // Call the function with appropriate parameters
      final result = await callable.call({
        'dataType': dataType,
        'filters': filters,
        'useCache': useCache,
      });
      
      // Process the result
      final data = Map<String, dynamic>.from(result.data);
      
      // Save to local memory cache
      if (!data.containsKey('error') && data.containsKey('data')) {
        _memoryCache[cacheKey] = data['data'];
        _cacheExpiry[cacheKey] = DateTime.now().add(localCacheDuration);
      }
      
      return data;
    } catch (e) {
      debugPrint('Error fetching analytics data: $e');
      return {'error': e.toString()};
    }
  }
  
  // Helper to create cache key
  static String _createCacheKey(String dataType, Map<String, dynamic>? filters) {
    if (filters == null || filters.isEmpty) {
      return dataType;
    }
    
    final filterString = filters.entries
        .map((e) => '${e.key}=${e.value}')
        .join('_');
    
    return '${dataType}_$filterString';
  }
  
  // New method to clear local cache
  static void clearLocalCache() {
    _memoryCache.clear();
    _cacheExpiry.clear();
    debugPrint('Local analytics cache cleared');
  }
  
  // Force refresh server-side analytics
  static Future<bool> forceRefreshAnalytics() async {
    try {
      final callable = FirebaseFunctions.instance.httpsCallable('triggerManualAggregation');
      final result = await callable.call();
      
      // Clear local cache to ensure fresh data
      clearLocalCache();
      
      return result.data['success'] == true;
    } catch (e) {
      debugPrint('Error forcing analytics refresh: $e');
      return false;
    }
  }

  /// Get metadata about the analytics system
static Future<Map<String, dynamic>> getAnalyticsMetadata() async {
  try {
    // Use the same approach as getAnalyticsData but specifically for metadata
    final callable = FirebaseFunctions.instance.httpsCallable('getAnalyticsData');
    
    // Call without a specific dataType to get metadata
    final result = await callable.call({
      'metadataOnly': true
    });
    
    if (result.data is Map) {
      return Map<String, dynamic>.from(result.data);
    }
    
    // Fallback to fetching from Firestore directly if the function doesn't return metadata
    await FirebaseService.initialize();
    final db = FirebaseFirestore.instance;
    
    final doc = await db.collection('precomputedAnalytics').doc('metadata').get();
    if (!doc.exists) {
      return {'status': 'unknown'};
    }
    
    return doc.data() ?? {'status': 'unknown'};
  } catch (e) {
    debugPrint('Error fetching analytics metadata: $e');
    return {
      'status': 'error',
      'error': e.toString(),
      'lastChecked': DateTime.now()
    };
  }
}

/// Process a batch of analytics data
static Future<Map<String, dynamic>> processAnalyticsBatch() async {
  try {
    await FirebaseService.initialize();
    
    // Call the cloud function for batch processing
    final callable = FirebaseFunctions.instance.httpsCallable('continueAnalyticsAggregation');
    final result = await callable.call();
    
    if (result.data is Map) {
      return Map<String, dynamic>.from(result.data);
    }
    
    return {
      'error': 'Invalid response format from analytics processing',
      'raw': result.data
    };
  } catch (e) {
    debugPrint('Error processing analytics batch: $e');
    return {
      'error': e.toString(),
      'timestamp': DateTime.now().toIso8601String()
    };
  }
}

/// Run a robust analytics aggregation process
static Future<bool> runRobustAggregation() async {
  try {
    await FirebaseService.initialize();
    
    // Call the cloud function for full aggregation
    final callable = FirebaseFunctions.instance.httpsCallable('triggerRobustAggregation');
    final result = await callable.call();
    
    if (result.data is Map && result.data['success'] == true) {
      return true;
    }
    
    // If function approach fails, try direct Firestore approach
    final db = FirebaseFirestore.instance;
    
    // Request a manual aggregation run
    await db.collection('precomputedAnalytics').doc('metadata').set({
      'manualRunRequested': true,
      'manualRunTimestamp': FieldValue.serverTimestamp(),
      'requestSource': 'app_admin_panel',
    }, SetOptions(merge: true));
    
    // Clear local cache
    AnalyticsCacheManager.clearCache();
    
    return true;
  } catch (e) {
    debugPrint('Error running robust aggregation: $e');
    return false;
  }
}

/// Fix data structure issues in analytics collections
static Future<bool> fixAnalyticsDataStructure() async {
  try {
    await FirebaseService.initialize();
    
    // Call the cloud function for data structure fixing
    final callable = FirebaseFunctions.instance.httpsCallable('fixAnalyticsDataStructure');
    final result = await callable.call();
    
    if (result.data is Map && result.data['success'] == true) {
      return true;
    }
    
    // Alternative approach with direct Firestore access
    final db = FirebaseFirestore.instance;
    
    // Request a data structure fix
    await db.collection('precomputedAnalytics').doc('metadata').set({
      'dataStructureFixRequested': true,
      'fixRequestTimestamp': FieldValue.serverTimestamp(),
      'requestSource': 'app_admin_panel',
    }, SetOptions(merge: true));
    
    // Sample data for critical collections if needed
    // This is a simple emergency approach to ensure basic data is available
    await _createSampleDataIfNeeded(db);
    
    return true;
  } catch (e) {
    debugPrint('Error fixing analytics data structure: $e');
    return false;
  }
}

/// Helper method to create sample data for critical collections if they're empty
static Future<void> _createSampleDataIfNeeded(FirebaseFirestore db) async {
  try {
    // Check if position trends data exists
    final positionTrendsDoc = await db.collection('precomputedAnalytics')
        .doc('positionsByPickRound1')
        .get();
    
    if (!positionTrendsDoc.exists || 
        positionTrendsDoc.data()?['data'] is! List || 
        (positionTrendsDoc.data()?['data'] as List).isEmpty) {
      
      // Create minimal sample data
      await db.collection('precomputedAnalytics').doc('positionsByPickRound1').set({
        'data': [
          {
            'pick': 1,
            'round': '1',
            'positions': [
              {'position': 'QB', 'count': 100, 'percentage': '65.6%'},
              {'position': 'EDGE', 'count': 30, 'percentage': '34.0%'},
            ],
            'totalDrafts': 150
          }
        ],
        'lastUpdated': FieldValue.serverTimestamp(),
        'isSampleData': true
      });
      
      debugPrint('Created sample position data');
    }
    
    // Check if team needs data exists
    final teamNeedsDoc = await db.collection('precomputedAnalytics')
        .doc('teamNeeds')
        .get();
    
    if (!teamNeedsDoc.exists || teamNeedsDoc.data()?['needs'] is! Map) {
      // Create minimal sample team needs
      await db.collection('precomputedAnalytics').doc('teamNeeds').set({
        'needs': {
          'ARI': ['DL', 'WR', 'OT', 'EDGE', 'IOL'],
          'ATL': ['EDGE', 'DL', 'CB', 'IOL', 'RB'],
        },
        'year': DateTime.now().year,
        'lastUpdated': FieldValue.serverTimestamp(),
        'isSampleData': true
      });
      
      debugPrint('Created sample team needs data');
    }
  } catch (e) {
    debugPrint('Error creating sample data: $e');
  }
}

/// Process a single batch of analytics data with optional continuation token
static Future<Map<String, dynamic>> processSingleBatch(String? continuationToken) async {
  try {
    await FirebaseService.initialize();
    
    // Call the Cloud Function with continuation token
    final callable = FirebaseFunctions.instance.httpsCallable('continueAnalyticsAggregation');
    final result = await callable.call({
      'continuationToken': continuationToken,
      'batchSize': 20, // Can be adjusted based on performance needs
    });
    
    if (result.data is Map) {
      return Map<String, dynamic>.from(result.data);
    }
    
    // Alternative approach using direct Firestore access if Cloud Functions aren't available
    final db = FirebaseFirestore.instance;
    
    // Request batch processing via metadata
    await db.collection('precomputedAnalytics').doc('metadata').set({
      'batchProcessRequested': true,
      'continuationToken': continuationToken,
      'requestTimestamp': FieldValue.serverTimestamp(),
      'requestSource': 'app_admin_panel',
    }, SetOptions(merge: true));
    
    // Wait briefly for processing to start
    await Future.delayed(const Duration(seconds: 2));
    
    // Get the updated metadata to return results
    final updatedMetadata = await db.collection('precomputedAnalytics').doc('metadata').get();
    final metadataData = updatedMetadata.data() ?? {};
    
    return {
      'continuationToken': metadataData['continuationToken'],
      'complete': metadataData['batchProcessRequested'] == false,
      'documentsProcessed': metadataData['documentsProcessed'] ?? 0,
      'picksProcessed': metadataData['picksProcessed'] ?? 0,
    };
  } catch (e) {
    debugPrint('Error processing single batch: $e');
    return {
      'error': e.toString(),
      'timestamp': DateTime.now().toIso8601String(),
    };
  }
}

}
