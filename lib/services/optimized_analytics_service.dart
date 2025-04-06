// lib/services/optimized_analytics_service.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'cache_service.dart';

class OptimizedAnalyticsService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  static Future<Map<String, dynamic>> getDailyUsage({DateTime? date}) async {
    date ??= DateTime.now();
    final String dateKey = '${date.year}-${date.month}-${date.day}';
    
    // Check cache first
    final cacheKey = 'daily_usage_$dateKey';
    final cachedData = CacheService.getData(cacheKey);
    if (cachedData != null) {
      return cachedData;
    }
    
    try {
      final snapshot = await _firestore
          .collection('analytics')
          .where('date', isEqualTo: dateKey)
          .limit(1)
          .get();
      
      if (snapshot.docs.isEmpty) {
        final emptyData = {'pageViews': 0, 'uniqueUsers': 0};
        CacheService.setData(cacheKey, emptyData);
        return emptyData;
      }
      
      final data = snapshot.docs.first.data();
      
      // Store in cache
      CacheService.setData(cacheKey, data);
      
      return data;
    } catch (e) {
      debugPrint('Error getting daily usage: $e');
      return {'error': e.toString()};
    }
  }
  
  static Future<List<Map<String, dynamic>>> getWeeklyTrend() async {
    const cacheKey = 'weekly_trend';
    final cachedData = CacheService.getData(cacheKey);
    if (cachedData != null) {
      return List<Map<String, dynamic>>.from(cachedData);
    }
    
    try {
      // Calculate date range for the past week
      final now = DateTime.now();
      final oneWeekAgo = now.subtract(const Duration(days: 7));
      
      final query = await _firestore
          .collection('analytics')
          .where('timestamp', isGreaterThanOrEqualTo: oneWeekAgo.millisecondsSinceEpoch)
          .orderBy('timestamp')
          .limit(10) // Add limit to prevent excessive reads
          .get();
      
      final trend = query.docs.map((doc) => doc.data()).toList();
      
      // Store in cache
      CacheService.setData(cacheKey, trend);
      
      return trend;
    } catch (e) {
      debugPrint('Error getting weekly trend: $e');
      return [];
    }
  }
  
  static Future<Map<String, dynamic>> getTeamAnalytics(String teamName) async {
    final cacheKey = 'team_analytics_$teamName';
    final cachedData = CacheService.getData(cacheKey);
    if (cachedData != null) {
      return cachedData;
    }
    
    try {
      final snapshot = await _firestore
          .collection('team_analytics')
          .where('team', isEqualTo: teamName)
          .limit(1)
          .get();
      
      if (snapshot.docs.isEmpty) {
        return {};
      }
      
      final data = snapshot.docs.first.data();
      
      // Store in cache
      CacheService.setData(cacheKey, data);
      
      return data;
    } catch (e) {
      debugPrint('Error getting team analytics: $e');
      return {'error': e.toString()};
    }
  }
  
  // Add pagination for analytics dashboard
  static Future<List<Map<String, dynamic>>> getPaginatedAnalytics({
    required String metric,
    int limit = 10,
    DocumentSnapshot? lastDocument,
  }) async {
    try {
      Query query = _firestore
          .collection('analytics')
          .orderBy('timestamp', descending: true);
      
      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }
      
      query = query.limit(limit);
      
      final snapshot = await query.get();
      
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();
      
    } catch (e) {
      debugPrint('Error getting paginated analytics: $e');
      return [];
    }
  }
  // Add to lib/services/optimized_analytics_service.dart

static Future<Map<String, dynamic>> getDailySnapshot({DateTime? date}) async {
  date ??= DateTime.now();
  final String dateKey = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  
  final cacheKey = 'daily_snapshot_$dateKey';
  final cachedData = CacheService.getData(cacheKey);
  if (cachedData != null) {
    return cachedData;
  }
  
  try {
    final snapshot = await _firestore
        .collection('analytics_daily_snapshots')
        .doc(dateKey)
        .get();
        
    if (!snapshot.exists) {
      return {};
    }
    
    final data = snapshot.data() as Map<String, dynamic>;
    
    // Cache the result
    CacheService.setData(cacheKey, data);
    
    return data;
  } catch (e) {
    debugPrint('Error getting daily snapshot: $e');
    return {};
  }
}

static Future<List<Map<String, dynamic>>> getRecentDailySnapshots(int days) async {
  final cacheKey = 'recent_snapshots_$days';
  final cachedData = CacheService.getData(cacheKey);
  if (cachedData != null) {
    return List<Map<String, dynamic>>.from(cachedData);
  }
  
  try {
    // Generate date strings for the last X days
    final dateStrings = List.generate(days, (index) {
      final date = DateTime.now().subtract(Duration(days: index));
      return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    });
    
    // Firestore limits 'in' queries to 10 items, so batch if needed
    List<Map<String, dynamic>> results = [];
    
    for (int i = 0; i < dateStrings.length; i += 10) {
      final batch = dateStrings.skip(i).take(10).toList();
      
      final snapshot = await _firestore
          .collection('analytics_daily_snapshots')
          .where(FieldPath.documentId, whereIn: batch)
          .get();
          
      results.addAll(snapshot.docs.map((doc) => doc.data()).toList());
    }
    
    // Sort by date
    results.sort((a, b) => b['date'].compareTo(a['date']));
    
    // Cache the results
    CacheService.setData(cacheKey, results);
    
    return results;
  } catch (e) {
    debugPrint('Error getting recent snapshots: $e');
    return [];
  }
}
}