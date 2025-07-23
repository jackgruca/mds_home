import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../models/draft/historical_draft_pick.dart';

class HistoricalDraftService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'draftPicks';
  static const int _pageSize = 50;

  // Cache for team list, years, positions, and schools
  static List<String>? _cachedTeams;
  static List<int>? _cachedYears;
  static List<String>? _cachedPositions;
  static List<String>? _cachedSchools;

  /// Get available teams from the draft data
  static Future<List<String>> getAvailableTeams() async {
    if (_cachedTeams != null) {
      return _cachedTeams!;
    }

    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .get();

      final teams = <String>{};
      for (var doc in querySnapshot.docs) {
        final team = doc.data()['team'] as String?;
        if (team != null && team.isNotEmpty) {
          teams.add(team);
        }
      }

      _cachedTeams = teams.toList()..sort();
      return _cachedTeams!;
    } catch (e) {
      debugPrint('Error fetching available teams: $e');
      return [];
    }
  }

  /// Get available years from the draft data
  static Future<List<int>> getAvailableYears() async {
    if (_cachedYears != null) {
      return _cachedYears!;
    }

    try {
      // First check what years actually exist in the data - remove limit to get ALL data
      final querySnapshot = await _firestore
          .collection(_collection)
          .get();

      final existingYears = <int>{};
      for (var doc in querySnapshot.docs) {
        final year = doc.data()['year'] as int?;
        if (year != null) {
          existingYears.add(year);
        }
      }

      debugPrint('🗓️ Years found in database: ${existingYears.toList()..sort()}');
      debugPrint('📊 Total documents processed: ${querySnapshot.docs.length}');

      // If we have limited data, provide the full expected range
      if (existingYears.isEmpty) {
        // Fallback to expected range if no data found
        final expectedYears = List.generate(15, (index) => 2024 - index); // 2024 down to 2010
        _cachedYears = expectedYears;
        debugPrint('⚠️ No years in database, using expected range: $expectedYears');
      } else {
        _cachedYears = existingYears.toList()..sort((a, b) => b.compareTo(a)); // Newest first
      }

      return _cachedYears!;
    } catch (e) {
      debugPrint('❌ Error fetching available years: $e');
      // Fallback to expected years on error
      final expectedYears = List.generate(15, (index) => 2024 - index);
      _cachedYears = expectedYears;
      return expectedYears;
    }
  }

  /// Get available positions from the draft data
  static Future<List<String>> getAvailablePositions() async {
    if (_cachedPositions != null) {
      return _cachedPositions!;
    }

    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .get();

      final positions = <String>{};
      for (var doc in querySnapshot.docs) {
        final position = doc.data()['position'] as String?;
        if (position != null && position.isNotEmpty) {
          positions.add(position);
        }
      }

      _cachedPositions = positions.toList()..sort();
      return _cachedPositions!;
    } catch (e) {
      debugPrint('Error fetching available positions: $e');
      return [];
    }
  }

  /// Get available schools from the draft data
  static Future<List<String>> getAvailableSchools() async {
    if (_cachedSchools != null) {
      return _cachedSchools!;
    }

    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .get();

      final schools = <String>{};
      for (var doc in querySnapshot.docs) {
        final school = doc.data()['school'] as String?;
        if (school != null && school.isNotEmpty) {
          schools.add(school);
        }
      }

      _cachedSchools = schools.toList()..sort();
      return _cachedSchools!;
    } catch (e) {
      debugPrint('Error fetching available schools: $e');
      return [];
    }
  }

  /// Get draft picks with filtering and pagination
  static Future<List<HistoricalDraftPick>> getDraftPicks({
    int? year,
    String? team,
    String? position,
    String? school,
    int? round,
    int page = 0,
    int pageSize = _pageSize,
  }) async {
    try {
      debugPrint('🔍 HistoricalDraftService.getDraftPicks called with:');
      debugPrint('  year: $year, team: $team, position: $position, school: $school');
      debugPrint('  round: $round, page: $page, pageSize: $pageSize');

      // First, let's test if there's ANY data in the collection
      final testQuery = await _firestore.collection(_collection).limit(5).get();
      debugPrint('🧪 Test query returned ${testQuery.docs.length} documents');
      if (testQuery.docs.isNotEmpty) {
        debugPrint('  Sample document: ${testQuery.docs.first.data()}');
      }

      Query query = _firestore.collection(_collection);

      // Apply filters
      if (year != null) {
        debugPrint('  🎯 Adding year filter: $year');
        query = query.where('year', isEqualTo: year);
      }
      
      if (team != null && team.isNotEmpty && team != 'All Teams') {
        debugPrint('  🎯 Adding team filter: $team');
        query = query.where('team', isEqualTo: team);
      }

      if (position != null && position.isNotEmpty && position != 'All Positions') {
        debugPrint('  🎯 Adding position filter: $position');
        query = query.where('position', isEqualTo: position);
      }

      if (school != null && school.isNotEmpty && school != 'All Schools') {
        debugPrint('  🎯 Adding school filter: $school');
        query = query.where('school', isEqualTo: school);
      }

      if (round != null) {
        debugPrint('  🎯 Adding round filter: $round');
        query = query.where('round', isEqualTo: round);
      }

      // Remove Firestore ordering to rely on in-memory sorting
      // This ensures we get all data and sort it properly in memory

      // Remove all limits to get ALL data from Firebase
      // We'll sort everything in memory and then paginate
      // No query limits - fetch all available data

      debugPrint('  🔥 Executing Firestore query...');
      final querySnapshot = await query.get();
      debugPrint('  📊 Query returned ${querySnapshot.docs.length} documents');
      
      // Convert all documents to picks first
      final allPicks = querySnapshot.docs.map((doc) {
        return HistoricalDraftPick.fromFirestore(doc.data() as Map<String, dynamic>);
      }).toList();

      // Sort all picks in memory: year (desc), round (asc), pick (asc) - show Round 1 Pick 1 first
      allPicks.sort((a, b) {
        // First by year (descending - most recent first)
        int yearComparison = b.year.compareTo(a.year);
        if (yearComparison != 0) return yearComparison;
        
        // Then by round (ascending - Round 1 first)
        int roundComparison = a.round.compareTo(b.round);
        if (roundComparison != 0) return roundComparison;
        
        // Finally by pick within round (ascending - Pick 1 in each round first)
        return a.pick.compareTo(b.pick);
      });

      // Debug: Show first few picks to verify sorting
      if (allPicks.isNotEmpty) {
        debugPrint('🔍 First 10 picks after sorting:');
        for (int i = 0; i < (allPicks.length < 10 ? allPicks.length : 10); i++) {
          final pick = allPicks[i];
          debugPrint('  ${i+1}. Year: ${pick.year}, Round: ${pick.round}, Pick: ${pick.pick}, Player: ${pick.player}');
        }
      }

      // Apply pagination after sorting
      final startIndex = page * pageSize;
      final endIndex = startIndex + pageSize;
      final picks = allPicks.length > startIndex 
          ? allPicks.sublist(startIndex, allPicks.length > endIndex ? endIndex : allPicks.length)
          : <HistoricalDraftPick>[];

      debugPrint('  ✅ After in-memory pagination (${startIndex}-${endIndex}): ${picks.length} documents');
      debugPrint('  🎉 Returning ${picks.length} draft picks (properly sorted and paginated)');
      return picks;

    } catch (e) {
      debugPrint('❌ Error fetching draft picks: $e');
      return [];
    }
  }

  /// Get total count of draft picks matching filters
  static Future<int> getDraftPicksCount({
    int? year,
    String? team,
    String? position,
    String? school,
    int? round,
  }) async {
    try {
      Query query = _firestore.collection(_collection);

      // Apply same filters as getDraftPicks
      if (year != null) {
        query = query.where('year', isEqualTo: year);
      }
      
      if (team != null && team.isNotEmpty && team != 'All Teams') {
        query = query.where('team', isEqualTo: team);
      }

      if (position != null && position.isNotEmpty && position != 'All Positions') {
        query = query.where('position', isEqualTo: position);
      }

      if (school != null && school.isNotEmpty && school != 'All Schools') {
        query = query.where('school', isEqualTo: school);
      }

      if (round != null) {
        query = query.where('round', isEqualTo: round);
      }

      final querySnapshot = await query.get();
      return querySnapshot.docs.length;

    } catch (e) {
      debugPrint('Error getting draft picks count: $e');
      return 0;
    }
  }

  /// Get draft picks for a specific round
  static Future<List<HistoricalDraftPick>> getDraftPicksByRound({
    required int year,
    required int round,
  }) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('year', isEqualTo: year)
          .where('round', isEqualTo: round)
          .orderBy('pick')
          .get();

      return querySnapshot.docs.map((doc) {
        return HistoricalDraftPick.fromFirestore(doc.data() as Map<String, dynamic>);
      }).toList();

    } catch (e) {
      debugPrint('Error fetching draft picks by round: $e');
      return [];
    }
  }

  /// Get draft picks for a specific team in a year
  static Future<List<HistoricalDraftPick>> getTeamDraftPicks({
    required int year,
    required String team,
  }) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('year', isEqualTo: year)
          .where('team', isEqualTo: team)
          .orderBy('pick')
          .get();

      return querySnapshot.docs.map((doc) {
        return HistoricalDraftPick.fromFirestore(doc.data() as Map<String, dynamic>);
      }).toList();

    } catch (e) {
      debugPrint('Error fetching team draft picks: $e');
      return [];
    }
  }

  /// Search draft picks by player name
  static Future<List<HistoricalDraftPick>> searchDraftPicks({
    required String playerName,
    int? year,
    String? team,
    String? position,
    String? school,
    int limit = 100,
  }) async {
    try {
      Query query = _firestore.collection(_collection);

      // Apply optional filters
      if (year != null) {
        query = query.where('year', isEqualTo: year);
      }
      
      if (team != null && team.isNotEmpty && team != 'All Teams') {
        query = query.where('team', isEqualTo: team);
      }

      if (position != null && position.isNotEmpty && position != 'All Positions') {
        query = query.where('position', isEqualTo: position);
      }

      if (school != null && school.isNotEmpty && school != 'All Schools') {
        query = query.where('school', isEqualTo: school);
      }

      // Remove limit to get all matching results
      // query = query.limit(limit);

      final querySnapshot = await query.get();
      
      // Filter by player name on the client side (Firestore doesn't support case-insensitive search)
      final picks = querySnapshot.docs
          .map((doc) => HistoricalDraftPick.fromFirestore(doc.data() as Map<String, dynamic>))
          .where((pick) => pick.player.toLowerCase().contains(playerName.toLowerCase()))
          .toList();

      // Sort search results: year (desc), round (asc), pick (asc) - show Round 1 Pick 1 first
      picks.sort((a, b) {
        int yearComparison = b.year.compareTo(a.year);
        if (yearComparison != 0) return yearComparison;
        
        int roundComparison = a.round.compareTo(b.round);
        if (roundComparison != 0) return roundComparison;
        
        return a.pick.compareTo(b.pick);
      });

      return picks;

    } catch (e) {
      debugPrint('Error searching draft picks: $e');
      return [];
    }
  }

  /// Clear cached data (useful for refresh operations)
  static void clearCache() {
    _cachedTeams = null;
    _cachedYears = null;
    _cachedPositions = null;
    _cachedSchools = null;
  }

  /// Get summary statistics
  static Future<Map<String, dynamic>> getDraftSummary({int? year}) async {
    try {
      Query query = _firestore.collection(_collection);
      
      if (year != null) {
        query = query.where('year', isEqualTo: year);
      }

      final querySnapshot = await query.get();
      final picks = querySnapshot.docs.map((doc) => 
        HistoricalDraftPick.fromFirestore(doc.data() as Map<String, dynamic>)
      ).toList();

      // Calculate summary statistics
      final positionCounts = <String, int>{};
      final teamCounts = <String, int>{};
      final schoolCounts = <String, int>{};

      for (var pick in picks) {
        positionCounts[pick.position] = (positionCounts[pick.position] ?? 0) + 1;
        teamCounts[pick.team] = (teamCounts[pick.team] ?? 0) + 1;
        schoolCounts[pick.school] = (schoolCounts[pick.school] ?? 0) + 1;
      }

      return {
        'totalPicks': picks.length,
        'topPositions': positionCounts.entries
            .toList()
            ..sort((a, b) => b.value.compareTo(a.value)),
        'topTeams': teamCounts.entries
            .toList()
            ..sort((a, b) => b.value.compareTo(a.value)),
        'topSchools': schoolCounts.entries
            .toList()
            ..sort((a, b) => b.value.compareTo(a.value)),
      };

    } catch (e) {
      debugPrint('Error getting draft summary: $e');
      return {
        'totalPicks': 0,
        'topPositions': <MapEntry<String, int>>[],
        'topTeams': <MapEntry<String, int>>[],
        'topSchools': <MapEntry<String, int>>[],
      };
    }
  }
}