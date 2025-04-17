// lib/services/analytics_api_service.dart (Updated)
import 'package:flutter/material.dart';
import '../services/analytics_cache_manager.dart';
import '../services/firebase_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'direct_analytics_service.dart'; // Import the direct service

class AnalyticsApiService {
  /// Get data from the analytics API or fallback to direct calculations
  static Future<Map<String, dynamic>> getAnalyticsData({
    required String dataType,
    Map<String, dynamic>? filters,
  }) async {
    final cacheKey = 'api_${dataType}_${filters?.toString() ?? 'no_filters'}';
    
    debugPrint('Attempting to fetch analytics data: $dataType with filters: $filters');
    
    return AnalyticsCacheManager.getCachedData(
      cacheKey,
      () => _fetchFromApiFallbackToDirect(dataType, filters),
      expiry: const Duration(hours: 1), // Reduced for development
    );
  }

  static Future<Map<String, dynamic>> _fetchFromApiFallbackToDirect(
    String dataType,
    Map<String, dynamic>? filters,
  ) async {
    try {
      // Ensure Firebase is initialized
      await FirebaseService.initialize();
      
      debugPrint('Fetching $dataType from analytics API with filters: $filters');
      
      // First try to get from precomputedAnalytics collection
      try {
        final db = FirebaseFirestore.instance;
        final doc = await db.collection('precomputedAnalytics').doc(dataType).get();
        
        if (doc.exists) {
          final data = doc.data() as Map<String, dynamic>;
          debugPrint('Retrieved data from precomputedAnalytics collection');
          
          // Apply filters if specified
          if (filters != null && filters.isNotEmpty) {
            // Apply simple filtering based on the data type
            if (dataType == 'positionDistribution' && filters.containsKey('team')) {
              String team = filters['team'];
              if (data.containsKey('byTeam') && data['byTeam'].containsKey(team)) {
                return {'data': data['byTeam'][team]};
              }
            }
            
            // Add more filter handling as needed for other data types
          }
          
          return {'data': data};
        }
      } catch (e) {
        debugPrint('Error querying precomputedAnalytics: $e');
        // Continue to alternative methods
      }
      
      // If not found in precomputedAnalytics, try position_trends collection for position data
      if (dataType.startsWith('positionsByPick')) {
        int? round;
        if (dataType == 'positionsByPick') {
          round = filters?['round'] as int?;
        } else {
          // Extract round number from dataType (e.g., 'positionsByPickRound1' -> 1)
          final roundStr = dataType.replaceAll('positionsByPickRound', '');
          round = int.tryParse(roundStr);
        }
        
        if (round != null) {
          final result = await DirectAnalyticsService.getPositionTrendsByRound(
            round: round,
            team: filters?['team'] as String?,
          );
          
          if (!result.containsKey('error')) {
            debugPrint('Retrieved position data from DirectAnalyticsService');
            return result;
          }
        }
      }
      
      // For team needs data
      if (dataType == 'teamNeeds') {
        final teamNeeds = await DirectAnalyticsService.getTeamNeeds(
          year: filters?['year'] as int?,
        );
        
        return {'data': {'needs': teamNeeds, 'year': DateTime.now().year}};
      }
      
      // For position distribution
      if (dataType == 'positionDistribution') {
        final distribution = await DirectAnalyticsService.getPositionDistribution(
          team: filters?['team'] as String?,
          rounds: filters?['rounds'] as List<int>?,
          year: filters?['year'] as int?,
        );
        
        return {'data': distribution};
      }
      
      // Return empty data if we couldn't find anything
      debugPrint('No data found for $dataType, returning empty result');
      return {'data': {}};
    } catch (e) {
      debugPrint('Error fetching analytics data: $e');
      return {'error': 'Failed to fetch analytics data: $e'};
    }
  }
  
  /// Get metadata about the analytics
  static Future<Map<String, dynamic>> getAnalyticsMetadata() async {
    try {
      // Ensure Firebase is initialized
      await FirebaseService.initialize();
      
      // Try to get metadata from precomputedAnalytics
      try {
        final db = FirebaseFirestore.instance;
        final doc = await db.collection('precomputedAnalytics').doc('metadata').get();
        
        if (doc.exists) {
          return {'metadata': doc.data()};
        }
      } catch (e) {
        debugPrint('Error fetching precomputed analytics metadata: $e');
      }
      
      // If not found, return basic metadata
      final draftAnalyticsCount = await FirebaseFirestore.instance
          .collection('draftAnalytics')
          .count()
          .get();
      
      return {
        'metadata': {
          'lastUpdated': Timestamp.now(),
          'draftAnalyticsCount': draftAnalyticsCount.count,
          'directCalculation': true,
        }
      };
    } catch (e) {
      debugPrint('Error fetching analytics metadata: $e');
      return {'error': 'Failed to fetch analytics metadata: $e'};
    }
  }
}