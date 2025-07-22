import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class WRProjections2025Screen extends StatefulWidget {
  const WRProjections2025Screen({super.key});

  @override
  State<WRProjections2025Screen> createState() => _WRProjections2025ScreenState();
}

class _WRProjections2025ScreenState extends State<WRProjections2025Screen> {
  bool _showValues = true;
  final String _selectedSeason = '2025';
  String _selectedTeam = 'All Teams';
  String _selectedTier = 'All Tiers';
  List<Map<String, dynamic>> _projections = [];
  bool _isLoading = true;
  String _sortBy = 'myRankNum';

  final List<String> _teams = [
    'All Teams', 'ARI', 'ATL', 'BAL', 'BUF', 'CAR', 'CHI', 'CIN', 'CLE', 'DAL', 'DEN',
    'DET', 'GB', 'HOU', 'IND', 'JAX', 'KC', 'LV', 'LAC', 'LA', 'MIA', 'MIN', 'NE',
    'NO', 'NYG', 'NYJ', 'PHI', 'PIT', 'SEA', 'SF', 'TB', 'TEN', 'WAS'
  ];

  final List<String> _tiers = [
    'All Tiers', 'Tier 1', 'Tier 2', 'Tier 3', 'Tier 4',
    'Tier 5', 'Tier 6', 'Tier 7', 'Tier 8'
  ];

  @override
  void initState() {
    super.initState();
    _loadProjections();
  }

  Future<void> _loadProjections() async {
    setState(() => _isLoading = true);
    
    try {
      Query query = FirebaseFirestore.instance.collection('wr_projections_2025');
      
      // Apply filters
      if (_selectedTeam != 'All Teams') {
        query = query.where('NY_posteam', isEqualTo: _selectedTeam);
      }
      
      if (_selectedTier != 'All Tiers') {
        int tier = int.parse(_selectedTier.split(' ')[1]);
        query = query.where('wr_tier', isEqualTo: tier);
      }
      
      final snapshot = await query.get();
      
      setState(() {
        _projections = snapshot.docs.map((doc) {
          var data = doc.data() as Map<String, dynamic>;
          return {
            ...data,
            'id': doc.id,
          };
        }).toList();
        
        // Sort data
        _sortProjections();
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading projections: $e');
      setState(() => _isLoading = false);
    }
  }

  void _sortProjections() {
    _projections.sort((a, b) {
      switch (_sortBy) {
        case 'myRankNum':
          return (a['myRankNum'] ?? 999).compareTo(b['myRankNum'] ?? 999);
        case 'projected_points':
          return (b['projected_points'] ?? 0).compareTo(a['projected_points'] ?? 0);
        case 'projected_yards':
          return (b['projected_yards'] ?? 0).compareTo(a['projected_yards'] ?? 0);
        case 'player_name':
          return (a['player_name'] ?? '').compareTo(b['player_name'] ?? '');
        default:
          return (a['myRankNum'] ?? 999).compareTo(b['myRankNum'] ?? 999);
      }
    });
  }

  Color _getTierColor(int tier) {
    switch (tier) {
      case 1: return Colors.purple.shade600;
      case 2: return Colors.blue.shade600;
      case 3: return Colors.green.shade600;
      case 4: return Colors.orange.shade600;
      case 5: return Colors.red.shade600;
      case 6: return Colors.brown.shade600;
      case 7: return Colors.grey.shade600;
      case 8: return Colors.grey.shade400;
      default: return Colors.grey.shade400;
    }
  }

  Widget _buildFilterChips() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        // Team Filter
        PopupMenuButton<String>(
          initialValue: _selectedTeam,
          onSelected: (value) {
            setState(() => _selectedTeam = value);
            _loadProjections();
          },
          child: Chip(
            label: Text(_selectedTeam),
            backgroundColor: Colors.blue.shade50,
          ),
          itemBuilder: (context) => _teams.map((team) => 
            PopupMenuItem(value: team, child: Text(team))).toList(),
        ),
        
        // Tier Filter
        PopupMenuButton<String>(
          initialValue: _selectedTier,
          onSelected: (value) {
            setState(() => _selectedTier = value);
            _loadProjections();
          },
          child: Chip(
            label: Text(_selectedTier),
            backgroundColor: Colors.green.shade50,
          ),
          itemBuilder: (context) => _tiers.map((tier) => 
            PopupMenuItem(value: tier, child: Text(tier))).toList(),
        ),
        
        // Sort By
        PopupMenuButton<String>(
          initialValue: _sortBy,
          onSelected: (value) {
            setState(() => _sortBy = value);
            _sortProjections();
          },
          child: Chip(
            label: Text(_getSortLabel(_sortBy)),
            backgroundColor: Colors.orange.shade50,
          ),
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'myRankNum', child: Text('My Rank')),
            const PopupMenuItem(value: 'projected_points', child: Text('Projected Points')),
            const PopupMenuItem(value: 'projected_yards', child: Text('Projected Yards')),
            const PopupMenuItem(value: 'player_name', child: Text('Player Name')),
          ],
        ),
        
        // Toggle Values/Ranks
        FilterChip(
          label: Text(_showValues ? 'Show Values' : 'Show Ranks'),
          selected: _showValues,
          onSelected: (selected) => setState(() => _showValues = selected),
          backgroundColor: Colors.purple.shade50,
          selectedColor: Colors.purple.shade100,
        ),
      ],
    );
  }

  String _getSortLabel(String sortBy) {
    switch (sortBy) {
      case 'myRankNum': return 'My Rank';
      case 'projected_points': return 'Points';
      case 'projected_yards': return 'Yards';
      case 'player_name': return 'Name';
      default: return 'My Rank';
    }
  }

  Widget _buildProjectionCard(Map<String, dynamic> projection) {
    final tier = projection['wr_tier'] ?? 8;
    final tierColor = _getTierColor(tier);
    final rank = projection['myRankNum'] ?? 0;
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      elevation: 2,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: tierColor,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$rank',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          title: Row(
            children: [
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      projection['player_name'] ?? 'Unknown',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      '${projection['NY_posteam'] ?? projection['posteam'] ?? 'FA'} • Tier $tier',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              if (_showValues) ...[
                Expanded(
                  child: Text(
                    '${(projection['projected_points'] ?? 0).toStringAsFixed(1)} pts',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  child: Text(
                    '${(projection['projected_yards'] ?? 0).toStringAsFixed(0)} yds',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  child: Text(
                    '${projection['projected_touchdowns'] ?? 0} TDs',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                    textAlign: TextAlign.center,
                  ),
                ),
              ] else ...[
                Expanded(
                  child: Text(
                    '#$rank',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  child: Text(
                    'T$tier',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: tierColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ],
          ),
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Projection Stats
                  _buildStatRow('2025 Projections', ''),
                  const Divider(height: 20),
                  _buildStatRow('Points', '${(projection['projected_points'] ?? 0).toStringAsFixed(1)}'),
                  _buildStatRow('Yards', '${(projection['projected_yards'] ?? 0).toStringAsFixed(0)}'),
                  _buildStatRow('Touchdowns', '${projection['projected_touchdowns'] ?? 0}'),
                  _buildStatRow('Receptions', '${projection['projected_receptions'] ?? 0}'),
                  _buildStatRow('Games', '${projection['projected_games'] ?? 16}'),
                  
                  const SizedBox(height: 16),
                  
                  // Team Context
                  _buildStatRow('Team Context', ''),
                  const Divider(height: 20),
                  _buildStatRow('Target Share', '${((projection['NY_tgtShare'] ?? 0) * 100).toStringAsFixed(1)}%'),
                  _buildStatRow('Pass Offense Tier', '${projection['NY_passOffenseTier'] ?? 'N/A'}'),
                  _buildStatRow('QB Tier', '${projection['NY_qbTier'] ?? 'N/A'}'),
                  _buildStatRow('Pass Frequency Tier', '${projection['NY_passFreqTier'] ?? 'N/A'}'),
                  
                  if (projection['NY_posteam'] != projection['posteam']) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.trending_up, color: Colors.blue.shade600, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Projected move from ${projection['posteam']} to ${projection['NY_posteam']}',
                              style: TextStyle(
                                color: Colors.blue.shade800,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey.shade700,
              fontWeight: label.contains('Context') || label.contains('Projections') 
                ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: label.contains('Context') || label.contains('Projections')
                ? Colors.grey.shade700 : Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('2025 WR Projections'),
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadProjections,
          ),
        ],
      ),
      body: Column(
        children: [
          // Header with filters
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.sports_football, color: Colors.blue.shade600),
                    const SizedBox(width: 8),
                    const Text(
                      '2025 Wide Receiver Projections',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Fantasy projections and team context for the 2025 NFL season',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 16),
                _buildFilterChips(),
              ],
            ),
          ),
          
          // Column headers
          if (!_isLoading && _projections.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 56), // For rank circle
                  const Expanded(
                    flex: 3,
                    child: Text(
                      'Player',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ),
                  if (_showValues) ...[
                    const Expanded(
                      child: Text(
                        'Points',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const Expanded(
                      child: Text(
                        'Yards',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const Expanded(
                      child: Text(
                        'TDs',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ] else ...[
                    const Expanded(
                      child: Text(
                        'Rank',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const Expanded(
                      child: Text(
                        'Tier',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          
          // Content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _projections.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.sports_football,
                              size: 64,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No projections found',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Try adjusting your filters',
                              style: TextStyle(
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: _projections.length,
                        itemBuilder: (context, index) {
                          return _buildProjectionCard(_projections[index]);
                        },
                      ),
          ),
        ],
      ),
    );
  }
} 