// lib/widgets/draft/player_selection_dialog.dart
import 'package:flutter/material.dart';
import '../../models/player.dart';
import '../../models/team_need.dart';

class PlayerSelectionDialog extends StatefulWidget {
  final List<Player> availablePlayers;
  final TeamNeed teamNeed;
  final String teamName;
  final Function(Player) onPlayerSelected;
  final VoidCallback onAutoPick;

  const PlayerSelectionDialog({
    super.key,
    required this.availablePlayers,
    required this.teamNeed,
    required this.teamName,
    required this.onPlayerSelected,
    required this.onAutoPick,
  });

  @override
  _PlayerSelectionDialogState createState() => _PlayerSelectionDialogState();
}

class _PlayerSelectionDialogState extends State<PlayerSelectionDialog> {
  String _selectedPosition = '';
  String _searchQuery = '';
  
  @override
  Widget build(BuildContext context) {
    // Filter players based on position and search
    List<Player> filteredPlayers = widget.availablePlayers.where((player) {
      bool matchesPosition = _selectedPosition.isEmpty || 
                            player.position == _selectedPosition;
      bool matchesSearch = _searchQuery.isEmpty ||
                           player.name.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesPosition && matchesSearch;
    }).toList();
    
    // Get unique positions from available players
    Set<String> availablePositions = widget.availablePlayers
        .map((player) => player.position)
        .toSet();
    
    // Determine which positions are team needs
    Set<String> needPositions = widget.teamNeed.needs.toSet();

    return AlertDialog(
      title: Text('Select a Player for ${widget.teamName}'),
      content: SizedBox(
        width: double.maxFinite,
        height: 500,
        child: Column(
          children: [
            // Search bar
            TextField(
              decoration: const InputDecoration(
                labelText: 'Search Players',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
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
                  ChoiceChip(
                    label: const Text('All'),
                    selected: _selectedPosition.isEmpty,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _selectedPosition = '';
                        });
                      }
                    },
                  ),
                  const SizedBox(width: 4),
                  ...availablePositions.map((position) {
                    bool isNeed = needPositions.contains(position);
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2.0),
                      child: ChoiceChip(
                        label: Text(position),
                        selected: _selectedPosition == position,
                        onSelected: (selected) {
                          setState(() {
                            _selectedPosition = selected ? position : '';
                          });
                        },
                        backgroundColor: isNeed ? Colors.green.shade50 : null,
                        labelStyle: TextStyle(
                          color: isNeed ? Colors.green.shade800 : null,
                          fontWeight: isNeed ? FontWeight.bold : null,
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 8),
            
            // Team needs banner
            if (needPositions.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(4.0),
                ),
                child: Text(
                  'Team Needs: ${widget.teamNeed.needs.join(", ")}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade800,
                  ),
                ),
              ),
            const SizedBox(height: 8),
            
            // Player list
            Expanded(
              child: ListView.builder(
                itemCount: filteredPlayers.length,
                itemBuilder: (context, index) {
                  final player = filteredPlayers[index];
                  final isNeed = needPositions.contains(player.position);
                  
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 4.0),
                    color: isNeed ? Colors.green.shade50 : null,
                    child: ListTile(
                      title: Text(
                        player.name,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isNeed ? Colors.green.shade800 : null,
                        ),
                      ),
                      subtitle: Text(
                        '${player.position} - Rank: ${player.rank}${player.school.isNotEmpty ? ' - ${player.school}' : ''}',
                      ),
                      trailing: isNeed 
                        ? const Chip(
                            label: Text('Need'),
                            backgroundColor: Colors.green,
                            labelStyle: TextStyle(color: Colors.white),
                          )
                        : null,
                      onTap: () {
                        widget.onPlayerSelected(player);
                        Navigator.pop(context);
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            widget.onAutoPick();
            Navigator.pop(context);
          },
          child: const Text('Auto Pick'),
        ),
      ],
    );
  }
}