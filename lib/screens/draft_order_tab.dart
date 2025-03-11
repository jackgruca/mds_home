import 'package:flutter/material.dart';
import '../models/draft_pick.dart';
import '../models/player.dart';
import '../widgets/draft/animated_draft_pick_card.dart';

class DraftOrderTab extends StatefulWidget {
  // Update this to accept a list of DraftPick objects instead of List<List<dynamic>>
  final List<DraftPick> draftOrder; 
  final String? userTeam;
  final ScrollController? scrollController;
  final List<List<dynamic>> teamNeeds; // Still need this for team needs
  
  const DraftOrderTab({
    required this.draftOrder,
    this.userTeam,
    this.scrollController,
    required this.teamNeeds,
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
    // Filter draft order based on search
    List<DraftPick> filteredPicks = widget.draftOrder
      .where((pick) {
        // Filter by search query
        String teamName = pick.teamName;
        bool matchesSearch = _searchQuery.isEmpty || 
                           teamName.toLowerCase().contains(_searchQuery.toLowerCase());
        
        return matchesSearch;
      })
      .toList();

    return ListView.builder(
      controller: _scrollController,
      itemCount: filteredPicks.length,
      itemBuilder: (context, index) {
        final DraftPick draftPick = filteredPicks[index];
        final isUserTeam = draftPick.teamName == widget.userTeam;
        final isRecentPick = index < 3; // Consider the first 3 picks as "recent"
        
        return AnimatedDraftPickCard(
          draftPick: draftPick,
          isUserTeam: isUserTeam,
          isRecentPick: isRecentPick,
          teamNeeds: _getTeamNeeds(draftPick.teamName),
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