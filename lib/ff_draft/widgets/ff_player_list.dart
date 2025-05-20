import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/ff_player.dart';
import '../providers/ff_draft_provider.dart';

class FFPlayerList extends StatefulWidget {
  final Function(FFPlayer) onPlayerSelected;

  const FFPlayerList({
    super.key,
    required this.onPlayerSelected,
  });

  @override
  State<FFPlayerList> createState() => _FFPlayerListState();
}

class _FFPlayerListState extends State<FFPlayerList> {
  String _selectedPosition = 'All';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          // Search bar
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search players...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _searchQuery = '';
                        });
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
          ),
          
          const SizedBox(height: 8),
          
          // Position filter
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildPositionChip('All'),
                _buildPositionChip('QB'),
                _buildPositionChip('RB'),
                _buildPositionChip('WR'),
                _buildPositionChip('TE'),
                _buildPositionChip('K'),
                _buildPositionChip('DEF'),
              ],
            ),
          ),
          
          const SizedBox(height: 8),
          
          // Player list
          Expanded(
            child: Consumer<FFDraftProvider>(
              builder: (context, provider, child) {
                final players = _filterPlayers(provider);
                
                return ListView.builder(
                  itemCount: players.length,
                  itemBuilder: (context, index) {
                    final player = players[index];
                    final canDraft = provider.canDraftPlayer(player);
                    
                    return _buildPlayerListItem(
                      context,
                      player,
                      canDraft,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPositionChip(String position) {
    final isSelected = position == _selectedPosition;
    
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: FilterChip(
        label: Text(position),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _selectedPosition = selected ? position : 'All';
          });
        },
      ),
    );
  }

  Widget _buildPlayerListItem(
    BuildContext context,
    FFPlayer player,
    bool canDraft,
  ) {
    final theme = Theme.of(context);
    final rank = player.stats?['rank'] as int? ?? 0;
    final adp = player.stats?['adp'] as double? ?? 0.0;
    final projectedPoints = player.stats?['projectedPoints'] as double? ?? 0.0;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 4.0),
      child: ListTile(
        enabled: canDraft,
        onTap: canDraft ? () => widget.onPlayerSelected(player) : null,
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: _getPositionColor(player.position),
            borderRadius: BorderRadius.circular(4.0),
          ),
          child: Center(
            child: Text(
              player.position,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        title: Row(
          children: [
            Text(
              player.name,
              style: TextStyle(
                color: canDraft ? null : Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '#$rank',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[700],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                  player.team ?? 'FA',
                  style: TextStyle(
                    color: canDraft ? Colors.grey[600] : Colors.grey,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'ADP: ${adp.toStringAsFixed(1)}',
                  style: TextStyle(
                    color: canDraft ? Colors.grey[600] : Colors.grey,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Proj: ${projectedPoints.toStringAsFixed(1)}',
                  style: TextStyle(
                    color: canDraft ? Colors.grey[600] : Colors.grey,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(
                player.isFavorite ? Icons.star : Icons.star_border,
                color: player.isFavorite ? Colors.amber : Colors.grey,
              ),
              onPressed: () {
                Provider.of<FFDraftProvider>(context, listen: false).toggleFavorite(player);
              },
            ),
            canDraft
                ? IconButton(
                    icon: const Icon(Icons.add_circle_outline),
                    onPressed: () => widget.onPlayerSelected(player),
                  )
                : const Icon(Icons.block),
          ],
        ),
      ),
    );
  }

  List<FFPlayer> _filterPlayers(FFDraftProvider provider) {
    var players = provider.availablePlayers;
    
    // Filter by position
    if (_selectedPosition != 'All') {
      players = players.where((p) => p.position == _selectedPosition).toList();
    }
    
    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      players = players.where((p) {
        return p.name.toLowerCase().contains(query) ||
            (p.team.toLowerCase().contains(query) ?? false);
      }).toList();
    }
    
    return players;
  }

  Color _getPositionColor(String position) {
    switch (position) {
      case 'QB':
        return Colors.blue;
      case 'RB':
        return Colors.green;
      case 'WR':
        return Colors.orange;
      case 'TE':
        return Colors.purple;
      case 'K':
        return Colors.red;
      case 'DEF':
        return Colors.brown;
      default:
        return Colors.grey;
    }
  }
} 