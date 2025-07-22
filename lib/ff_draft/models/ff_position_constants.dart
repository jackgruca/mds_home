import 'dart:ui';

/// Standardized position colors and constants for Fantasy Football draft
class FFPositionConstants {
  // Standard position colors used throughout the app
  static const Map<String, Color> positionColors = {
    'QB': Color(0xFFD32F2F),   // Red
    'RB': Color(0xFF388E3C),   // Green  
    'WR': Color(0xFF1976D2),   // Blue
    'TE': Color(0xFFFF9800),   // Orange
    'K': Color(0xFF7B1FA2),    // Purple
    'DST': Color(0xFF5D4037),  // Brown
  };

  // Position abbreviations for display
  static const Map<String, String> positionLabels = {
    'QB': 'QB',
    'RB': 'RB', 
    'WR': 'WR',
    'TE': 'TE',
    'K': 'K',
    'DST': 'DST',
  };

  // Position priorities for draft logic
  static const Map<String, int> positionPriority = {
    'QB': 1,
    'RB': 2,
    'WR': 3, 
    'TE': 4,
    'K': 5,
    'DST': 6,
  };

  /// Get color for a given position
  static Color getPositionColor(String position) {
    return positionColors[position] ?? const Color(0xFF757575); // Default gray
  }

  /// Get display label for a position
  static String getPositionLabel(String position) {
    return positionLabels[position] ?? position;
  }

  /// Get all available positions in priority order
  static List<String> getAllPositions() {
    return positionPriority.keys.toList();
  }
} 