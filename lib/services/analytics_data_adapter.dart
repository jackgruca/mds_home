// In lib/services/analytics_data_adapter.dart
import 'package:flutter/material.dart';

class AnalyticsDataAdapter {
  // Adapt position data to a consistent format
  static List<Map<String, dynamic>> adaptPositionData(dynamic rawData) {
    if (rawData == null) return [];
    
    // Handle different possible data formats
    if (rawData is List) {
      return List<Map<String, dynamic>>.from(rawData.map((item) {
        // Ensure each item has the required fields
        final result = Map<String, dynamic>.from(item);
        
        // Add missing fields with defaults if needed
        if (!result.containsKey('pick')) result['pick'] = 0;
        if (!result.containsKey('round')) result['round'] = '1';
        if (!result.containsKey('positions')) result['positions'] = [];
        if (!result.containsKey('totalDrafts')) result['totalDrafts'] = 0;
        
        return result;
      }));
    } else if (rawData is Map) {
      // Handle if it's a map with 'data' field
      if (rawData.containsKey('data') && rawData['data'] is List) {
        return adaptPositionData(rawData['data']);
      }
    }
    
    // Return empty list for unsupported formats
    debugPrint('Unsupported position data format: ${rawData.runtimeType}');
    return [];
  }
  
  // Similar adapters for other data types
  static List<Map<String, dynamic>> adaptPlayerData(dynamic rawData) {
    // Implementation for player data
    // ...
    return [];
  }
  
  static Map<String, List<String>> adaptTeamNeedsData(dynamic rawData) {
    // Implementation for team needs
    // ...
    return {};
  }
}