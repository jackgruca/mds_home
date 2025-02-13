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
  final List<List<dynamic>> _draftOrder = [];
  List<List<dynamic>> _availablePlayers = [];
  final List<List<dynamic>> _teamNeeds = [];

  // Hard code... see if the issue is because of loading the CSV ?
  List<List<dynamic>> availablePlayers = [
    [
      '',
      'Name',
      'Position',
      'mddRank',
      'tankRank',
      'espnRank',
      'drafttekRank',
      'pffRank',
      'athleticRank',
      'buzz_rank',
      'jeremiah_rank',
      'Rank_average',
      'Rank_combined'
    ],
    [1, 'Caleb Williams', 'QB', 1, 1, 1, 1, 1, 1, 2, 1, 1.125, 1],
    [2, 'Marvin Harrison Jr.', 'WR', 3, 2, 2, 2, 2, 2, 1, 2, 2, 2],
    [3, 'Malik Nabers', 'WR', 5, 3, 3, 7, 4, 3, 3, 4, 4, 3],
    [4, 'Drake Maye', 'QB', 2, 8, 6, 6, 3, 4, 7, 5, 5.125, 4],
    [5, 'Joe Alt', 'OT', 8, 5, 4, 4, 5, 6, 4, 8, 5.5, 5],
    [6, 'Rome Odunze', 'WR', 6, 6, 8, 8, 6, 7, 10, 3, 6.75, 6],
    [7, 'Jayden Daniels', 'QB', 4, 4, 5, 3, 21, 8, 6, 6, 7.125, 7],
    [8, 'Brock Bowers', 'TE / WR', 10, 7, 13, 5, 7, 5, 5, 7, 7.375, 8],
    [9, 'Dallas Turner', 'EDGE', 9, 9, 7, 9, 16, 12, 14, 13, 11.125, 9],
    [10, 'Quinyon Mitchell', 'CB', 11, 11, 10, 13, 9, 11, 16, 12, 11.625, 10],
  ];

  @override
  void initState() {
    super.initState();
    //_loadDraftOrder();
    // _loadAvailablePlayers();
    _availablePlayers = availablePlayers; // Use hard coded list
    debugPrint("Available Players Loaded: $_availablePlayers");
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
      await Future.delayed(
          const Duration(seconds: 2)); // Wait time between picks
      _makeDraftPick(); // Auto-pick a player
    }
  }

  void _makeDraftPick() {
    if (_availablePlayers.isNotEmpty) {
      setState(() {
        final pick = _availablePlayers.removeAt(0); // Selects first player
        _draftOrder.add(pick); // Adds the pick to draft history
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
            AvailablePlayersTab(
                availablePlayers: _availablePlayers), // Available Players tab
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
