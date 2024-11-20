import 'package:flutter/material.dart';

class AvailablePlayersTab extends StatefulWidget {
  final List<List<dynamic>> availablePlayers;

  AvailablePlayersTab({required this.availablePlayers, super.key});

  @override
  _AvailablePlayersTabState createState() => _AvailablePlayersTabState();
}

class _AvailablePlayersTabState extends State<AvailablePlayersTab> {
  String _searchQuery = '';
  String _selectedPosition = '';

  @override
  Widget build(BuildContext context) {
    List<List<dynamic>> filteredPlayers = widget.availablePlayers
        .where((player) =>
            (_searchQuery.isEmpty ||
                player[1].toString().toLowerCase().contains(_searchQuery.toLowerCase())) &&
            (_selectedPosition.isEmpty || player[2] == _selectedPosition))
        .toList();

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Search Bar
          TextField(
            decoration: InputDecoration(
              labelText: 'Search Players',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
          ),
          SizedBox(height: 16),
          // Position Filter Bubbles
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                ChoiceChip(
                  label: Text('All'),
                  selected: _selectedPosition.isEmpty,
                  onSelected: (selected) {
                    setState(() {
                      _selectedPosition = '';
                    });
                  },
                ),
                SizedBox(width: 8),
                ...widget.availablePlayers
                    .skip(1) // Skip header row
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
                    .toList(),
              ],
            ),
          ),
          SizedBox(height: 16),
          // Data Table
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('ID')),
                  DataColumn(label: Text('Name')),
                  DataColumn(label: Text('Position')),
                  DataColumn(label: Text('Rank Combined')),
                ],
                rows: filteredPlayers
                    .skip(1) // Skipping header row
                    .map(
                      (row) => DataRow(
                        cells: [
                          DataCell(Text(row[0].toString())),
                          DataCell(Text(row[1].toString())),
                          DataCell(Text(row[2].toString())),
                          DataCell(Text(row[3].toString())),
                        ],
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
