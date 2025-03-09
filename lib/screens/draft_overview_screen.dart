import 'package:flutter/material.dart';
import 'available_players_tab.dart';
import 'team_needs_tab.dart';
import 'draft_order_tab.dart';
import '../../widgets/draft/draft_control_buttons.dart';
import '../utils/csv_data_handler.dart';

import 'package:flutter/services.dart' show rootBundle;
import 'package:csv/csv.dart';

class DraftApp extends StatefulWidget {
  // Add parameters to control draft behavior
  final double randomnessFactor;
  final int numberOfRounds;
  final double speedFactor;
  final String selectedTeam;
  final String draftYear;
  final bool enableTrading;
  final bool enableUserTradeProposals;
  final bool enableQBPremium;
  final bool showAnalytics;

  const DraftApp({
    super.key,
    this.randomnessFactor = 0.5,
    this.numberOfRounds = 1,
    this.speedFactor = 1.0,
    this.selectedTeam = '',
    this.draftYear = '2024',
    this.enableTrading = false,
    this.enableUserTradeProposals = false,
    this.enableQBPremium = false,
    this.showAnalytics = false,
  });

  @override
  DraftAppState createState() => DraftAppState();
}

class DraftAppState extends State<DraftApp> {
  bool _isDraftRunning = false;

  // State variables for data
  List<List<dynamic>> _draftOrder = [];
  List<List<dynamic>> _availablePlayers = [];
  List<List<dynamic>> _teamNeeds = [];

  // Indexes for key fields (will be determined dynamically)
  late Map<String, Map<String, int>> _fieldIndexes;

  @override
  void initState() {
    super.initState();
    _fieldIndexes = {
      'draftOrder': {},
      'availablePlayers': {},
      'teamNeeds': {},
    };
    
    // Log draft parameters
    debugPrint("📊 Draft Parameters:");
    debugPrint("  Randomness: ${widget.randomnessFactor}");
    debugPrint("  Rounds: ${widget.numberOfRounds}");
    debugPrint("  Speed: ${widget.speedFactor}");
    debugPrint("  Selected Team: ${widget.selectedTeam}");
    debugPrint("  Draft Year: ${widget.draftYear}");
    debugPrint("  Enable Trading: ${widget.enableTrading}");
    debugPrint("  Enable User Trade Proposals: ${widget.enableUserTradeProposals}");
    debugPrint("  Enable QB Premium: ${widget.enableQBPremium}");
    debugPrint("  Show Analytics: ${widget.showAnalytics}");
    
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    // Load all data and ensure it's properly initialized
    await Future.wait([
      _loadDraftOrder(),
      _loadAvailablePlayers(),
      _loadTeamNeeds(),
    ]);
    
    // Map field indexes after loading data
    _mapFieldIndexes();
  }

  void _mapFieldIndexes() {
    // Set indexes for draft order fields
    if (_draftOrder.isNotEmpty && _draftOrder[0].isNotEmpty) {
      // Example mapping for draft order
      for (int i = 0; i < _draftOrder[0].length; i++) {
        String header = _draftOrder[0][i].toString().toLowerCase();
        _fieldIndexes['draftOrder']![header] = i;
      }
      
      // Fallback mappings if headers don't match expected names
      if (!_fieldIndexes['draftOrder']!.containsKey('pick')) {
        _fieldIndexes['draftOrder']!['pick'] = 0;  // Assume first column is pick
      }
      if (!_fieldIndexes['draftOrder']!.containsKey('team')) {
        _fieldIndexes['draftOrder']!['team'] = 1;  // Assume second column is team
      }
      if (!_fieldIndexes['draftOrder']!.containsKey('selection')) {
        _fieldIndexes['draftOrder']!['selection'] = 2;  // Assume third column is selection
      }
      if (!_fieldIndexes['draftOrder']!.containsKey('position')) {
        _fieldIndexes['draftOrder']!['position'] = 3;  // Assume fourth column is position
      }
      if (!_fieldIndexes['draftOrder']!.containsKey('trade')) {
        _fieldIndexes['draftOrder']!['trade'] = 5;  // Fallback for trade info
      }
    }
    
    // Map available players fields
    if (_availablePlayers.isNotEmpty && _availablePlayers[0].isNotEmpty) {
      for (int i = 0; i < _availablePlayers[0].length; i++) {
        String header = _availablePlayers[0][i].toString().toLowerCase();
        _fieldIndexes['availablePlayers']![header] = i;
      }
      
      // Fallback mappings
      if (!_fieldIndexes['availablePlayers']!.containsKey('player')) {
        _fieldIndexes['availablePlayers']!['player'] = 1;  // Assume player name is second column
      }
      if (!_fieldIndexes['availablePlayers']!.containsKey('position')) {
        _fieldIndexes['availablePlayers']!['position'] = 2;  // Assume position is third column
      }
      if (!_fieldIndexes['availablePlayers']!.containsKey('rank')) {
        _fieldIndexes['availablePlayers']!['rank'] = _availablePlayers[0].length - 1;  // Assume rank is last column
      }
    }
    
    // Map team needs fields
    if (_teamNeeds.isNotEmpty && _teamNeeds[0].isNotEmpty) {
      for (int i = 0; i < _teamNeeds[0].length; i++) {
        String header = _teamNeeds[0][i].toString().toLowerCase();
        _fieldIndexes['teamNeeds']![header] = i;
      }
      
      // Fallback mappings
      if (!_fieldIndexes['teamNeeds']!.containsKey('team')) {
        _fieldIndexes['teamNeeds']!['team'] = 1;  // Assume team name is second column
      }
    }
    
    // Log field mappings for debugging
    debugPrint("✅ Field Indexes Mapped:");
    _fieldIndexes.forEach((key, value) {
      debugPrint("  $key: $value");
    });
  }

  /// Load draft order data with improved error handling
  Future<void> _loadDraftOrder() async {
    try {
      // Use draft year if provided
      String filename = 'assets/draft_order${widget.draftYear != '2024' ? '_${widget.draftYear}' : ''}.csv';
      debugPrint("📄 Loading draft order from: $filename");
      
      final data = await rootBundle.loadString(filename);
      final parsedData = CsvDataHandler.parseCsvData(data);

      setState(() {
        _draftOrder = parsedData;
      });

      debugPrint("✅ Draft Order Loaded: ${_draftOrder.length} rows");
      if (_draftOrder.isNotEmpty) {
        debugPrint("✅ Draft Order Headers: ${_draftOrder[0]}");
      }
    } catch (e) {
      debugPrint("❌ Error loading draft order CSV: $e");
      // Try loading default file if year-specific file failed
      try {
        final data = await rootBundle.loadString('assets/draft_order.csv');
        final parsedData = CsvDataHandler.parseCsvData(data);
        
        setState(() {
          _draftOrder = parsedData;
        });
        
        debugPrint("✅ Fallback Draft Order Loaded: ${_draftOrder.length} rows");
      } catch (fallbackError) {
        debugPrint("❌ Fallback loading also failed: $fallbackError");
        // Initialize with empty header row as last resort
        setState(() {
          _draftOrder = [["Pick", "Team", "Selection", "Position", "College", "Trade"]];
        });
      }
    }
  }

  /// Load available players with improved error handling
  Future<void> _loadAvailablePlayers() async {
    try {
      // Use draft year if provided
      String filename = 'assets/available_players${widget.draftYear != '2024' ? '_${widget.draftYear}' : ''}.csv';
      debugPrint("📄 Loading available players from: $filename");
      
      final data = await rootBundle.loadString(filename);
      final parsedData = CsvDataHandler.parseCsvData(data);

      setState(() {
        _availablePlayers = parsedData;
      });

      debugPrint("✅ Available Players Loaded: ${_availablePlayers.length} rows");
      if (_availablePlayers.isNotEmpty) {
        debugPrint("✅ Available Players Headers: ${_availablePlayers[0]}");
      }
    } catch (e) {
      debugPrint("❌ Error loading available players CSV: $e");
      // Try loading default file if year-specific file failed
      try {
        final data = await rootBundle.loadString('assets/available_players.csv');
        final parsedData = CsvDataHandler.parseCsvData(data);
        
        setState(() {
          _availablePlayers = parsedData;
        });
        
        debugPrint("✅ Fallback Available Players Loaded: ${_availablePlayers.length} rows");
      } catch (fallbackError) {
        debugPrint("❌ Fallback loading also failed: $fallbackError");
        // Initialize with empty header row as last resort
        setState(() {
          _availablePlayers = [["Rank", "Player", "Position", "College", "Grade"]];
        });
      }
    }
  }

  /// Load team needs with improved error handling
  Future<void> _loadTeamNeeds() async {
    try {
      // Use draft year if provided
      String filename = 'assets/team_needs${widget.draftYear != '2024' ? '_${widget.draftYear}' : ''}.csv';
      debugPrint("📄 Loading team needs from: $filename");
      
      final data = await rootBundle.loadString(filename);
      final parsedData = CsvDataHandler.parseCsvData(data);

      setState(() {
        _teamNeeds = parsedData;
      });

      debugPrint("✅ Team Needs Loaded: ${_teamNeeds.length} rows");
      if (_teamNeeds.isNotEmpty) {
        debugPrint("✅ Team Needs Headers: ${_teamNeeds[0]}");
      }
    } catch (e) {
      debugPrint("❌ Error loading team needs CSV: $e");
      // Try loading default file if year-specific file failed
      try {
        final data = await rootBundle.loadString('assets/team_needs.csv');
        final parsedData = CsvDataHandler.parseCsvData(data);
        
        setState(() {
          _teamNeeds = parsedData;
        });
        
        debugPrint("✅ Fallback Team Needs Loaded: ${_teamNeeds.length} rows");
      } catch (fallbackError) {
        debugPrint("❌ Fallback loading also failed: $fallbackError");
        // Initialize with empty header row as last resort
        setState(() {
          _teamNeeds = [["Rank", "Team", "Need1", "Need2", "Need3", "Need4", "Need5", "Need6", "Need7", "Need8", "Need9", "Need10", "Selected"]];
        });
      }
    }
  }

  void _toggleDraft() {
    debugPrint("🚀 Toggle Draft Pressed! Current State: $_isDraftRunning");

    setState(() {
      _isDraftRunning = !_isDraftRunning;
    });

    debugPrint("🛠️ Draft Running Status After Toggle: $_isDraftRunning");

    if (_isDraftRunning) {
      debugPrint("🏈 Draft is now running! Calling _draftNextPlayer...");
      _draftNextPlayer();
    } else {
      debugPrint("⏹️ Draft Paused or Stopped.");
    }
  }

  void _draftNextPlayer() {
    if (!_isDraftRunning) {
      debugPrint("⏹️ Draft is paused. No pick made.");
      return;
    }

    debugPrint("📢 Drafting next player...");

    // ✅ Log current state
    debugPrint("📝 Draft Order Before: ${_draftOrder.length} entries");
    debugPrint("📝 Available Players Before: ${_availablePlayers.length} entries");

    if (_availablePlayers.length <= 1 || _draftOrder.length <= 1) {
      debugPrint("❌ No available players or draft picks left.");
      setState(() {
        _isDraftRunning = false; // Stop the draft if no players are available
      });
      return;
    }

    // Get indexes for key fields
    final teamIdx = _fieldIndexes['draftOrder']!['team'] ?? 1;
    final selectionIdx = _fieldIndexes['draftOrder']!['selection'] ?? 2;
    final positionIdx = _fieldIndexes['draftOrder']!['position'] ?? 3;
    
    final playerNameIdx = _fieldIndexes['availablePlayers']!['player'] ?? 1;
    final playerPosIdx = _fieldIndexes['availablePlayers']!['position'] ?? 2;

    // ✅ Step 1: Find the next available draft slot
    debugPrint("🔍 Finding the next pick...");
    List<dynamic>? nextPick;
    for (var pick in _draftOrder.skip(1)) { // Skip header row
      // Safely check if selection field is empty
      if (pick.length > selectionIdx && 
          (CsvDataHandler.safeAccess(pick, selectionIdx).isEmpty)) {
        nextPick = pick;
        break;
      }
    }

    if (nextPick == null) {
      debugPrint("🏁 Draft Completed! No more picks available.");
      setState(() {
        _isDraftRunning = false;
      });
      return;
    }

    debugPrint("📝 Next Pick Found: $nextPick");

    // ✅ Step 2: Select the best available player
    if (_availablePlayers.length < 2) {
      debugPrint("❌ ERROR: No players left to draft!");
      return;
    }

    List<dynamic> bestPlayer = _availablePlayers[1]; // Best player at index 1
    debugPrint("📝 Best Player Selected: $bestPlayer");

    // ✅ Step 3: Assign the player to the draft order
    try {
      // Ensure the pick row has enough elements
      while (nextPick.length <= positionIdx) {
        nextPick.add("");
      }
      
      // Safely access player name and position
      String playerName = CsvDataHandler.safeAccess(bestPlayer, playerNameIdx);
      String playerPos = CsvDataHandler.safeAccess(bestPlayer, playerPosIdx);
      
      nextPick[selectionIdx] = playerName; // Assign player name
      nextPick[positionIdx] = playerPos; // Assign player position
    } catch (e) {
      debugPrint("❌ ERROR: Assigning best player to draft order failed - $e");
      return;
    }

    // ✅ Update team needs dynamically based on the selected player
    try {
      String teamName = CsvDataHandler.safeAccess(nextPick, teamIdx);
      String playerPos = CsvDataHandler.safeAccess(bestPlayer, playerPosIdx);
      
      for (var team in _teamNeeds.skip(1)) { // Skip header row
        String currentTeamName = CsvDataHandler.safeAccess(team, 1); // Team name is typically at index 1
        
        if (currentTeamName.toLowerCase() == teamName.toLowerCase()) {
          bool needRemoved = false;
          
          // Look for the position in the team needs columns (typically start at index 2)
          for (int i = 2; i < team.length && i < 12; i++) {
            if (CsvDataHandler.safeAccess(team, i).toLowerCase() == playerPos.toLowerCase()) {
              team[i] = ""; // Remove the need
              needRemoved = true;
              break;
            }
          }
          
          // Ensure "Selected" column exists
          int selectedIdx = team.length;
          if (selectedIdx <= 12) {
            // Add empty items until we reach the "Selected" column
            while (team.length < 12) {
              team.add("");
            }
            team.add(playerPos); // Add selected position
          } else {
            team[12] = playerPos; // Update existing "Selected" column
          }
          
          break; // Found the team, no need to continue
        }
      }
    } catch (e) {
      debugPrint("❌ ERROR: Updating team needs failed - $e");
    }

    // ✅ Step 4: Remove the drafted player from available players
    try {
      setState(() {
        _draftOrder = List.from(_draftOrder); // Ensure UI updates
        _availablePlayers.removeAt(1);
        _teamNeeds = List.from(_teamNeeds);
      });
    } catch (e) {
      debugPrint("❌ ERROR: Removing drafted player from available players list failed - $e");
      return;
    }

    // Log the result
    String playerName = CsvDataHandler.safeAccess(bestPlayer, playerNameIdx);
    String playerPos = CsvDataHandler.safeAccess(bestPlayer, playerPosIdx);
    String teamName = CsvDataHandler.safeAccess(nextPick, teamIdx);
    
    debugPrint("✅ Pick Made: $teamName selects $playerName ($playerPos)");
    
    // Apply speed factor to determine delay
    int delayMs = (1000 / widget.speedFactor).round();
    delayMs = delayMs.clamp(200, 5000); // Ensure reasonable bounds
    
    // ✅ Step 5: Continue the draft loop
    if (_isDraftRunning) {
      debugPrint("🔄 Draft continuing in ${delayMs}ms...");
      Future.delayed(Duration(milliseconds: delayMs), _draftNextPlayer);
    }
  }

  void _restartDraft() {
    setState(() {
      _isDraftRunning = false;
    });
    
    // Reload all data to reset the draft
    _loadAllData();
  }

  void _requestTrade() {
    if (!widget.enableUserTradeProposals) {
      // Show dialog to inform user that trade functionality is disabled
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Trade Proposals Disabled'),
          content: const Text('Trade proposals are currently disabled. Enable them in draft settings.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }
    
    // Logic to request a trade goes here
    debugPrint("Trade requested");
    
    // Show dialog to inform user that trade functionality is coming soon
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Trade Request'),
        content: const Text('Trade functionality coming soon!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3, // Number of tabs
      child: Scaffold(
        appBar: AppBar(
          title: Text('NFL Draft ${widget.draftYear}'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Draft Order', icon: Icon(Icons.list)),
              Tab(text: 'Available Players', icon: Icon(Icons.people)),
              Tab(text: 'Team Needs', icon: Icon(Icons.assignment)),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            DraftOrderTab(draftOrder: _draftOrder), // Draft Order tab
            AvailablePlayersTab(availablePlayers: _availablePlayers), // Available Players tab
            TeamNeedsTab(teamNeeds: _teamNeeds), // Team Needs tab
          ],
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        floatingActionButton: DraftControlButtons(
          isDraftRunning: _isDraftRunning,
          onToggleDraft: _toggleDraft,
          onRestartDraft: _restartDraft,
          onRequestTrade: _requestTrade,
        ),
      ),
    );
  }
}