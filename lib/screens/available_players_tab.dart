import 'package:flutter/material.dart';

class AvailablePlayersTab extends StatefulWidget {
  final List<List<dynamic>> availablePlayers;

  const AvailablePlayersTab({required this.availablePlayers, super.key});

  @override
  _AvailablePlayersTabState createState() => _AvailablePlayersTabState();
}

class _AvailablePlayersTabState extends State<AvailablePlayersTab> {
  String _searchQuery = '';
  String _selectedPosition = '';

  @override
  Widget build(BuildContext context) {
    List<List<dynamic>> filteredPlayers = widget.availablePlayers.skip(1).where((player) {

      // Normalize text for comparison
      String playerName = player[1].toString().trim().toLowerCase();
      String searchQuery = _searchQuery.trim().toLowerCase();
      String playerPosition = player[2].toString().trim().toLowerCase();
      
      bool matchesSearch = searchQuery.isEmpty || playerName.contains(searchQuery);
      bool matchesPosition = _selectedPosition.isEmpty || playerPosition == _selectedPosition.toLowerCase();

      return matchesSearch && matchesPosition;
    }).toList();

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Search Bar
          TextField(
            decoration: const InputDecoration(
              labelText: 'Search Players',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value.trim().toLowerCase(); // Trim spaces & force lowercase;
              });
            },
          ),
          const SizedBox(height: 16),
          // Position Filter Bubbles
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                ChoiceChip(
                  label: const Text('All'),
                  selected: _selectedPosition.isEmpty,
                  onSelected: (selected) {
                    setState(() {
                      _selectedPosition = '';
                    });
                  },
                ),
                const SizedBox(width: 8),
                ...widget.availablePlayers
                    //.skip(1) // Skip header row
                    .map((player) => player[2])
                    .toSet()
                    .map((position) => Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4.0),
                          child: ChoiceChip(
                            label: Text(position),
                            selected: _selectedPosition == position,
                            onSelected: (selected) {
                              setState(() {
                                _selectedPosition = selected ? position : '';
                              });
                            },
                          ),
                        ))
                    ,
              ],
            ),
          ),
          const SizedBox(height: 16),
          
          // Data Table
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: Table(
                border: TableBorder.all(color: Colors.grey), // Adds border to table
                columnWidths: const {
                  0: FlexColumnWidth(3), // Player Name (Wider)
                  1: FlexColumnWidth(2), // Position
                  2: FlexColumnWidth(1), // Rank (Smaller)
                },
                children: [
                  // 🏆 Styled Header Row
                  TableRow(
                    decoration: BoxDecoration(color: Colors.blueGrey[100]), // Light background for header
                    children: const [
                      Padding(
                        padding: EdgeInsets.all(8),
                        child: Text("Player", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                      Padding(
                        padding: EdgeInsets.all(8),
                        child: Text("Position", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                      Padding(
                        padding: EdgeInsets.all(8),
                        child: Text("Rank", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                    ],
                  ),

                  // 🏈 Player Data Rows
                  for (var i = 0; i < filteredPlayers.length; i++) 
                    TableRow(
                      decoration: BoxDecoration(color: i.isEven ? Colors.white : Colors.grey[200]), // Alternating row colors
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: Text(filteredPlayers[i][1], style: const TextStyle(fontSize: 14)),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: Text(filteredPlayers[i][2], style: const TextStyle(fontSize: 14, fontStyle: FontStyle.italic)),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: Text(filteredPlayers[i].last, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
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
