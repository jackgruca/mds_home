import 'package:cloud_firestore/cloud_firestore.dart';
import 'data_source_interface.dart';

/// Firebase implementation of DataSourceInterface
class FirebaseDataSource implements DataSourceInterface {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  @override
  String get sourceType => 'Firebase';
  
  @override
  Future<bool> isAvailable() async {
    try {
      // Try a simple query to check connectivity
      await _firestore
          .collection('playerSeasonStats')
          .limit(1)
          .get(const GetOptions(source: Source.server));
      return true;
    } catch (e) {
      return false;
    }
  }
  
  @override
  Future<List<Map<String, dynamic>>> queryPlayerStats({
    String? position,
    String? team,
    int? season,
    String? playerId,
    String? orderBy,
    bool descending = true,
    int? limit,
  }) async {
    try {
      Query query = _firestore.collection('playerSeasonStats');
      
      // Apply filters
      if (position != null) {
        query = query.where('position', isEqualTo: position);
      }
      if (team != null) {
        query = query.where('recent_team', isEqualTo: team);
      }
      if (season != null) {
        query = query.where('season', isEqualTo: season);
      }
      if (playerId != null) {
        query = query.where('player_id', isEqualTo: playerId);
      }
      
      // Apply ordering
      if (orderBy != null) {
        query = query.orderBy(orderBy, descending: descending);
      }
      
      // Apply limit
      if (limit != null) {
        query = query.limit(limit);
      }
      
      final snapshot = await query.get();
      
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      throw Exception('Firebase query failed: $e');
    }
  }
  
  @override
  Future<List<Map<String, dynamic>>> getTopPerformers({
    required String stat,
    String? position,
    int season = 2024,
    int limit = 10,
  }) {
    return queryPlayerStats(
      position: position,
      season: season,
      orderBy: stat,
      descending: true,
      limit: limit,
    );
  }
  
  @override
  Future<List<Map<String, dynamic>>> searchPlayers(String query) async {
    final searchQuery = query.toLowerCase();
    
    try {
      // Firebase doesn't support full-text search, so we use a workaround
      // Search by player_display_name_lower field
      final snapshot = await _firestore
          .collection('playerSeasonStats')
          .where('player_display_name_lower', isGreaterThanOrEqualTo: searchQuery)
          .where('player_display_name_lower', isLessThan: searchQuery + 'z')
          .limit(20)
          .get();
      
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      throw Exception('Firebase search failed: $e');
    }
  }
  
  @override
  Future<Map<String, dynamic>?> getPlayerById(String playerId) async {
    try {
      final snapshot = await _firestore
          .collection('playerSeasonStats')
          .where('player_id', isEqualTo: playerId)
          .limit(1)
          .get();
      
      if (snapshot.docs.isEmpty) return null;
      
      final data = snapshot.docs.first.data();
      data['id'] = snapshot.docs.first.id;
      return data;
    } catch (e) {
      throw Exception('Firebase getPlayerById failed: $e');
    }
  }
}