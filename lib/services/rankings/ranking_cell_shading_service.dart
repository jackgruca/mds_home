import 'package:flutter/material.dart';

class RankingCellShadingService {
  static Map<String, Map<String, double>> calculatePercentiles(
    List<Map<String, dynamic>> rankings,
    List<String> statColumns,
  ) {
    final Map<String, Map<String, double>> percentileCache = {};
    
    if (rankings.isEmpty) return percentileCache;
    
    for (String column in statColumns) {
      final values = rankings
          .map((item) {
            final value = item[column];
            if (value is num) {
              return value.toDouble();
            } else if (value is String) {
              return double.tryParse(value) ?? 0.0;
            }
            return 0.0;
          })
          .where((value) => value.isFinite)
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

  static double _calculatePercentile(List<double> sortedValues, double percentile) {
    final index = (sortedValues.length - 1) * percentile;
    final lower = index.floor();
    final upper = index.ceil();
    
    if (lower == upper) {
      return sortedValues[lower];
    }
    
    return sortedValues[lower] * (upper - index) + sortedValues[upper] * (index - lower);
  }

  static Color getDensityColor(String column, double value, Map<String, Map<String, double>> percentileCache) {
    final percentiles = percentileCache[column];
    if (percentiles == null) return Colors.grey.shade200;
    
    final p25 = percentiles['p25']!;
    final p50 = percentiles['p50']!;
    final p75 = percentiles['p75']!;
    
    // Determine color intensity based on percentile
    if (value >= p75) {
      return Colors.green.withOpacity(0.7);
    } else if (value >= p50) {
      return Colors.green.withOpacity(0.4);
    } else if (value >= p25) {
      return Colors.orange.withOpacity(0.3);
    } else {
      return Colors.red.withOpacity(0.3);
    }
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
    final numValue = (displayValue as num?)?.toDouble() ?? 0.0;
    
    return Container(
      width: width,
      height: height,
      margin: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: getDensityColor(column, showRanks ? (1.0 - numValue) : numValue, percentileCache),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.grey.shade300, width: 0.5),
      ),
      child: Center(
        child: Text(
          formatValue(displayValue, column),
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
} 