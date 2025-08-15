import 'package:flutter/material.dart';

class RankingCellShadingService {
  // Muted color palette for dark mode
  static const Color _darkGreenHigh = Color(0xFF2E7D32); // green 800
  static const Color _darkGreenLow = Color(0xFF1B5E20);  // green 900
  static const Color _darkOrange = Color(0xFFEF6C00);    // orange 800
  static const Color _darkRed = Color(0xFFC62828);       // red 800

  static Map<String, Map<String, double>> calculatePercentiles(
    List<Map<String, dynamic>> rankings,
    List<String> statColumns,
  ) {
    final Map<String, Map<String, double>> percentileCache = {};
    
    if (rankings.isEmpty) return percentileCache;
    
    for (String column in statColumns) {
      // Skip string fields that shouldn't be processed as numbers
      if (_isStringField(column)) {
        continue;
      }
      
      final values = rankings
          .map((item) {
            final value = item[column];
            if (value == null || value == 'N/A' || value == '') {
              return null;
            }
            if (value is num) {
              return value.toDouble();
            } else if (value is String) {
              // Try to parse string numbers, handling commas and spaces
              final cleaned = value.replaceAll(',', '').trim();
              final parsed = double.tryParse(cleaned);
              return parsed;
            }
            return null;
          })
          .where((value) => value != null && value.isFinite)
          .cast<double>()
          .toList()
        ..sort();
      
      if (values.isNotEmpty) {
        percentileCache[column] = {
          'min': values.first,
          'p25': _calculatePercentile(values, 0.25),
          'p50': _calculatePercentile(values, 0.5),
          'p75': _calculatePercentile(values, 0.75),
          'max': values.last,
        };
      }
    }
    
    return percentileCache;
  }

  // Helper method to identify string fields that shouldn't be processed as numbers
  static bool _isStringField(String field) {
    const stringFields = {
      'player_name',
      'receiver_player_name', 
      'passer_player_name',
      'team',
      'posteam',
      'player_position',
      'position',
      'player_id',
      'receiver_player_id',
      'passer_player_id',
      'id'
    };
    return stringFields.contains(field);
  }

  static double _calculatePercentile(List<double> sortedValues, double percentile) {
    final index = (sortedValues.length - 1) * percentile;
    final lower = index.floor();
    final upper = index.ceil();
    
    if (lower == upper) {
      return sortedValues[lower];
    }
    
    return sortedValues[lower] * (upper - index) + sortedValues[upper] * (index - lower);
  }

  static Color getDensityColor(String column, double value, Map<String, Map<String, double>> percentileCache, {bool isRankField = false, required bool isDarkMode}) {
    final percentiles = percentileCache[column];
    if (percentiles == null) return Colors.grey.shade200;
    
    final p25 = percentiles['p25']!;
    final p50 = percentiles['p50']!;
    final p75 = percentiles['p75']!;
    
    // Check if this is a "lower is better" stat
    final isLowerBetter = isRankField || _isLowerBetterStat(column);
    
    // Helper to pick palette per mode
    Color greenStrong() => isDarkMode ? _darkGreenHigh.withValues(alpha: 0.8) : Colors.green.withOpacity(0.7);
    Color greenLight()  => isDarkMode ? _darkGreenLow.withValues(alpha: 0.6)  : Colors.green.withOpacity(0.4);
    Color warn()        => isDarkMode ? _darkOrange.withValues(alpha: 0.55)   : Colors.orange.withOpacity(0.3);
    Color bad()         => isDarkMode ? _darkRed.withValues(alpha: 0.55)      : Colors.red.withOpacity(0.3);

    if (isLowerBetter) {
      // Inverted logic: lower value = better = green
      if (value <= p25) {
        return greenStrong();  // Top 25% (best values)
      } else if (value <= p50) {
        return greenLight();  // Top 50%
      } else if (value <= p75) {
        return warn(); // Top 75%
      } else {
        return bad();    // Bottom 25% (worst values)
      }
    } else {
      // Regular logic: higher value = better = green
      if (value >= p75) {
        return greenStrong();
      } else if (value >= p50) {
        return greenLight();
      } else if (value >= p25) {
        return warn();
      } else {
        return bad();
      }
    }
  }

  // Helper method to identify stats where lower values are better
  static bool _isLowerBetterStat(String column) {
    const lowerBetterStats = {
      'intPerGame',     // Interceptions per game - lower is better
      'int_rank',       // Interception rank - lower rank number is better
      'int_rank_num',   // Interception rank number - lower rank number is better
    };
    
    // Any field containing "rank" or "Rank" where lower numbers are better (rank 1 = best)
    final isRankField = column.toLowerCase().contains('rank') || 
                       column.contains('Rank') ||
                       column.endsWith('_rank') ||
                       column.endsWith('Rank');
    
    return lowerBetterStats.contains(column) || isRankField;
  }

  static Widget buildDensityCell({
    required String column,
    required dynamic value,
    required dynamic rankValue,
    required bool showRanks,
    required Map<String, Map<String, double>> percentileCache,
    required String Function(dynamic, String) formatValue,
    double width = 80,
    double height = 40,
  }) {
    final displayValue = showRanks ? rankValue : value;
    final isRankField = showRanks && (column.endsWith('_rank') || column.endsWith('_rank_num'));
    
    // Parse numeric value for color calculation
    double? numValue;
    if (!_isStringField(column)) {
      if (displayValue == null || displayValue == 'N/A' || displayValue == '') {
        numValue = null;
      } else if (displayValue is num) {
        numValue = displayValue.toDouble();
      } else if (displayValue is String) {
        // Clean and parse string numbers
        final cleaned = displayValue.replaceAll(',', '').trim();
        numValue = double.tryParse(cleaned);
      }
    }
    
    final isDarkMode = WidgetsBinding.instance.platformDispatcher.platformBrightness == Brightness.dark;
    final Color textColor = isDarkMode ? Colors.white : Colors.black87;
    
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: _isStringField(column) || numValue == null
            ? (isDarkMode ? Colors.grey.shade800 : Colors.grey.shade100)  // Default color for string fields or null values
            : getDensityColor(column, numValue, percentileCache, isRankField: isRankField, isDarkMode: isDarkMode),
        borderRadius: BorderRadius.circular(2),
      ),
      child: Align(
        alignment: Alignment.centerLeft, // Force left alignment
        child: Padding(
          padding: const EdgeInsets.only(left: 6, right: 2), // More left padding for clear left alignment
          child: Text(
            formatValue(displayValue, column),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: textColor,
            ),
            textAlign: TextAlign.left, // Text itself is left-aligned
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
      ),
    );
  }
} 