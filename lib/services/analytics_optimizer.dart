// lib/services/analytics_optimizer.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';

class AnalyticsOptimizer {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _aggregatedCollectionName = 'aggregated_analytics';

  /// Process and optimize all analytics data into pre-computed formats
  static Future<bool> runFullOptimization() async {
    try {
      debugPrint('Starting full analytics optimization...');
      
      // Record start time
      final startTime = DateTime.now();
      
      // 1. Process position trends by round
      await _optimizePositionTrends();
      
      // 2. Process team needs consensus
      await _optimizeTeamNeeds();
      
      // 3. Process player value analysis
      await _optimizePlayerAnalysis();
      
      // 4. Create a single document with versioned timestamp for all common queries
      await _createQuickAccessDocument();
      
      // Record optimization metadata
      final duration = DateTime.now().difference(startTime);
      await _firestore.collection(_aggregatedCollectionName).doc('meta').set({
        'lastOptimized': FieldValue.serverTimestamp(),
        'optimizationDurationMs': duration.inMilliseconds,
        'version': '1.0',
        'status': 'success'
      });
      
      debugPrint('Analytics optimization completed in ${duration.inSeconds} seconds');
      return true;
    } catch (e) {
      debugPrint('Error during analytics optimization: $e');
      
      // Record failure
      await _firestore.collection(_aggregatedCollectionName).doc('meta').set({
        'lastOptimized': FieldValue.serverTimestamp(),
        'status': 'failed',
        'error': e.toString()
      });
      
      return false;
    }
  }

  /// Optimize position trends data
  static Future<void> _optimizePositionTrends() async {
    // Get raw draft data - limit to recent data for performance (e.g., last 2000 drafts)
    final draftData = await _firestore
        .collection('draftAnalytics')
        .orderBy('timestamp', descending: true)
        .limit(2000)
        .get();
        
    // Process data by round
    Map<String, Map<int, Map<String, Map<String, dynamic>>>> roundPositionData = {};
    
    // Initialize data structure for all rounds (1-7 + "all")
    for (int round = 1; round <= 7; round++) {
      roundPositionData[round.toString()] = {};
    }
    roundPositionData['all'] = {};
    
    // Process each draft
    for (final doc in draftData.docs) {
      final data = doc.data();
      final picks = List<Map<String, dynamic>>.from(data['picks'] ?? []);
      
      for (final pickData in picks) {
        // Process by pick number and position
        final round = pickData['round']?.toString() ?? '1';
        final pickNumber = pickData['pickNumber'] as int? ?? 0;
        final position = pickData['position'] as String? ?? 'Unknown';
        
        // Skip invalid data
        if (pickNumber <= 0 || position == 'Unknown') continue;
        
        // Process for specific round
        if (roundPositionData.containsKey(round)) {
          // Initialize pick data if needed
          roundPositionData[round]![pickNumber] ??= {};
          roundPositionData[round]![pickNumber]![position] ??= {
            'count': 0,
            'percentage': '0%',
          };
          
          // Increment position count
          roundPositionData[round]![pickNumber]![position]!['count'] = 
              (roundPositionData[round]![pickNumber]![position]!['count'] as int) + 1;
        }
        
        // Also process for "all" rounds
        roundPositionData['all']![pickNumber] ??= {};
        roundPositionData['all']![pickNumber]![position] ??= {
          'count': 0,
          'percentage': '0%',
        };
        
        // Increment position count for "all" rounds
        roundPositionData['all']![pickNumber]![position]!['count'] = 
            (roundPositionData['all']![pickNumber]![position]!['count'] as int) + 1;
      }
    }
    
    // Process percentages and format data for each round
    Map<String, List<Map<String, dynamic>>> finalPositionTrends = {};
    
    roundPositionData.forEach((round, pickData) {
      finalPositionTrends[round] = [];
      
      pickData.forEach((pickNumber, positionData) {
        // Calculate total picks for this pick number
        int totalPicks = 0;
        positionData.forEach((_, data) {
          totalPicks += (data['count'] as int);
        });
        
        // Calculate percentages
        positionData.forEach((pos, data) {
          data['percentage'] = '${((data['count'] as int) / totalPicks * 100).toStringAsFixed(1)}%';
        });
        
        // Sort positions by count
        final sortedPositions = positionData.entries.toList()
          ..sort((a, b) => (b.value['count'] as int).compareTo(a.value['count'] as int));
        
        // Format for storage
        finalPositionTrends[round]!.add({
          'pick': pickNumber,
          'round': round,
          'positions': sortedPositions.map((e) => {
            'position': e.key,
            'count': e.value['count'],
            'percentage': e.value['percentage'],
          }).toList(),
          'totalDrafts': totalPicks,
        });
      });
      
      // Sort by pick number
      finalPositionTrends[round]!.sort((a, b) => (a['pick'] as int).compareTo(b['pick'] as int));
    });
    
    // Store optimized data
    for (final round in finalPositionTrends.keys) {
      await _firestore.collection(_aggregatedCollectionName).doc('position_trends_$round').set({
        'data': finalPositionTrends[round],
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  /// Optimize team needs consensus data
  static Future<void> _optimizeTeamNeeds() async {
    // Get raw draft data - focus on recent data
    final draftData = await _firestore
        .collection('draftAnalytics')
        .orderBy('timestamp', descending: true)
        .limit(2000)
        .get();
        
    // Track early round picks (1-3) by team and position
    Map<String, Map<String, int>> teamPositionCounts = {};
    
    // Process each draft
    for (final doc in draftData.docs) {
      final data = doc.data();
      final picks = List<Map<String, dynamic>>.from(data['picks'] ?? []);
      
      for (final pickData in picks) {
        final round = int.tryParse(pickData['round']?.toString() ?? '0') ?? 0;
        
        // Only consider early rounds
        if (round <= 0 || round > 3) continue;
        
        final team = pickData['actualTeam'] as String? ?? '';
        final position = pickData['position'] as String? ?? '';
        
        // Skip invalid data
        if (team.isEmpty || position.isEmpty) continue;
        
        // Initialize team data if needed
        teamPositionCounts[team] ??= {};
        
        // Use round-based weighting: R1=3x, R2=2x, R3=1x
        final weight = 4 - round;
        teamPositionCounts[team]![position] = (teamPositionCounts[team]![position] ?? 0) + weight;
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
    
    // Store optimized consensus needs
    await _firestore.collection(_aggregatedCollectionName).doc('consensus_needs').set({
      'needs': consensusNeeds,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Optimize player value analysis data
  static Future<void> _optimizePlayerAnalysis() async {
    // Get raw draft data
    final draftData = await _firestore
        .collection('draftAnalytics')
        .orderBy('timestamp', descending: true)
        .limit(2000)
        .get();
        
    // Track player value differentials
    Map<String, List<int>> playerDeviations = {};
    Map<String, Map<String, dynamic>> playerDetails = {};
    
    // Process each draft
    for (final doc in draftData.docs) {
      final data = doc.data();
      final picks = List<Map<String, dynamic>>.from(data['picks'] ?? []);
      
      for (final pickData in picks) {
        final pickNumber = pickData['pickNumber'] as int? ?? 0;
        final rank = pickData['playerRank'] as int? ?? 0;
        
        // Skip invalid data
        if (pickNumber <= 0 || rank <= 0) continue;
        
        // Calculate value differential (positive = value pick, negative = reach)
        final diff = pickNumber - rank;
        
        // Use player name and position as key
        final playerName = pickData['playerName'] as String? ?? '';
        final position = pickData['position'] as String? ?? '';
        if (playerName.isEmpty || position.isEmpty) continue;
        
        final key = '$playerName|$position';
        
        // Store value differential
        playerDeviations[key] ??= [];
        playerDeviations[key]!.add(diff);
        
        // Store player details
        playerDetails[key] ??= {
          'name': playerName,
          'position': position,
          'school': pickData['school'] ?? '',
        };
      }
    }
    
    // Calculate average deviations
    Map<String, Map<String, dynamic>> valueAnalysis = {};
    
    // Process risers (positive value)
    List<Map<String, dynamic>> risers = [];
    List<Map<String, dynamic>> fallers = [];
    
    playerDeviations.forEach((key, diffs) {
      // Need at least 3 data points for statistical significance
      if (diffs.length < 3) return;
      
      // Calculate average
      final sum = diffs.reduce((a, b) => a + b);
      final avg = sum / diffs.length;
      
      // Get player details
      final details = playerDetails[key]!;
      
      // Create analysis entry
      final analysisEntry = {
        'name': details['name'],
        'position': details['position'],
        'school': details['school'],
        'avgDeviation': avg,
        'sampleSize': diffs.length,
      };
      
      // Add to appropriate list
      if (avg > 0) {
        risers.add(analysisEntry);
      } else if (avg < 0) {
        fallers.add(analysisEntry);
      }
    });
    
    // Sort lists
    risers.sort((a, b) => (b['avgDeviation'] as double).compareTo(a['avgDeviation'] as double));
    fallers.sort((a, b) => (a['avgDeviation'] as double).compareTo(b['avgDeviation'] as double));
    
    // Store optimized value analysis
    await _firestore.collection(_aggregatedCollectionName).doc('player_value_analysis').set({
      'risers': risers,
      'fallers': fallers,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Create a single quick-access document with all common data
  static Future<void> _createQuickAccessDocument() async {
    // Get all the aggregated data
    final positionTrendsRound1 = await _firestore.collection(_aggregatedCollectionName).doc('position_trends_1').get();
    final consensusNeeds = await _firestore.collection(_aggregatedCollectionName).doc('consensus_needs').get();
    final playerValueAnalysis = await _firestore.collection(_aggregatedCollectionName).doc('player_value_analysis').get();
    
    // Combine into a single document with all common queries
    Map<String, dynamic> quickAccess = {
      'version': '1.0',
      'updatedAt': FieldValue.serverTimestamp(),
      'firstRoundTrends': positionTrendsRound1.exists ? (positionTrendsRound1.data() != null ? positionTrendsRound1.data()!['data'] : []) : [],
      'consensusNeeds': consensusNeeds.exists ? (consensusNeeds.data() != null ? consensusNeeds.data()!['needs'] : {}) : {},
      'topValuePlayers': playerValueAnalysis.exists ? {
        'risers': (playerValueAnalysis.data()?['risers'] as List?)?.take(10).toList() ?? [],
        'fallers': (playerValueAnalysis.data()?['fallers'] as List?)?.take(10).toList() ?? [],
      } : {'risers': [], 'fallers': []},
    };
    
    // Store the quick access document
    await _firestore.collection(_aggregatedCollectionName).doc('quick_access').set(quickAccess);
    
    // Also store as JSON string for even faster access
    await _firestore.collection(_aggregatedCollectionName).doc('quick_access_json').set({
      'json': jsonEncode(quickAccess),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}