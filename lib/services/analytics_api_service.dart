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
  
  debugPrint('Attempting to fetch analytics data: $dataType with filters: $filters');
  
  return AnalyticsCacheManager.getCachedData(
    cacheKey,
    () => _fetchFromApi(dataType, filters),
    expiry: const Duration(hours: 12),
  );
}

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
    
    // DETAILED ERROR LOGGING
    debugPrint('Accessing Firestore collection: precomputedAnalytics');
    debugPrint('Accessing document: $dataType');
    
    // Query precomputed data from Firestore
    DocumentSnapshot doc;
    
    try {
      if (dataType.isEmpty) {
        doc = await db.collection('precomputedAnalytics').doc('metadata').get();
      } else {
        doc = await db.collection('precomputedAnalytics').doc(dataType).get();
      }
      
      debugPrint('Document fetch successful: ${doc.exists}');
      
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        debugPrint('Document contains keys: ${data.keys.join(", ")}');
      }
    } catch (docError) {
      debugPrint('ERROR fetching document: $docError');
      rethrow;
    }
    
    if (!doc.exists) {
      debugPrint('Data not found for $dataType');
      return {'error': 'Data not found'};
    }
    
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    
    // Apply filters if specified
    if (filters != null && filters.isNotEmpty) {
      // Simple filtering for team, year, etc.
      if (filters.containsKey('team') && data.containsKey('byTeam')) {
        String team = filters['team'];
        if (data['byTeam'].containsKey(team)) {
          data = {'data': data['byTeam'][team]};
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