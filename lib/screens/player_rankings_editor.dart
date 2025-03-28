// lib/screens/player_rankings_editor.dart
import 'package:flutter/material.dart';
import 'dart:math';
import '../models/player.dart';
import '../utils/team_logo_utils.dart';
import '../services/csv_export_service.dart';
import '../services/csv_import_service.dart';

class PlayerRankingsEditor extends StatefulWidget {
  final List<List<dynamic>> playerRankings;
  final Function(List<List<dynamic>>) onPlayerRankingsChanged;

  const PlayerRankingsEditor({
    super.key,
    required this.playerRankings,
    required this.onPlayerRankingsChanged,
  });

  @override
  State<PlayerRankingsEditor> createState() => _PlayerRankingsEditorState();
}

class _PlayerRankingsEditorState extends State<PlayerRankingsEditor> {
  late List<List<dynamic>> _editablePlayerRankings;
  List<Player> _players = [];
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _positionFilter = 'All';
  
  // List of all positions for filtering
  final List<String> _availablePositions = [
    'All',
    'QB', 'RB', 'FB', 'WR', 'TE', 'OT', 'IOL', 'OL', 'G', 'C',
    'EDGE', 'DL', 'IDL', 'DT', 'DE', 'LB', 'ILB', 'OLB', 'CB', 'S', 'FS', 'SS'
  ];

  // Map to store column indices from header row
  final Map<String, int> _columnIndices = {};

  @override
  void initState() {
    super.initState();
    _initializePlayers();
    
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _initializePlayers() {
    // Make a deep copy to avoid modifying the original data
    _editablePlayerRankings = widget.playerRankings.map((row) => List<dynamic>.from(row)).toList();
    
    // Parse header row to get column indices
    if (_editablePlayerRankings.isNotEmpty) {
      List<String> headers = _editablePlayerRankings[0].map<String>((dynamic col) => 
          col.toString().toUpperCase()).toList();
      
      for (int i = 0; i < headers.length; i++) {
        _columnIndices[headers[i]] = i;
      }
    }
    
    // Convert data rows to Player objects
    _players = [];
    for (int i = 1; i < _editablePlayerRankings.length; i++) {
      try {
        final player = _createPlayerFromRow(_editablePlayerRankings[i]);
        if (player != null) {
          _players.add(player);
        }
      } catch (e) {
        debugPrint("Error creating player from row: $e");
      }
    }
    
    // Sort players by rank
    _players.sort((a, b) => a.rank.compareTo(b.rank));
  }

  Player? _createPlayerFromRow(List<dynamic> row) {
    // Check if we have the necessary columns
    if (_columnIndices.isEmpty) return null;
    
    try {
      // Get indices for required columns
      int idIndex = _columnIndices['ID'] ?? 0;
      int nameIndex = _columnIndices['NAME'] ?? 1;
      int positionIndex = _columnIndices['POSITION'] ?? 2;
      int schoolIndex = _columnIndices['SCHOOL'] ?? 3;
      int rankIndex = _columnIndices['RANK_COMBINED'] ?? _columnIndices['RANK'] ?? 
                      row.length - 1; // Default to last column
      
      // Parse values
      int id = idIndex < row.length ? 
               (int.tryParse(row[idIndex].toString()) ?? 0) : 0;
      
      String name = nameIndex < row.length ? row[nameIndex].toString() : "";
      String position = positionIndex < row.length ? row[positionIndex].toString() : "";
      String school = schoolIndex < row.length ? row[schoolIndex].toString() : "";
      
      int rank = rankIndex < row.length ? 
                (int.tryParse(row[rankIndex].toString()) ?? 999) : 999;
      
      // Skip empty or invalid rows
      if (name.isEmpty || position.isEmpty) return null;
      
      return Player(
        id: id,
        name: name,
        position: position,
        rank: rank,
        school: school,
      );
    } catch (e) {
      debugPrint("Error parsing player data: $e");
      return null;
    }
  }

  void _updateRankingsFromPlayers() {
    // Ensure we have header row
    if (_editablePlayerRankings.isEmpty) return;
    
    // Get index for rank column
    int rankIndex = _columnIndices['RANK_COMBINED'] ?? _columnIndices['RANK'] ?? 
                    _editablePlayerRankings[0].length - 1;
    
    // Update the rank value in the original data structure
    for (var player in _players) {
      for (int i = 1; i < _editablePlayerRankings.length; i++) {
        var row = _editablePlayerRankings[i];
        
        // Match player by ID and name (for added reliability)
        int idIndex = _columnIndices['ID'] ?? 0;
        int nameIndex = _columnIndices['NAME'] ?? 1;
        
        int rowId = idIndex < row.length ? 
                   (int.tryParse(row[idIndex].toString()) ?? -1) : -1;
                   
        String rowName = nameIndex < row.length ? row[nameIndex].toString() : "";
        
        if ((rowId == player.id && rowId > 0) || 
            (rowName.toLowerCase() == player.name.toLowerCase() && rowName.isNotEmpty)) {
          
          // Update the rank in the original data
          if (rankIndex < row.length) {
            row[rankIndex] = player.rank;
          }
          break;
        }
      }
    }
    
    // Notify parent component of changes
    widget.onPlayerRankingsChanged(_editablePlayerRankings);
  }

  void _movePlayer(int oldIndex, int newIndex) {
    setState(() {
      // Adjust indices for ReorderableListView's behavior
      if (oldIndex < newIndex) {
        newIndex -= 1;
      }
      
      final movedPlayer = _players.removeAt(oldIndex);
      _players.insert(newIndex, movedPlayer);
      
      // Update ranks based on new positions
      for (int i = 0; i < _players.length; i++) {
        _players[i].rank = i + 1;
      }
      
      // Update the data in the original format
      _updateRankingsFromPlayers();
    });
  }

  List<Player> _getFilteredPlayers() {
    return _players.where((player) {
      // Apply position filter
      if (_positionFilter != 'All' && player.position != _positionFilter) {
        return false;
      }
      
      // Apply search query
      if (_searchQuery.isNotEmpty) {
        return player.name.toLowerCase().contains(_searchQuery) ||
               player.school.toLowerCase().contains(_searchQuery) ||
               player.position.toLowerCase().contains(_searchQuery);
      }
      
      return true;
    }).toList();
  }

  @override
Widget build(BuildContext context) {
  final isDarkMode = Theme.of(context).brightness == Brightness.dark;
  final filteredPlayers = _getFilteredPlayers();
  
  return Stack(
    children: [
      Column(
        children: [
          // Search and filter controls
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                // Search field
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search Players...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 12.0),
                      isDense: true,
                    ),
                  ),
                ),
                
                const SizedBox(width: 8),
                
                // Position filter dropdown
                Expanded(
                  flex: 2,
                  child: DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      labelText: 'Position',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      isDense: true,
                    ),
                    value: _positionFilter,
                    items: _availablePositions
                        .map((position) => DropdownMenuItem(
                              value: position,
                              child: Text(position),
                            ))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _positionFilter = value;
                        });
                      }
                    },
                  ),
                ),
                
                const SizedBox(width: 8),
                
                // Import Button
                ElevatedButton.icon(
                  onPressed: _importFromCSV,
                  icon: const Icon(Icons.upload_file, size: 12),
                  label: const Text('Import'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
                const SizedBox(width: 8),
                // Export Button
                // ElevatedButton.icon(
                //   onPressed: _exportToCSV,
                //   icon: const Icon(Icons.download, size: 12),
                //   label: const Text('Export'),
                //   style: ElevatedButton.styleFrom(
                //     padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
                //     visualDensity: VisualDensity.compact,
                //   ),
                // ),
                // Help Button
                IconButton(
                  onPressed: _showFormatGuideDialog,
                  icon: const Icon(Icons.help_outline),
                  tooltip: 'CSV Format Guide',
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 10),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
                
                const SizedBox(width: 8),
                
                // Batch adjustment button
                // ElevatedButton.icon(
                //   icon: const Icon(Icons.tune, size: 16),
                //   label: const Text('Batch'),
                //   style: ElevatedButton.styleFrom(
                //     padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                //     visualDensity: VisualDensity.compact,
                //   ),
                //   onPressed: _showBatchAdjustmentDialog,
                // ),
                
                const SizedBox(width: 8),
                
                // Reset button
                IconButton(
                  tooltip: 'Reset Rankings',
                  icon: const Icon(Icons.restore),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Reset Player Rankings'),
                        content: const Text('Are you sure you want to reset all player rankings to their default values?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                              setState(() {
                                _initializePlayers();
                              });
                              widget.onPlayerRankingsChanged(_editablePlayerRankings);
                            },
                            child: const Text('Reset'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          
          // Player count indicator
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Showing ${filteredPlayers.length} players',
                  style: TextStyle(
                    color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                Text(
                  'Drag to reorder rankings',
                  style: TextStyle(
                    color: isDarkMode ? Colors.blue.shade300 : Colors.blue.shade700,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 8),
          
          // Header row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200,
              border: Border(
                bottom: BorderSide(
                  color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
                ),
              ),
            ),
            child: const Row(
              children: [
                SizedBox(width: 32), // space for drag handle
                SizedBox(width: 50, child: Center(child: Text('Rank', style: TextStyle(fontWeight: FontWeight.bold)))),
                SizedBox(width: 8),
                Expanded(child: Text('Name', style: TextStyle(fontWeight: FontWeight.bold))),
                SizedBox(width: 80, child: Center(child: Text('Position', style: TextStyle(fontWeight: FontWeight.bold)))),
                SizedBox(width: 8),
                Text('School', style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(width: 40), // Space for edit button
              ],
            ),
          ),
          
          // Player list with reordering
          Expanded(
            child: ReorderableListView.builder(
              itemCount: filteredPlayers.length,
              onReorder: _movePlayer,
              itemBuilder: (context, index) {
                final player = filteredPlayers[index];
                return _buildPlayerRow(player, index, isDarkMode);
              },
            ),
          ),
        ],
      ),
      
      // Add FAB for adding new players - THIS IS THE NEW PART
      Positioned(
        bottom: 16,
        right: 16,
        child: FloatingActionButton(
          onPressed: _addNewPlayer,
          tooltip: 'Add New Player',
          child: const Icon(Icons.add),
        ),
      ),
    ],
  );
}

  Widget _buildPlayerRow(Player player, int index, bool isDarkMode) {
    return Card(
      key: ValueKey('player-${player.id}-${player.name}'),
      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
      color: isDarkMode ? Colors.grey.shade900 : Colors.white,
      elevation: 1,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
        leading: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Rank number label
            Container(
              width: 50,
              height: 30,
              decoration: BoxDecoration(
                color: _getPositionColor(player.position),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Center(
                child: Text(
                  '${player.rank}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
        title: Text(
          player.name,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: player.school.isNotEmpty ? Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: TeamLogoUtils.buildCollegeTeamLogo(
                player.school,
                size: 20,
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                player.school,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ) : null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Position badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getPositionColor(player.position).withOpacity(0.2),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: _getPositionColor(player.position),
                  width: 1,
                ),
              ),
              child: Text(
                player.position,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: _getPositionColor(player.position),
                ),
              ),
            ),
            
            const SizedBox(width: 8),
            
            // Manual edit button
            IconButton(
              icon: Icon(
                Icons.edit,
                size: 18,
                color: isDarkMode ? Colors.blue.shade300 : Colors.blue.shade700,
              ),
              onPressed: () {
                _showEditPlayerDialog(player);
              },
              tooltip: 'Edit Player',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
      ),
    );
  }

  void _showEditPlayerDialog(Player player) {
    final rankController = TextEditingController(text: player.rank.toString());
    final nameController = TextEditingController(text: player.name);
    final schoolController = TextEditingController(text: player.school);
    String position = player.position;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Player'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Name',
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  // Position dropdown
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Position',
                      ),
                      value: position,
                      items: _availablePositions
                          .where((pos) => pos != 'All')
                          .map((position) => DropdownMenuItem(
                                value: position,
                                child: Text(position),
                              ))
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          position = value;
                        }
                      },
                    ),
                  ),
                  
                  const SizedBox(width: 16),
                  
                  // Rank field
                  SizedBox(
                    width: 80,
                    child: TextField(
                      controller: rankController,
                      decoration: const InputDecoration(
                        labelText: 'Rank',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: schoolController,
                decoration: const InputDecoration(
                  labelText: 'School',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              
              // Get edited values
              final newName = nameController.text;
              final newSchool = schoolController.text;
              final newRank = int.tryParse(rankController.text) ?? player.rank;
              
              setState(() {
                // Update player object
                player.name = newName;
                player.school = newSchool;
                player.position = position;
                
                // Only update rank if it changed
                if (player.rank != newRank) {
                  // Update the player's rank
                  player.rank = newRank;
                  
                  // Resort players list
                  _players.sort((a, b) => a.rank.compareTo(b.rank));
                  
                  // Reassign ranks to ensure no duplicates and proper ordering
                  for (int i = 0; i < _players.length; i++) {
                    _players[i].rank = i + 1;
                  }
                }
                
                // Update rankings in the original format
                _updateRankingsFromPlayers();
              });
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showBatchAdjustmentDialog() {
  // Selected position to adjust
  String? positionToAdjust;
  bool increaseRank = false; // true = better rank (lower number), false = worse rank (higher number)
  int adjustmentAmount = 5;
  
  showDialog(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) {
        return AlertDialog(
          title: const Text('Batch Rank Adjustment'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Adjust the ranking of all players in a specific position',
                style: TextStyle(fontSize: 14),
              ),
              
              const SizedBox(height: 16),
              
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Position to Adjust',
                ),
                value: positionToAdjust,
                items: _availablePositions
                    .where((pos) => pos != 'All')
                    .map((pos) => DropdownMenuItem(
                          value: pos,
                          child: Text(pos),
                        ))
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      positionToAdjust = value;
                    });
                  }
                },
              ),
              
              const SizedBox(height: 16),
              
              // Adjustment direction
              Row(
                children: [
                  const Text('Direction:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(width: 16),
                  ChoiceChip(
                    label: const Text('Better ↑'),
                    selected: increaseRank,
                    onSelected: (selected) {
                      setState(() {
                        increaseRank = true;
                      });
                    },
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('Worse ↓'),
                    selected: !increaseRank,
                    onSelected: (selected) {
                      setState(() {
                        increaseRank = false;
                      });
                    },
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Adjustment amount
              Row(
                children: [
                  const Text('Amount:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Slider(
                      value: adjustmentAmount.toDouble(),
                      min: 1,
                      max: 20,
                      divisions: 19,
                      label: adjustmentAmount.toString(),
                      onChanged: (value) {
                        setState(() {
                          adjustmentAmount = value.toInt();
                        });
                      },
                    ),
                  ),
                  SizedBox(
                    width: 30,
                    child: Text(
                      '$adjustmentAmount',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: positionToAdjust != null ? () {
                Navigator.pop(context);
                
                // Apply the batch adjustment
                _applyBatchAdjustment(
                  position: positionToAdjust!,
                  amount: adjustmentAmount,
                  improvement: increaseRank,
                );
              } : null,
              child: const Text('Apply'),
            ),
          ],
        );
      }
    ),
  );
}

void _applyBatchAdjustment({
  required String position,
  required int amount,
  required bool improvement,
}) {
  // Get all players with the specified position
  final positionPlayers = _players.where((p) => p.position == position).toList();
  
  if (positionPlayers.isEmpty) return;
  
  // Sort by current rank
  positionPlayers.sort((a, b) => a.rank.compareTo(b.rank));
  
  setState(() {
    if (improvement) {
      // Better rank (move players up)
      for (var player in positionPlayers) {
        // Calculate new rank (lower = better)
        int targetRank = max(1, player.rank - amount);
        int currentRank = player.rank;
        
        // Move players down to make room
        for (var p in _players) {
          if (p != player && p.rank >= targetRank && p.rank < currentRank) {
            p.rank += 1;
          }
        }
        
        // Assign new rank
        player.rank = targetRank;
      }
    } else {
      // Worse rank (move players down)
      // Sort in reverse order to avoid conflicts
      positionPlayers.sort((a, b) => b.rank.compareTo(a.rank));
      
      for (var player in positionPlayers) {
        // Calculate new rank (higher = worse)
        int targetRank = min(_players.length, player.rank + amount);
        int currentRank = player.rank;
        
        // Move players up to make room
        for (var p in _players) {
          if (p != player && p.rank <= targetRank && p.rank > currentRank) {
            p.rank -= 1;
          }
        }
        
        // Assign new rank
        player.rank = targetRank;
      }
    }
    
    // Sort players by rank
    _players.sort((a, b) => a.rank.compareTo(b.rank));
    
    // Normalize ranks to ensure no duplicates and proper ordering
    for (int i = 0; i < _players.length; i++) {
      _players[i].rank = i + 1;
    }
    
    // Update the data in the original format
    _updateRankingsFromPlayers();
  });
}

  void _addNewPlayer() {
  // Generate a unique ID for the new player
  final random = Random();
  int newId = 10000 + random.nextInt(90000); // Random ID in the 10000-99999 range
  while (_players.any((p) => p.id == newId)) {
    newId = 10000 + random.nextInt(90000);
  }
  
  // Default rank is last + 1
  int newRank = _players.isEmpty ? 1 : _players.map((p) => p.rank).reduce(max) + 1;
  
  showDialog(
    context: context,
    builder: (context) {
      final nameController = TextEditingController();
      final schoolController = TextEditingController();
      String position = 'QB'; // Default position
      
      return AlertDialog(
        title: const Text('Add New Player'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Name',
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Position',
                ),
                value: position,
                items: _availablePositions
                    .where((pos) => pos != 'All')
                    .map((pos) => DropdownMenuItem(
                          value: pos,
                          child: Text(pos),
                        ))
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    position = value;
                  }
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: schoolController,
                decoration: const InputDecoration(
                  labelText: 'School',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final name = nameController.text.trim();
              final school = schoolController.text.trim();
              
              if (name.isEmpty) {
                // Show error or return
                return;
              }
              
              Navigator.pop(context);
              
              setState(() {
                // Create and add the new player
                final newPlayer = Player(
                  id: newId,
                  name: name,
                  position: position,
                  rank: newRank,
                  school: school,
                );
                
                _players.add(newPlayer);
                
                // Sort the list by rank
                _players.sort((a, b) => a.rank.compareTo(b.rank));
                
                // Update the data in the original format
                _updateRankingsFromPlayers();
              });
            },
            child: const Text('Add'),
          ),
        ],
      );
    },
  );
}

void _exportToCSV() {
  if (!CsvExportService.isWebPlatform) {
    CsvExportService.showPlatformWarning(context);
    return;
  }
  
  CsvExportService.exportToCsv(
    data: _editablePlayerRankings,
    filename: 'custom_player_rankings.csv',
  );
}

Future<void> _importFromCSV() async {
  List<List<dynamic>>? importedData = await CsvImportService.importFromCsv();
  
  if (importedData == null || importedData.isEmpty) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No data imported')),
      );
    }
    return;
  }
  
  // Validate format
  if (!CsvImportService.validatePlayerRankingsFormat(importedData)) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid player rankings format')),
      );
    }
    return;
  }
  
  // Show preview dialog with confirmation
  if (mounted) {
    _showCsvPreviewDialog(importedData, 'Player Rankings');
    
    // Ask user to confirm the import
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Import'),
        content: Text('Import ${importedData.length - 1} player rankings?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              
              setState(() {
                _editablePlayerRankings = importedData;
                _initializePlayers(); // Rebuild players from imported data
              });
              
              // Notify parent
              widget.onPlayerRankingsChanged(_editablePlayerRankings);
              
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Imported ${importedData.length - 1} player rankings')),
              );
            },
            child: const Text('Import'),
          ),
        ],
      ),
    );
  }
}

void _showFormatGuideDialog() {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Player Rankings CSV Format Guide'),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Required columns:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('• ID - Player identifier number'),
            const Text('• Name - Player full name'),
            const Text('• Position - Player position code (e.g., "QB", "WR")'),
            const Text('• School - Player college/school'),
            const Text('• Rank - Player overall ranking'),
            const SizedBox(height: 16),
            const Text('Example format:', style: TextStyle(fontWeight: FontWeight.bold)),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'ID,Name,Position,School,Notes,Rank\n'
                '1,John Smith,QB,Alabama,,1\n'
                '2,Mike Johnson,WR,Ohio State,,2\n'
                '3,Chris Williams,EDGE,Georgia,,3',
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    ),
  );
}

void _downloadTemplate() {
  final templateData = [
    ['ID', 'Name', 'Position', 'School', 'Notes', 'Rank'],
    [1, 'Player Name', 'QB', 'University', '', 1],
    [2, 'Another Player', 'WR', 'College', '', 2],
  ];
  
  CsvExportService.exportToCsv(
    data: templateData,
    filename: 'player_rankings_template.csv',
  );
}

// Add this to both editor classes
void _showCsvPreviewDialog(List<List<dynamic>> data, String title) {
  if (data.isEmpty) return;
  
  final headers = data[0];
  final rows = data.sublist(1, min(11, data.length)); // Show up to 10 data rows
  
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Preview: $title'),
      content: SizedBox(
        width: double.maxFinite,
        height: 400,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SingleChildScrollView(
            child: DataTable(
              columns: headers.map<DataColumn>((header) => 
                DataColumn(label: Text(header.toString()))
              ).toList(),
              rows: rows.map<DataRow>((row) => 
                DataRow(
                  cells: List.generate(
                    min(row.length, headers.length),
                    (index) => DataCell(Text(row[index].toString())),
                  ),
                ),
              ).toList(),
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    ),
  );
}

  Color _getPositionColor(String position) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    // Different colors for different position groups with dark mode adjustments
    if (['QB', 'RB', 'FB'].contains(position)) {
      return isDarkMode ? Colors.blue.shade600 : Colors.blue.shade700; // Backfield
    } else if (['WR', 'TE'].contains(position)) {
      return isDarkMode ? Colors.green.shade600 : Colors.green.shade700; // Receivers
    } else if (['OT', 'IOL', 'OL', 'G', 'C'].contains(position)) {
      return isDarkMode ? Colors.purple.shade600 : Colors.purple.shade700; // O-Line
    } else if (['EDGE', 'DL', 'IDL', 'DT', 'DE'].contains(position)) {
      return isDarkMode ? Colors.red.shade600 : Colors.red.shade700; // D-Line
    } else if (['LB', 'ILB', 'OLB'].contains(position)) {
      return isDarkMode ? Colors.orange.shade600 : Colors.orange.shade700; // Linebackers
    } else if (['CB', 'S', 'FS', 'SS'].contains(position)) {
      return isDarkMode ? Colors.teal.shade600 : Colors.teal.shade700; // Secondary
    } else {
      return isDarkMode ? Colors.grey.shade600 : Colors.grey.shade700; // Special teams, etc.
    }
  }
}