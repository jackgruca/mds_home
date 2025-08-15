import 'package:flutter/services.dart';
import 'package:csv/csv.dart';
import '../../models/projections/stat_prediction.dart';
import '../../models/projections/prediction_comparison.dart';

class StatPredictorService {
  static const String _csvAssetPath = 'data/processed/draft_sim/2025/FF_WR_2025_v2.csv';
  
  List<StatPrediction>? _cachedPredictions;
  Map<String, List<StatPrediction>>? _cachedTeamPredictions;
  Map<String, List<StatPrediction>>? _cachedPositionPredictions;

  // Load predictions from CSV
  Future<List<StatPrediction>> loadPredictions() async {
    if (_cachedPredictions != null) {
      return _cachedPredictions!;
    }

    try {
      print('Loading predictions from: $_csvAssetPath');
      final csvData = await rootBundle.loadString(_csvAssetPath);
      final List<List<dynamic>> csvTable = const CsvToListConverter().convert(csvData);
      
      if (csvTable.isEmpty) {
        throw Exception('CSV file is empty');
      }

      print('CSV loaded successfully. Total rows: ${csvTable.length}');
      
      // Get headers from first row
      final headers = csvTable.first.map((e) => e.toString()).toList();
      print('CSV headers: $headers');
      
      final predictions = <StatPrediction>[];
      
      // Process each row (skip header)
      for (int i = 1; i < csvTable.length; i++) {
        try {
          final row = csvTable[i];
          final rowMap = <String, dynamic>{};
          
          // Create map from headers and row data
          for (int j = 0; j < headers.length && j < row.length; j++) {
            rowMap[headers[j]] = row[j];
          }
          
          // Only include WR and TE positions
          final position = rowMap['position']?.toString() ?? '';
          if (position == 'WR' || position == 'TE') {
            final prediction = StatPrediction.fromCsvRow(rowMap);
            predictions.add(prediction);
          }
        } catch (e) {
          print('Error parsing row $i: $e');
          print('Row data: ${csvTable[i]}');
          // Continue processing other rows
        }
      }

_cachedPredictions = predictions;
      _buildCaches();
      
      print('Successfully processed ${predictions.length} predictions');
      print('WR count: ${predictions.where((p) => p.position == 'WR').length}');
      print('TE count: ${predictions.where((p) => p.position == 'TE').length}');
      
      return predictions;
    } catch (e) {
      print('Error loading predictions: $e');
      throw Exception('Failed to load predictions: $e');
    }
  }

  // Get predictions filtered by position
  Future<List<StatPrediction>> getPredictionsByPosition(String position) async {
    if (_cachedPositionPredictions == null) {
      await loadPredictions();
    }
    
    return _cachedPositionPredictions?[position] ?? [];
  }

  // Get predictions filtered by team
  Future<List<StatPrediction>> getPredictionsByTeam(String team) async {
    if (_cachedTeamPredictions == null) {
      await loadPredictions();
    }
    
    return _cachedTeamPredictions?[team] ?? [];
  }

  // Get all WR predictions
  Future<List<StatPrediction>> getWRPredictions() async {
    return getPredictionsByPosition('WR');
  }

  // Get all TE predictions
  Future<List<StatPrediction>> getTEPredictions() async {
    return getPredictionsByPosition('TE');
  }

  // Get both WR and TE predictions
  Future<List<StatPrediction>> getPassCatcherPredictions() async {
    final predictions = await loadPredictions();
    return predictions.where((p) => p.position == 'WR' || p.position == 'TE').toList();
  }

  // Update a player's prediction
  Future<StatPrediction> updatePlayerPrediction(StatPrediction updatedPrediction) async {
    if (_cachedPredictions == null) {
      await loadPredictions();
    }

    final index = _cachedPredictions!.indexWhere((p) => p.playerId == updatedPrediction.playerId);
    if (index != -1) {
      _cachedPredictions![index] = updatedPrediction;
      _buildCaches(); // Rebuild caches with updated data
    }

    return updatedPrediction;
  }

  // Get prediction comparison objects for easier UI handling
  Future<List<PlayerPredictionComparisons>> getPredictionComparisons({String? position}) async {
    List<StatPrediction> predictions;
    
    if (position != null) {
      predictions = await getPredictionsByPosition(position);
    } else {
      predictions = await getPassCatcherPredictions();
    }

    return predictions.map((p) => PlayerPredictionComparisons.fromStatPrediction(p)).toList();
  }

  // Search predictions by player name
  Future<List<StatPrediction>> searchPredictions(String query) async {
    final predictions = await loadPredictions();
    final lowercaseQuery = query.toLowerCase();
    
    return predictions.where((p) => 
      p.playerName.toLowerCase().contains(lowercaseQuery) ||
      p.team.toLowerCase().contains(lowercaseQuery)
    ).toList();
  }

  // Get teams with predictions
  Future<List<String>> getTeamsWithPredictions() async {
    if (_cachedTeamPredictions == null) {
      await loadPredictions();
    }
    
    return _cachedTeamPredictions!.keys.toList()..sort();
  }

  // Get summary statistics
  Future<Map<String, dynamic>> getSummaryStats() async {
    final predictions = await loadPredictions();
    
    final wrCount = predictions.where((p) => p.position == 'WR').length;
    final teCount = predictions.where((p) => p.position == 'TE').length;
    final editedCount = predictions.where((p) => p.isEdited).length;
    final teamsCount = _cachedTeamPredictions?.keys.length ?? 0;

    return {
      'totalPlayers': predictions.length,
      'wrCount': wrCount,
      'teCount': teCount,
      'editedCount': editedCount,
      'teamsCount': teamsCount,
    };
  }

  // Reset all predictions to original values
  Future<void> resetAllToOriginal() async {
    if (_cachedPredictions == null) {
      await loadPredictions();
      return;
    }

    _cachedPredictions = _cachedPredictions!.map((p) => p.resetToOriginal()).toList();
    _buildCaches();
  }

  // Reset specific player to original values
  Future<StatPrediction?> resetPlayerToOriginal(String playerId) async {
    if (_cachedPredictions == null) {
      await loadPredictions();
    }

    final index = _cachedPredictions!.indexWhere((p) => p.playerId == playerId);
    if (index != -1) {
      _cachedPredictions![index] = _cachedPredictions![index].resetToOriginal();
      _buildCaches();
      return _cachedPredictions![index];
    }

    return null;
  }

  // Export current predictions (for integration with custom rankings)
  Future<List<Map<String, dynamic>>> exportPredictions({String? position}) async {
    List<StatPrediction> predictions;
    
    if (position != null) {
      predictions = await getPredictionsByPosition(position);
    } else {
      predictions = await getPassCatcherPredictions();
    }

    return predictions.map((p) => p.toMap()).toList();
  }

  // Build internal caches for faster filtering
  void _buildCaches() {
    if (_cachedPredictions == null) return;

    // Build team cache
    _cachedTeamPredictions = <String, List<StatPrediction>>{};
    for (final prediction in _cachedPredictions!) {
      if (!_cachedTeamPredictions!.containsKey(prediction.team)) {
        _cachedTeamPredictions![prediction.team] = [];
      }
      _cachedTeamPredictions![prediction.team]!.add(prediction);
    }

    // Build position cache
    _cachedPositionPredictions = <String, List<StatPrediction>>{};
    for (final prediction in _cachedPredictions!) {
      if (!_cachedPositionPredictions!.containsKey(prediction.position)) {
        _cachedPositionPredictions![prediction.position] = [];
      }
      _cachedPositionPredictions![prediction.position]!.add(prediction);
    }

    // Sort team predictions by target share (descending)
    _cachedTeamPredictions!.forEach((team, predictions) {
      predictions.sort((a, b) => b.nyTgtShare.compareTo(a.nyTgtShare));
    });
  }

  // Clear cache (useful for testing or manual refresh)
  void clearCache() {
    _cachedPredictions = null;
    _cachedTeamPredictions = null;
    _cachedPositionPredictions = null;
  }

  // Validate prediction values
  bool validatePrediction(StatPrediction prediction) {
    // Basic validation rules
    if (prediction.nyTgtShare < 0 || prediction.nyTgtShare > 1) return false;
    if (prediction.nyWrRank < 1) return false;
    if (prediction.nyPoints < 0) return false;
    if (prediction.nySeasonYards < 0) return false;
    if (prediction.nyNumTD < 0) return false;
    if (prediction.nyNumRec < 0) return false;
    if (prediction.nyNumGames < 0 || prediction.nyNumGames > 17) return false;

    return true;
  }

  // Get players by tier
  Future<Map<String, List<StatPrediction>>> getPredictionsByTier(String tierType) async {
    final predictions = await loadPredictions();
    final tierMap = <String, List<StatPrediction>>{};

    for (final prediction in predictions) {
      final tierDescription = prediction.getTierDescription(tierType);
      if (!tierMap.containsKey(tierDescription)) {
        tierMap[tierDescription] = [];
      }
      tierMap[tierDescription]!.add(prediction);
    }

    return tierMap;
  }
}