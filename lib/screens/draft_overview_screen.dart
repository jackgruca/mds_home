import 'package:flutter/material.dart';
import 'available_players_tab.dart';
import 'team_needs_tab.dart';
import 'draft_order_tab.dart';
import '../../widgets/draft/draft_control_buttons.dart';

import 'package:flutter/services.dart' show rootBundle;
import 'package:csv/csv.dart';

class DraftApp extends StatefulWidget {
  final String? selectedTeam; // Nullable team selection
  
  const DraftApp({super.key, this.selectedTeam});

  @override
  DraftAppState createState() => DraftAppState();
}

class DraftAppState extends State<DraftApp> {
  bool _isDraftRunning = false;

  // State variables for data
  final List<List<dynamic>> _draftOrder = [];
  List<List<dynamic>> _availablePlayers = [];
  final List<List<dynamic>> _teamNeeds = [];

  @override
  void initState() {
    super.initState();
    //_loadDraftOrder();
    _loadAvailablePlayers();
    //_loadTeamNeeds();
  }

  Future<void> _loadAvailablePlayers() async {
    try {
      final data = await rootBundle.loadString('assets/available_players.csv');
      List<List<dynamic>> csvTable = const CsvToListConverter().convert(data);
      setState(() {
        _availablePlayers = csvTable;
      });
      debugPrint("Available Players Loaded: $_availablePlayers");
    } catch (e) {
      debugPrint("Error loading available players CSV: $e");
    }
  }

  void _toggleDraft() {
    setState(() {
      _isDraftRunning = !_isDraftRunning;
    });
    
    if (_isDraftRunning) {
    _runDraftLoop();
    }
  }

  Future<void> _runDraftLoop() async {
    while (_isDraftRunning && _availablePlayers.isNotEmpty) {
      await Future.delayed(const Duration(seconds: 2)); // Wait time between picks
      _makeDraftPick(); // Auto-pick a player
    }
  }

  void _makeDraftPick() {
    if (_availablePlayers.isNotEmpty) {
      setState(() {
        final pick = _availablePlayers.removeAt(0);  // Selects first player
        _draftOrder.add([_draftOrder.length + 1, pick[1]]); // Add to draft order
      });

      debugPrint("Drafted: ${_draftOrder.last}");
    } else {
      setState(() {
        _isDraftRunning = false; // Stop when no players remain
      });
    }
  }

  void _restartDraft() {
    setState(() {
      _isDraftRunning = false;
      _draftOrder.clear(); // Clear draft picks
      _loadAvailablePlayers(); // Reload the player pool
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
            DraftOrderTab(), // Draft Order tab
            AvailablePlayersTab(availablePlayers: _availablePlayers), // Available Players tab
            TeamNeedsTab(), // Team Needs tab
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
