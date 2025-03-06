// lib/services/draft_value_service.dart
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:csv/csv.dart';
import '../models/draft_value.dart';

/// Service for handling the draft value chart
class DraftValueService {
  static List<DraftValue> _draftValues = [];
  static bool _isInitialized = false;

  /// Load the draft value chart from CSV
  static Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      final data = await rootBundle.loadString('assets/draft_value_chart.csv');
      List<List<dynamic>> csvTable = const CsvToListConverter(eol: "\n").convert(data);
      
      // Skip header row if present
      final startIndex = csvTable[0][0] == "Pick" || csvTable[0][0] == "PICK" ? 1 : 0;
      
      _draftValues = csvTable
          .skip(startIndex)
          .map((row) => DraftValue.fromCsvRow(row))
          .toList();
      
      _isInitialized = true;
    } catch (e) {
      debugPrint("Error loading draft value chart: $e");
      // Create default values as fallback
      _createDefaultValues();
      _isInitialized = true;
    }
  }
  
  /// Get the value for a specific pick
  static double getValueForPick(int pickNumber) {
    if (!_isInitialized) {
      debugPrint("Warning: Draft value chart not initialized");
      return _estimateValueForPick(pickNumber);
    }
    
    try {
      return _draftValues.firstWhere((dv) => dv.pick == pickNumber).value;
    } catch (e) {
      // If the specific pick isn't found, estimate it
      return _estimateValueForPick(pickNumber);
    }
  }
  
  /// Create default draft values if CSV loading fails
  static void _createDefaultValues() {
    _draftValues = [];
    
    // Create values for picks 1-32 (1st round)
    for (int i = 1; i <= 32; i++) {
      double value = 3000 * MathHelper.pow(0.9, i - 1);
      _draftValues.add(DraftValue(pick: i, value: value));
    }
    
    // Create values for picks 33-64 (2nd round)
    for (int i = 33; i <= 64; i++) {
      double value = 580 * MathHelper.pow(0.98, i - 33);
      _draftValues.add(DraftValue(pick: i, value: value));
    }
    
    // Create values for picks 65-96 (3rd round)
    for (int i = 65; i <= 96; i++) {
      double value = 340 * MathHelper.pow(0.98, i - 65);
      _draftValues.add(DraftValue(pick: i, value: value));
    }
    
    // Create values for picks 97-128 (4th round)
    for (int i = 97; i <= 128; i++) {
      double value = 170 * MathHelper.pow(0.98, i - 97);
      _draftValues.add(DraftValue(pick: i, value: value));
    }
    
    // Create values for picks 129-160 (5th round)
    for (int i = 129; i <= 160; i++) {
      double value = 85 * MathHelper.pow(0.98, i - 129);
      _draftValues.add(DraftValue(pick: i, value: value));
    }
    
    // Create values for picks 161-192 (6th round)
    for (int i = 161; i <= 192; i++) {
      double value = 42 * MathHelper.pow(0.98, i - 161);
      _draftValues.add(DraftValue(pick: i, value: value));
    }
    
    // Create values for picks 193-224 (7th round)
    for (int i = 193; i <= 224; i++) {
      double value = 21 * MathHelper.pow(0.98, i - 193);
      _draftValues.add(DraftValue(pick: i, value: value));
    }
  }
  
  /// Estimate value for a pick if it's not in the chart
  static double _estimateValueForPick(int pickNumber) {
    if (pickNumber <= 0) return 0;
    
    if (pickNumber <= 32) {
      return 3000 * MathHelper.pow(0.9, pickNumber - 1);
    } else if (pickNumber <= 64) {
      return 580 * MathHelper.pow(0.98, pickNumber - 33);
    } else if (pickNumber <= 96) {
      return 340 * MathHelper.pow(0.98, pickNumber - 65);
    } else if (pickNumber <= 128) {
      return 170 * MathHelper.pow(0.98, pickNumber - 97);
    } else if (pickNumber <= 160) {
      return 85 * MathHelper.pow(0.98, pickNumber - 129);
    } else if (pickNumber <= 192) {
      return 42 * MathHelper.pow(0.98, pickNumber - 161);
    } else {
      return 21 * MathHelper.pow(0.98, pickNumber - 193);
    }
  }
  
  /// Helper to calculate the round from a pick number
  static int getRoundForPick(int pickNumber) {
    return ((pickNumber - 1) / 32).floor() + 1;
  }
  
  /// Create a draft value string representation
  static String getValueDescription(double value) {
    if (value >= 1000) {
      return "${(value / 1000).toStringAsFixed(1)}k";
    } else {
      return value.toStringAsFixed(0);
    }
  }
}

// Replace the current MathHelper extension with this class:

/// Helper utility for math operations
class MathHelper {
  /// Calculate x raised to power y
  static double pow(double x, int y) {
    double result = 1.0;
    for (int i = 0; i < y; i++) {
      result *= x;
    }
    return result;
  }
}