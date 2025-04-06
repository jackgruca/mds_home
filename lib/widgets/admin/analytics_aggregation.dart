// lib/admin/analytics_aggregation.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AnalyticsAggregation {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  /// One-time function to aggregate historical analytics data 
  /// Run this from an admin panel or developer tool
  static Future<void> aggregateHistoricalData(int daysBack) async {
    // Process the last X days
    for (int i = 0; i < daysBack; i++) {
      final date = DateTime.now().subtract(Duration(days: i));
      await aggregateDayData(date);
    }
  }
  
  /// Aggregate a specific day's data
  static Future<void> aggregateDayData(DateTime date) async {
    final dateKey = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    
    debugPrint('Aggregating data for $dateKey');
    
    try {
      // Check if we already have this day's data
      final existingSnapshot = await _firestore
          .collection('analytics_daily_snapshots')
          .doc(dateKey)
          .get();
          
      if (existingSnapshot.exists) {
        debugPrint('Data for $dateKey already exists, skipping');
        return;
      }
      
      // Query all analytics entries for this day
      final analyticsQuery = await _firestore
          .collection('analytics')
          .where('date', isEqualTo: dateKey)
          .get();
          
      if (analyticsQuery.docs.isEmpty) {
        debugPrint('No data found for $dateKey');
        return;
      }
      
      // Aggregate the data
      int pageViews = 0;
      Set<String> uniqueUsers = {};
      Map<String, int> teamViews = {};
      Map<String, int> deviceTypes = {};
      Map<String, int> pageViewCounts = {};
      
      for (final doc in analyticsQuery.docs) {
        final data = doc.data();
        
        // Count page views
        final views = data['pageViews'] ?? 0;
        pageViews += (views as int);
        
        // Count unique users
        if (data.containsKey('userId') && data['userId'] != null) {
          uniqueUsers.add(data['userId']);
        }
        
        // Count team views
        if (data.containsKey('team') && data['team'] != null) {
          final team = data['team'];
          teamViews[team] = (teamViews[team] ?? 0) + 1;
        }
        
        // Count device types
        if (data.containsKey('deviceType') && data['deviceType'] != null) {
          final deviceType = data['deviceType'];
          deviceTypes[deviceType] = (deviceTypes[deviceType] ?? 0) + 1;
        }
        
        // Count page views by URL
        if (data.containsKey('page') && data['page'] != null) {
          final page = data['page'];
          pageViewCounts[page] = (pageViewCounts[page] ?? 0) + 1;
        }
      }
      
      // Sort pages by view count and take top 10
      final sortedPages = pageViewCounts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      final mostViewedPages = sortedPages.take(10).map((e) => {
        'page': e.key,
        'views': e.value
      }).toList();
      
      // Create the snapshot document
      await _firestore.collection('analytics_daily_snapshots').doc(dateKey).set({
        'date': dateKey,
        'pageViews': pageViews,
        'uniqueUsers': uniqueUsers.length,
        'teamViews': teamViews,
        'deviceTypes': deviceTypes,
        'mostViewedPages': mostViewedPages,
        'aggregatedAt': FieldValue.serverTimestamp(),
      });
      
      debugPrint('Successfully aggregated data for $dateKey');
    } catch (e) {
      debugPrint('Error aggregating data for $dateKey: $e');
    }
  }
}