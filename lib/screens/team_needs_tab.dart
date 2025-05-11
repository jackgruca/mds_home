// lib/screens/team_needs_tab.dart
import 'package:flutter/material.dart';
import 'package:mds_home/utils/constants.dart';


class TeamNeedsTab extends StatefulWidget {
  final List<List<dynamic>> teamNeeds;

  const TeamNeedsTab({required this.teamNeeds, super.key});

  @override
  _TeamNeedsTabState createState() => _TeamNeedsTabState();
}

class _TeamNeedsTabState extends State<TeamNeedsTab> {
  final String _searchQuery = '';

@override
Widget build(BuildContext context) {
  final isDarkMode = Theme.of(context).brightness == Brightness.dark;
  List<List<dynamic>> filteredTeamNeeds = widget.teamNeeds
      .skip(1)
      .where((row) =>
          _searchQuery.isEmpty ||
          row[1].toString().toLowerCase().contains(_searchQuery.toLowerCase()))
      .toList();

  return Padding(
    padding: const EdgeInsets.all(8.0),
    child: Column(
      children: [
        // ... existing search bar code ...
        
        // Team Needs Table
        Expanded(
          child: Card(
            elevation: 2,
            margin: EdgeInsets.zero,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            color: isDarkMode ? Colors.grey.shade800 : Colors.white,
            child: Column(
              children: [
                // Header row
                Container(
                  decoration: BoxDecoration(
                    color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade200,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(8),
                      topRight: Radius.circular(8),
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                  child: const Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Text("Team", style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      Expanded(
                        flex: 5,
                        child: Text("Needs", style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
                
                // Team needs rows
                Expanded(
                  child: ListView.builder(
                    itemCount: filteredTeamNeeds.length,
                    itemBuilder: (context, i) {
                      var teamName = filteredTeamNeeds[i][1].toString();
                      var needsList = _getFormattedNeeds(filteredTeamNeeds[i]);
                      var selectedPositions = filteredTeamNeeds[i].length > 12 ? 
                                            filteredTeamNeeds[i][12].toString() : "";
                      
                      // Create list of positions that have been selected
                      List<String> selectedPositionsList = selectedPositions.isNotEmpty ? 
                                                        selectedPositions.split(", ") : [];
                      
                      return Container(
                        decoration: BoxDecoration(
                          color: isDarkMode ? 
                            (i.isEven ? Colors.grey.shade800 : Colors.grey.shade900) : 
                            (i.isEven ? Colors.white : Colors.grey.shade50),
                          border: Border(
                            bottom: BorderSide(
                              color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade200
                            ),
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Team name and logo
                            Expanded(
                              flex: 2,
                              child: Row(
                                children: [
                                  // Add team logo
                                  _buildTeamLogo(teamName),
                                  const SizedBox(width: 8),
                                  // Team name
                                  Expanded(
                                    child: Text(
                                      teamName,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: isDarkMode ? Colors.white : Colors.black87,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            
                            // Needs with selected positions crossed out - improved for dark mode
                            Expanded(
                              flex: 5,
                              child: 
                              Wrap(
                                spacing: 6.0,
                                runSpacing: 6.0,
                                children: needsList.map((need) {
                                  // Check if this position is in the selectedPositions list
                                  bool isSelected = selectedPositionsList.contains(need);
                                  Color positionColor = _getPositionColor(need);
                                  
                                  return Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: isSelected 
                                          ? (isDarkMode ? Colors.grey.shade700 : Colors.grey.shade200)
                                          : positionColor.withOpacity(isDarkMode ? 0.3 : 0.2),
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(
                                        color: isSelected 
                                            ? (isDarkMode ? Colors.grey.shade600 : Colors.grey.shade400)
                                            : positionColor.withOpacity(isDarkMode ? 0.7 : 0.5),
                                        width: 1.0,
                                      ),
                                    ),
                                    child: isSelected ? 
                                      Stack(
                                        alignment: Alignment.center,
                                        children: [
                                          Text(
                                            need,
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                                            ),
                                          ),
                                          Positioned(
                                            left: 0,
                                            right: 0,
                                            child: Container(
                                              height: 1.5,
                                              color: isDarkMode ? Colors.grey.shade500 : Colors.grey.shade700,
                                            ),
                                          ),
                                        ],
                                      ) :
                                      Text(
                                        need,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: isDarkMode ? Colors.white : positionColor,
                                        ),
                                      ),
                                  );
                                }).toList(),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

// Improved team logo builder with more reliable logo loading
Widget _buildTeamLogo(String teamName) {
  // Try to get the abbreviation from the mapping
  String? abbr = NFLTeamMappings.fullNameToAbbreviation[teamName];
  
  // If we can't find it in the mapping, check if it's already an abbreviation
  if (abbr == null && teamName.length <= 3) {
    abbr = teamName;
  }
  
  // If we still don't have an abbreviation, create a placeholder
  if (abbr == null) {
    return _buildPlaceholderLogo(teamName);
  }
  
  // Convert abbreviation to lowercase for URL
  final logoUrl = 'https://a.espncdn.com/i/teamlogos/nfl/500/${abbr.toLowerCase()}.png';
  
  // Handle the image with error fallback
  return Container(
    width: 30.0,
    height: 30.0,
    decoration: const BoxDecoration(
      shape: BoxShape.circle,
    ),
    child: ClipOval(
      child: Image.network(
        logoUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          // On error, return the placeholder
          return _buildPlaceholderLogo(teamName);
        },
      ),
    ),
  );
}

Widget _buildPlaceholderLogo(String teamName) {
  final initials = teamName.split(' ')
      .map((word) => word.isNotEmpty ? word[0] : '')
      .join('')
      .toUpperCase();
  
  return Container(
    width: 30.0,
    height: 30.0,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: Colors.blue.shade700,
    ),
    child: Center(
      child: Text(
        initials.length > 2 ? initials.substring(0, 2) : initials,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 12.0,
        ),
      ),
    ),
  );
}


// Helper method for team initials

  // Inside the _getFormattedNeeds method, modify it to return both active needs and selected positions
  List<String> _getFormattedNeeds(List<dynamic> teamNeedRow) {
    // Get needs from columns 2-11 (indices 2-11)
    List<String> needs = [];
    
    for (int i = 2; i < teamNeedRow.length - 1; i++) {
      if (i - 2 >= 10) break; // Only consider the first 10 needs
      
      String need = teamNeedRow[i].toString();
      if (need.isNotEmpty && need != "-") {
        needs.add(need);
      }
    }
    
    // Get selected positions from the last column
    String selectedPositionsStr = teamNeedRow.length > 12 ? 
                                teamNeedRow[12].toString() : "";
    
    List<String> selectedPositions = selectedPositionsStr.isNotEmpty ? 
                                  selectedPositionsStr.split(", ") : [];
    
    // Combine both lists to show all positions (both active and selected)
    List<String> allPositions = [...needs];
    
    // Add selected positions that aren't already in the needs list
    for (String selected in selectedPositions) {
      if (!allPositions.contains(selected)) {
        allPositions.add(selected);
      }
    }
    
    return allPositions;
  }
  
  Color _getPositionColor(String position) {
  final isDarkMode = Theme.of(context).brightness == Brightness.dark;
  
  // Offensive position colors
  if (['QB', 'RB', 'FB'].contains(position)) {
    return isDarkMode ? Colors.blue.shade400 : Colors.blue.shade700; // Backfield
  } else if (['WR', 'TE'].contains(position)) {
    return isDarkMode ? Colors.green.shade400 : Colors.green.shade700; // Receivers
  } else if (['OT', 'IOL', 'OL', 'G', 'C'].contains(position)) {
    return isDarkMode ? Colors.purple.shade400 : Colors.purple.shade700; // O-Line
  } 
  // Defensive position colors
  else if (['EDGE', 'DL', 'IDL', 'DT', 'DE'].contains(position)) {
    return isDarkMode ? Colors.red.shade400 : Colors.red.shade700; // D-Line
  } else if (['LB', 'ILB', 'OLB'].contains(position)) {
    return isDarkMode ? Colors.orange.shade400 : Colors.orange.shade700; // Linebackers
  } else if (['CB', 'S', 'FS', 'SS'].contains(position)) {
    return isDarkMode ? Colors.teal.shade400 : Colors.teal.shade700; // Secondary
  }
  // Default color
  return isDarkMode ? Colors.grey.shade400 : Colors.grey.shade700;
}
}