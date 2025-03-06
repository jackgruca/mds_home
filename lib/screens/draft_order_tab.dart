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
                  0: IntrinsicColumnWidth(), // Pick number (auto-sized)
                  1: FlexColumnWidth(3),     // Team (larger)
                  2: FlexColumnWidth(4),     // Selection (largest)
                  3: IntrinsicColumnWidth(), // Trade// Trade Info
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
                        // Team column
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  image: DecorationImage(
                                    image: NetworkImage(
                                      'https://a.espncdn.com/i/teamlogos/nfl/500/${filteredDraftOrder[i][1].toString().toLowerCase()}.png',
                                    ),
                                    fit: BoxFit.contain,
                                  ),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                filteredDraftOrder[i][1].toString(),
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                        // Selection column
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: filteredDraftOrder[i][2].toString().isEmpty 
                            ? const Text("—") 
                            : Row(
                                children: [
                                  Text(
                                    filteredDraftOrder[i][2].toString(),
                                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    "(${filteredDraftOrder[i][3].toString()})",
                                    style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.grey),
                                  ),
                                ],
                              ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: filteredDraftOrder[i][5].toString().isEmpty 
                            ? const Text("") // Empty when no trade 
                            : GestureDetector(
                                onTap: () {
                                  showDialog(
                                    context: context,
                                    builder: (context) => _buildTradeDetailsDialog(filteredDraftOrder[i]),
                                  );
                                },
                                child: const Icon(
                                  Icons.compare_arrows,
                                  color: Colors.deepOrange,
                                  size: 20,
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

  // Add this method to the _DraftOrderTabState class
  Widget _buildTradeDetailsDialog(List<dynamic> draftRow) {
    // Extract trade info
    String tradeInfo = draftRow[5].toString();
    String team = draftRow[1].toString();
    String pickNum = draftRow[0].toString();
    
    // Parse trade info (assuming format like "From TEAM")
    String otherTeam = "Unknown Team";
    if (tradeInfo.startsWith("From ")) {
      otherTeam = tradeInfo.substring(5);
    }
    
    return AlertDialog(
      title: const Text('Trade Details'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Trade diagram
            Row(
              children: [
                // Left side - Team that traded up
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        team,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Received:',
                        style: TextStyle(fontSize: 12),
                        textAlign: TextAlign.center,
                      ),
                      Card(
                        color: Colors.green.shade50,
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            'Pick #$pickNum',
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Arrows
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8.0),
                  child: Icon(Icons.swap_horiz, color: Colors.grey),
                ),
                
                // Right side - Team that traded down
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        otherTeam,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Received:',
                        style: TextStyle(fontSize: 12),
                        textAlign: TextAlign.center,
                      ),
                      Card(
                        color: Colors.blue.shade50,
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            tradeInfo,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }
}