// Update the DraftOrderTab class to handle current pick tracking
import 'package:flutter/material.dart';

import '../models/draft_pick.dart';
import '../widgets/common/help_button.dart';
import '../widgets/draft/animated_draft_pick_card.dart';

class DraftOrderTab extends StatefulWidget {
  final List<DraftPick> draftOrder;
  final String? userTeam;
  final ScrollController? scrollController;
  final List<List<dynamic>> teamNeeds; // Still need this for team needs
  final int? currentPickNumber; // Add this to track the current pick 
  
  const DraftOrderTab({
    required this.draftOrder,
    this.userTeam,
    this.scrollController,
    required this.teamNeeds,
    this.currentPickNumber, // New parameter
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
        final isUserTeam = draftPick.teamName == widget.userTeam;
        final isRecentPick = index < 3; // Consider the first 3 picks as "recent"
        
        // Check if this is the current pick
        final isCurrentPick = widget.currentPickNumber != null && 
                             draftPick.pickNumber == widget.currentPickNumber;
        
        // Add key for better list diffing and animation
        return AnimatedDraftPickCard(
          key: ValueKey('draft-pick-${draftPick.pickNumber}'),
          draftPick: draftPick,
          isUserTeam: isUserTeam,
          isRecentPick: isRecentPick,
          teamNeeds: _getTeamNeeds(draftPick.teamName),
          isCurrentPick: isCurrentPick, // Pass the isCurrentPick flag
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
                
                // Help button
                IconButton(
                  icon: const Icon(Icons.help_outline),
                  tooltip: 'What can I do?',
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Draft Order'),
                        content: const Text(
                          'This tab shows the order of picks in the draft.\n\n'
                          '• Your team\'s picks are highlighted in blue\n'
                          '• The current pick is highlighted in green\n'
                          '• Each card shows the team, pick number, and top team needs\n'
                          '• Completed picks show the selected player\n'
                          '• The draft proceeds top to bottom\n'
                          '• When a trade occurs, the draft order will update'
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('Got it'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                
                // Current pick indicator
                if (widget.currentPickNumber != null)
                  Container(
                    margin: const EdgeInsets.only(left: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isDarkMode ? Colors.green.shade800 : Colors.green.shade100,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: isDarkMode ? Colors.green.shade600 : Colors.green.shade300,
                      ),
                    ),
                    child: Text(
                      'Pick #${widget.currentPickNumber}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? Colors.white : Colors.green.shade900,
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