import 'stat_prediction.dart';

class PredictionComparison {
  final String statName;
  final String displayName;
  final dynamic currentValue;
  final dynamic predictedValue;
  final bool isEditable;
  final String valueType; // 'double', 'int', 'percentage'
  final String? unit;

  PredictionComparison({
    required this.statName,
    required this.displayName,
    required this.currentValue,
    required this.predictedValue,
    required this.isEditable,
    required this.valueType,
    this.unit,
  });

  // Calculate percentage change
  double? getPercentageChange() {
    if (currentValue == null || predictedValue == null) return null;
    
    final current = _toDouble(currentValue);
    final predicted = _toDouble(predictedValue);
    
    if (current == 0) return null;
    
    return ((predicted - current) / current) * 100;
  }

  // Get formatted display value
  String getFormattedCurrentValue() {
    return _formatValue(currentValue);
  }

  String getFormattedPredictedValue() {
    return _formatValue(predictedValue);
  }

  String getFormattedPercentageChange() {
    final change = getPercentageChange();
    if (change == null) return 'N/A';
    
    final sign = change >= 0 ? '+' : '';
    return '$sign${change.toStringAsFixed(1)}%';
  }

  // Get change direction for styling
  ChangeDirection getChangeDirection() {
    final change = getPercentageChange();
    if (change == null) return ChangeDirection.neutral;
    if (change > 0) return ChangeDirection.positive;
    if (change < 0) return ChangeDirection.negative;
    return ChangeDirection.neutral;
  }

  String _formatValue(dynamic value) {
    if (value == null) return 'N/A';
    
    switch (valueType) {
      case 'percentage':
        final doubleVal = _toDouble(value);
        return '${(doubleVal * 100).toStringAsFixed(1)}%';
      case 'double':
        final doubleVal = _toDouble(value);
        return doubleVal.toStringAsFixed(2);
      case 'int':
        final intVal = _toInt(value);
        return intVal.toString();
      default:
        return value.toString();
    }
  }

  double _toDouble(dynamic value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.round();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  PredictionComparison copyWith({
    String? statName,
    String? displayName,
    dynamic currentValue,
    dynamic predictedValue,
    bool? isEditable,
    String? valueType,
    String? unit,
  }) {
    return PredictionComparison(
      statName: statName ?? this.statName,
      displayName: displayName ?? this.displayName,
      currentValue: currentValue ?? this.currentValue,
      predictedValue: predictedValue ?? this.predictedValue,
      isEditable: isEditable ?? this.isEditable,
      valueType: valueType ?? this.valueType,
      unit: unit ?? this.unit,
    );
  }
}

enum ChangeDirection {
  positive,
  negative,
  neutral,
}

class PlayerPredictionComparisons {
  final StatPrediction prediction;
  final List<PredictionComparison> comparisons;

  PlayerPredictionComparisons({
    required this.prediction,
    required this.comparisons,
  });

  // Factory to create from StatPrediction
  factory PlayerPredictionComparisons.fromStatPrediction(StatPrediction prediction) {
    final comparisons = [
      PredictionComparison(
        statName: 'tgtShare',
        displayName: 'Target Share',
        currentValue: prediction.tgtShare,
        predictedValue: prediction.nyTgtShare,
        isEditable: true,
        valueType: 'percentage',
      ),
      PredictionComparison(
        statName: 'wrRank',
        displayName: 'Team Rank',
        currentValue: prediction.wrRank,
        predictedValue: prediction.nyWrRank,
        isEditable: true,
        valueType: 'int',
      ),
      PredictionComparison(
        statName: 'points',
        displayName: 'Fantasy Points',
        currentValue: prediction.points,
        predictedValue: prediction.nyPoints,
        isEditable: true,
        valueType: 'double',
      ),
      PredictionComparison(
        statName: 'yards',
        displayName: 'Receiving Yards',
        currentValue: prediction.numYards,
        predictedValue: prediction.nySeasonYards,
        isEditable: true,
        valueType: 'int',
      ),
      PredictionComparison(
        statName: 'touchdowns',
        displayName: 'Receiving TDs',
        currentValue: prediction.numTD,
        predictedValue: prediction.nyNumTD,
        isEditable: true,
        valueType: 'int',
      ),
      PredictionComparison(
        statName: 'receptions',
        displayName: 'Receptions',
        currentValue: prediction.numRec,
        predictedValue: prediction.nyNumRec,
        isEditable: true,
        valueType: 'int',
      ),
      PredictionComparison(
        statName: 'games',
        displayName: 'Games Played',
        currentValue: prediction.numGames,
        predictedValue: prediction.nyNumGames,
        isEditable: true,
        valueType: 'int',
      ),
    ];

    return PlayerPredictionComparisons(
      prediction: prediction,
      comparisons: comparisons,
    );
  }

  // Get specific comparison by stat name
  PredictionComparison? getComparison(String statName) {
    try {
      return comparisons.firstWhere((comp) => comp.statName == statName);
    } catch (e) {
      return null;
    }
  }

  // Update a comparison with new predicted value
  PlayerPredictionComparisons updatePredictedValue(String statName, dynamic newValue) {
    final updatedComparisons = comparisons.map((comp) {
      if (comp.statName == statName) {
        return comp.copyWith(predictedValue: newValue);
      }
      return comp;
    }).toList();

    // Also update the underlying StatPrediction
    final updatedPrediction = _updateStatPrediction(statName, newValue);

    return PlayerPredictionComparisons(
      prediction: updatedPrediction,
      comparisons: updatedComparisons,
    );
  }

  StatPrediction _updateStatPrediction(String statName, dynamic newValue) {
    switch (statName) {
      case 'tgtShare':
        return prediction.updateNyStat('nyTgtShare', newValue);
      case 'wrRank':
        return prediction.updateNyStat('nyWrRank', newValue);
      case 'points':
        return prediction.updateNyStat('nyPoints', newValue);
      case 'yards':
        return prediction.updateNyStat('nySeasonYards', newValue);
      case 'touchdowns':
        return prediction.updateNyStat('nyNumTD', newValue);
      case 'receptions':
        return prediction.updateNyStat('nyNumRec', newValue);
      case 'games':
        return prediction.updateNyStat('nyNumGames', newValue);
      default:
        return prediction;
    }
  }

  // Get summary statistics
  Map<String, dynamic> getSummaryStats() {
    int improvingStats = 0;
    int decliningStats = 0;
    int stableStats = 0;

    for (final comp in comparisons) {
      final direction = comp.getChangeDirection();
      switch (direction) {
        case ChangeDirection.positive:
          improvingStats++;
          break;
        case ChangeDirection.negative:
          decliningStats++;
          break;
        case ChangeDirection.neutral:
          stableStats++;
          break;
      }
    }

    return {
      'improving': improvingStats,
      'declining': decliningStats,
      'stable': stableStats,
      'total': comparisons.length,
    };
  }

  @override
  String toString() {
    return 'PlayerPredictionComparisons{player: ${prediction.playerName}, comparisons: ${comparisons.length}}';
  }
}