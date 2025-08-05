import 'package:flutter/material.dart';
import '../../models/player_info.dart';
import '../../services/player_data_service.dart';
import 'player_detail_screen.dart';

class PlayerListScreen extends StatefulWidget {
  const PlayerListScreen({Key? key}) : super(key: key);

  @override
  State<PlayerListScreen> createState() => _PlayerListScreenState();
}

class _PlayerListScreenState extends State<PlayerListScreen> {
  final PlayerDataService _playerService = PlayerDataService();
  final TextEditingController _searchController = TextEditingController();
  
  List<PlayerInfo> _allPlayers = [];
  List<PlayerInfo> _filteredPlayers = [];
  String? _selectedPosition;
  String? _selectedTeam;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
    _searchController.addListener(_filterPlayers);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    print('PlayerListScreen: Starting to load data... (ASSETS RESTART)');
    try {
      await _playerService.loadPlayerData();
      print('PlayerListScreen: Player service loaded');
      
      final allPlayers = _playerService.getAllPlayers();
      print('PlayerListScreen: Got ${allPlayers.length} players from service');
      
      setState(() {
        _allPlayers = allPlayers;
        _filteredPlayers = _allPlayers;
        _isLoading = false;
      });
      
      print('PlayerListScreen: State updated, loading complete');
    } catch (e) {
      print('PlayerListScreen: Error loading data: $e');
      setState(() {
        _allPlayers = [];
        _filteredPlayers = [];
        _isLoading = false;
      });
    }
  }

  void _filterPlayers() {
    setState(() {
      _filteredPlayers = _allPlayers.where((player) {
        // Search filter
        if (_searchController.text.isNotEmpty && 
            !player.matchesSearch(_searchController.text)) {
          return false;
        }
        
        // Position filter
        if (_selectedPosition != null && 
            player.positionGroup != _selectedPosition) {
          return false;
        }
        
        // Team filter
        if (_selectedTeam != null && 
            player.team != _selectedTeam) {
          return false;
        }
        
        return true;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('NFL Players'),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final teams = _playerService.getAllTeams();
    final positions = ['QB', 'RB', 'WR', 'TE'];

    return Scaffold(
      appBar: AppBar(
        title: const Text('NFL Players'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(120),
          child: Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Search bar
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search players...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    fillColor: Theme.of(context).colorScheme.surface,
                    filled: true,
                  ),
                ),
                const SizedBox(height: 8),
                // Filter chips
                Row(
                  children: [
                    // Position filter
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            const Text('Position: '),
                            ...positions.map((pos) => Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: FilterChip(
                                label: Text(pos),
                                selected: _selectedPosition == pos,
                                onSelected: (selected) {
                                  setState(() {
                                    _selectedPosition = selected ? pos : null;
                                  });
                                  _filterPlayers();
                                },
                              ),
                            )),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      body: _filteredPlayers.isEmpty
          ? Center(
              child: Text(
                'No players found',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            )
          : ListView.builder(
              itemCount: _selectedTeam != null 
                  ? _filteredPlayers.length
                  : teams.length,
              itemBuilder: (context, index) {
                if (_selectedTeam != null) {
                  // Show individual players
                  return _buildPlayerTile(_filteredPlayers[index]);
                } else {
                  // Show teams with players
                  final team = teams[index];
                  final teamPlayers = _filteredPlayers
                      .where((p) => p.team == team)
                      .toList();
                  
                  if (teamPlayers.isEmpty) return const SizedBox.shrink();
                  
                  return ExpansionTile(
                    title: Text(
                      team,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text('${teamPlayers.length} players'),
                    children: teamPlayers.map(_buildPlayerTile).toList(),
                  );
                }
              },
            ),
    );
  }

  Widget _buildPlayerTile(PlayerInfo player) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: _getPositionColor(player.positionGroup),
        child: Text(
          player.position,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
      title: Text(player.displayNameOrFullName),
      subtitle: Text(
        '${player.team} • ${player.fantasyPpg.toStringAsFixed(1)} PPG',
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (player.jerseyNumber != null)
            Text(
              '#${player.jerseyNumber}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right),
        ],
      ),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PlayerDetailScreen(player: player),
          ),
        );
      },
    );
  }

  Color _getPositionColor(String position) {
    switch (position) {
      case 'QB':
        return Colors.red;
      case 'RB':
        return Colors.green;
      case 'WR':
        return Colors.blue;
      case 'TE':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
}