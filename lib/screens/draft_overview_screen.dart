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

  @override
  void initState() {
    super.initState();
    //_loadDraftOrder();
    _loadAvailablePlayers();
    //_loadTeamNeeds();
  }

    /// Potentially it doesn't like the way its being loaded? 
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
