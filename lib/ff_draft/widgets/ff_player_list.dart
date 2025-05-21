import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/ff_player.dart';
import '../models/ff_draft_pick.dart';
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
  final String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<FFDraftProvider>(context);
    final availablePlayers = provider.availablePlayers;
    final draftPicks = provider.draftPicks;
    final teams = provider.teams;
    final numTeams = teams.length;
    return ListView.builder(
      itemCount: availablePlayers.length,
      itemBuilder: (context, index) {
        final player = availablePlayers[index];
        // Always use player.rank or player.stats['rank'] for the left circle
        final rank = player.rank ?? player.stats?['rank'] ?? index + 1;
        // Find the original pick for this player (for round/pick/team display)
        FFDraftPick? originalPick;
        try {
          originalPick = draftPicks.firstWhere((pick) => pick.selectedPlayer?.id == player.id);
        } catch (_) {
          originalPick = null;
        }
        String bottomRow;
        if (originalPick != null) {
          final pickNumber = originalPick.pickNumber;
          final round = originalPick.round;
          final pickInRound = pickNumber - (round - 1) * numTeams;
          final teamName = originalPick.team.name;
          bottomRow = '$round.$pickInRound $teamName';
        } else {
          bottomRow = player.team.isNotEmpty ? player.team : '';
        }
        final roundColor = _getRoundColor((rank - 1) ~/ numTeams + 1);
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: roundColor,
              child: Text(
                rank.toString(),
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    player.name,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                const SizedBox(width: 8),
                _buildPositionBadge(player.position),
              ],
            ),
            subtitle: Text(bottomRow),
            onTap: () => widget.onPlayerSelected(player),
          ),
        );
      },
    );
  }

  Color _getRoundColor(int round) {
    // Cycle through a palette for rounds
    const palette = [
      Colors.blue, Colors.green, Colors.orange, Colors.purple, Colors.red, Colors.teal, Colors.brown
    ];
    return palette[(round - 1) % palette.length];
  }

  Widget _buildPositionBadge(String position) {
    Color color;
    switch (position) {
      case 'QB':
        color = Colors.blue;
        break;
      case 'RB':
        color = Colors.green;
        break;
      case 'WR':
        color = Colors.orange;
        break;
      case 'TE':
        color = Colors.purple;
        break;
      case 'K':
        color = Colors.red;
        break;
      case 'DEF':
      case 'D/ST':
        color = Colors.brown;
        break;
      default:
        color = Colors.grey;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color, width: 1),
      ),
      child: Text(
        position,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 13,
        ),
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