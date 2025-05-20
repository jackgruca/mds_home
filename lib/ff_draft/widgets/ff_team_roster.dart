import 'package:flutter/material.dart';
import '../models/ff_team.dart';
import '../models/ff_player.dart';

class FFTeamRoster extends StatelessWidget {
  final FFTeam team;
  final Function(FFPlayer) onPlayerSelected;

  const FFTeamRoster({
    super.key,
    required this.team,
    required this.onPlayerSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header (player count only)
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            border: Border(
              bottom: BorderSide(
                color: Colors.grey[300]!,
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              const Spacer(),
              Text(
                '${team.roster.length} players',
                style: TextStyle(
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),

        // Roster sections
        Expanded(
          child: ListView(
            children: [
              _buildRosterSection('Starters', _getStarterPositions()),
              _buildRosterSection('Bench', _getBenchPositions()),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRosterSection(String title, List<String> positions) {
    // Create a copy of the roster to track which players have been assigned
    final assigned = <int>{};
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        ...positions.asMap().entries.map((entry) {
          final idx = entry.key;
          final position = entry.value;
          // Find the first unassigned player for this position
          final playerIdx = team.roster.indexWhere((p) => p.position == position && !assigned.contains(team.roster.indexOf(p)) && p.id.isNotEmpty);
          FFPlayer? player;
          if (playerIdx != -1) {
            player = team.roster[playerIdx];
            assigned.add(playerIdx);
          } else {
            player = FFPlayer(id: '', name: '', position: position, team: '', stats: {});
          }
          return _buildPlayerCard(player, position);
        }).toList(),
      ],
    );
  }

  Widget _buildPlayerCard(FFPlayer player, String position) {
    final isEmpty = player.id.isEmpty;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isEmpty ? Colors.grey[300] : _getPositionColor(position),
          child: Text(
            position,
            style: TextStyle(
              color: isEmpty ? Colors.grey[600] : Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: isEmpty
            ? const SizedBox.shrink()
            : Text(
                player.name,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
        subtitle: isEmpty
            ? null
            : Text(
                '${player.team} - $position',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
        trailing: isEmpty
            ? null
            : IconButton(
                icon: const Icon(Icons.remove_circle_outline),
                onPressed: () {
                  // TODO: Remove player from roster
                },
              ),
        onTap: isEmpty ? null : () => onPlayerSelected(player),
      ),
    );
  }

  List<String> _getStarterPositions() {
    return [
      'QB',
      'RB',
      'RB',
      'WR',
      'WR',
      'WR',
      'TE',
      'FLEX',
      'K',
      'DEF',
    ];
  }

  List<String> _getBenchPositions() {
    return List.generate(6, (index) => 'BN${index + 1}');
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
      case 'FLEX':
        return Colors.amber;
      case 'K':
        return Colors.red;
      case 'DEF':
        return Colors.brown;
      default:
        return Colors.grey;
    }
  }
} 