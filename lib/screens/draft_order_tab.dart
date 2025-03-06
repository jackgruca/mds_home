import 'package:flutter/material.dart';

// In draft_order_tab.dart, find the DraftOrderTab class definition
class DraftOrderTab extends StatefulWidget {
  final List<List<dynamic>> draftOrder;
  final String? userTeam;  // Add this parameter

  const DraftOrderTab({
    required this.draftOrder, 
    this.userTeam,  // Add this
    super.key
  });

  @override
  _DraftOrderTabState createState() => _DraftOrderTabState();
}

class _DraftOrderTabState extends State<DraftOrderTab> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    List<List<dynamic>> filteredDraftOrder = widget.draftOrder
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

          // Draft Order Table
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: Table(
                border: TableBorder.all(color: Colors.grey),
                columnWidths: const {
                  0: FlexColumnWidth(1), // Pick Number
                  1: FlexColumnWidth(2), // Team
                  2: FlexColumnWidth(3), // Selection (Drafted Player)
                  3: FlexColumnWidth(2), // Trade Info
                },
                children: [
                  // 🏆 Styled Header Row
                  TableRow(
                    decoration: BoxDecoration(color: Colors.blueGrey[100]),
                    children: const [
                      Padding(
                        padding: EdgeInsets.all(8),
                        child: Text("Pick", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      ),
                      Padding(
                        padding: EdgeInsets.all(8),
                        child: Text("Team", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      ),
                      Padding(
                        padding: EdgeInsets.all(8),
                        child: Text("Selection", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      ),
                      Padding(
                        padding: EdgeInsets.all(8),
                        child: Text("Trade", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      ),
                    ],
                  ),

                  // 🏈 Draft Order Rows
                  for (var i = 0; i < filteredDraftOrder.length; i++)
                    TableRow(
                      decoration: BoxDecoration(
                        color: filteredDraftOrder[i][1].toString() == widget.userTeam
                            ? Colors.blue.shade100  // Highlight user team
                            : (i.isEven ? Colors.white : Colors.grey[200]),
                      ),
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: Text(filteredDraftOrder[i][0].toString(), style: const TextStyle(fontSize: 14)),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: Text(filteredDraftOrder[i][1].toString(), style: const TextStyle(fontSize: 14, fontStyle: FontStyle.italic)),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: Text(filteredDraftOrder[i][2].toString().isEmpty ? "—" : filteredDraftOrder[i][2].toString(), style: const TextStyle(fontSize: 14)),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: Text(filteredDraftOrder[i][5].toString().isEmpty ? "—" : filteredDraftOrder[i][5].toString(), style: const TextStyle(fontSize: 14)),
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