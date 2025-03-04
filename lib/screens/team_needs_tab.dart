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
                    ],
                  ),

                  // 🏈 Team Needs Rows
                  for (var i = 0; i < filteredTeamNeeds.length; i++)
                    TableRow(
                      decoration: BoxDecoration(color: i.isEven ? Colors.white : Colors.grey[200]),
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: Text(filteredTeamNeeds[i][1].toString(), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: Text(
                            // Joins all needs into a single string, skipping empty ones
                            filteredTeamNeeds[i].sublist(2).where((e) => e.toString().isNotEmpty).join(", "),
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