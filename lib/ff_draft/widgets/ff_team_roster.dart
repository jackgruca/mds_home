import 'package:flutter/material.dart';
import '../models/ff_team.dart';
import '../models/ff_player.dart';
import '../models/ff_position_constants.dart';

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
        // Roster sections (remove player count header)
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
    // Assign players to starting spots, then FLEX, then BENCH
    final assigned = <int>{};
    final starters = _getStarterPositions();
    final flexEligible = ['RB', 'WR', 'TE'];
    final List<FFPlayer> starterPlayers = [];
    final List<FFPlayer> benchPlayers = [];

    // 1. Assign starters (excluding FLEX)
    for (var pos in starters.where((p) => p != 'FLEX')) {
      final idx = team.roster.indexWhere((p) => p.position == pos && !assigned.contains(team.roster.indexOf(p)) && p.id.isNotEmpty);
      if (idx != -1) {
        starterPlayers.add(team.roster[idx]);
        assigned.add(idx);
      } else {
        starterPlayers.add(FFPlayer(id: '', name: '', position: pos, team: '', stats: {}));
      }
    }

    // 2. Find FLEX candidate (first unassigned RB/WR/TE)
    int flexIdx = team.roster.indexWhere((p) => flexEligible.contains(p.position) && !assigned.contains(team.roster.indexOf(p)) && p.id.isNotEmpty);
    FFPlayer flexPlayer;
    if (flexIdx != -1) {
      flexPlayer = team.roster[flexIdx];
      assigned.add(flexIdx);
    } else {
      flexPlayer = FFPlayer(id: '', name: '', position: 'FLEX', team: '', stats: {});
    }

    // 3. All remaining unassigned players go to bench
    for (int i = 0; i < team.roster.length; i++) {
      if (!assigned.contains(i) && team.roster[i].id.isNotEmpty) {
        benchPlayers.add(team.roster[i]);
        assigned.add(i);
      }
    }

    // 4. Render the section
    if (title == 'Starters') {
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
          ...starterPlayers.map((player) => _buildPlayerCard(player, player.position)),
          _buildPlayerCard(flexPlayer, 'FLEX'),
        ],
      );
    } else if (title == 'Bench') {
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
            FFPlayer player = idx < benchPlayers.length
                ? benchPlayers[idx]
                : FFPlayer(id: '', name: '', position: 'BN${idx + 1}', team: '', stats: {});
            return _buildPlayerCard(player, 'BN');
          }).toList(),
        ],
      );
    } else {
      return const SizedBox.shrink();
    }
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
              fontSize: 12,
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
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${player.team} - $position',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    'ADP ${player.adp.toStringAsFixed(1)}',
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
        trailing: isEmpty
            ? null
            : const IconButton(
                icon: Icon(Icons.remove_circle_outline),
                onPressed: null,
              ),
        onTap: null,
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
    // Handle FLEX and bench positions specially
    if (position == 'FLEX') {
      return const Color(0xFFFF9800); // Amber/Orange
    } else if (position.startsWith('BN')) {
      return const Color(0xFF757575); // Gray for bench
    }
    return FFPositionConstants.getPositionColor(position);
  }
} 