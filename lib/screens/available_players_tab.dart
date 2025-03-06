import 'package:flutter/material.dart';

class AvailablePlayersTab extends StatefulWidget {
  final List<List<dynamic>> availablePlayers;
  final bool selectionEnabled;
  final Function(int)? onPlayerSelected;
  final String? userTeam;

  const AvailablePlayersTab({
    required this.availablePlayers, 
    this.selectionEnabled = false,
    this.onPlayerSelected,
    this.userTeam,
    super.key
  });

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
          // Add guidance banner when in selection mode
          if (widget.selectionEnabled)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.green.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.shade300),
              ),
              child: Row(
                children: [
                  const Icon(Icons.sports_football, color: Colors.green),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "YOUR TURN TO PICK",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Click 'Draft' button next to a player to select them for your team",
                          style: TextStyle(
                            color: Colors.green.shade800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

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
                columnWidths: {
                  0: const FlexColumnWidth(3), // Player Name
                  1: const FlexColumnWidth(1.5), // Position
                  2: const FlexColumnWidth(1), // Rank
                  3: FlexColumnWidth(widget.selectionEnabled ? 1.5 : 0), // Draft button - remove const
                },

                children: [
                  // Styled Header Row
                  TableRow(
                    decoration: BoxDecoration(color: Colors.blueGrey[100]), // Light background for header
                    children: [
                      const Padding(
                        padding: EdgeInsets.all(8),
                        child: Text("Player", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                      const Padding(
                        padding: EdgeInsets.all(8),
                        child: Text("Position", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                      const Padding(
                        padding: EdgeInsets.all(8),
                        child: Text("Rank", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                      if (widget.selectionEnabled)
                        const Padding(
                          padding: EdgeInsets.all(8),
                          child: Text("Action", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        ),
                    ],
                  ),

                  // Player Data Rows
                  for (var i = 0; i < filteredPlayers.length; i++) 
                    TableRow(
                      decoration: BoxDecoration(color: i.isEven ? Colors.white : Colors.grey[200]),
                      children: [
                        // Player name cell
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: Text(
                            filteredPlayers[i][1], 
                            style: const TextStyle(fontSize: 14)
                          ),
                        ),
                        
                        // Position cell
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: Text(
                            filteredPlayers[i][2], 
                            style: const TextStyle(
                              fontSize: 14, 
                              fontStyle: FontStyle.italic
                            )
                          ),
                        ),
                        
                        // Rank cell
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: Text(
                            filteredPlayers[i].last, 
                            style: const TextStyle(
                              fontSize: 14, 
                              fontWeight: FontWeight.bold
                            )
                          ),
                        ),
                        
                        // Draft button cell - only show when selection is enabled
                        if (widget.selectionEnabled)
                          Padding(
                            padding: const EdgeInsets.all(4),
                            child: ElevatedButton(
                              onPressed: () {
                                if (widget.onPlayerSelected != null) {
                                  // Use the first column value (ID) or appropriate identifier
                                  int playerId = int.tryParse(filteredPlayers[i][0].toString()) ?? i;
                                  widget.onPlayerSelected!(playerId);
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              ),
                              child: const Text(
                                'Draft',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
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