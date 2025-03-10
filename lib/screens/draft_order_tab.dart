import 'package:flutter/material.dart';
import '../models/draft_pick.dart';
import '../models/player.dart';
import '../widgets/draft/animated_draft_pick_card.dart';

class DraftOrderTab extends StatefulWidget {
  final List<List<dynamic>> draftOrder;
  final String? userTeam;
  final ScrollController? scrollController;
  final List<List<dynamic>> teamNeeds; // Add this parameter
  
  const DraftOrderTab({
    required this.draftOrder,
    this.userTeam,
    this.scrollController,
    required this.teamNeeds, // Add this parameter
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

  List<String> _getTeamNeeds(String teamName) {
    // Find the team's needs in teamNeeds
    for (var row in widget.teamNeeds.skip(1)) { // Skip header row
      if (row.length > 1 && row[1].toString() == teamName) {
        List<String> needs = [];
        // Team needs start at index 2
        for (int i = 2; i < row.length && i < 12; i++) { // Up to 10 needs (indices 2-11)
          String need = row[i].toString();
          if (need.isNotEmpty && need != '-' && need != 'null') {
            needs.add(need);
          }
        }
        // Return the top 3 needs
        return needs.take(3).toList();
      }
    }
    return [];
  }

  Widget _buildDraftOrderCards() {
    // Map column names to indices for the filtered draft order
    Map<String, int> columnIndices = {};
    if (widget.draftOrder.isNotEmpty) {
      List<String> headers = widget.draftOrder[0].map<String>((dynamic col) => col.toString().toUpperCase()).toList();
      for (int i = 0; i < headers.length; i++) {
        columnIndices[headers[i]] = i;
      }
    }
    
    // Get index for key columns
    int pickIndex = columnIndices['PICK'] ?? 0;
    int teamIndex = columnIndices['TEAM'] ?? 1;
    int selectionIndex = columnIndices['SELECTION'] ?? 2;
    int positionIndex = columnIndices['POSITION'] ?? 3;
    int roundIndex = columnIndices['ROUND'] ?? 4;
    int tradeIndex = columnIndices['TRADE'] ?? 5;

    // Filter draft order rows
    List<List<dynamic>> filteredRows = widget.draftOrder
      .skip(1)  // Skip header row
      .where((row) {
        // Check if row has enough elements
        if (row.length <= teamIndex) return false;
        
        // Filter by search query
        String teamName = row[teamIndex].toString();
        bool matchesSearch = _searchQuery.isEmpty || 
                           teamName.toLowerCase().contains(_searchQuery.toLowerCase());
        
        return matchesSearch;
      })
      .toList();
  
    // Convert to DraftPick objects
    List<DraftPick> draftPicks = [];
    for (var row in filteredRows) {
      try {
        // Parse pick number
        int pickNumber = pickIndex < row.length ? 
                       (int.tryParse(row[pickIndex].toString()) ?? 0) : 0;
        
        // Get team name
        String teamName = teamIndex < row.length ? row[teamIndex].toString() : "Unknown";
        
        // Parse round
        String round = roundIndex < row.length ? row[roundIndex].toString() : "1";
        if (round.isEmpty) {
          round = ((pickNumber - 1) / 32 + 1).floor().toString();
        }
        
        // Get trade info if available
        String? tradeInfo = (tradeIndex < row.length) ? row[tradeIndex].toString() : null;
        if (tradeInfo?.isEmpty ?? true) tradeInfo = null;
        
        // Create the draft pick
        final draftPick = DraftPick(
          pickNumber: pickNumber,
          teamName: teamName,
          round: round,
          tradeInfo: tradeInfo,
        );
        
        // Add selected player if there is one
        if (selectionIndex < row.length && row[selectionIndex].toString().isNotEmpty) {
          String playerName = row[selectionIndex].toString();
          String position = (positionIndex < row.length) ? row[positionIndex].toString() : "";
          
          draftPick.selectedPlayer = Player(
            id: pickNumber, // Using pick number as ID for simplicity
            name: playerName,
            position: position,
            rank: pickNumber, // Default to pick number as rank if you don't have the actual rank
          );
        }
        
        draftPicks.add(draftPick);
      } catch (e) {
        debugPrint("Error processing draft row: $e");
      }
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
          teamNeeds: _getTeamNeeds(draftPicks[index].teamName), // Add this line
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
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
}