// lib/services/analytics_aggregation_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'cache_service.dart';

class AnalyticsAggregationService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Store the last aggregation time to prevent excessive runs
  static DateTime? _lastAggregationTime;
  static bool _isAggregating = false;
  
  /// Run daily aggregation if needed (should be called once per app session)
  static Future<bool> runDailyAggregationIfNeeded() async {
    // Check if already aggregated today
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    // Skip if already run today or currently running
    if (_isAggregating) return false;
    if (_lastAggregationTime != null) {
      final lastRun = DateTime(
        _lastAggregationTime!.year,
        _lastAggregationTime!.month,
        _lastAggregationTime!.day
      );
      
      if (lastRun.isAtSameMomentAs(today)) {
        debugPrint('Daily aggregation already run today, skipping');
        return false;
      }
    }
    
    // Check if we already have today's snapshot
    final dateKey = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    
    try {
      final existingSnapshot = await _firestore
          .collection('analytics_daily_snapshots')
          .doc(dateKey)
          .get();
          
      if (existingSnapshot.exists) {
        debugPrint('Daily snapshot for $dateKey already exists, skipping aggregation');
        _lastAggregationTime = now;
        return false;
      }
    } catch (e) {
      debugPrint('Error checking for existing snapshot: $e');
    }
    
    // Start aggregation
    _isAggregating = true;
    debugPrint('Starting daily analytics aggregation');
    
    try {
      // Aggregate yesterday's data
      final yesterday = today.subtract(const Duration(days: 1));
      final result = await aggregateDay(yesterday);
      
      // Update aggregation time
      _lastAggregationTime = now;
      _isAggregating = false;
      
      // Clear relevant caches to force a refresh
      CacheService.clearCacheWithPrefix('all_analytics');
      
      return result;
    } catch (e) {
      debugPrint('Error in daily aggregation: $e');
      _isAggregating = false;
      return false;
    }
  }
  
  /// Aggregate a specific day's data
  static Future<bool> aggregateDay(DateTime date) async {
    final dateKey = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    
    debugPrint('Aggregating analytics for $dateKey');
    
    try {
      // First, check if we already have this day's data
      final existingSnapshot = await _firestore
          .collection('analytics_daily_snapshots')
          .doc(dateKey)
          .get();
          
      if (existingSnapshot.exists) {
        debugPrint('Data for $dateKey already exists, skipping');
        return false;
      }
      
      // 1. Aggregate base metrics (pageviews, users)
      final baseMetrics = await _aggregateBaseMetrics(dateKey);
      
      // 2. Aggregate team position trends
      final teamPositions = await _aggregateTeamPositions(dateKey);
      
      // 3. Aggregate player selection trends
      final playerTrends = await _aggregatePlayerTrends(dateKey);
      
      // 4. Combine all data
      final combinedData = {
        'date': dateKey,
        'timestamp': FieldValue.serverTimestamp(),
        ...baseMetrics,
        'team_positions': teamPositions,
        'player_trends': playerTrends,
      };
      
      // Save to Firestore
      await _firestore
          .collection('analytics_daily_snapshots')
          .doc(dateKey)
          .set(combinedData);
          
      debugPrint('Successfully aggregated analytics for $dateKey');
      return true;
    } catch (e) {
      debugPrint('Error aggregating analytics for $dateKey: $e');
      return false;
    }
  }
  
  /// Aggregate base metrics
  static Future<Map<String, dynamic>> _aggregateBaseMetrics(String dateKey) async {
    // Query raw analytics for the day
    final snapshot = await _firestore
        .collection('analytics')
        .where('date', isEqualTo: dateKey)
        .get();
        
    // Calculate metrics
    int pageViews = 0;
    Set<String> uniqueUsers = {};
    Map<String, int> deviceTypes = {};
    
    for (final doc in snapshot.docs) {
      final data = doc.data();
      
      // Increment page views
      pageViews += (data['pageViews'] as int?) ?? 0;
      
      // Track unique users
      if (data['userId'] != null) {
        uniqueUsers.add(data['userId'] as String);
      }
      
      // Track device types
      if (data['deviceType'] != null) {
        final deviceType = data['deviceType'] as String;
        deviceTypes[deviceType] = (deviceTypes[deviceType] ?? 0) + 1;
      }
    }
    
    return {
      'pageViews': pageViews,
      'uniqueUsers': uniqueUsers.length,
      'deviceTypes': deviceTypes,
    };
  }
  
  /// Aggregate team position trends
  static Future<Map<String, dynamic>> _aggregateTeamPositions(String dateKey) async {
    // Query all draft data for the day
    final snapshot = await _firestore
        .collection('draftAnalytics')
        .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(
          DateTime.parse('${dateKey}T00:00:00Z'))
        )
        .where('timestamp', isLessThan: Timestamp.fromDate(
          DateTime.parse('${dateKey}T23:59:59Z'))
        )
        .get();
        
    // Track team position selections
    Map<String, Map<String, int>> teamPositions = {};
    
    for (final doc in snapshot.docs) {
      final data = doc.data();
      final picks = (data['picks'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      
      for (final pick in picks) {
        final team = pick['actualTeam'] as String?;
        final position = pick['position'] as String?;
        
        if (team != null && position != null) {
          // Initialize team data if needed
          teamPositions[team] ??= {};
          
          // Increment position count
          teamPositions[team]![position] = (teamPositions[team]![position] ?? 0) + 1;
        }
      }
    }
    
    return teamPositions;
  }
  
  /// Aggregate player selection trends
  static Future<Map<String, List<Map<String, dynamic>>>> _aggregatePlayerTrends(String dateKey) async {
    // Query all draft data for the day
    final snapshot = await _firestore
        .collection('draftAnalytics')
        .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(
          DateTime.parse('${dateKey}T00:00:00Z'))
        )
        .where('timestamp', isLessThan: Timestamp.fromDate(
          DateTime.parse('${dateKey}T23:59:59Z'))
        )
        .get();
        
    // Track player selections by pick number
    Map<int, Map<String, int>> playerCounts = {};
    
    for (final doc in snapshot.docs) {
      final data = doc.data();
      final picks = (data['picks'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      
      for (final pick in picks) {
        final pickNumber = pick['pickNumber'] as int?;
        final playerName = pick['playerName'] as String?;
        
        if (pickNumber != null && playerName != null) {
          // Initialize pick data if needed
          playerCounts[pickNumber] ??= {};
          
          // Increment player count
          playerCounts[pickNumber]![playerName] = (playerCounts[pickNumber]![playerName] ?? 0) + 1;
        }
      }
    }
    
    // Convert to proper format
    Map<String, List<Map<String, dynamic>>> result = {};
    
    playerCounts.forEach((pickNumber, players) {
      // Convert to list of player details
      final playerList = players.entries.map((e) => {
        'player': e.key,
        'count': e.value,
      }).toList();
      
      // Sort by count
      playerList.sort((a, b) => (b['count'] as int).compareTo(a['count'] as int));
      
      // Store by pick number
      result[pickNumber.toString()] = playerList;
    });
    
    return result;
  }
}