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
