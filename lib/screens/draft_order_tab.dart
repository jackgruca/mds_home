import 'package:flutter/material.dart';
import '../models/draft_pick.dart';
import '../models/player.dart';
import '../widgets/draft/animated_draft_pick_card.dart';

class DraftOrderTab extends StatefulWidget {
  final List<List<dynamic>> draftOrder;
  final String? userTeam;
  final ScrollController? scrollController; // Add this parameter
  
  const DraftOrderTab({
    required this.draftOrder,
    this.userTeam,
    this.scrollController, // Accept external scroll controller
    super.key,
  });

  @override
  _DraftOrderTabState createState() => _DraftOrderTabState();
}

class _DraftOrderTabState extends State<DraftOrderTab> {
  String _searchQuery = '';
  final ScrollController _localScrollController = ScrollController();
  
  // Use provided controller or local one
  ScrollController get _scrollController => 
      widget.scrollController ?? _localScrollController;

  @override
  void dispose() {
    // Only dispose the local controller if we created it
    if (widget.scrollController == null) {
      _localScrollController.dispose();
    }
    super.dispose();
  }

  Widget _buildDraftOrderCards() {
  List<List<dynamic>> filteredDraftOrder = widget.draftOrder
      .skip(1)
      .where((row) =>
          _searchQuery.isEmpty ||
          row[1].toString().toLowerCase().contains(_searchQuery.toLowerCase()))
      .toList();
      
  // Convert dynamic rows to DraftPick objects
  List<DraftPick> draftPicks = [];
    for (var row in filteredDraftOrder) {
      final pickNumber = int.tryParse(row[0].toString()) ?? 0;
      final teamName = row[1].toString();
      final selection = row[2].toString();
      final position = row[3].toString();
      final round = row[4].toString();
      final tradeInfo = row[5].toString();
      
      // Create a basic DraftPick
      final draftPick = DraftPick(
        pickNumber: pickNumber,
        teamName: teamName,
        round: round,
        tradeInfo: tradeInfo.isEmpty ? null : tradeInfo,
      );
      
      // Add selected player if there is one
      if (selection.isNotEmpty) {
        draftPick.selectedPlayer = Player(
          id: pickNumber, // Using pick number as ID for simplicity
          name: selection,
          position: position,
          rank: pickNumber, // Default to pick number as rank if you don't have the actual rank
        );
      }
      
      draftPicks.add(draftPick);
    }

  return ListView.builder(
    controller: _scrollController,
    itemCount: draftPicks.length,
    itemBuilder: (context, index) {
      final isUserTeam = draftPicks[index].teamName == widget.userTeam;
      final isRecentPick = index < 3; // Consider the first 3 picks as "recent"
      
      return AnimatedDraftPickCard(
        draftPick: draftPicks[index],
        isUserTeam: isUserTeam,
        isRecentPick: isRecentPick,
      );
    },
  );
}

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
            child: _buildDraftOrderCards(),
          ),
        ],
      ),
    );
  }
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
    
    // Track the assets each team received
    String teamReceived = 'Pick #$pickNum';
    String otherTeamReceived = '';
    
    // Find all picks traded to the other team
    for (var row in widget.draftOrder.skip(1)) {
      if (row[5].toString().contains("From $team")) {
        if (otherTeamReceived.isEmpty) {
          otherTeamReceived = 'Pick #${row[0]}';
        } else {
          otherTeamReceived += ', Pick #${row[0]}';
        }
      }
    }
    
    // If we couldn't find any, use a fallback message
    if (otherTeamReceived.isEmpty) {
      otherTeamReceived = "Unknown picks";
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
                            teamReceived,
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
                            otherTeamReceived,
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