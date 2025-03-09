import 'package:flutter/material.dart';
import '../utils/csv_data_handler.dart'; // Import our new utility

class AvailablePlayersTab extends StatefulWidget {
  final List<List<dynamic>> availablePlayers;

  const AvailablePlayersTab({required this.availablePlayers, super.key});

  @override
  _AvailablePlayersTabState createState() => _AvailablePlayersTabState();
}

class _AvailablePlayersTabState extends State<AvailablePlayersTab> {
  String _searchQuery = '';
  String _selectedPosition = '';
  
  // Field indexes for key columns
  late Map<String, int> _fieldIndexes;
  
  @override
  void initState() {
    super.initState();
    _mapFieldIndexes();
  }
  
  @override
  void didUpdateWidget(AvailablePlayersTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Re-map field indexes if data changes
    if (widget.availablePlayers != oldWidget.availablePlayers) {
      _mapFieldIndexes();
    }
  }
  
  /// Maps field indexes dynamically from header row
  void _mapFieldIndexes() {
    _fieldIndexes = {};
    
    if (widget.availablePlayers.isNotEmpty && widget.availablePlayers[0].isNotEmpty) {
      // Try to map fields by header names
      for (int i = 0; i < widget.availablePlayers[0].length; i++) {
        String header = widget.availablePlayers[0][i].toString().toLowerCase();
        _fieldIndexes[header] = i;
      }
      
      // Set default indexes if not found
      if (!_fieldIndexes.containsKey('player')) {
        _fieldIndexes['player'] = 1; // Default player name index
      }
      
      if (!_fieldIndexes.containsKey('position')) {
        _fieldIndexes['position'] = 2; // Default position index
      }
      
      if (!_fieldIndexes.containsKey('rank')) {
        _fieldIndexes['rank'] = widget.availablePlayers[0].length - 1; // Default rank to last column
      }
    }
  }

  /// Safely gets a unique set of positions from the available players list
  Set<String> getUniquePositions() {
    Set<String> positions = {};
    
    // Default position index
    int positionIdx = _fieldIndexes['position'] ?? 2;
    
    // Collect unique positions from players data
    for (var player in widget.availablePlayers.skip(1)) {
      if (player.length > positionIdx) {
        String position = player[positionIdx]?.toString().trim() ?? "";
        if (position.isNotEmpty) {
          positions.add(position);
        }
      }
    }
    
    return positions;
  }

  @override
  Widget build(BuildContext context) {
    // Get field indexes
    int playerNameIdx = _fieldIndexes['player'] ?? 1;
    int positionIdx = _fieldIndexes['position'] ?? 2;
    int rankIdx = _fieldIndexes['rank'] ?? (widget.availablePlayers.isNotEmpty && 
        widget.availablePlayers[0].isNotEmpty ? 
        widget.availablePlayers[0].length - 1 : 0);
    
    // Filter players based on search and position
    List<List<dynamic>> filteredPlayers = widget.availablePlayers.skip(1).where((player) {
      // Safely access fields
      String playerName = CsvDataHandler.safeAccess(player, playerNameIdx).toLowerCase();
      String playerPosition = CsvDataHandler.safeAccess(player, positionIdx).toLowerCase();
      String searchQuery = _searchQuery.toLowerCase();
      
      bool matchesSearch = searchQuery.isEmpty || playerName.contains(searchQuery);
      bool matchesPosition = _selectedPosition.isEmpty || 
          playerPosition == _selectedPosition.toLowerCase();

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
                _searchQuery = value.trim().toLowerCase();
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
                ...getUniquePositions().map((position) => Padding(
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
                )),
              ],
            ),
          ),
          const SizedBox(height: 16),
          
          // Data Table
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: Table(
                border: TableBorder.all(color: Colors.grey),
                columnWidths: const {
                  0: FlexColumnWidth(3), // Player Name (Wider)
                  1: FlexColumnWidth(2), // Position
                  2: FlexColumnWidth(1), // Rank (Smaller)
                },
                children: [
                  // 🏆 Styled Header Row
                  TableRow(
                    decoration: BoxDecoration(color: Colors.blueGrey[100]),
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

                  // 🏈 Player Data Rows - with safe access
                  for (var i = 0; i < filteredPlayers.length; i++) 
                    TableRow(
                      decoration: BoxDecoration(color: i.isEven ? Colors.white : Colors.grey[200]),
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: Text(
                            CsvDataHandler.safeAccess(filteredPlayers[i], playerNameIdx),
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: Text(
                            CsvDataHandler.safeAccess(filteredPlayers[i], positionIdx),
                            style: const TextStyle(fontSize: 14, fontStyle: FontStyle.italic),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: Text(
                            filteredPlayers[i].length > rankIdx ? 
                              CsvDataHandler.safeAccess(filteredPlayers[i], rankIdx) : "",
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
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