// lib/services/analytics_aggregation_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

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

  /// Generate optimized data structures for community analytics
  static Future<void> generateOptimizedStructures() async {
    debugPrint('Generating optimized analytics structures...');
    
    try {
      // 1. Generate position trends by round
      await _generatePositionTrendsByRound();
      
      // 2. Generate consensus needs document
      await _generateConsensusNeeds();
      
      debugPrint('Optimized structures generated successfully');
    } catch (e) {
      debugPrint('Error generating optimized structures: $e');
    }
  }
  
  static Future<void> _generatePositionTrendsByRound() async {
    // Process for each round (1-7)
    for (int round = 1; round <= 7; round++) {
      await _generatePositionTrendsForRound(round);
    }
    
    // Also create an "all rounds" document
    await _generatePositionTrendsForRound(null);
  }
  
  static Future<void> _generatePositionTrendsForRound(int? round) async {
  final roundStr = round?.toString() ?? 'all';
  final docId = 'round_$roundStr';
  
  try {
    // Query draft data - we'll filter the picks in memory instead of in the query
    Query query = _firestore.collection('draftAnalytics');
    
    // Limit to most recent data (e.g., last 1000 drafts)
    query = query.orderBy('timestamp', descending: true).limit(1000);
    
    final snapshot = await query.get();
    
    // Process position frequencies
    Map<int, Map<String, int>> pickPositions = {};
    
    for (final doc in snapshot.docs) {
  final data = doc.data();
  
  // Safely check if the data has 'picks' key
  if (data == null || !(data as Map<String, dynamic>).containsKey('picks')) continue;
  
  List<dynamic> rawPicks = data['picks'] as List<dynamic>;
  
  // Process each pick
  for (final rawPick in rawPicks) {
        // Convert pick to map
        final pick = Map<String, dynamic>.from(rawPick as Map);
        
        // Skip if not the round we're looking for
        if (round != null && pick['round'] != round.toString()) {
          continue;
        }
        
        final pickNumber = pick['pickNumber'] as int?;
        final position = pick['position'] as String?;
        
        if (pickNumber != null && position != null) {
          pickPositions[pickNumber] ??= {};
          pickPositions[pickNumber]![position] = (pickPositions[pickNumber]![position] ?? 0) + 1;
        }
      }
    }
    
    // Rest of the method remains the same...
    List<Map<String, dynamic>> positionTrends = [];
    
    pickPositions.forEach((pickNumber, positions) {
      // Calculate total for this pick
      final totalCount = positions.values.fold(0, (sum, count) => sum + count);
      
      // Create position lists sorted by frequency
      final List<Map<String, dynamic>> positionList = positions.entries.map((entry) => {
        'position': entry.key,
        'count': entry.value,
        'percentage': '${((entry.value / totalCount) * 100).toStringAsFixed(1)}%',
      }).toList();
      
      // Sort by count
      positionList.sort((a, b) => (b['count'] as int).compareTo(a['count'] as int));
      
      // Add to trends
      positionTrends.add({
        'pick': pickNumber,
        'round': round?.toString() ?? 'multiple',
        'positions': positionList,
        'totalDrafts': totalCount,
      });
    });
    
    // Sort by pick number
    positionTrends.sort((a, b) => (a['pick'] as int).compareTo(b['pick'] as int));
    
    // Save to Firestore
    await _firestore.collection('position_trends').doc(docId).set({
      'round': roundStr,
      'positions': positionTrends,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    
    debugPrint('Generated position trends for round $roundStr with ${positionTrends.length} picks');
  } catch (e) {
    debugPrint('Error generating position trends for round $roundStr: $e');
  }
}

  static Future<void> _generateConsensusNeeds() async {
  try {
    // Query recent drafts (e.g., last 1000)
    final snapshot = await _firestore
        .collection('draftAnalytics')
        .orderBy('timestamp', descending: true)
        .limit(1000)
        .get();
    
    // Track early round picks (1-3) by team and position
    Map<String, Map<String, int>> teamPositionCounts = {};
    
    for (final doc in snapshot.docs) {
      final data = doc.data();
      
      // Safely check if the data has 'picks' key
      if (!data.containsKey('picks')) continue;
      
      List<dynamic> rawPicks = data['picks'] as List<dynamic>;
      
      for (final rawPick in rawPicks) {
        // Convert to map
        final pick = Map<String, dynamic>.from(rawPick as Map);
        
        final round = int.tryParse(pick['round']?.toString() ?? '0') ?? 0;
        
        // Only consider early rounds
        if (round <= 0 || round > 3) continue;
        
        final team = pick['actualTeam'] as String?;
        final position = pick['position'] as String?;
        
        if (team != null && position != null) {
          teamPositionCounts[team] ??= {};
          
          // Use round-based weighting: R1=3x, R2=2x, R3=1x
          final weight = 4 - round;
          teamPositionCounts[team]![position] = (teamPositionCounts[team]![position] ?? 0) + weight;
        }
      }
    }
      
      // Convert to consensus needs format
      Map<String, List<String>> consensusNeeds = {};
      
      teamPositionCounts.forEach((team, positions) {
        // Sort positions by weighted count
        final sortedPositions = positions.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        
        // Take top 5 positions as needs
        consensusNeeds[team] = sortedPositions
            .take(5)
            .map((e) => e.key)
            .toList();
      });
      
      // Save to Firestore
      await _firestore.collection('consensus_needs').doc('latest').set({
        ...consensusNeeds,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      debugPrint('Generated consensus needs for ${consensusNeeds.length} teams');
    } catch (e) {
      debugPrint('Error generating consensus needs: $e');
    }
  }
}