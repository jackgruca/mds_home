import 'package:flutter/material.dart';
import 'available_players_tab.dart';
import 'team_needs_tab.dart';
import 'draft_order_tab.dart';
import '../../widgets/draft/draft_control_buttons.dart';

import 'package:flutter/services.dart' show rootBundle;
import 'package:csv/csv.dart';

class DraftApp extends StatefulWidget {
  const DraftApp({super.key});

  @override
  DraftAppState createState() => DraftAppState();
}

class DraftAppState extends State<DraftApp> {
  bool _isDraftRunning = false;

  // State variables for data
  List<List<dynamic>> _draftOrder = [];
  List<List<dynamic>> _availablePlayers = [];
  List<List<dynamic>> _teamNeeds = [];

  @override
  void initState() {
    super.initState();
    _loadDraftOrder();
    _loadAvailablePlayers();
    _loadTeamNeeds();
  }

    /// Potentially it doesn't like the way its being loaded? 
  Future<void> _loadAvailablePlayers() async {
    try {
      final data = await rootBundle.loadString('assets/available_players.csv');
      List<List<dynamic>> csvTable = const CsvToListConverter(eol: "\n").convert(data);

      setState(() {
        _availablePlayers = csvTable.map((row) => row.map((cell) => cell.toString()).toList()).toList();
      });

      // 🚀 Debugging to Verify Fix
      debugPrint("✅ Data Type of filteredPlayers: ${_availablePlayers.runtimeType}");
      debugPrint("✅ First Row: ${_availablePlayers.isNotEmpty ? _availablePlayers[0] : "No Data"}");
      debugPrint("✅ First Player Row: ${_availablePlayers.length > 1 ? _availablePlayers[1] : "No Data"}");

    } catch (e) {
      debugPrint("❌ Error loading CSV: $e");
    }
  }

  Future<void> _loadDraftOrder() async {
    try {
      final data = await rootBundle.loadString('assets/draft_order.csv');
      List<List<dynamic>> csvTable = const CsvToListConverter(eol: "\n").convert(data);

      setState(() {
        _draftOrder = csvTable.map((row) => row.map((cell) => cell.toString()).toList()).toList();
      });

      // 🚀 Debugging to Verify Fix
      debugPrint("✅ Data Type of draftOrder: ${_draftOrder.runtimeType}");
      debugPrint("✅ First Row: ${_draftOrder.isNotEmpty ? _draftOrder[0] : "No Data"}");
      debugPrint("✅ First Draft Row: ${_draftOrder.length > 1 ? _draftOrder[1] : "No Data"}");

    } catch (e) {
      debugPrint("❌ Error loading CSV: $e");
    }
  }

    Future<void> _loadTeamNeeds() async {
    try {
      final data = await rootBundle.loadString('assets/team_needs.csv');
      List<List<dynamic>> csvTable = const CsvToListConverter(eol: "\n").convert(data);

      setState(() {
        _teamNeeds= csvTable.map((row) => row.map((cell) => cell.toString()).toList()).toList();
      });

      // 🚀 Debugging to Verify Fix
      debugPrint("✅ Data Type of teamNeeds: ${_teamNeeds.runtimeType}");
      debugPrint("✅ First Row: ${_teamNeeds.isNotEmpty ? _teamNeeds[0] : "No Data"}");
      debugPrint("✅ First Needs Row: ${_teamNeeds.length > 1 ? _teamNeeds[1] : "No Data"}");

    } catch (e) {
      debugPrint("❌ Error loading CSV: $e");
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

  // ✅ Step 1: Find the next available draft slot
  debugPrint("🔍 Finding the next pick...");
  List<dynamic>? nextPick;
  for (var pick in _draftOrder) {
    if (pick.length > 2 && (pick[2] == null || pick[2].toString().isEmpty)) {
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
    nextPick[2] = bestPlayer[1]; // Assign player name
    nextPick[3] = bestPlayer[2]; // Assign player position
  } catch (e) {
    debugPrint("❌ ERROR: Assigning best player to draft order failed - $e");
    return;
  }

  // ✅ Remove drafted player's position from team needs
for (var team in _teamNeeds) {
  if (team[1] == nextPick[1]) { // Match team name in team needs
    bool needRemoved = false;
    
    for (int i = 2; i < 12; i++) { // Scan only within the 10 needs columns
      if (team[i] == bestPlayer[2]) { // ✅ If drafted position is a team need
        team[i] = ""; // ✅ Remove the need
        needRemoved = true;
        break; // Stop after removing one instance
      }
    }

    // ✅ Ensure "Selected" column exists (team[12])
    if (team.length < 13) {
      team.add(""); 
    }

    // ✅ If position was a need, update selected. If not, still show selection
    team[12] = bestPlayer[2]; // ✅ Always show the drafted player’s position
  }
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

  debugPrint("✅ Pick Made: ${nextPick[1]} selects ${bestPlayer[1]} (${bestPlayer[2]})");

  // ✅ Step 5: Continue the draft loop
  if (_isDraftRunning) {
    debugPrint("🔄 Draft continuing in 1 second...");
    Future.delayed(const Duration(seconds: 1), _draftNextPlayer);
  }
}

  void _restartDraft() {
    setState(() {
      _isDraftRunning = false;
      // Logic to reset the draft goes here
    });
  }

  void _requestTrade() {
    // Logic to request a trade goes here
    debugPrint("Trade requested");
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3, // Number of tabs
      child: Scaffold(
        appBar: AppBar(
          title: const Text('NFL Draft'),
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
