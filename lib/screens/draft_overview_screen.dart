// lib/screens/draft_overview_screen.dart - Updated with trade integration
import 'package:flutter/material.dart';
import 'package:mds_home/utils/theme_manager.dart';
import 'package:provider/provider.dart';
import '../models/player.dart';
import '../models/draft_pick.dart';
import '../models/team_need.dart';
import '../models/trade_offer.dart';
import '../models/trade_package.dart';
import '../services/data_service.dart';
import '../services/draft_service.dart';
import '../services/draft_value_service.dart';
import '../utils/constants.dart';
import '../widgets/trade/enhanced_trade_dialog.dart';
import '../widgets/trade/user_trade_dialog.dart';
import '../widgets/trade/trade_response_dialog.dart';
import '../widgets/trade/user_trade_tabs_dialog.dart';
import '../widgets/analytics/draft_analytics_dashboard.dart';
import '../widgets/draft/draft_history_widget.dart';

import '../widgets/trade/trade_dialog.dart';
import '../widgets/trade/trade_history.dart';
import 'available_players_tab.dart';
import 'draft_summary_screen.dart';
import 'team_needs_tab.dart';
import 'draft_order_tab.dart';
import 'team_selection_screen.dart';

import '../widgets/draft/draft_control_buttons.dart';

class DraftApp extends StatefulWidget {
  final double randomnessFactor;
  final int numberOfRounds;
  final double speedFactor;
  final String? selectedTeam;
  final int draftYear; // Add this line
  final bool enableTrading;
  final bool enableUserTradeProposals;
  final bool enableQBPremium;
  final bool showAnalytics;

  const DraftApp({
    super.key,
    this.randomnessFactor = AppConstants.defaultRandomnessFactor,
    this.numberOfRounds = 1,
    this.speedFactor = 1.0,
    this.selectedTeam,
    this.draftYear = 2025, // Add this line with default
    this.enableTrading = true,
    this.enableUserTradeProposals = true,
    this.enableQBPremium = true,
    this.showAnalytics = true,
  });

  @override
  DraftAppState createState() => DraftAppState();
}

class DraftAppState extends State<DraftApp> with SingleTickerProviderStateMixin {
  bool _isDraftRunning = false;
  bool _isDataLoaded = false;
  String _statusMessage = "Loading draft data...";
  DraftService? _draftService;
  bool _isUserPickMode = false;  // Tracks if we're waiting for user to pick
  DraftPick? _userNextPick;
  final ScrollController _draftOrderScrollController = ScrollController();
  bool _summaryShown = false;

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
    _draftOrderScrollController.dispose();
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

  List<String> _getSelectedPositions() {
  // Extract positions that have been drafted
  List<String> selectedPositions = [];
  
  // Find all picks from user's team that have been made
  final userPicks = _draftPicks.where((pick) => 
    pick.teamName == widget.selectedTeam && 
    pick.selectedPlayer != null
  );
  
  // Add those positions to the list
  for (var pick in userPicks) {
    if (pick.selectedPlayer?.position != null) {
      selectedPositions.add(pick.selectedPlayer!.position);
    }
  }
  
  return selectedPositions;
}

  // Modify the loadData method in DraftAppState
Future<void> _loadData() async {
  try {
    await DraftValueService.initialize();

    // Load data using our DataService
    final players = await DataService.loadAvailablePlayers(year: widget.draftYear);
    final allDraftPicks = await DataService.loadDraftOrder(year: widget.draftYear);
    final teamNeeds = await DataService.loadTeamNeeds(year: widget.draftYear);
    
    // Mark which picks are active in the current draft (based on selected rounds)
    // but keep all picks for trading purposes
    for (var pick in allDraftPicks) {
      int round = int.tryParse(pick.round) ?? 1;
      pick.isActiveInDraft = round <= widget.numberOfRounds;
    }
    
    // Filter display picks for draft order tab
    final displayDraftPicks = allDraftPicks.where((pick) => pick.isActiveInDraft).toList();

    // After loading draftPicks
    debugPrint("Teams in draft order:");
    for (var pick in displayDraftPicks.take(10)) {
      debugPrint("Pick #${pick.pickNumber}: Team '${pick.teamName}'");
    }

    // Create the draft service with ALL picks (not just filtered ones)
    final draftService = DraftService(
      availablePlayers: List.from(players),
      draftOrder: allDraftPicks,  // Use all picks for the draft service
      teamNeeds: teamNeeds,
      randomnessFactor: widget.randomnessFactor,
      userTeam: widget.selectedTeam,
      numberRounds: widget.numberOfRounds,
      enableTrading: widget.enableTrading,
      enableUserTradeProposals: widget.enableUserTradeProposals,
      enableQBPremium: widget.enableQBPremium,
    );

    // Convert models to lists for the existing UI components
    final draftOrderLists = DataService.draftPicksToLists(displayDraftPicks); // Only filtered picks for display
    final availablePlayersLists = DataService.playersToLists(players);
    final teamNeedsLists = DataService.teamNeedsToLists(teamNeeds);

    setState(() {
      _players = players;
      _draftPicks = allDraftPicks;  // Store all picks
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
          // Add this code to automatically switch to the Analytics tab
    if (widget.showAnalytics && !_summaryShown) {
      _summaryShown = true;
      Future.delayed(const Duration(milliseconds: 1600), () {
        // Switch to the Analytics tab - adjust the index to match your app
        _tabController.animateTo(3); // Adjust this index if your Analytics tab is at a different position
        
        // Show a notification
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Draft complete! View your draft summary and analytics.'),
            duration: Duration(seconds: 3),
          ),
        );
      });
    }
      return;
    }

    try {
      // Get the next pick
      final nextPick = _draftService!.getNextPick();

      debugPrint("Next pick: ${nextPick?.pickNumber}, Team: ${nextPick?.teamName}, Selected Team: ${widget.selectedTeam}");
      
      // Check if this is the user's team and they should make a choice
      if (nextPick != null && nextPick.teamName == widget.selectedTeam) {
        setState(() {
          _isDraftRunning = false; // Pause the draft
          _statusMessage = "YOUR PICK: Select a player from the Available Players tab";
          _isUserPickMode = true; // Add this flag to your class
          _userNextPick = nextPick; // Add this field to store the current pick
        });
        
        // Switch to the available players tab
        _tabController.animateTo(1); // Index of available players tab
        
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

       if (_tabController.index == 0 && _draftOrderScrollController.hasClients) {
          // Calculate position based on completed picks
          double position = _draftService!.completedPicksCount * 50.0;
          
          // Ensure we don't scroll beyond content
          if (position > _draftOrderScrollController.position.maxScrollExtent) {
            position = _draftOrderScrollController.position.maxScrollExtent;
          }
          
          // Smooth scroll
          _draftOrderScrollController.animateTo(
            position,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
          );
        }

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

// In draft_overview_screen.dart, inside the DraftAppState class
void _initiateUserTradeProposal() {
  if (_draftService == null || widget.selectedTeam == null) {
    debugPrint("Draft service or selected team is null");
    return;
  }
  
  // Generate offers for user picks if needed
  _draftService!.generateUserPickOffers();
  
  // Get user's available picks
  final userPicks = _draftService!.getTeamPicks(widget.selectedTeam!);
  
  // Get other teams' available picks
  final otherTeamPicks = _draftService!.getOtherTeamPicks(widget.selectedTeam!);
  
  if (userPicks.isEmpty || otherTeamPicks.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('No available picks to trade'),
        duration: Duration(seconds: 2),
      ),
    );
    return;
  }
  
  // Show trade tabs dialog
  showDialog(
    context: context,
    builder: (context) => UserTradeTabsDialog(
      userTeam: widget.selectedTeam!,
      userPicks: userPicks,
      targetPicks: otherTeamPicks,
      pendingOffers: _draftService!.pendingUserOffers,
      onAcceptOffer: (offer) {
        Navigator.pop(context); // Close dialog
        
        // Execute the trade
        _draftService!.executeUserSelectedTrade(offer);
        
        setState(() {
          _executedTrades = _draftService!.executedTrades;
          _draftOrderLists = DataService.draftPicksToLists(_draftPicks);
          _statusMessage = "Trade accepted: ${offer.tradeDescription}";
        });
      },
      onPropose: (proposal) {
        Navigator.pop(context); // Close dialog
        
        // Process the proposal
        final accepted = _draftService!.processUserTradeProposal(proposal);
        
        // Show response dialog
        showDialog(
          context: context,
          builder: (context) => TradeResponseDialog(
            tradePackage: proposal,
            wasAccepted: accepted,
            rejectionReason: accepted ? null : _draftService!.getTradeRejectionReason(proposal),
            onClose: () {
              Navigator.pop(context);
              
              // Update UI if trade was accepted
              if (accepted) {
                setState(() {
                  _executedTrades = _draftService!.executedTrades;
                  _draftOrderLists = DataService.draftPicksToLists(_draftPicks);
                  _statusMessage = _draftService!.statusMessage;
                });
              }
            },
          ),
        );
      },
      onCancel: () {
        Navigator.pop(context);
      },
    ),
  );
}

  void _showTradeOptions(DraftPick pick) {
    if (_draftService == null) return;
    
    // Generate trade offers for this pick
    final tradeOffers = _draftService!.getTradeOffersForCurrentPick();
    
    // Only show the dialog if there are viable trade offers
    if (tradeOffers.packages.isNotEmpty) {
      showDialog(
        context: context,
        builder: (context) => EnhancedTradeDialog(  // <-- Using the enhanced dialog
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

void _openDraftHistory() {
  if (_draftService == null) return;
  
  // Show a full-screen dialog with the draft history
  showDialog(
    context: context,
    builder: (context) => Dialog.fullscreen(
      child: Scaffold(
        appBar: AppBar(
          title: Text('${widget.draftYear} NFL Draft'),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: DraftHistoryWidget(
          completedPicks: _draftPicks.where((pick) => pick.selectedPlayer != null).toList(),
          userTeam: widget.selectedTeam,
        ),
      ),
    ),
  );
}

  void _showDraftSummary() {
  if (_draftService == null) return;
  
  // Show a full-screen dialog with the draft summary
  showDialog(
    context: context,
    barrierDismissible: false, // Prevent dismissing by tapping outside
    builder: (context) => DraftSummaryScreen(
      completedPicks: _draftPicks.where((pick) => pick.selectedPlayer != null).toList(),
      draftedPlayers: _players.where((player) => 
        _draftPicks.any((pick) => pick.selectedPlayer?.id == player.id)).toList(),
      executedTrades: _executedTrades,
      userTeam: widget.selectedTeam,
    ),
  );
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
      
      // Reset user pick mode
      _isUserPickMode = false;
      _userNextPick = null;
      
      // Automatically resume the draft
      _isDraftRunning = true;
    });
    
    // Switch to draft order tab to see the selection
    _tabController.animateTo(0);
    
    // Continue the draft after a brief pause
    Future.delayed(
      const Duration(milliseconds: 500), 
      _processDraftPick
    );
  }

  void _autoSelectPlayer(DraftPick pick) {
    if (_draftService == null) return;
    
    // Let the draft service select the best player
    final player = _draftService!.selectBestPlayerForTeam(pick.teamName);
    
    _selectPlayer(pick, player);
  }

  void _restartDraft() {
  // Navigate back to team selection screen instead of reloading data
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => const TeamSelectionScreen(),
      ),
    );
  }

  // Find this method in draft_overview_screen.dart and replace it
  void _requestTrade() {
    if (_draftService == null) return;
    
    // If user has selected a team, show user trade proposal UI
    if (widget.selectedTeam != null) {
      _initiateUserTradeProposal();
      return;
    }
    
    // Otherwise, show trade options for current pick
    DraftPick? nextPick = _draftService!.getNextPick();
    if (nextPick != null) {
      _showTradeOptions(nextPick);
    }
  }

// Add this method to the DraftAppState class
void _testDraftSummary() {
  // Force show the draft summary for testing
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('Manually triggering draft summary'),
      duration: Duration(seconds: 1),
    ),
  );
  
  // Show the summary after a brief delay
  Future.delayed(const Duration(milliseconds: 500), () {
    _showDraftSummary();
  });
}

// Add a check to show the summary when draft is complete
@override
void didUpdateWidget(DraftApp oldWidget) {
  super.didUpdateWidget(oldWidget);
  
  print("Draft complete check: ${_draftService?.isDraftComplete()}");
  print("Draft running: $_isDraftRunning");
  print("Data loaded: $_isDataLoaded");
  print("Show analytics: ${widget.showAnalytics}");
  print("Summary already shown: $_summaryShown");

  // Check if draft just completed and summary hasn't been shown yet
  if (_draftService != null && 
      _draftService!.isDraftComplete() && 
      !_isDraftRunning && 
      _isDataLoaded &&
      widget.showAnalytics &&
      !_summaryShown) {
    // Set flag to prevent showing summary multiple times
    _summaryShown = true;
    
    // Wait a moment, then switch to the Analytics tab
    Future.delayed(const Duration(milliseconds: 500), () {
      // Switch to the Analytics tab (assuming it's the 3rd tab, index 2)
      _tabController.animateTo(3); // Adjust this index if needed
      
      // Show a notification to inform the user
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Draft complete! View your draft summary and analytics.'),
          duration: Duration(seconds: 3),
        ),
      );
    });
  }
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

     bool hasTradeOffers = false;
      if (_draftService != null && widget.selectedTeam != null) {
        DraftPick? nextPick = _draftService!.getNextPick();
        if (nextPick != null && nextPick.teamName == widget.selectedTeam) {
          hasTradeOffers = _draftService!.hasOffersForPick(nextPick.pickNumber);
        }
    }
    

    return Scaffold(
      appBar: AppBar(
        title: const Text('NFL Draft'),
        actions: [
    // Theme toggle button
    IconButton(
      icon: Icon(
        Provider.of<ThemeManager>(context).themeMode == ThemeMode.light
            ? Icons.dark_mode
            : Icons.light_mode,
      ),
      tooltip: 'Toggle Theme',
      onPressed: () {
        Provider.of<ThemeManager>(context, listen: false).toggleTheme();
      },
    ),
    // Other app bar actions...
  ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            const Tab(text: 'Draft Order', icon: Icon(Icons.list)),
            const Tab(text: 'Available Players', icon: Icon(Icons.people)),
            const Tab(text: 'Team Needs', icon: Icon(Icons.assignment)),
            if (widget.showAnalytics) // Only show if enabled
              const Tab(text: 'Analytics', icon: Icon(Icons.analytics)),
          ],
        ),
      ),
      body: Column(
        children: [
          // Status bar
          Container(
            padding: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: widget.selectedTeam != null 
                  ? [Colors.blue.shade50, Colors.green.shade50]
                  : [Colors.blue.shade50, Colors.blue.shade100],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  spreadRadius: 1,
                  blurRadius: 2,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Row(
              children: [
                if (widget.selectedTeam != null) ...[
                  const Icon(Icons.sports_football, color: Colors.green),
                  const SizedBox(width: 8),
                  Text(
                    '${widget.selectedTeam}:',  
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                
                // Status message - always show this
                Expanded(
                  child: Text(
                    _statusMessage,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    textAlign: widget.selectedTeam != null ? TextAlign.left : TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                
                // Always show the propose trade button if user team selected
                if (widget.selectedTeam != null)
                  OutlinedButton.icon(
                    onPressed: _initiateUserTradeProposal,
                    icon: const Icon(Icons.swap_horiz, size: 16),
                    label: const Text('Trade'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
              ],
            ),
          ),
          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                DraftOrderTab(
                  draftOrder: _draftOrderLists,
                  userTeam: widget.selectedTeam,
                  scrollController: _draftOrderScrollController, // Add this line instead of the key
                  teamNeeds: _teamNeedsLists,
                ),
               AvailablePlayersTab(
                availablePlayers: _availablePlayersLists,
                selectionEnabled: _isUserPickMode,
                userTeam: widget.selectedTeam,
                selectedPositions: _getSelectedPositions(), // Add this parameter
                onPlayerSelected: (playerIndex) {
                    // Keep your existing onPlayerSelected code unchanged
                    if (_isUserPickMode && _userNextPick != null) {
                      Player? selectedPlayer;
                      
                      try {
                        selectedPlayer = _players.firstWhere((p) => p.id == playerIndex);
                      } catch (e) {
                        if (playerIndex >= 0 && playerIndex < _draftService!.availablePlayers.length) {
                          selectedPlayer = _draftService!.availablePlayers[playerIndex];
                        }
                      }
                      
                      if (selectedPlayer != null) {
                        _selectPlayer(_userNextPick!, selectedPlayer);
                        setState(() {
                          _isUserPickMode = false;
                          _userNextPick = null;
                        });
                      } else {
                        debugPrint("Could not find player with index $playerIndex");
                      }
                    }
                  },
                ),
                TeamNeedsTab(teamNeeds: _teamNeedsLists),
                if (widget.showAnalytics)
                  DraftAnalyticsDashboard(
                    completedPicks: _draftPicks.where((pick) => pick.selectedPlayer != null).toList(),
                    draftedPlayers: _players.where((player) => 
                      _draftPicks.any((pick) => pick.selectedPlayer?.id == player.id)).toList(),
                    executedTrades: _executedTrades,
                    userTeam: widget.selectedTeam,
                  ),
                ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomAppBar(
  child: Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Existing UI elements, if any
        
        // Add the history button
        OutlinedButton.icon(
          onPressed: _openDraftHistory,
          icon: const Icon(Icons.history),
          label: const Text('Draft History'),
        ),
      ],
    ),
  ),
),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: DraftControlButtons(
        isDraftRunning: _isDraftRunning,
        hasTradeOffers: hasTradeOffers,  // Pass this value
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