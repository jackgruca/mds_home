import 'package:flutter/material.dart';
import '../models/draft_pick.dart';
import '../models/player.dart';
import '../widgets/draft/animated_draft_pick_card.dart';

class DraftOrderTab extends StatefulWidget {
  // Update this to accept a list of DraftPick objects instead of List<List<dynamic>>
  final List<DraftPick> draftOrder; 
  final String? userTeams;
  final ScrollController? scrollController;
  final List<List<dynamic>> teamNeeds; // Still need this for team needs
  
  const DraftOrderTab({
    required this.draftOrder,
    this.userTeams,
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
      padding: const EdgeInsets.symmetric(vertical: 4),
      itemCount: filteredPicks.length,
      itemBuilder: (context, index) {
        final DraftPick draftPick = filteredPicks[index];
        final isUserTeams = draftPick.teamName == widget.userTeams;
        final isRecentPick = index < 3; // Consider the first 3 picks as "recent"
        
        return AnimatedDraftPickCard(
          draftPick: draftPick,
          isUserTeams: isUserTeams,
          isRecentPick: isRecentPick,
          teamNeeds: _getTeamNeeds(draftPick.teamName),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          // Search Bar - Styled to match the design in AvailablePlayersTab
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8.0),
              border: Border.all(
                color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
              ),
            ),
            child: Row(
              children: [
                // Search field
                Expanded(
                  child: SizedBox(
                    height: 36,
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Search by Team',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        contentPadding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
                      ),
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value;
                        });
                      },
                    ),
                  ),
                ),
                
                // Pick count
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${widget.draftOrder.length} picks',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDarkMode ? Colors.white : Colors.grey.shade800,
                    ),
                  ),
                ),
                
                // Clear search button when search is active
                if (_searchQuery.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.clear, size: 16),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    visualDensity: VisualDensity.compact,
                    onPressed: () {
                      setState(() {
                        _searchQuery = '';
                      });
                    },
                    tooltip: 'Clear search',
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Draft Order List
          Expanded(
            child: _buildDraftOrderCards(),
          ),
        ],
      ),
    );
  }
}