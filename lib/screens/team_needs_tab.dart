// lib/screens/team_needs_tab.dart
import 'package:flutter/material.dart';

class TeamNeedsTab extends StatefulWidget {
  final List<List<dynamic>> teamNeeds;

  const TeamNeedsTab({required this.teamNeeds, super.key});

  @override
  _TeamNeedsTabState createState() => _TeamNeedsTabState();
}

class _TeamNeedsTabState extends State<TeamNeedsTab> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
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
          // Compact search bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(8.0),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Row(
              children: [
                // Search field
                Expanded(
                  child: SizedBox(
                    height: 36,
                    child: TextField(
                      decoration: const InputDecoration(
                        hintText: 'Search by Team',
                        prefixIcon: Icon(Icons.search, size: 18),
                        contentPadding: EdgeInsets.zero,
                        isDense: true,
                        border: OutlineInputBorder(),
                      ),
                      style: const TextStyle(fontSize: 14),
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value;
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Team count
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${filteredTeamNeeds.length} teams',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[800],
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 6),
          
          // Team Needs Table
          Expanded(
            child: Card(
              elevation: 2,
              margin: EdgeInsets.zero,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              child: Column(
                children: [
                  // Header row
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
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
                            color: i.isEven ? Colors.white : Colors.grey[50],
                            border: Border(
                              bottom: BorderSide(color: Colors.grey[200]!),
                            ),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Team name and logo
                              Expanded(
                                flex: 2,
                                child: _buildTeamLogo(teamName),
                              ),
                              
                              // Needs with selected positions crossed out
                              Expanded(
                                flex: 5,
                                child: Wrap(
                                  spacing: 6.0,
                                  runSpacing: 6.0,
                                  children: needsList.map((need) {
                                    bool isSelected = selectedPositionsList.contains(need);
                                    return Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: _getPositionColor(need).withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(
                                          color: isSelected ? 
                                              Colors.grey.withOpacity(0.5) : 
                                              _getPositionColor(need).withOpacity(0.5),
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
                                                color: _getPositionColor(need).withOpacity(0.5),
                                              ),
                                            ),
                                            Positioned(
                                              left: 0,
                                              right: 0,
                                              child: Container(
                                                height: 1.5,
                                                color: Colors.grey[700],
                                              ),
                                            ),
                                          ],
                                        ) :
                                        Text(
                                          need,
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: _getPositionColor(need),
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
    
    return needs;
  }
  
  Widget _buildTeamLogo(String teamName) {
    // First try to get the abbreviation from the mapping
    // This assumes you have NFLTeamMappings class available
    
    // Simpler version - just show the team name with logo placeholder
    return Row(
      children: [
        Container(
          width: 25,
          height: 25,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.blue.shade700,
          ),
          child: Center(
            child: Text(
              _getTeamInitials(teamName),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 10,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            teamName,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
  
  String _getTeamInitials(String teamName) {
    final initials = teamName.split(' ')
        .map((word) => word.isNotEmpty ? word[0] : '')
        .join('')
        .toUpperCase();
    
    return initials.length > 2 ? initials.substring(0, 2) : initials;
  }
  
  Color _getPositionColor(String position) {
    // Offensive position colors
    if (['QB', 'RB', 'FB'].contains(position)) {
      return Colors.blue.shade700; // Backfield
    } else if (['WR', 'TE'].contains(position)) {
      return Colors.green.shade700; // Receivers
    } else if (['OT', 'IOL', 'OL', 'G', 'C'].contains(position)) {
      return Colors.purple.shade700; // O-Line
    } 
    // Defensive position colors
    else if (['EDGE', 'DL', 'IDL', 'DT', 'DE'].contains(position)) {
      return Colors.red.shade700; // D-Line
    } else if (['LB', 'ILB', 'OLB'].contains(position)) {
      return Colors.orange.shade700; // Linebackers
    } else if (['CB', 'S', 'FS', 'SS'].contains(position)) {
      return Colors.teal.shade700; // Secondary
    }
    // Default color
    return Colors.grey.shade700;
  }
}