import 'package:flutter/material.dart';
import '../utils/csv_data_handler.dart';

class TeamNeedsTab extends StatefulWidget {
  final List<List<dynamic>> teamNeeds;

  const TeamNeedsTab({required this.teamNeeds, super.key});

  @override
  _TeamNeedsTabState createState() => _TeamNeedsTabState();
}

class _TeamNeedsTabState extends State<TeamNeedsTab> {
  String _searchQuery = '';
  
  // Field indexes for key columns
  late Map<String, int> _fieldIndexes;
  late int _teamNameIndex;
  late int _selectedIndex;
  late List<int> _needsIndexes;
  
  @override
  void initState() {
    super.initState();
    _mapFieldIndexes();
  }
  
  @override
  void didUpdateWidget(TeamNeedsTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Re-map field indexes if data changes
    if (widget.teamNeeds != oldWidget.teamNeeds) {
      _mapFieldIndexes();
    }
  }
  
  /// Maps field indexes dynamically from header row
  void _mapFieldIndexes() {
    _fieldIndexes = {};
    
    if (widget.teamNeeds.isNotEmpty && widget.teamNeeds[0].isNotEmpty) {
      // Try to map fields by header names
      for (int i = 0; i < widget.teamNeeds[0].length; i++) {
        String header = widget.teamNeeds[0][i].toString().toLowerCase();
        _fieldIndexes[header] = i;
      }
      
      // Default team name index (usually the second column)
      _teamNameIndex = _fieldIndexes['team'] ?? 1;
      
      // Find the "Selected" column index or use the last column
      _selectedIndex = _fieldIndexes['selected'] ?? 
                       (widget.teamNeeds[0].length > 12 ? 12 : widget.teamNeeds[0].length - 1);
      
      // Find indexes for need columns (typically columns 2-11)
      _needsIndexes = [];
      for (int i = 2; i < widget.teamNeeds[0].length; i++) {
        // Skip the "Selected" column if found
        if (i != _selectedIndex) {
          String header = widget.teamNeeds[0][i].toString().toLowerCase();
          // Check if this looks like a needs column
          if (header.contains('need') || 
              (i >= 2 && i <= 11) || // Columns 2-11 are typically needs
              header.isEmpty) {
            _needsIndexes.add(i);
          }
        }
        
        // Stop after collecting 10 needs columns
        if (_needsIndexes.length >= 10) break;
      }
    } else {
      // Default values if no data
      _teamNameIndex = 1;
      _selectedIndex = 12;
      _needsIndexes = List.generate(10, (index) => index + 2); // Columns 2-11
    }
  }

  /// Safely joins team needs into a comma-separated string
  String getTeamNeeds(List<dynamic> team) {
    List<String> needs = [];
    
    for (int index in _needsIndexes) {
      if (team.length > index) {
        String need = team[index]?.toString().trim() ?? "";
        if (need.isNotEmpty) {
          needs.add(need);
        }
      }
    }
    
    return needs.join(", ");
  }

  /// Safely gets the selected position
  String getSelectedPosition(List<dynamic> team) {
    if (team.length > _selectedIndex) {
      return team[_selectedIndex]?.toString() ?? "";
    }
    return "";
  }

  @override
  Widget build(BuildContext context) {
    List<List<dynamic>> filteredTeamNeeds = widget.teamNeeds
        .skip(1) // Skip header row
        .where((row) {
          if (row.length <= _teamNameIndex) return false;
          String teamName = row[_teamNameIndex]?.toString().toLowerCase() ?? "";
          return _searchQuery.isEmpty || teamName.contains(_searchQuery.toLowerCase());
        })
        .toList();

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Search Bar
          TextField(
            decoration: const InputDecoration(
              labelText: 'Search by Team',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
          ),
          const SizedBox(height: 16),

          // Team Needs Table
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: Table(
                border: TableBorder.all(color: Colors.grey),
                columnWidths: const {
                  0: FlexColumnWidth(2), // Team Name
                  1: FlexColumnWidth(5), // Needs
                  2: FlexColumnWidth(2), // Selected
                },
                children: [
                  // 🏆 Styled Header Row
                  TableRow(
                    decoration: BoxDecoration(color: Colors.blueGrey[100]),
                    children: const [
                      Padding(
                        padding: EdgeInsets.all(8),
                        child: Text("Team", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      ),
                      Padding(
                        padding: EdgeInsets.all(8),
                        child: Text("Needs", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      ),
                      Padding(
                        padding: EdgeInsets.all(8),
                        child: Text("Selected", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      ),
                    ],
                  ),

                  // 🏈 Team Needs Rows
                  for (var i = 0; i < filteredTeamNeeds.length; i++)
                    TableRow(
                      decoration: BoxDecoration(color: i.isEven ? Colors.white : Colors.grey[200]),
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: Text(
                            CsvDataHandler.safeAccess(filteredTeamNeeds[i], _teamNameIndex),
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: Text(
                            getTeamNeeds(filteredTeamNeeds[i]),
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: Text(
                            getSelectedPosition(filteredTeamNeeds[i]),
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}