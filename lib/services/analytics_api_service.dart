// lib/services/analytics_api_service.dart
import 'package:flutter/material.dart';
import '../services/analytics_cache_manager.dart';
import '../services/firebase_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AnalyticsApiService {
  /// Get data from the cached analytics API
  static Future<Map<String, dynamic>> getAnalyticsData({
    required String dataType,
    Map<String, dynamic>? filters,
  }) async {
    final cacheKey = 'api_${dataType}_${filters?.toString() ?? 'no_filters'}';
    
    return AnalyticsCacheManager.getCachedData(
      cacheKey,
      () => _fetchFromApi(dataType, filters),
      expiry: const Duration(hours: 12), // Cache for 12 hours
    );
  }
  
  // lib/services/analytics_api_service.dart

static Future<Map<String, dynamic>> _fetchFromApi(
  String dataType,
  Map<String, dynamic>? filters,
) async {
  try {
    // Ensure Firebase is initialized
    await FirebaseService.initialize();
    
    debugPrint('Fetching $dataType from analytics API with filters: $filters');
    
    // Use Firestore as a fallback since cloud_functions isn't available
    final db = FirebaseFirestore.instance;
    
    // Query precomputed data from Firestore
    DocumentSnapshot doc;
    
    if (dataType.isEmpty) {
      doc = await db.collection('precomputedAnalytics').doc('metadata').get();
    } else {
      doc = await db.collection('precomputedAnalytics').doc(dataType).get();
    }
    
    if (!doc.exists) {
      debugPrint('Document not found: $dataType');
      return {'error': 'Data not found'};
    }
    
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    
    // Add detailed debugging to diagnose issues
    debugPrint('Document retrieved for $dataType with keys: ${data.keys.toList()}');
    
    // If the document has a "data" field, check if it's empty
    if (data.containsKey('data')) {
      final dataArray = data['data'];
      if (dataArray is List && dataArray.isEmpty) {
        debugPrint('Warning: "data" field exists but is empty for $dataType');
      } else if (dataArray is List) {
        debugPrint('Data field contains ${dataArray.length} items for $dataType');
      }
    }
    
    // Apply filters if specified
    if (filters != null && filters.isNotEmpty) {
      // Simple filtering for team, year, etc.
      if (filters.containsKey('team') && data.containsKey('byTeam')) {
        String team = filters['team'];
        if (data['byTeam'].containsKey(team)) {
          data = {'data': data['byTeam'][team]};
          debugPrint('Applied team filter for: $team');
        } else {
          debugPrint('Warning: Team $team not found in byTeam data');
        }
      }
      
      // Add more filter logic as needed
    }
    
    debugPrint('Successfully fetched data from Firestore: $dataType');
    return {'data': data};
  } catch (e) {
    debugPrint('Error fetching analytics data: $e');
    return {'error': 'Failed to fetch analytics data: $e'};
  }
}
  
  /// Get metadata about the analytics cache
  static Future<Map<String, dynamic>> getAnalyticsMetadata() async {
    try {
      // Ensure Firebase is initialized
      await FirebaseService.initialize();
      
      // Query metadata from Firestore
      final db = FirebaseFirestore.instance;
      final doc = await db.collection('precomputedAnalytics').doc('metadata').get();
      
      if (!doc.exists) {
        return {'error': 'Metadata not found'};
      }
      
      return {'metadata': doc.data()};
    } catch (e) {
      debugPrint('Error fetching analytics metadata: $e');
      return {'error': 'Failed to fetch analytics metadata: $e'};
    }
  }
}