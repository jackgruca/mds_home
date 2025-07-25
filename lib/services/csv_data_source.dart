import 'data_source_interface.dart';
import 'local_data_service.dart';

/// CSV implementation of DataSourceInterface
class CsvDataSource implements DataSourceInterface {
  final LocalDataService _localService = LocalDataService();
  
  @override
  String get sourceType => 'CSV';
  
  @override
  Future<bool> isAvailable() async {
    try {
      final data = await _localService.loadPlayerStats();
      return data.isNotEmpty;
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
  }) {
    return _localService.queryPlayerStats(
      position: position,
      team: team,
      season: season,
      playerId: playerId,
      orderBy: orderBy,
      descending: descending,
      limit: limit,
    );
  }
  
  @override
  Future<List<Map<String, dynamic>>> getTopPerformers({
    required String stat,
    String? position,
    int season = 2024,
    int limit = 10,
  }) {
    return _localService.getTopPerformers(
      stat: stat,
      position: position,
      season: season,
      limit: limit,
    );
  }
  
  @override
  Future<List<Map<String, dynamic>>> searchPlayers(String query) {
    return _localService.searchPlayers(query);
  }
  
  @override
  Future<Map<String, dynamic>?> getPlayerById(String playerId) {
    return _localService.getPlayerById(playerId);
  }
}