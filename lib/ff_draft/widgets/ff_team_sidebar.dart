import 'package:flutter/material.dart';
import '../models/ff_team.dart';

class FFTeamSidebar extends StatelessWidget {
  final List<FFTeam> teams;
  final int selectedTeamIndex;
  final Function(int) onTeamSelected;

  const FFTeamSidebar({
    super.key,
    required this.teams,
    required this.selectedTeamIndex,
    required this.onTeamSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      decoration: BoxDecoration(
        border: Border(
          right: BorderSide(
            color: Colors.grey[300]!,
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          // Header
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
            child: const Text(
              'Teams',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          
          // Team list
          Expanded(
            child: ListView.builder(
              itemCount: teams.length,
              itemBuilder: (context, index) {
                final team = teams[index];
                final isSelected = index == selectedTeamIndex;
                
                return ListTile(
                  selected: isSelected,
                  selectedTileColor: Colors.blue.withValues(alpha: 0.1),
                  leading: CircleAvatar(
                    backgroundColor: _getTeamColor(index),
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(
                    team.name,
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? Colors.blue : null,
                    ),
                  ),
                  subtitle: Text(
                    '${team.roster.length} players',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                  onTap: () => onTeamSelected(index),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Color _getTeamColor(int index) {
    final colors = [
      Colors.red,
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.pink,
      Colors.indigo,
      Colors.amber,
      Colors.cyan,
      Colors.deepPurple,
      Colors.lime,
    ];
    return colors[index % colors.length];
  }
} 