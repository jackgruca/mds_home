// lib/screens/draft_overview_screen.dart
import 'package:flutter/material.dart';
import '../models/player.dart';
import '../models/draft_pick.dart';
import '../models/team_need.dart';
import '../services/data_service.dart';
import '../services/draft_service.dart';
import '../utils/constants.dart';

import 'available_players_tab.dart';
import 'team_needs_tab.dart';
import 'draft_order_tab.dart';
import '../widgets/draft/draft_control_buttons.dart';

class DraftApp extends StatefulWidget {
  final double randomnessFactor;
  final int numberOfRounds;
  final double speedFactor;
  final String? selectedTeam;

  const DraftApp({
    super.key,
    this.randomnessFactor = AppConstants.defaultRandomnessFactor,
    this.numberOfRounds = 1,
    this.speedFactor = 1.0,
    this.selectedTeam,
  });

  @override
  DraftAppState createState() => DraftAppState();
}

class DraftAppState extends State<DraftApp> {
  bool _isDraftRunning = false;
  bool _isDataLoaded = false;
  String _statusMessage = "Loading draft data...";
  DraftService? _draftService;

  // State variables for data (now using typed models)
  List<Player> _players = [];
  List<DraftPick> _draftPicks = [];
  List<TeamNeed> _teamNeeds = [];
  
  // Compatibility variables for existing UI components
  List<List<dynamic>> _draftOrderLists = [];
  List<List<dynamic>> _availablePlayersLists = [];
  List<List<dynamic>> _teamNeedsLists = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      // Load data using our DataService
      final players = await DataService.loadAvailablePlayers();
      final draftPicks = await DataService.loadDraftOrder();
      final teamNeeds = await DataService.loadTeamNeeds();
      
      // Filter draft picks based on the number of rounds selected
      final filteredDraftPicks = draftPicks.where((pick) {
        int round = int.tryParse(pick.round) ?? 1;
        return round <= widget.numberOfRounds;
      }).toList();

      // Create the draft service with the loaded data
      final draftService = DraftService(
        availablePlayers: List.from(players), // Create copies to avoid modifying originals
        draftOrder: filteredDraftPicks,
        teamNeeds: teamNeeds,
        randomnessFactor: widget.randomnessFactor,
      );

      // Convert models to lists for the existing UI components
      final draftOrderLists = DataService.draftPicksToLists(filteredDraftPicks);
      final availablePlayersLists = DataService.playersToLists(players);
      final teamNeedsLists = DataService.teamNeedsToLists(teamNeeds);

      setState(() {
        _players = players;
        _draftPicks = filteredDraftPicks;
        _teamNeeds = teamNeeds;
        _draftService = draftService;
        
        // Set list versions for UI compatibility
        _draftOrderLists = draftOrderLists;
        _availablePlayersLists = availablePlayersLists;
        _teamNeedsLists = teamNeedsLists;
        
        _isDataLoaded = true;
        _statusMessage = "Draft data loaded successfully";
      });
    } catch (e) {
      setState(() {
        _statusMessage = "Error loading draft data: $e";
      });
      debugPrint("Error loading data: $e");
    }
  }

  void _toggleDraft() {
    if (!_isDataLoaded || _draftService == null) {
      debugPrint("Cannot start draft: Data not loaded or draft service is null");
      return;
    }

    setState(() {
      _isDraftRunning = !_isDraftRunning;
    });

    if (_isDraftRunning) {
      _processDraftPick();
    }
  }

  void _processDraftPick() {
    if (!_isDraftRunning || _draftService == null) {
      return;
    }

    if (_draftService!.isDraftComplete()) {
      setState(() {
        _isDraftRunning = false;
        _statusMessage = "Draft complete!";
      });
      return;
    }

    try {
      // Process the next pick
      final updatedPick = _draftService!.processDraftPick();
      
      // Update the UI with newly processed data
      setState(() {
        // Refresh the list representations for UI
        _draftOrderLists = DataService.draftPicksToLists(_draftPicks);
        _availablePlayersLists = DataService.playersToLists(_draftService!.availablePlayers);
        _teamNeedsLists = DataService.teamNeedsToLists(_teamNeeds);
        
        _statusMessage = "Pick #${updatedPick.pickNumber}: ${updatedPick.teamName} selects ${updatedPick.selectedPlayer?.name} (${updatedPick.selectedPlayer?.position})";
      });

      // Continue the draft loop with delay
      if (_isDraftRunning) {
        // Adjust delay based on speed factor (lower is faster)
        int delay = (AppConstants.defaultDraftSpeed / widget.speedFactor).round();
        Future.delayed(Duration(milliseconds: delay), _processDraftPick);
      }
    } catch (e) {
      debugPrint("Error processing draft pick: $e");
      setState(() {
        _isDraftRunning = false;
        _statusMessage = "Error during draft: $e";
      });
    }
  }

  void _restartDraft() {
    setState(() {
      _isDraftRunning = false;
    });
    
    // Reload data to reset the draft
    _loadData();
  }

  void _requestTrade() {
    // To be implemented
    debugPrint("Trade requested (not implemented yet)");
  }

  @override
  Widget build(BuildContext context) {
    if (!_isDataLoaded) {
      return Scaffold(
        appBar: AppBar(title: const Text('NFL Draft')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(_statusMessage),
            ],
          ),
        ),
      );
    }

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
        body: Column(
          children: [
            // Status bar
            Container(
              padding: const EdgeInsets.all(8.0),
              color: Colors.blue.shade100,
              width: double.infinity,
              child: Text(
                _statusMessage,
                style: const TextStyle(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),
            
            // Tab content
            Expanded(
              child: TabBarView(
                children: [
                  DraftOrderTab(draftOrder: _draftOrderLists),
                  AvailablePlayersTab(availablePlayers: _availablePlayersLists),
                  TeamNeedsTab(teamNeeds: _teamNeedsLists),
                ],
              ),
            ),
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