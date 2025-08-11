// lib/widgets/trade/player_selection_modal.dart

import 'package:flutter/material.dart';
import '../../models/nfl_trade/nfl_player.dart';
import '../../models/nfl_trade/nfl_team_info.dart';
import '../../services/trade_data_service.dart';

class PlayerSelectionModal extends StatefulWidget {
  final String teamName;
  final String teamAbbreviation;
  final Function(NFLPlayer) onPlayerSelected;
  final NFLTeamInfo? receivingTeam; // Team that would receive the player
  final Future<double> Function(NFLPlayer, NFLTeamInfo)? calculateGrade; // Grade calculation function

  const PlayerSelectionModal({
    super.key,
    required this.teamName,
    required this.teamAbbreviation,
    required this.onPlayerSelected,
    this.receivingTeam,
    this.calculateGrade,
  });

  @override
  State<PlayerSelectionModal> createState() => _PlayerSelectionModalState();
}

class _PlayerSelectionModalState extends State<PlayerSelectionModal> {
  List<NFLPlayer> allPlayers = [];
  List<NFLPlayer> filteredPlayers = [];
  List<String> availablePositions = ['All'];
  String selectedPosition = 'All';
  String sortBy = 'rating'; // 'rating', 'age', 'name', 'position', 'salary'
  bool isLoading = true;
  String searchQuery = '';
  final TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadPlayers();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> _loadPlayers() async {
    setState(() => isLoading = true);
    
    try {
      await TradeDataService.initialize();
      allPlayers = TradeDataService.getPlayersByTeam(widget.teamAbbreviation);
      // Build positions list from loaded players
      final posSet = allPlayers.map((p) => p.position).where((p) => p.isNotEmpty).toSet().toList()..sort();
      availablePositions = ['All', ...posSet];
      
      _applyFiltersAndSort();
      
    } catch (e) {
      // print('Error loading players: $e');
      // Show error snackbar
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading players: $e')),
        );
      }
    }
    
    setState(() => isLoading = false);
  }

  void _applyFiltersAndSort() {
    List<NFLPlayer> filtered = allPlayers;
    
    // Apply position filter
    if (selectedPosition != 'All') {
      filtered = filtered.where((player) => player.position == selectedPosition).toList();
    }
    
    // Apply search filter
    if (searchQuery.isNotEmpty) {
      final searchLower = searchQuery.toLowerCase();
      filtered = filtered.where((player) => 
        player.name.toLowerCase().contains(searchLower) ||
        player.position.toLowerCase().contains(searchLower)
      ).toList();
    }
    
    // Apply sorting
    switch (sortBy) {
      case 'rating':
        filtered.sort((a, b) => b.overallRating.compareTo(a.overallRating));
        break;
      case 'age':
        filtered.sort((a, b) => a.age.compareTo(b.age));
        break;
      case 'name':
        filtered.sort((a, b) => a.name.compareTo(b.name));
        break;
      case 'position':
        filtered.sort((a, b) => a.position.compareTo(b.position));
        break;
      case 'salary':
        filtered.sort((a, b) => b.annualSalary.compareTo(a.annualSalary));
        break;
      case 'value':
        filtered.sort((a, b) => b.marketValue.compareTo(a.marketValue));
        break;
    }
    
    setState(() {
      filteredPlayers = filtered;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.85,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 16),
            _buildFilters(),
            const SizedBox(height: 16),
            Expanded(child: _buildPlayerList()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Icon(Icons.group, color: Theme.of(context).primaryColor),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Select Player',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${widget.teamName} Roster',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.close),
        ),
      ],
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        children: [
          // Search bar
          TextField(
            controller: searchController,
            decoration: const InputDecoration(
              hintText: 'Search players...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
              isDense: true,
            ),
            onChanged: (value) {
              searchQuery = value;
              _applyFiltersAndSort();
            },
          ),
          const SizedBox(height: 12),
          // Filter row
          Row(
            children: [
              // Position filter
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Position', style: TextStyle(fontWeight: FontWeight.bold)),
                    DropdownButtonFormField<String>(
                      value: selectedPosition,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      items: availablePositions.map((position) {
                        return DropdownMenuItem(
                          value: position,
                          child: Text(position),
                        );
                      }).toList(),
                      onChanged: (value) {
                        selectedPosition = value ?? 'All';
                        _applyFiltersAndSort();
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Sort by filter
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Sort By', style: TextStyle(fontWeight: FontWeight.bold)),
                    DropdownButtonFormField<String>(
                      value: sortBy,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      items: const [
                        DropdownMenuItem(value: 'rating', child: Text('Overall Rating')),
                        DropdownMenuItem(value: 'value', child: Text('Market Value')),
                        DropdownMenuItem(value: 'age', child: Text('Age')),
                        DropdownMenuItem(value: 'salary', child: Text('Salary')),
                        DropdownMenuItem(value: 'name', child: Text('Name')),
                        DropdownMenuItem(value: 'position', child: Text('Position')),
                      ],
                      onChanged: (value) {
                        sortBy = value ?? 'rating';
                        _applyFiltersAndSort();
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Results count
              Expanded(
                flex: 1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text('Results', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Center(
                        child: Text(
                          '${filteredPlayers.length}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Theme.of(context).primaryColor,
                          ),
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
    );
  }

  Widget _buildPlayerList() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (filteredPlayers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No players found',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your filters',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: filteredPlayers.length,
      itemBuilder: (context, index) {
        final player = filteredPlayers[index];
        return _buildPlayerCard(player, index);
      },
    );
  }

  Widget _buildPlayerCard(NFLPlayer player, int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 1,
      child: ListTile(
        leading: _buildPlayerAvatar(player),
        title: Text(
          player.name,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                _buildStatChip('Age ${player.age}', Colors.blue),
                const SizedBox(width: 4),
                _buildStatChip('${player.experience} YRS', Colors.green),
                const SizedBox(width: 4),
                _buildStatChip('\$${player.annualSalary.toStringAsFixed(1)}M', Colors.orange),
                const SizedBox(width: 4),
                _buildStatChip(player.ageTier.toUpperCase(), Colors.purple),
              ],
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.receivingTeam != null && widget.calculateGrade != null)
              FutureBuilder<double>(
                future: widget.calculateGrade!(player, widget.receivingTeam!),
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    double grade = snapshot.data!;
                    Color gradeColor = _getGradeColor(grade);
                    return Container(
                      width: 50,
                      height: 36,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: gradeColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: gradeColor.withValues(alpha: 0.5),
                          width: 1.5,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          '${grade.round()}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: gradeColor,
                          ),
                        ),
                      ),
                    );
                  } else {
                    return Container(
                      width: 50,
                      height: 36,
                      margin: const EdgeInsets.only(right: 8),
                      child: Center(
                        child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(Colors.grey[400]),
                          ),
                        ),
                      ),
                    );
                  }
                },
              ),
            ElevatedButton(
              onPressed: () {
                widget.onPlayerSelected(player);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              child: const Text(
                'SELECT',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayerAvatar(NFLPlayer player) {
    return CircleAvatar(
      backgroundColor: _getPositionColor(player.position).withValues(alpha: 0.2),
      child: Text(
        player.position,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: _getPositionColor(player.position),
        ),
      ),
    );
  }

  Color _getGradeColor(double grade) {
    if (grade >= 90) return Colors.purple; // A+
    if (grade >= 80) return Colors.green; // A
    if (grade >= 70) return Colors.blue; // B
    if (grade >= 60) return Colors.orange; // C
    if (grade >= 50) return Colors.amber; // D
    return Colors.red; // F
  }

  Widget _buildStatChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: color.withValues(alpha: 0.8),
        ),
      ),
    );
  }

  Color _getPositionColor(String position) {
    const positionColors = {
      'QB': Colors.purple,
      'RB': Colors.green,
      'WR': Colors.blue,
      'TE': Colors.teal,
      'OT': Colors.brown,
      'OG': Colors.brown,
      'C': Colors.brown,
      'DE': Colors.red,
      'DT': Colors.red,
      'EDGE': Colors.red,
      'LB': Colors.orange,
      'CB': Colors.indigo,
      'S': Colors.indigo,
      'K': Colors.grey,
      'P': Colors.grey,
    };
    return positionColors[position] ?? Colors.grey;
  }

}