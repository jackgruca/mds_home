// lib/screens/customize_draft_tab.dart
import 'package:flutter/material.dart';
import '../models/custom_draft_data.dart';
import 'team_needs_editor.dart';
import 'player_rankings_editor.dart';
import '../services/data_service.dart';
import '../widgets/draft/custom_data_manager_dialog.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class CustomizeDraftTabView extends StatefulWidget {
  final int selectedYear;
  final Function(List<List<dynamic>>) onTeamNeedsChanged;
  final Function(List<List<dynamic>>) onPlayerRankingsChanged;
  final List<List<dynamic>>? initialTeamNeeds;
  final List<List<dynamic>>? initialPlayerRankings;

  const CustomizeDraftTabView({
    super.key,
    required this.selectedYear,
    required this.onTeamNeedsChanged,
    required this.onPlayerRankingsChanged,
    this.initialTeamNeeds,
    this.initialPlayerRankings,
  });

  @override
  State<CustomizeDraftTabView> createState() => _CustomizeDraftTabViewState();
}

class _CustomizeDraftTabViewState extends State<CustomizeDraftTabView> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<List<dynamic>>? _teamNeeds;
  List<List<dynamic>>? _playerRankings;
  bool _isLoading = true;
  

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _teamNeeds = widget.initialTeamNeeds;
    _playerRankings = widget.initialPlayerRankings;
    
    if (_teamNeeds == null || _playerRankings == null) {
      _loadData();
    } else {
      _isLoading = false;
    }
     Future<void> loadLastSession() async {
  final authProvider = Provider.of<AuthProvider>(context, listen: false);
  
  if (!authProvider.isLoggedIn) return;
  
  // Get all saved data sets
  final allDataSets = authProvider.getUserCustomDraftData();
  
  if (allDataSets.isEmpty) return;
  
  // Sort by last modified (most recent first)
  allDataSets.sort((a, b) => b.lastModified.compareTo(a.lastModified));
  
  // Get the most recent Auto Save for the current year
  final autoSave = allDataSets.firstWhere(
    (data) => data.name == 'Auto Save ${widget.selectedYear}' && data.year == widget.selectedYear,
    orElse: () => allDataSets.first, // Fallback to most recent
  );
  
  // Load the data
  setState(() {
    if (autoSave.teamNeeds != null) {
      _teamNeeds = autoSave.teamNeeds;
      widget.onTeamNeedsChanged(autoSave.teamNeeds!);
    }
    
    if (autoSave.playerRankings != null) {
      _playerRankings = autoSave.playerRankings;
      widget.onPlayerRankingsChanged(autoSave.playerRankings!);
    }
  });
  
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Loaded last session: "${autoSave.name}"')),
  );
}
    // Auto-load last session after a delay
    Future.delayed(const Duration(milliseconds: 500), () {
      if ((_teamNeeds == null || _teamNeeds!.isEmpty) && 
          (_playerRankings == null || _playerRankings!.isEmpty)) {
        loadLastSession();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Load team needs if not provided
      if (_teamNeeds == null) {
        final teamNeeds = await DataService.loadTeamNeeds(year: widget.selectedYear);
        _teamNeeds = DataService.teamNeedsToLists(teamNeeds);
      }
      
      // Load player rankings if not provided
      if (_playerRankings == null) {
        final players = await DataService.loadAvailablePlayers(year: widget.selectedYear);
        _playerRankings = DataService.playersToLists(players);
      }
      
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Error loading data for customization: $e");
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showDataManagerDialog() {
  final authProvider = Provider.of<AuthProvider>(context, listen: false);
  
  if (!authProvider.isLoggedIn) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('You need to be logged in to manage saved draft data'),
      ),
    );
    return;
  }
  
  showDialog(
    context: context,
    builder: (context) => CustomDataManagerDialog(
      currentYear: widget.selectedYear,
      currentTeamNeeds: _teamNeeds,
      currentPlayerRankings: _playerRankings,
      onDataSelected: (customData) {
        setState(() {
          if (customData.teamNeeds != null) {
            _teamNeeds = customData.teamNeeds;
            widget.onTeamNeedsChanged(customData.teamNeeds!);
          }
          
          if (customData.playerRankings != null) {
            _playerRankings = customData.playerRankings;
            widget.onPlayerRankingsChanged(customData.playerRankings!);
          }
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Loaded "${customData.name}" data set'),
          ),
        );
      },
    ),
  );
}

Future<void> _autoSaveChanges(String type) async {
  final authProvider = Provider.of<AuthProvider>(context, listen: false);
  
  if (!authProvider.isLoggedIn) return;
  
  // Only save if there's actual data
  if ((_teamNeeds == null || _teamNeeds!.isEmpty) && 
      (_playerRankings == null || _playerRankings!.isEmpty)) {
    return;
  }
  
  try {
    // Create auto-save data set
    final autoSaveData = CustomDraftData(
      name: 'Auto Save ${widget.selectedYear}',
      year: widget.selectedYear,
      lastModified: DateTime.now(),
      teamNeeds: type == 'team_needs' ? _teamNeeds : null,
      playerRankings: type == 'player_rankings' ? _playerRankings : null,
    );
    
    // Save to user profile
    await authProvider.saveCustomDraftData(autoSaveData);
  } catch (e) {
    debugPrint('Auto-save error: $e');
  }
}

  @override
Widget build(BuildContext context) {
  if (_isLoading) {
    return const Center(child: CircularProgressIndicator());
  }

  return Column(
    children: [
      // Add a row for the save/load button
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Consumer<AuthProvider>(
              builder: (context, authProvider, _) => 
                authProvider.isLoggedIn 
                  ? ElevatedButton.icon(
                      onPressed: _showDataManagerDialog,
                      icon: const Icon(Icons.save_alt),
                      label: const Text('Save/Load Custom Data'),
                    )
                  : TextButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Log in to save your custom data'),
                          ),
                        );
                      },
                      icon: const Icon(Icons.login),
                      label: const Text('Login to Save Settings'),
                    ),
            ),
          ],
        ),
      ),
      Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark 
              ? Colors.blue.shade900.withOpacity(0.2) 
              : Colors.blue.shade50,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            const Icon(Icons.info_outline, size: 16),
            const SizedBox(width: 8),
            Text(
              'Year: ${widget.selectedYear}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 16),
            if (_teamNeeds != null) ...[
              Text(
                'Team Needs: ${_teamNeeds!.length - 1} teams',
                style: const TextStyle(fontStyle: FontStyle.italic),
              ),
            ],
            const SizedBox(width: 16),
            if (_playerRankings != null) ...[
              Text(
                'Player Rankings: ${_playerRankings!.length - 1} players',
                style: const TextStyle(fontStyle: FontStyle.italic),
              ),
            ],
          ],
        ),
      ),
      
      TabBar(
        controller: _tabController,
        tabs: const [
          Tab(text: 'Team Needs'),
          Tab(text: 'Player Rankings'),
        ],
      ),
      Expanded(
      child: TabBarView(
        controller: _tabController,
        children: [
          // Team Needs Editor Tab
          TeamNeedsEditor(
            teamNeeds: _teamNeeds ?? [],
            onTeamNeedsChanged: (updatedNeeds) {
              setState(() {
                _teamNeeds = updatedNeeds;
              });
              widget.onTeamNeedsChanged(updatedNeeds);
              
              // Add this line for auto-save
              _autoSaveChanges('team_needs');
            },
          ),
          
          // Player Rankings Editor Tab
          PlayerRankingsEditor(
            playerRankings: _playerRankings ?? [],
            onPlayerRankingsChanged: (updatedRankings) {
              setState(() {
                _playerRankings = updatedRankings;
              });
              widget.onPlayerRankingsChanged(updatedRankings);
              
              // Add this line for auto-save
              _autoSaveChanges('player_rankings');
            },
          ),
        ],
      ),
    ),
    ],
  );
}
}