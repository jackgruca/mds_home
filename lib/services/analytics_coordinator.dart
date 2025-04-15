// In lib/services/analytics_coordinator.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'analytics_cache_manager.dart';
import 'firebase_service.dart';

class AnalyticsCoordinator {
  static const String analyticsStatusKey = 'analytics_processing_status';
  
  // Process different data types in parallel with continuation
  static Future<bool> processAllAnalytics() async {
    try {
      await FirebaseService.initialize();
      final db = FirebaseFirestore.instance;
      
      // Clean up any old processing status
      await db.collection('precomputedAnalytics').doc('metadata').set({
        'processingStarted': FieldValue.serverTimestamp(),
        'inProgress': true,
        'statusMessage': 'Starting multi-phase analytics processing',
        'jobStatus': {
          'positions': 'pending',
          'players': 'pending',
          'teamNeeds': 'pending',
          'deviations': 'pending'
        }
      }, SetOptions(merge: true));
      
      // Kick off position processing
      final positionsResult = await _startPositionProcessing();
      
      // Start player processing in parallel
      final playersResult = await _startPlayerProcessing();
      
      // Process team needs
      final teamNeedsResult = await _processTeamNeeds();
      
      // Process player deviations
      final deviationsResult = await _processPlayerDeviations();
      
      // Update status
      await db.collection('precomputedAnalytics').doc('metadata').set({
        'processingCompleted': FieldValue.serverTimestamp(),
        'inProgress': false,
        'jobStatus': {
          'positions': positionsResult ? 'completed' : 'failed',
          'players': playersResult ? 'completed' : 'failed',
          'teamNeeds': teamNeedsResult ? 'completed' : 'failed',
          'deviations': deviationsResult ? 'completed' : 'failed'
        },
        'statusMessage': 'Processing complete'
      }, SetOptions(merge: true));
      
      // Clear caches to ensure fresh data
      AnalyticsCacheManager.clearCache();
      
      return positionsResult && playersResult && teamNeedsResult && deviationsResult;
    } catch (e) {
      debugPrint('Error in processAllAnalytics: $e');
      return false;
    }
  }
  
  // Kick off position processing with continuation
  static Future<bool> _startPositionProcessing() async {
    try {
      final db = FirebaseFirestore.instance;
      
      // Update status
      await db.collection('precomputedAnalytics').doc('metadata').set({
        'jobStatus': {
          'positions': 'processing'
        }
      }, SetOptions(merge: true));
      
      // Run the first batch and get continuation token
      final result = await _processPositionBatch(null);
      
      // Whether the first batch succeeded
      return !result.containsKey('error');
    } catch (e) {
      debugPrint('Error starting position processing: $e');
      return false;
    }
  }
  
  // Process a batch of positions
  static Future<Map<String, dynamic>> _processPositionBatch(String? token) async {
    // Implementation similar to our existing continuation code
    // ...
    
    // Return a result with continuation token
    return {'continuationToken': 'next_token'};
  }
  
  // Similar methods for player processing, team needs, and deviations
  // ...
  
  // Check analytics processing status
  static Future<Map<String, dynamic>> getProcessingStatus() async {
    try {
      await FirebaseService.initialize();
      final db = FirebaseFirestore.instance;
      
      final doc = await db.collection('precomputedAnalytics').doc('metadata').get();
      if (!doc.exists) {
        return {'status': 'unknown'};
      }
      
      return doc.data() ?? {'status': 'unknown'};
    } catch (e) {
      debugPrint('Error getting processing status: $e');
      return {'status': 'error', 'message': e.toString()};
    }
  }
  
  // Clear dummy data and replace with real data
  static Future<bool> replaceDummyWithRealData() async {
    try {
      await FirebaseService.initialize();
      final db = FirebaseFirestore.instance;
      
      // Identify documents with dummy data
      final metadataDoc = await db.collection('precomputedAnalytics').doc('metadata').get();
      final hasDummyData = metadataDoc.data()?['hasDummyData'] == true;
      
      if (hasDummyData) {
        // Delete all dummy data documents
        for (int round = 1; round <= 7; round++) {
          await db.collection('precomputedAnalytics').doc('positionsByPickRound$round').delete();
        }
        
        // Delete other dummy documents
        await db.collection('precomputedAnalytics').doc('playerDeviations').delete();
        await db.collection('precomputedAnalytics').doc('teamNeeds').delete();
        
        // Update metadata
        await db.collection('precomputedAnalytics').doc('metadata').set({
          'hasDummyData': false,
          'dataCleanupTime': FieldValue.serverTimestamp()
        }, SetOptions(merge: true));
      }
      
      return true;
    } catch (e) {
      debugPrint('Error replacing dummy data: $e');
      return false;
    }
  }
  // Add these methods to your AnalyticsCoordinator class

static Future<bool> _startPlayerProcessing() async {
  try {
    final db = FirebaseFirestore.instance;
    
    // Update status
    await db.collection('precomputedAnalytics').doc('metadata').set({
      'jobStatus': {
        'players': 'processing'
      }
    }, SetOptions(merge: true));
    
    // Process player data (simplified implementation)
    final querySnapshot = await db.collection('draftAnalytics')
        .limit(20)
        .get();
    
    if (querySnapshot.docs.isEmpty) {
      await db.collection('precomputedAnalytics').doc('metadata').set({
        'jobStatus': {
          'players': 'completed',
          'message': 'No data found to process'
        }
      }, SetOptions(merge: true));
      return true;
    }
    
    // Count top players
    Map<String, Map<String, dynamic>> playerCounts = {};
    int totalPicks = 0;
    
    for (var doc in querySnapshot.docs) {
      final data = doc.data();
      final picks = data['picks'];
      
      if (picks != null && picks is List) {
        for (var pick in picks) {
          if (pick is Map && pick.containsKey('playerName') && pick.containsKey('position')) {
            final playerName = pick['playerName'];
            final position = pick['position'];
            final key = '$playerName|$position';
            
            if (!playerCounts.containsKey(key)) {
              playerCounts[key] = {
                'name': playerName,
                'position': position,
                'count': 0
              };
            }
            
            playerCounts[key]!['count'] = (playerCounts[key]!['count'] as int) + 1;
            totalPicks++;
          }
        }
      }
    }
    
    // Convert to list and sort
    final playersList = playerCounts.values.toList()
      ..sort((a, b) => (b['count'] as int).compareTo(a['count'] as int));
    
    // Save top 100 players
    await db.collection('precomputedAnalytics').doc('playersByPick').set({
      'data': playersList.take(100).toList(),
      'totalPicks': totalPicks,
      'lastUpdated': FieldValue.serverTimestamp()
    });
    
    // Update status
    await db.collection('precomputedAnalytics').doc('metadata').set({
      'jobStatus': {
        'players': 'completed'
      }
    }, SetOptions(merge: true));
    
    return true;
  } catch (e) {
    debugPrint('Error in player processing: $e');
    
    // Update status to failed
    final db = FirebaseFirestore.instance;
    await db.collection('precomputedAnalytics').doc('metadata').set({
      'jobStatus': {
        'players': 'failed',
        'error': e.toString()
      }
    }, SetOptions(merge: true));
    
    return false;
  }
}

static Future<bool> _processTeamNeeds() async {
  try {
    final db = FirebaseFirestore.instance;
    
    // Update status
    await db.collection('precomputedAnalytics').doc('metadata').set({
      'jobStatus': {
        'teamNeeds': 'processing'
      }
    }, SetOptions(merge: true));
    
    // Sample team needs data - in a real implementation you'd calculate this from analytics
    final Map<String, List<String>> teamNeeds = {
      'BUF': ['WR', 'DL', 'CB', 'S', 'OT'],
      'MIA': ['OT', 'IOL', 'EDGE', 'LB', 'TE'],
      'NE': ['QB', 'WR', 'OT', 'CB', 'DL'],
      'NYJ': ['OT', 'EDGE', 'RB', 'TE', 'S'],
      'BAL': ['WR', 'CB', 'EDGE', 'RB', 'IOL'],
      'CIN': ['OT', 'TE', 'DL', 'CB', 'S'],
      'CLE': ['WR', 'DL', 'LB', 'EDGE', 'S'],
      'PIT': ['OT', 'CB', 'IOL', 'WR', 'DL'],
    };
    
    await db.collection('precomputedAnalytics').doc('teamNeeds').set({
      'needs': teamNeeds,
      'year': DateTime.now().year,
      'lastUpdated': FieldValue.serverTimestamp()
    });
    
    // Update status
    await db.collection('precomputedAnalytics').doc('metadata').set({
      'jobStatus': {
        'teamNeeds': 'completed'
      }
    }, SetOptions(merge: true));
    
    return true;
  } catch (e) {
    debugPrint('Error in team needs processing: $e');
    
    // Update status to failed
    final db = FirebaseFirestore.instance;
    await db.collection('precomputedAnalytics').doc('metadata').set({
      'jobStatus': {
        'teamNeeds': 'failed',
        'error': e.toString()
      }
    }, SetOptions(merge: true));
    
    return false;
  }
}

static Future<bool> _processPlayerDeviations() async {
  try {
    final db = FirebaseFirestore.instance;
    
    // Update status
    await db.collection('precomputedAnalytics').doc('metadata').set({
      'jobStatus': {
        'deviations': 'processing'
      }
    }, SetOptions(merge: true));
    
    // Get player rank deviations (simplified)
    final querySnapshot = await db.collection('draftAnalytics')
        .limit(20)
        .get();
    
    if (querySnapshot.docs.isEmpty) {
      await db.collection('precomputedAnalytics').doc('metadata').set({
        'jobStatus': {
          'deviations': 'completed',
          'message': 'No data found to process'
        }
      }, SetOptions(merge: true));
      return true;
    }
    
    // Calculate deviations between pick number and rank
    Map<String, Map<String, dynamic>> playerDeviations = {};
    
    for (var doc in querySnapshot.docs) {
      final data = doc.data();
      final picks = data['picks'];
      
      if (picks != null && picks is List) {
        for (var pick in picks) {
          if (pick is Map && 
              pick.containsKey('playerName') && 
              pick.containsKey('position') &&
              pick.containsKey('pickNumber') &&
              pick.containsKey('playerRank')) {
            
            final playerName = pick['playerName'];
            final position = pick['position'];
            final pickNumber = pick['pickNumber'] is int ? pick['pickNumber'] : int.tryParse(pick['pickNumber'].toString()) ?? 0;
            final playerRank = pick['playerRank'] is int ? pick['playerRank'] : int.tryParse(pick['playerRank'].toString()) ?? 0;
            
            // Skip invalid data
            if (pickNumber <= 0 || playerRank <= 0) continue;
            
            // Calculate deviation (positive means drafted later than rank)
            final deviation = pickNumber - playerRank;
            final key = '$playerName|$position';
            
            if (!playerDeviations.containsKey(key)) {
              playerDeviations[key] = {
                'name': playerName,
                'position': position,
                'deviations': <double>[],
                'school': pick['school'] ?? 'Unknown'
              };
            }
            
            playerDeviations[key]!['deviations'] = [
              ...playerDeviations[key]!['deviations'] as List<double>,
              deviation.toDouble()
            ];
          }
        }
      }
    }
    
    // Calculate average deviations
    List<Map<String, dynamic>> avgDeviations = [];
    
    for (var entry in playerDeviations.entries) {
      final deviations = entry.value['deviations'] as List<double>;
      
      // Skip players with too few data points
      if (deviations.length < 2) continue;
      
      final sum = deviations.fold<double>(0, (prev, d) => prev + d);
      final avg = sum / deviations.length;
      
      avgDeviations.add({
        'name': entry.value['name'],
        'position': entry.value['position'],
        'avgDeviation': avg.toStringAsFixed(1),
        'sampleSize': deviations.length,
        'school': entry.value['school']
      });
    }
    
    // Sort by absolute deviation value (largest first)
    avgDeviations.sort((a, b) => 
      double.parse(b['avgDeviation'].toString()).abs().compareTo(
        double.parse(a['avgDeviation'].toString()).abs()
      )
    );
    
    // Save to Firestore
    await db.collection('precomputedAnalytics').doc('playerDeviations').set({
      'players': avgDeviations,
      'sampleSize': querySnapshot.size,
      'lastUpdated': FieldValue.serverTimestamp()
    });
    
    // Update status
    await db.collection('precomputedAnalytics').doc('metadata').set({
      'jobStatus': {
        'deviations': 'completed'
      }
    }, SetOptions(merge: true));
    
    return true;
  } catch (e) {
    debugPrint('Error in player deviations processing: $e');
    
    // Update status to failed
    final db = FirebaseFirestore.instance;
    await db.collection('precomputedAnalytics').doc('metadata').set({
      'jobStatus': {
        'deviations': 'failed',
        'error': e.toString()
      }
    }, SetOptions(merge: true));
    
    return false;
  }
}
}