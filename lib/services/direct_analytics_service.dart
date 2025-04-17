// lib/services/direct_analytics_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../services/firebase_service.dart';
import '../services/analytics_cache_manager.dart';

/// Service to directly query analytics data from existing collections
/// This is a temporary solution until the precomputedAnalytics collection is populated
class DirectAnalyticsService {
  // Use caching to reduce database reads
  static Future<Map<String, dynamic>> getPositionTrendsByRound({
    required int round,
    String? team,
  }) async {
    final cacheKey = 'direct_positions_round${round}_${team ?? 'all'}';
    
    return AnalyticsCacheManager.getCachedData(
      cacheKey,
      () => _queryPositionTrendsByRound(round, team),
      expiry: const Duration(minutes: 10), // Short cache time for development
    );
  }

  static Future<Map<String, dynamic>> _queryPositionTrendsByRound(int round, String? team) async {
    try {
      // Ensure Firebase is initialized
      if (!FirebaseService.isInitialized) {
        await FirebaseService.initialize();
      }
      
      final db = FirebaseFirestore.instance;
      final roundDoc = await db.collection('position_trends').doc('round_$round').get();
      
      if (!roundDoc.exists) {
        debugPrint('No data found for round $round');
        return {'error': 'Data not found'};
      }
      
      Map<String, dynamic> data = roundDoc.data() ?? {};
      
      // Process the data to match the expected format from precomputedAnalytics
      List<Map<String, dynamic>> processedData = [];
      
      // Extract the positions data from your existing structure
      // This assumes your data is in the form of {pick: {positions: [...], ...}, ...}
      data.forEach((key, value) {
        if (key == 'positions') {
          // Handle the case where positions is a list at the top level
          List<Map<String, dynamic>> positionsList = [];
          
          if (value is List) {
            for (var pos in value) {
              if (pos is Map) {
                positionsList.add(Map<String, dynamic>.from(pos));
              }
            }
          } else if (value is Map) {
            // Handle the case where positions is a map at the top level
            value.forEach((posKey, posValue) {
              if (posValue is Map) {
                positionsList.add({
                  'position': posKey,
                  'count': posValue['count'] ?? 0,
                  'percentage': posValue['percentage'] ?? '0%',
                });
              }
            });
          }
          
          processedData.add({
            'pick': 1, // Default pick number if not specified
            'round': round.toString(),
            'positions': positionsList,
            'totalDrafts': positionsList.isNotEmpty ? 
                (positionsList.first['count'] as int) * 100 ~/ (int.tryParse(positionsList.first['percentage'].toString().replaceAll('%', '')) ?? 1) : 1,
          });
        } else if (int.tryParse(key) != null) {
          // This is a pick number
          int pickNumber = int.parse(key);
          List<Map<String, dynamic>> positionsList = [];
          
          if (value is Map && value.containsKey('positions')) {
            var positions = value['positions'];
            if (positions is List) {
              for (var pos in positions) {
                if (pos is Map) {
                  positionsList.add(Map<String, dynamic>.from(pos));
                }
              }
            } else if (positions is Map) {
              positions.forEach((posKey, posValue) {
                if (posValue is Map) {
                  positionsList.add({
                    'position': posKey,
                    'count': posValue['count'] ?? 0,
                    'percentage': posValue['percentage'] ?? '0%',
                  });
                }
              });
            }
          }
          
          processedData.add({
            'pick': pickNumber,
            'round': round.toString(),
            'positions': positionsList,
            'totalDrafts': value['totalDrafts'] ?? 
                (positionsList.isNotEmpty ? 
                    (positionsList.first['count']) * 100 ~/ int.tryParse(positionsList.first['percentage'].toString().replaceAll('%', '')) ?? 1 : 1),
          });
        }
      });
      
      // Sort by pick number
      processedData.sort((a, b) => a['pick'].compareTo(b['pick']));
      
      // Filter by team if specified
      if (team != null && team != 'All Teams') {
        // This requires team-specific data, which might not be available
        // For now, we'll return the general data
      }
      
      return {'data': processedData};
    } catch (e) {
      debugPrint('Error querying position trends: $e');
      return {'error': 'Failed to query position trends: $e'};
    }
  }

  /// Get team needs from draft analytics
  static Future<Map<String, List<String>>> getTeamNeeds({int? year}) async {
    final cacheKey = 'direct_team_needs_${year ?? 'all'}';
    
    return AnalyticsCacheManager.getCachedData(
      cacheKey,
      () => _queryTeamNeeds(year),
      expiry: const Duration(minutes: 10), // Short cache time for development
    );
  }

  static Future<Map<String, List<String>>> _queryTeamNeeds(int? year) async {
    try {
      // Ensure Firebase is initialized
      if (!FirebaseService.isInitialized) {
        await FirebaseService.initialize();
      }
      
      final db = FirebaseFirestore.instance;
      
      // Try to get team needs from consensus_needs collection first
      try {
        final needsDoc = await db.collection('consensus_needs').doc('needs').get();
        if (needsDoc.exists && needsDoc.data() != null) {
          Map<String, dynamic> needsData = needsDoc.data()!;
          Map<String, List<String>> result = {};
          
          needsData.forEach((team, needs) {
            if (needs is List) {
              result[team] = List<String>.from(needs);
            }
          });
          
          if (result.isNotEmpty) {
            return result;
          }
        }
      } catch (e) {
        debugPrint('Error fetching from consensus_needs: $e');
        // Continue to alternative method
      }
      
      // Alternative: Analyze draft analytics data to infer team needs
      Map<String, List<String>> teamNeeds = {};
      Map<String, Map<String, int>> teamPositionCounts = {};
      
      // Query limited draft analytics to avoid excessive reads
      Query query = db.collection('draftAnalytics').limit(100);
      if (year != null) {
        query = query.where('year', isEqualTo: year);
      }
      
      final snapshot = await query.get();
      
      for (var doc in snapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        List<dynamic> picks = data['picks'] ?? [];
        
        // Process early round picks (1-3) with higher weight
        for (var pick in picks) {
          int round = int.tryParse(pick['round'] ?? '0') ?? 0;
          if (round > 3) continue; // Only consider early rounds
          
          String team = pick['actualTeam'] ?? '';
          String position = pick['position'] ?? '';
          
          if (team.isEmpty || position.isEmpty) continue;
          
          // Initialize data structures
          teamPositionCounts[team] ??= {};
          
          // Apply round weighting
          int weight = 4 - round; // Round 1 = 3, Round 2 = 2, Round 3 = 1
          teamPositionCounts[team]![position] = 
              (teamPositionCounts[team]![position] ?? 0) + weight;
        }
      }
      
      // Convert to team needs (most frequent positions)
      for (var entry in teamPositionCounts.entries) {
        String team = entry.key;
        Map<String, int> positionCounts = entry.value;
        
        // Convert to sorted list by count
        List<MapEntry<String, int>> sortedPositions = positionCounts.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        
        // Take top 5 positions as team needs
        teamNeeds[team] = sortedPositions.take(5).map((e) => e.key).toList();
      }
      
      return teamNeeds;
    } catch (e) {
      debugPrint('Error querying team needs: $e');
      return {}; // Return empty map on error
    }
  }

  /// Get position distribution aggregated from draft analytics
  static Future<Map<String, dynamic>> getPositionDistribution({
    String? team,
    List<int>? rounds,
    int? year,
  }) async {
    final cacheKey = 'direct_position_distribution_${team ?? 'all'}_${rounds?.join('_') ?? 'all'}_${year ?? 'all'}';
    
    return AnalyticsCacheManager.getCachedData(
      cacheKey,
      () => _queryPositionDistribution(team, rounds, year),
      expiry: const Duration(minutes: 10), // Short cache time for development
    );
  }

  static Future<Map<String, dynamic>> _queryPositionDistribution(
    String? team,
    List<int>? rounds,
    int? year,
  ) async {
    try {
      // Ensure Firebase is initialized
      if (!FirebaseService.isInitialized) {
        await FirebaseService.initialize();
      }
      
      final db = FirebaseFirestore.instance;
      Map<String, int> positionCounts = {};
      int totalPicks = 0;
      
      // First try to get from position_trends if available
      try {
        DocumentSnapshot? doc;
        if (rounds != null && rounds.length == 1) {
          // Specific round
          doc = await db.collection('position_trends').doc('round_${rounds[0]}').get();
        } else {
          // All rounds
          doc = await db.collection('position_trends').doc('round_all').get();
        }
        
        if (doc.exists && doc.data() != null) {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          
          // Process the position data if it's in the expected format
          if (data.containsKey('positions')) {
            var positions = data['positions'];
            
            if (positions is Map) {
              positions.forEach((pos, info) {
                if (info is Map && info.containsKey('count')) {
                  positionCounts[pos] = info['count'];
                  totalPicks += (info['count'] as num).toInt();
                }
              });
              
              // Return the formatted result
              Map<String, dynamic> result = {
                'total': totalPicks,
                'positions': {}
              };
              
              positionCounts.forEach((position, count) {
                result['positions'][position] = {
                  'count': count,
                  'percentage': '${((count / totalPicks) * 100).toStringAsFixed(1)}%'
                };
              });
              
              return result;
            }
          }
        }
      } catch (e) {
        debugPrint('Error fetching from position_trends: $e');
        // Continue to alternative method
      }
      
      // Alternative: Query draft analytics directly
      Query query = db.collection('draftAnalytics').limit(100);
      if (year != null) {
        query = query.where('year', isEqualTo: year);
      }
      
      final snapshot = await query.get();
      
      for (var doc in snapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        List<dynamic> picks = data['picks'] ?? [];
        
        for (var pick in picks) {
          // Apply round filter if specified
          if (rounds != null) {
            int pickRound = int.tryParse(pick['round'] ?? '0') ?? 0;
            if (!rounds.contains(pickRound)) continue;
          }
          
          // Apply team filter if specified
          if (team != null && team != 'All Teams') {
            String pickTeam = pick['actualTeam'] ?? '';
            if (pickTeam != team) continue;
          }
          
          String position = pick['position'] ?? '';
          if (position.isEmpty) continue;
          
          positionCounts[position] = (positionCounts[position] ?? 0) + 1;
          totalPicks++;
        }
      }
      
      // Format result
      Map<String, dynamic> result = {
        'total': totalPicks,
        'positions': {}
      };
      
      positionCounts.forEach((position, count) {
        result['positions'][position] = {
          'count': count,
          'percentage': '${((count / totalPicks) * 100).toStringAsFixed(1)}%'
        };
      });
      
      return result;
    } catch (e) {
      debugPrint('Error querying position distribution: $e');
      return {'total': 0, 'positions': {}};
    }
  }
}