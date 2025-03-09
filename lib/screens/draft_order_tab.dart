import 'package:flutter/material.dart';
import '../utils/csv_data_handler.dart';

class DraftOrderTab extends StatefulWidget {
  final List<List<dynamic>> draftOrder;

  const DraftOrderTab({required this.draftOrder, super.key});

  @override
  _DraftOrderTabState createState() => _DraftOrderTabState();
}

class _DraftOrderTabState extends State<DraftOrderTab> {
  String _searchQuery = '';
  
  // Field indexes for key columns
  late Map<String, int> _fieldIndexes;
  late int _pickIndex;
  late int _teamIndex;
  late int _selectionIndex;
  late int _tradeIndex;
  
  @override
  void initState() {
    super.initState();
    _mapFieldIndexes();
  }
  
  @override
  void didUpdateWidget(DraftOrderTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Re-map field indexes if data changes
    if (widget.draftOrder != oldWidget.draftOrder) {
      _mapFieldIndexes();
    }
  }
  
  /// Maps field indexes dynamically from header row
  void _mapFieldIndexes() {
    _fieldIndexes = {};
    
    if (widget.draftOrder.isNotEmpty && widget.draftOrder[0].isNotEmpty) {
      // Try to map fields by header names
      for (int i = 0; i < widget.draftOrder[0].length; i++) {
        String header = widget.draftOrder[0][i].toString().toLowerCase();
        _fieldIndexes[header] = i;
      }
      
      // Map common field names to their indexes
      _pickIndex = _fieldIndexes['pick'] ?? 0;
      _teamIndex = _fieldIndexes['team'] ?? 1;
      _selectionIndex = _fieldIndexes['selection'] ?? 2;
      
      // Try various possible names for trade column
      _tradeIndex = _fieldIndexes['trade'] ?? 
                   _fieldIndexes['trade info'] ?? 
                   _fieldIndexes['trade details'] ??
                   _fieldIndexes['notes'] ?? 5; // Default to column 5 if not found
    } else {
      // Default values if no data
      _pickIndex = 0;
      _teamIndex = 1;
      _selectionIndex = 2;
      _tradeIndex = 5;
    }
  }

  @override
  Widget build(BuildContext context) {
    List<List<dynamic>> filteredDraftOrder = widget.draftOrder
        .skip(1) // Skip header row
        .where((row) {
          if (row.length <= _teamIndex) return false;
          String teamName = row[_teamIndex]?.toString().toLowerCase() ?? "";
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
                      decoration: BoxDecoration(color: i.isEven ? Colors.white : Colors.grey[200]),
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: Text(
                            CsvDataHandler.safeAccess(filteredDraftOrder[i], _pickIndex),
                            style: const TextStyle(fontSize: 14)
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: Text(
                            CsvDataHandler.safeAccess(filteredDraftOrder[i], _teamIndex),
                            style: const TextStyle(fontSize: 14, fontStyle: FontStyle.italic)
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: Text(
                            CsvDataHandler.safeAccess(filteredDraftOrder[i], _selectionIndex, fallback: "—"),
                            style: const TextStyle(fontSize: 14)
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: Text(
                            filteredDraftOrder[i].length > _tradeIndex ? 
                              CsvDataHandler.safeAccess(filteredDraftOrder[i], _tradeIndex, fallback: "—") : "—",
                            style: const TextStyle(fontSize: 14)
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