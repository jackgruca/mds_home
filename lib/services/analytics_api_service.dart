// lib/services/analytics_api_service.dart
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import '../services/analytics_cache_manager.dart';

class AnalyticsApiService {
  static final FirebaseFunctions _functions = FirebaseFunctions.instance;
  
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
  
  static Future<Map<String, dynamic>> _fetchFromApi(
    String dataType,
    Map<String, dynamic>? filters,
  ) async {
    try {
      debugPrint('Fetching $dataType from analytics API with filters: $filters');
      
      final callable = _functions.httpsCallable('getAnalyticsData');
      
      final result = await callable.call({
        'dataType': dataType,
        'filters': filters,
      });
      
      final data = Map<String, dynamic>.from(result.data);
      
      // Check for errors
      if (data.containsKey('error')) {
        debugPrint('API error: ${data['error']}');
        return {'error': data['error']};
      }
      
      debugPrint('Successfully fetched data from analytics API: $dataType');
      return data;
    } catch (e) {
      debugPrint('Error fetching data from analytics API: $e');
      return {'error': 'Failed to fetch analytics data: $e'};
    }
  }
  
  /// Get metadata about the analytics cache
  static Future<Map<String, dynamic>> getAnalyticsMetadata() async {
    try {
      final HttpsCallable callable = _functions.httpsCallable('getAnalyticsData');
      
      final result = await callable.call({
        'dataType': null,
      });
      
      return Map<String, dynamic>.from(result.data);
    } catch (e) {
      debugPrint('Error fetching analytics metadata: $e');
      return {'error': 'Failed to fetch analytics metadata: $e'};
    }
  }
}