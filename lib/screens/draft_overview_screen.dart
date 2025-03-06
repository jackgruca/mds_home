// lib/screens/draft_overview_screen.dart - Updated with trade integration
import 'package:flutter/material.dart';
import '../models/player.dart';
import '../models/draft_pick.dart';
import '../models/team_need.dart';
import '../models/trade_offer.dart';
import '../models/trade_package.dart';
import '../services/data_service.dart';
import '../services/draft_service.dart';
import '../services/draft_value_service.dart';
import '../utils/constants.dart';

import '../widgets/trade/trade_dialog.dart';
import '../widgets/trade/trade_history.dart';
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

class DraftAppState extends State<DraftApp> with SingleTickerProviderStateMixin {
  bool _isDraftRunning = false;
  bool _isDataLoaded = false;
  String _statusMessage = "Loading draft data...";
  DraftService? _draftService;
  
  // Tab controller for the additional trade history tab
  late TabController _tabController;

  // State variables for data (now using typed models)
  List<Player> _players = [];
  List<DraftPick> _draftPicks = [];
  List<TeamNeed> _teamNeeds = [];
  
  // Trade tracking
  List<TradePackage> _executedTrades = [];
  
  // Compatibility variables for existing UI components
  List<List<dynamic>> _draftOrderLists = [];
  List<List<dynamic>> _availablePlayersLists = [];
  List<List<dynamic>> _teamNeedsLists = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _initializeServices();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _initializeServices() async {
    try {
      // Initialize the draft value service first
      await DraftValueService.initialize();
      
      // Then load the draft data
      await _loadData();
    } catch (e) {
      setState(() {
        _statusMessage = "Error initializing services: $e";
      });
      debugPrint("Error initializing services: $e");
    }
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
        userTeam: widget.selectedTeam,
        numberRounds: widget.numberOfRounds,
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
        
        // Reset trade tracking
        _executedTrades = [];
        
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
      // Get the next pick
      final nextPick = _draftService!.getNextPick();
      
      // Check if this is the user's team and they should make a choice
      if (nextPick != null && nextPick.teamName == widget.selectedTeam) {
        _handleUserPick(nextPick);
        return;
      }
      
      // Process the next pick using the enhanced algorithm
      final updatedPick = _draftService!.processDraftPick();
      
      // Check if a trade was executed
      _executedTrades = _draftService!.executedTrades;
      
      // Update the UI with newly processed data
      setState(() {
        // Refresh the list representations for UI
        _draftOrderLists = DataService.draftPicksToLists(_draftPicks);
        _availablePlayersLists = DataService.playersToLists(_draftService!.availablePlayers);
        _teamNeedsLists = DataService.teamNeedsToLists(_teamNeeds);
        
        _statusMessage = _draftService!.statusMessage;
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

  void _handleUserPick(DraftPick pick) {
    setState(() {
      _isDraftRunning = false;
      _statusMessage = "Your turn to pick or trade for pick #${pick.pickNumber}";
    });
    
    // First show trade offers for this pick
    _showTradeOptions(pick);
  }

  void _showTradeOptions(DraftPick pick) {
    if (_draftService == null) return;
    
    // Generate trade offers for this pick
    final tradeOffers = _draftService!.getTradeOffersForCurrentPick();
    
    // Only show the dialog if there are viable trade offers
    if (tradeOffers.packages.isNotEmpty) {
      showDialog(
        context: context,
        builder: (context) => TradeDialog(
          tradeOffer: tradeOffers,
          onAccept: (package) {
            // Execute the selected trade
            _draftService!.executeUserSelectedTrade(package);
            _executedTrades = _draftService!.executedTrades;
            
            // Update UI
            setState(() {
              _draftOrderLists = DataService.draftPicksToLists(_draftPicks);
              _statusMessage = _draftService!.statusMessage;
            });
            
            Navigator.pop(context); // Close the dialog
            
            // Continue the draft if it was running
            if (_isDraftRunning) {
              Future.delayed(
                Duration(milliseconds: (AppConstants.defaultDraftSpeed / widget.speedFactor).round()), 
                _processDraftPick
              );
            }
          },
          onReject: () {
            Navigator.pop(context); // Close the dialog
            
            // Let the user select a player if this is their pick
            if (pick.teamName == widget.selectedTeam) {
              _showPlayerSelectionDialog(pick);
            } else if (_isDraftRunning) {
              // Continue the draft if it was running
              Future.delayed(
                Duration(milliseconds: (AppConstants.defaultDraftSpeed / widget.speedFactor).round()), 
                _processDraftPick
              );
            }
          },
        ),
      );
    } else if (pick.teamName == widget.selectedTeam) {
      // If no trade offers, go straight to player selection
      _showPlayerSelectionDialog(pick);
    } else if (_isDraftRunning) {
      // Continue the draft if it was running
      Future.delayed(
        Duration(milliseconds: (AppConstants.defaultDraftSpeed / widget.speedFactor).round()), 
        _processDraftPick
      );
    }
  }

  void _showPlayerSelectionDialog(DraftPick pick) {
    if (_draftService == null) return;
    
    // Get team needs for the current team
    final teamNeed = _teamNeeds.firstWhere(
      (need) => need.teamName == pick.teamName,
      orElse: () => TeamNeed(teamName: pick.teamName, needs: []),
    );
    
    // Filter available players - first 10 players to make selection manageable
    final topPlayers = _draftService!.availablePlayers.take(10).toList();
    
    // Mark players that fill needs
    final needPositions = teamNeed.needs;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Select a Player for ${pick.teamName}'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: ListView.builder(
            itemCount: topPlayers.length,
            itemBuilder: (context, index) {
              final player = topPlayers[index];
              final isNeed = needPositions.contains(player.position);
              
              return ListTile(
                title: Text(player.name),
                subtitle: Text('${player.position} - Rank: ${player.rank}'),
                trailing: isNeed 
                  ? Chip(
                      label: const Text('Need'),
                      backgroundColor: Colors.green.shade100,
                    )
                  : null,
                onTap: () {
                  Navigator.pop(context);
                  
                  // Execute the player selection
                  _selectPlayer(pick, player);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              
              // Auto-select best player at position of need
              _autoSelectPlayer(pick);
            },
            child: const Text('Auto Pick'),
          ),
        ],
      ),
    );
  }

  void _selectPlayer(DraftPick pick, Player player) {
    if (_draftService == null) return;
    
    // Update the pick with the selected player
    pick.selectedPlayer = player;
    
    // Update team needs
    final teamNeed = _teamNeeds.firstWhere(
      (need) => need.teamName == pick.teamName,
      orElse: () => TeamNeed(teamName: pick.teamName, needs: []),
    );
    teamNeed.removeNeed(player.position);
    
    // Remove player from available players
    _draftService!.availablePlayers.remove(player);
    
    // Update UI
    setState(() {
      _draftOrderLists = DataService.draftPicksToLists(_draftPicks);
      _availablePlayersLists = DataService.playersToLists(_draftService!.availablePlayers);
      _teamNeedsLists = DataService.teamNeedsToLists(_teamNeeds);
      _statusMessage = "Pick #${pick.pickNumber}: ${pick.teamName} selects ${player.name} (${player.position})";
    });
    
    // Continue the draft if it was running
    if (_isDraftRunning) {
      Future.delayed(
        Duration(milliseconds: (AppConstants.defaultDraftSpeed / widget.speedFactor).round()), 
        _processDraftPick
      );
    }
  }

  void _autoSelectPlayer(DraftPick pick) {
    if (_draftService == null) return;
    
    // Let the draft service select the best player
    final player = _draftService!.selectBestPlayerForTeam(pick.teamName);
    
    _selectPlayer(pick, player);
  }

  void _restartDraft() {
    setState(() {
      _isDraftRunning = false;
    });
    
    // Reload data to reset the draft
    _loadData();
  }

  void _requestTrade() {
    if (_draftService == null) return;
    
    DraftPick? nextPick = _draftService!.getNextPick();
    if (nextPick == null) return;
    
    // Show trade dialog for current pick
    _showTradeOptions(nextPick);
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('NFL Draft'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Draft Order', icon: Icon(Icons.list)),
            Tab(text: 'Available Players', icon: Icon(Icons.people)),
            Tab(text: 'Team Needs', icon: Icon(Icons.assignment)),
            Tab(text: 'Trades', icon: Icon(Icons.swap_horiz)),
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
              controller: _tabController,
              children: [
                DraftOrderTab(draftOrder: _draftOrderLists),
                AvailablePlayersTab(availablePlayers: _availablePlayersLists),
                TeamNeedsTab(teamNeeds: _teamNeedsLists),
                TradeHistoryWidget(trades: _executedTrades),
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
    );
  }
}

// Extension method for DraftService to add required functionality
extension DraftServiceExtensions on DraftService {
  /// Get the next pick in the draft
  DraftPick? getNextPick() {
    for (var pick in draftOrder) {
      if (!pick.isSelected) {
        return pick;
      }
    }
    return null;
  }
  
  /// Select the best player for a specific team
  Player selectBestPlayerForTeam(String teamName) {
    // Get team needs
    TeamNeed? teamNeed = teamNeeds.firstWhere(
      (need) => need.teamName == teamName,
      orElse: () => TeamNeed(teamName: teamName, needs: []),
    );
    
    // Get next pick
    DraftPick? nextPick = getNextPick();
    if (nextPick == null) {
      // Fallback to best overall player if no pick found
      return availablePlayers.first;
    }
    
    // Use the existing selection algorithm
  return selectPlayerRStyle(teamNeed, nextPick);  }
}