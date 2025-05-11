import 'dart:math';

import 'package:flutter/material.dart';
import '../utils/team_logo_utils.dart';
import '../services/csv_import_service.dart';

class TeamNeedsEditor extends StatefulWidget {
  final List<List<dynamic>> teamNeeds;
  final Function(List<List<dynamic>>) onTeamNeedsChanged;

  const TeamNeedsEditor({
    super.key,
    required this.teamNeeds,
    required this.onTeamNeedsChanged,
  });

  @override
  State<TeamNeedsEditor> createState() => _TeamNeedsEditorState();
}

class _TeamNeedsEditorState extends State<TeamNeedsEditor> {
  late List<List<dynamic>> _editableTeamNeeds;
  int? _selectedTeamIndex;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  
  // Available positions for dropdown selection
  final List<String> _availablePositions = [
    'QB', 'RB', 'FB', 'WR', 'TE', 'OT', 'IOL', 'OL', 'G', 'C',
    'EDGE', 'DL', 'IDL', 'DT', 'DE', 'LB', 'ILB', 'OLB', 'CB', 'S', 'FS', 'SS'
  ];

  @override
  void initState() {
    super.initState();
    _initializeTeamNeeds();
    
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

  void _initializeTeamNeeds() {
    // Make a deep copy to avoid modifying the original data
    _editableTeamNeeds = widget.teamNeeds.map((row) => List<dynamic>.from(row)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Column(
      children: [
        // Search and info header
        Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search Teams...',
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
            IconButton(
              tooltip: 'Reset to Default',
              icon: const Icon(Icons.restore),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Reset Team Needs'),
                    content: const Text('Are you sure you want to reset all team needs to their default values?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          setState(() {
                            _initializeTeamNeeds();
                            _selectedTeamIndex = null;
                          });
                          widget.onTeamNeedsChanged(_editableTeamNeeds);
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

        
        // Main content
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Team selection list - 1/3 width
              Expanded(
                flex: 1,
                child: _buildTeamSelectionList(isDarkMode),
              ),
              
              // Team needs editor - 2/3 width
              Expanded(
                flex: 2,
                child: _selectedTeamIndex != null
                    ? _buildTeamNeedsEditorPanel(isDarkMode)
                    : Center(
                        child: Text(
                          'Select a team to edit needs',
                          style: TextStyle(
                            color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTeamSelectionList(bool isDarkMode) {
    // Skip header row when displaying
    List<List<dynamic>> filteredTeams = _editableTeamNeeds
        .skip(1) // Skip header row
        .where((team) {
          final teamName = team[1].toString().toLowerCase();
          return _searchQuery.isEmpty || teamName.contains(_searchQuery);
        })
        .toList();
    
    return Card(
      margin: const EdgeInsets.all(8.0),
      child: ListView.builder(
        itemCount: filteredTeams.length,
        itemBuilder: (context, index) {
          final team = filteredTeams[index];
          final teamName = team[1].toString();
          final isSelected = _selectedTeamIndex == _editableTeamNeeds.indexOf(team);
          
          return ListTile(
            leading: TeamLogoUtils.buildNFLTeamLogo(teamName, size: 24),
            title: Text(
              teamName,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            selected: isSelected,
            selectedTileColor: isDarkMode ? Colors.blue.shade900.withOpacity(0.2) : Colors.blue.shade50,
            onTap: () {
              setState(() {
                _selectedTeamIndex = _editableTeamNeeds.indexOf(team);
              });
            },
          );
        },
      ),
    );
  }

  Widget _buildTeamNeedsEditorPanel(bool isDarkMode) {
    if (_selectedTeamIndex == null || _selectedTeamIndex! <= 0 || _selectedTeamIndex! >= _editableTeamNeeds.length) {
      return const Center(child: Text('Select a team to edit needs'));
    }
    
    final team = _editableTeamNeeds[_selectedTeamIndex!];
    final teamName = team[1].toString();
    
    // Get the current needs
    List<String> currentNeeds = [];
    
    // Starting from index 2 (need1) to index 8 (need7)
    for (int i = 2; i < min(9, team.length); i++) {
      final need = team[i].toString();
      if (need.isNotEmpty && need != "-") {
        currentNeeds.add(need);
      }
    }
    
    return Card(
      margin: const EdgeInsets.all(8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Team header
            Row(
              children: [
                TeamLogoUtils.buildNFLTeamLogo(teamName, size: 40),
                const SizedBox(width: 16),
                Text(
                  teamName,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            
            const Divider(height: 32),
            
            const Text(
              'Team Needs (Drag to Reorder):',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 8),
            
            // Needs list (reorderable)
            Expanded(
              child: ReorderableListView(
                buildDefaultDragHandles: false,
                onReorder: (oldIndex, newIndex) {
                  setState(() {
                    if (oldIndex < newIndex) {
                      newIndex -= 1;
                    }
                    final item = currentNeeds.removeAt(oldIndex);
                    currentNeeds.insert(newIndex, item);
                    
                    // Update the team's needs
                    _updateTeamNeeds(teamName, currentNeeds);
                  });
                },
                children: List.generate(
                  min(7, currentNeeds.length + 1), // Allow adding up to 7 needs
                  (index) {
                    if (index < currentNeeds.length) {
                      // Existing need
                      return _buildNeedListItem(
                        index, 
                        currentNeeds[index], 
                        isDarkMode,
                        teamName,
                        currentNeeds,
                      );
                    } else {
                      // Add new need option
                      return _buildAddNeedItem(
                        index,
                        isDarkMode,
                        teamName,
                        currentNeeds,
                      );
                    }
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNeedListItem(
    int index, 
    String position, 
    bool isDarkMode,
    String teamName,
    List<String> currentNeeds,
  ) {
    return Card(
      key: ValueKey('need-$index'),
      margin: const EdgeInsets.symmetric(vertical: 4),
      color: isDarkMode ? Colors.grey.shade800 : Colors.white,
      child: ListTile(
        leading: ReorderableDragStartListener(
          index: index,
          child: const Icon(Icons.drag_handle),
        ),
        title: Text(
          '$position (Priority ${index + 1})',
          style: TextStyle(
            fontWeight: index < 3 ? FontWeight.bold : FontWeight.normal,
            color: _getPositionColor(position),
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Edit position button
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                _showPositionSelectionDialog(
                  position,
                  (newPosition) {
                    if (newPosition != position) {
                      setState(() {
                        currentNeeds[index] = newPosition;
                        _updateTeamNeeds(teamName, currentNeeds);
                      });
                    }
                  },
                );
              },
            ),
            
            // Remove position button
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () {
                setState(() {
                  currentNeeds.removeAt(index);
                  _updateTeamNeeds(teamName, currentNeeds);
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddNeedItem(
    int index,
    bool isDarkMode,
    String teamName,
    List<String> currentNeeds,
  ) {
    return Card(
      key: const ValueKey('add-need'),
      margin: const EdgeInsets.symmetric(vertical: 4),
      color: isDarkMode ? Colors.blue.shade900.withOpacity(0.2) : Colors.blue.shade50,
      child: ListTile(
        leading: const Icon(Icons.add_circle, color: Colors.blue),
        title: const Text('Add Position Need'),
        onTap: () {
          _showPositionSelectionDialog(
            null,
            (newPosition) {
              setState(() {
                currentNeeds.add(newPosition);
                _updateTeamNeeds(teamName, currentNeeds);
              });
            },
          );
        },
      ),
    );
  }

  void _showPositionSelectionDialog(String? currentPosition, Function(String) onPositionSelected) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(currentPosition == null ? 'Add Position' : 'Edit Position'),
          content: SizedBox(
            width: 300,
            height: 400,
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 2,
              ),
              itemCount: _availablePositions.length,
              itemBuilder: (context, index) {
                final position = _availablePositions[index];
                final isSelected = position == currentPosition;
                
                return GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    onPositionSelected(position);
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: isSelected 
                          ? _getPositionColor(position).withOpacity(0.8) 
                          : _getPositionColor(position).withOpacity(0.3),
                      border: Border.all(
                        color: _getPositionColor(position),
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        position,
                        style: TextStyle(
                          color: isSelected ? Colors.white : _getPositionColor(position),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  void _updateTeamNeeds(String teamName, List<String> needs) {
    if (_selectedTeamIndex == null || _selectedTeamIndex! <= 0 || _selectedTeamIndex! >= _editableTeamNeeds.length) {
      return;
    }
    
    final team = _editableTeamNeeds[_selectedTeamIndex!];
    
    // Clear existing needs
    for (int i = 2; i < min(9, team.length); i++) {
      team[i] = "-";
    }
    
    // Set new needs
    for (int i = 0; i < min(needs.length, 7); i++) {
      // Make sure the team list has enough elements
      while (team.length <= i + 2) {
        team.add("-");
      }
      team[i + 2] = needs[i];
    }
    
    // Notify parent of changes
    widget.onTeamNeedsChanged(_editableTeamNeeds);
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
  if (!CsvImportService.validateTeamNeedsFormat(importedData)) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid team needs format')),
      );
    }
    return;
  }

  setState(() {
    _editableTeamNeeds = importedData;
    _selectedTeamIndex = null;
  });
  
  // Notify parent
  widget.onTeamNeedsChanged(_editableTeamNeeds);
  
  if (mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Imported ${importedData.length - 1} team needs')),
    );
  }
}

void _showFormatGuideDialog() {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Team Needs CSV Format Guide'),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Required columns:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('• ID - Team identifier number'),
            const Text('• Team - Team name (e.g., "Dallas Cowboys")'),
            const Text('• Need1 through Need7 - Position needs in priority order'),
            const SizedBox(height: 16),
            const Text('Example format:', style: TextStyle(fontWeight: FontWeight.bold)),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.shade500,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'ID,Team,Need1,Need2,Need3,Need4,Need5,Need6,Need7\n'
                '1,Dallas Cowboys,WR,EDGE,DT,CB,S,-,-\n'
                '2,Philadelphia Eagles,CB,LB,S,DT,WR,RB,-',
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


// Add this to both editor classes

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