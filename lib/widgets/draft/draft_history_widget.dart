// lib/widgets/draft/draft_history_widget.dart
import 'package:flutter/material.dart';
import '../../models/draft_pick.dart';
import '../../models/player.dart';
import 'animated_draft_pick_card.dart';

class DraftHistoryWidget extends StatefulWidget {
  final List<DraftPick> completedPicks;
  final String? userTeam;

  const DraftHistoryWidget({
    super.key,
    required this.completedPicks,
    this.userTeam,
  });

  @override
  State<DraftHistoryWidget> createState() => _DraftHistoryWidgetState();
}

class _DraftHistoryWidgetState extends State<DraftHistoryWidget> {
  String _searchQuery = '';
  String _positionFilter = '';
  String _teamFilter = '';
  String _roundFilter = '';
  String _sortBy = 'Pick'; // Options: Pick, Rank, Value
  bool _ascending = true;

  // For analytics
  int _totalPicks = 0;
  double _averageValueGap = 0;
  Map<String, int> _positionCounts = {};

  @override
  void initState() {
    super.initState();
    _calculateAnalytics();
  }
  
  @override
  void didUpdateWidget(DraftHistoryWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.completedPicks.length != oldWidget.completedPicks.length) {
      _calculateAnalytics();
    }
  }
  
  void _calculateAnalytics() {
    _totalPicks = widget.completedPicks.where((p) => p.selectedPlayer != null).length;
    _positionCounts = {};
    
    int totalValueGap = 0;
    for (var pick in widget.completedPicks) {
      if (pick.selectedPlayer != null) {
        final player = pick.selectedPlayer!;
        
        // Count positions
        _positionCounts[player.position] = (_positionCounts[player.position] ?? 0) + 1;
        
        // Calculate value gap
        totalValueGap += (pick.pickNumber - player.rank);
      }
    }
    
    _averageValueGap = _totalPicks > 0 ? totalValueGap / _totalPicks : 0;
  }

  List<DraftPick> _getFilteredPicks() {
    return widget.completedPicks.where((pick) {
      // Skip picks without players
      if (pick.selectedPlayer == null) return false;
      
      // Apply search filter
      bool matchesSearch = _searchQuery.isEmpty || 
                         pick.selectedPlayer!.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                         pick.teamName.toLowerCase().contains(_searchQuery.toLowerCase());
      
      // Apply position filter
      bool matchesPosition = _positionFilter.isEmpty || 
                           pick.selectedPlayer!.position == _positionFilter;
      
      // Apply team filter
      bool matchesTeam = _teamFilter.isEmpty || 
                       pick.teamName == _teamFilter;
      
      // Apply round filter
      bool matchesRound = _roundFilter.isEmpty || 
                        pick.round == _roundFilter;
      
      return matchesSearch && matchesPosition && matchesTeam && matchesRound;
    }).toList();
  }

  List<DraftPick> _getSortedPicks(List<DraftPick> filteredPicks) {
    switch (_sortBy) {
      case 'Pick':
        filteredPicks.sort((a, b) => _ascending
            ? a.pickNumber.compareTo(b.pickNumber)
            : b.pickNumber.compareTo(a.pickNumber));
        break;
      case 'Rank':
        filteredPicks.sort((a, b) => _ascending
            ? a.selectedPlayer!.rank.compareTo(b.selectedPlayer!.rank)
            : b.selectedPlayer!.rank.compareTo(a.selectedPlayer!.rank));
        break;
      case 'Value':
        filteredPicks.sort((a, b) {
          int aValue = a.pickNumber - a.selectedPlayer!.rank;
          int bValue = b.pickNumber - b.selectedPlayer!.rank;
          return _ascending
              ? aValue.compareTo(bValue)
              : bValue.compareTo(aValue);
        });
        break;
    }
    return filteredPicks;
  }
  
  Set<String> _getAllPositions() {
    return widget.completedPicks
        .where((pick) => pick.selectedPlayer != null)
        .map((pick) => pick.selectedPlayer!.position)
        .toSet();
  }
  
  Set<String> _getAllTeams() {
    return widget.completedPicks
        .where((pick) => pick.selectedPlayer != null)
        .map((pick) => pick.teamName)
        .toSet();
  }
  
  Set<String> _getAllRounds() {
    return widget.completedPicks
        .where((pick) => pick.selectedPlayer != null)
        .map((pick) => pick.round)
        .toSet();
  }

  @override
  Widget build(BuildContext context) {
    final filteredPicks = _getFilteredPicks();
    final sortedPicks = _getSortedPicks(filteredPicks);
    
    final positions = _getAllPositions();
    final teams = _getAllTeams();
    final rounds = _getAllRounds();
    
    return Column(
      children: [
        // Analytics summary
        Card(
          margin: const EdgeInsets.all(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Draft Summary',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildSummaryItem(
                      'Total Picks',
                      '$_totalPicks',
                      Icons.sports_football,
                      Colors.blue,
                    ),
                    _buildSummaryItem(
                      'Avg. Value',
                      _averageValueGap.toStringAsFixed(1),
                      _averageValueGap >= 0 ? Icons.trending_up : Icons.trending_down,
                      _averageValueGap >= 0 ? Colors.green : Colors.red,
                    ),
                    _buildSummaryItem(
                      'Top Position',
                      _getTopPosition(),
                      Icons.people,
                      Colors.purple,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        
        // Search bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TextField(
            decoration: const InputDecoration(
              labelText: 'Search players or teams',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
          ),
        ),
        
        // Filter rows
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Filters',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    // Position filter
                    _buildFilterDropdown(
                      'Position',
                      _positionFilter,
                      ['', ...positions],
                      (value) {
                        setState(() {
                          _positionFilter = value ?? '';
                        });
                      },
                    ),
                    const SizedBox(width: 16),
                    
                    // Team filter
                    _buildFilterDropdown(
                      'Team',
                      _teamFilter,
                      ['', ...teams],
                      (value) {
                        setState(() {
                          _teamFilter = value ?? '';
                        });
                      },
                    ),
                    const SizedBox(width: 16),
                    
                    // Round filter
                    _buildFilterDropdown(
                      'Round',
                      _roundFilter,
                      ['', ...rounds],
                      (value) {
                        setState(() {
                          _roundFilter = value ?? '';
                        });
                      },
                    ),
                    const SizedBox(width: 16),
                    
                    // Sort by
                    _buildFilterDropdown(
                      'Sort By',
                      _sortBy,
                      ['Pick', 'Rank', 'Value'],
                      (value) {
                        setState(() {
                          _sortBy = value ?? 'Pick';
                        });
                      },
                    ),
                    const SizedBox(width: 8),
                    
                    // Sort direction
                    IconButton(
                      icon: Icon(_ascending ? Icons.arrow_upward : Icons.arrow_downward),
                      onPressed: () {
                        setState(() {
                          _ascending = !_ascending;
                        });
                      },
                      tooltip: _ascending ? 'Ascending' : 'Descending',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        
        // Results text
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Showing ${sortedPicks.length} of ${widget.completedPicks.length} picks',
            style: TextStyle(
              color: Colors.grey[600],
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
        
        // Draft picks list
        Expanded(
          child: sortedPicks.isEmpty
              ? Center(
                  child: Text(
                    'No picks match your filters',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: sortedPicks.length,
                  itemBuilder: (context, index) {
                    final pick = sortedPicks[index];
                    final isUserTeam = pick.teamName == widget.userTeam;
                    
                    return AnimatedDraftPickCard(
                      draftPick: pick,
                      isUserTeam: isUserTeam,
                      isRecentPick: index < 3 && _sortBy == 'Pick' && !_ascending,
                    );
                  },
                ),
        ),
      ],
    );
  }
  
  Widget _buildSummaryItem(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Icon(
          icon,
          color: color,
          size: 24,
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          title,
          style: const TextStyle(
            fontSize: 12,
          ),
        ),
      ],
    );
  }
  
  Widget _buildFilterDropdown(
    String label,
    String value,
    List<String> options,
    Function(String?) onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
          ),
        ),
        DropdownButton<String>(
          value: value.isEmpty ? options.first : value,
          onChanged: onChanged,
          items: options.map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value.isEmpty ? 'All $label' : value),
            );
          }).toList(),
        ),
      ],
    );
  }
  
  String _getTopPosition() {
    if (_positionCounts.isEmpty) return 'N/A';
    
    String topPosition = '';
    int maxCount = 0;
    
    for (var entry in _positionCounts.entries) {
      if (entry.value > maxCount) {
        maxCount = entry.value;
        topPosition = entry.key;
      }
    }
    
    return topPosition;
  }
}