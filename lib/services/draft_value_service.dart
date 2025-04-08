// lib/services/draft_value_service.dart
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:csv/csv.dart';
import '../models/draft_value.dart';

/// Service for handling the draft value chart
class DraftValueService {
  static List<DraftValue> _draftValues = [];
  static bool _isInitialized = false;

  static const String _version = "v1.1";
  static Map<int, double>? _draftValueMap;

  /// Load the draft value chart from CSV
/// Load the draft value chart from CSV
static Future<void> initialize() async {
  if (_isInitialized) return;
  
  try {
    debugPrint("Loading draft value chart...");
    final data = await rootBundle.loadString('assets/draft_value_chart.csv');
    debugPrint("CSV content length: ${data.length}");
    
    // Show a preview of the CSV data
    debugPrint("CSV preview: ${data.substring(0, min(100, data.length))}");
    
    List<List<dynamic>> csvTable = const CsvToListConverter(eol: "\n").convert(data);
    debugPrint("CSV parsed with ${csvTable.length} rows");
    
    // Determine if there's a header row
    bool hasHeader = false;
    if (csvTable.isNotEmpty) {
      var firstCell = csvTable[0][0].toString().trim();
      hasHeader = firstCell.toLowerCase() == "pick" || !RegExp(r'^\d+$').hasMatch(firstCell);
      debugPrint("CSV appears to ${hasHeader ? 'have' : 'not have'} a header row");
    }
    
    // Skip header if present
    int startIdx = hasHeader ? 1 : 0;
    
    _draftValues = [];
    
    // Process each row
    for (int i = startIdx; i < csvTable.length; i++) {
      if (csvTable[i].length >= 2) {
        // Get pick number - try to be forgiving with formats
        var pickData = csvTable[i][0];
        int pick;
        if (pickData is int) {
          pick = pickData;
        } else {
          // Try parsing as int, trimming any whitespace
          pick = int.tryParse(pickData.toString().trim()) ?? 0;
        }
        
        // Get value - try to be forgiving with formats
        var valueData = csvTable[i][1];
        double value;
        if (valueData is double) {
          value = valueData;
        } else if (valueData is int) {
          value = valueData.toDouble();
        } else {
          // Try parsing as double, trimming any whitespace
          value = double.tryParse(valueData.toString().trim()) ?? 0.0;
        }
        
        if (pick > 0 && value > 0) {
          debugPrint("Adding pick #$pick = $value points");
          _draftValues.add(DraftValue(pick: pick, value: value));
        } else {
          debugPrint("Skipping invalid row: pick=$pick, value=$value");
        }
      } else {
        debugPrint("Row $i has insufficient columns: ${csvTable[i]}");
      }
    }
    
    // Sort values to ensure they're in ascending order by pick number
    _draftValues.sort((a, b) => a.pick.compareTo(b.pick));
    
    // Audit the data - show first 10 values for verification
    debugPrint("Loaded ${_draftValues.length} draft values");
    for (int i = 0; i < min(10, _draftValues.length); i++) {
      debugPrint("Loaded: Pick #${_draftValues[i].pick} = ${_draftValues[i].value} points");
    }
    
    _isInitialized = true;
  } catch (e) {
    debugPrint("Error loading draft value chart: $e");
    debugPrint("Falling back to default values");
    _createDefaultValues();
    _isInitialized = true;
  }
}
  
/// Get the value for a specific pick
static double getValueForPick(int pickNumber) {
  if (pickNumber <= 0) {
    debugPrint("Warning: Invalid pick number $pickNumber requested");
    return 0.0;
  }
  
  if (!_isInitialized) {
    debugPrint("Warning: Draft value chart not initialized, initializing now");
    _createDefaultValues();
    _isInitialized = true;
  }
  
  // Find the draft value by pick number - optimize this search
  try {
    // Check if _draftValues is a List<DraftValue> as expected
    debugPrint("Searching for pick #$pickNumber among ${_draftValues.length} values");
    
    // Create a map for faster lookup if not already created
    if (_draftValueMap == null || _draftValueMap!.isEmpty) {
      _draftValueMap = {};
      for (var dv in _draftValues) {
        _draftValueMap![dv.pick] = dv.value;
      }
      debugPrint("Created map with ${_draftValueMap!.length} entries");
    }
    
    // Try to find the pick in the map first
    if (_draftValueMap!.containsKey(pickNumber)) {
      return _draftValueMap![pickNumber]!;
    }
    
    // If not in map, try the list as a fallback
    var value = _draftValues.firstWhere((dv) => dv.pick == pickNumber).value;
    return value;
  } catch (e) {
    // Only now do we fall back to estimation
    debugPrint("ERROR: Pick #$pickNumber not found in chart. This should not happen!");
    return _estimateValueForPick(pickNumber);
  }
}
  
  /// Create default draft values if CSV loading fails
/// Create default draft values if CSV loading fails
  static void _createDefaultValues() {
  debugPrint("Creating default draft values");
  _draftValues = [];
  
  // Create first round (picks 1-32) - UPDATED TO MATCH CSV
  for (int i = 1; i <= 32; i++) {
    double value;
    if (i == 1) value = 1000.0;  // Changed from 3000.0 to 1000.0
    else if (i == 2) value = 985.0;  // Specific value for #2
    else if (i == 3) value = 970.0;  // Specific value for #3
    else if (i <= 10) value = 970.0 - ((i - 3) * 14.0);  // Roughly matching values
    else value = 872.0 - ((i - 10) * 13.0);  // Roughly matching values
    
    _draftValues.add(DraftValue(pick: i, value: value));
    debugPrint("Default value: Pick #$i = $value points");
  }
  
  // Create second round (picks 33-64)
  for (int i = 33; i <= 64; i++) {
    double value = 615.0 - ((i - 32) * 7.5);  // Adjusted for new scale
    _draftValues.add(DraftValue(pick: i, value: value));
  }
  
  // Create third round (picks 65-96)
  for (int i = 65; i <= 96; i++) {
    double value = 380.0 - ((i - 64) * 4.5);  // Adjusted for new scale
    _draftValues.add(DraftValue(pick: i, value: value));
  }
  
  // Create fourth round (picks 97-128)
  for (int i = 97; i <= 128; i++) {
    double value = 234.0 - ((i - 96) * 2.75);  // Adjusted for new scale
    _draftValues.add(DraftValue(pick: i, value: value));
  }
  
  // Create fifth round (picks 129-160)
  for (int i = 129; i <= 160; i++) {
    double value = 146.0 - ((i - 128) * 1.75);  // Adjusted for new scale
    _draftValues.add(DraftValue(pick: i, value: max(90.0, value)));
  }
  
  // Create sixth round (picks 161-192)
  for (int i = 161; i <= 192; i++) {
    double value = 90.0 - ((i - 160) * 1.1);  // Adjusted for new scale
    _draftValues.add(DraftValue(pick: i, value: max(55.0, value)));
  }
  
  // Create seventh round (picks 193-224)
  for (int i = 193; i <= 224; i++) {
    double value = 55.0 - ((i - 192) * 0.7);  // Adjusted for new scale
    _draftValues.add(DraftValue(pick: i, value: max(33.0, value)));
  }
  
  // Create additional picks if needed (picks 225-260)
  for (int i = 225; i <= 260; i++) {
    // Values decrease from 33 to 20
    double value = max(20.0, 33.0 - ((i - 225) * 0.4));
    _draftValues.add(DraftValue(pick: i, value: value));
  }
  
  // Create picks beyond standard draft if ever needed
  for (int i = 261; i <= 270; i++) {
    _draftValues.add(DraftValue(pick: i, value: 20.0));
  }
  
  debugPrint("Created ${_draftValues.length} default draft values");
}
  
  /// Estimate value for a pick if it's not in the chart
  static double _estimateValueForPick(int pickNumber) {
    if (pickNumber <= 0) return 0;
    
    if (pickNumber <= 32) {
      return 3000.0 * pow(0.915, pickNumber - 1);
    } else if (pickNumber <= 64) {
      return 580.0 * pow(0.98, pickNumber - 33);
    } else if (pickNumber <= 96) {
      return 265.0 - ((pickNumber - 65) * 3);
    } else if (pickNumber <= 128) {
      return max(50, 170.0 - ((pickNumber - 97) * 2));
    } else if (pickNumber <= 160) {
      return max(30, 49.0 - ((pickNumber - 129) * 0.8));
    } else if (pickNumber <= 192) {
      return max(20, 29.0 - ((pickNumber - 161) * 0.4));
    } else if (pickNumber <= 224) {
      return max(15, 19.0 - ((pickNumber - 193) * 0.3));
    } else {
      return 15.0;
    }
  }
  
  /// Helper to calculate the round from a pick number
  static int getRoundForPick(int pickNumber) {
    // Define the pick ranges for each round (inclusive bounds)
    if (pickNumber <= 32) return 1;      // Round 1: picks 1-32
    if (pickNumber <= 64) return 2;      // Round 2: picks 33-64
    if (pickNumber <= 102) return 3;     // Round 3: picks 65-105
    if (pickNumber <= 138) return 4;     // Round 4: picks 106-143
    if (pickNumber <= 176) return 5;     // Round 5: picks 144-184
    if (pickNumber <= 216) return 6;     // Round 6: picks 185-224
    if (pickNumber <= 257) return 7;     // Round 7: picks 225-262
    return 8; // Any picks beyond 262 would be in hypothetical later rounds
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