// lib/models/team_need.dart
class TeamNeed {
  final String teamName;
  final List<String> needs;
  final List<String> selectedPositions = []; // Change from String? to List<String>
  
  TeamNeed({
    required this.teamName,
    required this.needs,
  });
  
  // Create a TeamNeed from CSV row data
  factory TeamNeed.fromCsvRow(List<dynamic> row) {
    List<String> needsList = [];
    
    // Skip the first two columns (index, team name) and get all non-empty needs
    for (int i = 2; i < row.length; i++) {
      if (row[i] != null && row[i].toString().isNotEmpty) {
        needsList.add(row[i].toString());
      }
    }
    
    return TeamNeed(
      teamName: row[1].toString(),
      needs: needsList,
    );
  }
  
  // Convert team need back to a list for compatibility with existing code
  List<dynamic> toList() {
    List<dynamic> result = [0, teamName]; // First column is usually an index
    
    // Add needs, ensuring at least 10 positions (empty strings for missing needs)
    final int needsToFill = 10 - needs.length;
    result.addAll(needs);
    if (needsToFill > 0) {
      result.addAll(List.filled(needsToFill, ''));
    }
    
    // Add the selected positions, joined by commas
    result.add(selectedPositions.join(", "));
    
    return result;
  }
  
  // Remove a position from needs when drafted and add to selected positions
  void removeNeed(String position) {
    needs.remove(position);
    selectedPositions.add(position); // Add to the list instead of replacing
  }
  
  // Check if this position is a need
  bool isPositionANeed(String position) {
    return needs.contains(position);
  }
  
  // Get the primary need (first in the list)
  String? get primaryNeed => needs.isNotEmpty ? needs.first : null;
  
  @override
  String toString() => '$teamName Needs: ${needs.join(", ")}';
}