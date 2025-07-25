/// Abstract interface for data sources
/// Allows switching between Firebase and Local CSV data
abstract class DataSourceInterface {
  /// Query player stats with filters
  Future<List<Map<String, dynamic>>> queryPlayerStats({
    String? position,
    String? team,
    int? season,
    String? playerId,
    String? orderBy,
    bool descending = true,
    int? limit,
  });
  
  /// Get top performers by stat
  Future<List<Map<String, dynamic>>> getTopPerformers({
    required String stat,
    String? position,
    int season = 2024,
    int limit = 10,
  });
  
  /// Search players by name
  Future<List<Map<String, dynamic>>> searchPlayers(String query);
  
  /// Get player by ID
  Future<Map<String, dynamic>?> getPlayerById(String playerId);
  
  /// Get data source type
  String get sourceType;
  
  /// Check if data is available
  Future<bool> isAvailable();
}