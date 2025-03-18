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
import '../services/player_descriptions_service.dart';
import '../utils/constants.dart';
import '../widgets/trade/enhanced_trade_dialog.dart';
import '../widgets/trade/user_trade_dialog.dart';
import '../widgets/trade/trade_response_dialog.dart';
import '../widgets/trade/user_trade_tabs_dialog.dart';
import '../widgets/analytics/draft_analytics_dashboard.dart';
import '../utils/constants.dart';

import '../widgets/trade/trade_dialog.dart';
import '../widgets/trade/trade_history.dart';
import 'available_players_tab.dart';
import 'draft_summary_screen.dart';
import 'team_needs_tab.dart';
import 'draft_order_tab.dart';
import 'team_selection_screen.dart';

import '../widgets/draft/draft_control_buttons.dart';
import '../widgets/trade/trade_dialog_wrapper.dart';

class DraftApp extends StatefulWidget {
  final double randomnessFactor;
  final int numberOfRounds;
  final double speedFactor;
  final List<String>? selectedTeams;
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
    this.selectedTeams,
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
    
    // Add listener to tab controller to handle tab changes
    _tabController.addListener(_handleTabChange);
    
    _initializeServices();
  }

  // Add this method
  void _handleTabChange() {
    // For now this is empty, but will be useful for the Draft Summary tab implementation
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange); // Remove listener
    _tabController.dispose();
    _draftOrderScrollController.dispose();
    super.dispose();
  }

  void _scrollToCurrentPick() {
    if (!_draftOrderScrollController.hasClients || _draftService == null) return;
    
    // Get the current pick
    DraftPick? currentPick = _draftService!.getNextPick();
    if (currentPick == null) return;
    
    // Get the active (displayed) picks
    final displayedPicks = _draftPicks.where((pick) => pick.isActiveInDraft).toList();
    
    // Find the current pick's position
    int currentPickIndex = displayedPicks.indexWhere(
      (pick) => pick.pickNumber == currentPick.pickNumber
    );
    
    if (currentPickIndex == -1) return; // Not found
    
    // Calculate position
    const double itemHeight = 72.0;
    double viewportHeight = _draftOrderScrollController.position.viewportDimension;
    double targetPosition = (currentPickIndex * itemHeight) - (viewportHeight / 2) + (itemHeight / 2);
    
    // Enforce bounds
    targetPosition = targetPosition.clamp(
      0.0, 
      _draftOrderScrollController.position.maxScrollExtent
    );
    
    // Animate to the position
    _draftOrderScrollController.animateTo(
      targetPosition,
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _initializeServices() async {
  try {
    // Initialize the draft value service first
    await DraftValueService.initialize();
    
    // Initialize the player descriptions service
    await PlayerDescriptionsService.initialize(year: widget.draftYear);
    
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
    pick.teamName == widget.selectedTeams && 
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

List<Color> _getTeamGradientColors(String teamName) {
  // Get team colors
  List<Color> teamColors = NFLTeamColors.getTeamColors(teamName);
  
  // For dark mode, use full colors
  if (Theme.of(context).brightness == Brightness.dark) {
    return teamColors;
  }
  
  // For light mode, use lighter versions for better readability
  return [
    teamColors[0].withOpacity(0.2),
    teamColors[1].withOpacity(0.2),
  ];
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
      // Calculate the round using the accurate method instead of relying on the stored round
      int round = DraftValueService.getRoundForPick(pick.pickNumber);
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
      userTeams: widget.selectedTeams,  // Pass the list of selected teams
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

    if (_tabController.index == 0) {
      // Short delay to allow UI to update
      Future.delayed(const Duration(milliseconds: 200), () {
        if (_draftOrderScrollController.hasClients && _draftService != null) {
          // Use the same scrolling logic as above to center the first pick
          DraftPick? firstPick = _draftService!.getNextPick();
          if (firstPick == null) return;
          
          final displayedPicks = _draftPicks.where((pick) => pick.isActiveInDraft).toList();
          int firstPickIndex = displayedPicks.indexWhere((pick) => pick.pickNumber == firstPick.pickNumber);
          
          if (firstPickIndex == -1) return;
          
          const double itemHeight = 72.0;
          final double viewportHeight = _draftOrderScrollController.position.viewportDimension;
          double targetPosition = (firstPickIndex * itemHeight) - (viewportHeight / 2) + (itemHeight / 2);
          
          targetPosition = targetPosition.clamp(0.0, _draftOrderScrollController.position.maxScrollExtent);
          
          _draftOrderScrollController.animateTo(
            targetPosition,
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeInOutCubic,
          );
        }
      });
    }
    
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
      Future.delayed(const Duration(milliseconds: 1200), () {
        _showDraftSummary();
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

      debugPrint("Next pick: ${nextPick?.pickNumber}, Team: ${nextPick?.teamName}, Selected Teams: ${widget.selectedTeams}");

      // Check if this is the user's team and they should make a choice
      if (nextPick != null && widget.selectedTeams != null && 
          widget.selectedTeams!.contains(nextPick.teamName)) {
        // Generate trade offers before pausing the draft
        _draftService!.generateUserTradeOffers();
        
        setState(() {
          _isDraftRunning = false; // Pause the draft
          _statusMessage = "YOUR PICK: Select a player from the Available Players tab";
          _isUserPickMode = true;
          _userNextPick = nextPick;
        });
        
        // Switch to the available players tab
        _tabController.animateTo(1);
        
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

    // After updating state, scroll to current pick if in draft order tab
    if (_tabController.index == 0 && _draftOrderScrollController.hasClients) {
      // Short delay to allow state to update
      Future.delayed(const Duration(milliseconds: 100), () {
        if (!_draftOrderScrollController.hasClients) return;
        
        // Get the newly processed pick
        DraftPick? currentPick = _draftService!.getNextPick();
        if (currentPick == null) return;
        
        // Get displayed picks
        final displayedPicks = _draftPicks.where((pick) => pick.isActiveInDraft).toList();
        
        // Find current pick index
        int currentPickIndex = displayedPicks.indexWhere(
          (pick) => pick.pickNumber == currentPick.pickNumber
        );
        
        if (currentPickIndex == -1) return; // Not found
        
        // Center the current pick
        const double itemHeight = 72.0;
        final double viewportHeight = _draftOrderScrollController.position.viewportDimension;
        double targetPosition = (currentPickIndex * itemHeight) - (viewportHeight / 2) + (itemHeight / 2);
        
        // Enforce bounds
        targetPosition = targetPosition.clamp(
          0.0, 
          _draftOrderScrollController.position.maxScrollExtent
        );
        
        // Smooth scroll
        _draftOrderScrollController.animateTo(
          targetPosition,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeOutCubic,
        );
      });
    }
        if (_draftService != null) {
          _draftService!.cleanupTradeOffers();
        }

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
      _statusMessage = "Your turn to pick or trade for pick #${pick.pickNumber} (${pick.teamName})";
    });
    
    // First show trade offers for this pick
    _showTradeOptions(pick);
  }

// In draft_overview_screen.dart, inside the DraftAppState class
void _initiateUserTradeProposal() {
  if (_draftService == null || widget.selectedTeams == null) {
    debugPrint("Draft service or selected team is null");
    return;
  }
  
  // Generate offers for user picks if needed
  _draftService!.generateUserTradeOffers();
  
  // Get user's available picks - now using the first team in the selectedTeams list
  final List<DraftPick> userPicks = widget.selectedTeams!.isNotEmpty 
    ? _draftService!.getTeamPicks(widget.selectedTeams!.first)
    : [];
    
  // Get other teams' available picks
  final List<DraftPick> otherTeamPicks = _draftService!.getOtherTeamPicks(widget.selectedTeams);
  
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
      userTeam: widget.selectedTeams!.first,
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
        barrierDismissible: false,
        builder: (context) => TradeDialogWrapper(
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
            if (widget.selectedTeams != null && widget.selectedTeams!.contains(pick.teamName)) {
              _showPlayerSelectionDialog(pick);
            } else if (_isDraftRunning) {
              // Continue the draft if it was running
              Future.delayed(
                Duration(milliseconds: (AppConstants.defaultDraftSpeed / widget.speedFactor).round()), 
                _processDraftPick
              );
            }
          },
          onCounter: (package) {
            // Show snackbar for now - counter feature coming in future update
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Counter offers will be available in a future update'),
                duration: Duration(seconds: 2),
              ),
            );
          },
          showAnalytics: widget.showAnalytics,
        ),
      );
    } else if (widget.selectedTeams != null && widget.selectedTeams!.contains(pick.teamName)) {
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

  void _showDraftSummary() {
  if (_draftService == null) return;
  
  // Get all unique team names for filtering
  final allTeams = _draftPicks
      .map((pick) => pick.teamName)
      .toSet()
      .toList();
  
  // Sort alphabetically for better UX
  allTeams.sort();
  
  // Show a full-screen dialog with the draft summary
  showDialog(
    context: context,
    barrierDismissible: false, // Prevent dismissing by tapping outside
    builder: (context) => DraftSummaryScreen(
      completedPicks: _draftPicks.where((pick) => pick.selectedPlayer != null).toList(),
      draftedPlayers: _players.where((player) => 
        _draftPicks.any((pick) => pick.selectedPlayer?.id == player.id)).toList(),
      executedTrades: _executedTrades,
      allTeams: allTeams, // Add the list of teams
      userTeam: widget.selectedTeams?.isNotEmpty == true ? widget.selectedTeams!.first : null,  // Convert list to single team
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
  // Show confirmation dialog before restarting
  showDialog(
    context: context,
    builder: (BuildContext context) {
      final isDarkMode = Theme.of(context).brightness == Brightness.dark;
      
      return AlertDialog(
        title: Row(
          children: [
            Icon(Icons.refresh, color: isDarkMode ? Colors.orange.shade300 : Colors.orange.shade700),
            const SizedBox(width: 8),
            const Text('Restart Draft?'),
          ],
        ),
        content: const Text(
          'Are you sure you want to restart the draft? All progress will be lost.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(), // Close dialog
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              
              // Reset the draft state instead of navigating
              setState(() {
                _isDraftRunning = false;
                _isUserPickMode = false;
                _userNextPick = null;
                _summaryShown = false;
                
                // Reload data to reset the draft
                _loadData();
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isDarkMode ? Colors.orange.shade700 : Colors.red.shade600,
              foregroundColor: Colors.white,
            ),
            child: const Text('Restart'),
          ),
        ],
      );
    },
  );
}

  // Find this method in draft_overview_screen.dart and replace it
  void _requestTrade() {
    if (_draftService == null) return;
    
    // If user has selected a team, show user trade proposal UI
    if (widget.selectedTeams != null) {
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

@override
void didUpdateWidget(DraftApp oldWidget) {
  super.didUpdateWidget(oldWidget);
  
  // Check if draft just completed and summary hasn't been shown yet
  if (_draftService != null && 
      _draftService!.isDraftComplete() && 
      !_isDraftRunning && 
      _isDataLoaded &&
      !_summaryShown) {
    // Set flag to prevent showing summary multiple times
    _summaryShown = true;
    
    // Wait a moment before showing the summary
    Future.delayed(const Duration(milliseconds: 800), () {
      // Show draft summary screen directly
      _showDraftSummary();
      
      // Notify the user
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Draft complete! View your draft summary.'),
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
  if (_draftService != null && widget.selectedTeams != null) {
    // Check if there are any pending offers for the user team
    hasTradeOffers = _draftService!.pendingUserOffers.isNotEmpty;
    
    // Specifically check for the current pick
    DraftPick? nextPick = _draftService!.getNextPick();
    if (nextPick != null && widget.selectedTeams!.contains(nextPick.teamName)) {
      hasTradeOffers = hasTradeOffers || _draftService!.hasOffersForPick(nextPick.pickNumber);
    }
  }

  return WillPopScope(
    onWillPop: () async {
    // Show a confirmation dialog
    bool shouldPop = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Exit Draft?'),
          content: const Text('Are you sure you want to return to team selection?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                // Pop the dialog with true result
                Navigator.of(dialogContext).pop(true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
              ),
              child: const Text('Exit'),
            ),
          ],
        );
      },
    ) ?? false;
    
    // If user confirms, forcefully navigate back to selection screen
    if (shouldPop) {
      // Push a replacement instead of normal pop to ensure we go back to selection screen
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const TeamSelectionScreen(),
        ),
      );
      return false; // Prevent the default back behavior
    }
    return false; // Prevent the default back behavior
  },
    child: Scaffold(
      appBar: AppBar(
        title: const Text(
          'NFL Draft',
          style: TextStyle(fontSize: TextConstants.kAppBarTitleSize),
        ),
        toolbarHeight: 48,
        centerTitle: true,
        titleSpacing: 8,
        elevation: 0,
        actions: [
          // Theme toggle button
          IconButton(
            icon: Icon(
              Provider.of<ThemeManager>(context).themeMode == ThemeMode.light
                  ? Icons.dark_mode
                  : Icons.light_mode,
              size: 20,
            ),
            onPressed: () {
              Provider.of<ThemeManager>(context, listen: false).toggleTheme();
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(40),
          child: TabBar(
            controller: _tabController,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            labelStyle: const TextStyle(fontSize: TextConstants.kTabLabelSize),
            tabs: [
              const Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.list, size: 18),
                    SizedBox(width: 4),
                    Text('Draft'),
                  ],
                ),
              ),
              const Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.people, size: 18),
                    SizedBox(width: 4),
                    Text('Players'),
                  ],
                ),
              ),
              const Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.assignment, size: 18),
                    SizedBox(width: 4),
                    Text('Needs'),
                  ],
                ),
              ),
              if (widget.showAnalytics)
                const Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.analytics, size: 18),
                      SizedBox(width: 4),
                      Text('Stats'),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          // Status bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: widget.selectedTeams != null 
                  ? _getTeamGradientColors(widget.selectedTeams!.first)
                  : Theme.of(context).brightness == Brightness.dark
                    ? [Colors.blue.shade900, Colors.blue.shade800]
                    : [Colors.blue.shade50, Colors.blue.shade100],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  spreadRadius: 0,
                  blurRadius: 1,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Row(
              children: [
                if (widget.selectedTeams != null) ...[
                  Icon(Icons.sports_football, 
                    size: 16,
                    color: Theme.of(context).brightness == Brightness.dark ? Colors.white70 : Colors.black54),
                  const SizedBox(width: 4),
                  Text(
                    '${widget.selectedTeams}:',  
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: TextConstants.kCardSubtitleSize, // Use standard subtitle size
                      color: Theme.of(context).brightness == Brightness.dark ? Colors.white70 : Colors.black87,
                    ),
                  ),
                  const SizedBox(width: 4),
                ],
                
                // Status message
                Expanded(
                  child: Text(
                    _statusMessage,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: TextConstants.kCardSubtitleSize, // Use standard subtitle size
                      color: Theme.of(context).brightness == Brightness.dark 
                        ? Colors.white 
                        : Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                
                // Trade button
                if (widget.selectedTeams != null)
                  OutlinedButton.icon(
                    onPressed: _showDraftSummary,
                    icon: const Icon(Icons.summarize, size: 14),
                    label: const Text('Draft Recap', style: TextStyle(fontSize: TextConstants.kButtonTextSize)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      visualDensity: VisualDensity.compact,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      // Keep other style properties
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
                  draftOrder: _draftPicks.where((pick) => pick.isActiveInDraft).toList(),
                  userTeam: widget.selectedTeams?.isNotEmpty == true ? widget.selectedTeams!.first : null,  // Convert list to single team
                  scrollController: _draftOrderScrollController,
                  teamNeeds: _teamNeedsLists,
                ),
               AvailablePlayersTab(
                availablePlayers: _availablePlayersLists,
                selectionEnabled: _isUserPickMode,
                userTeam: widget.selectedTeams?.isNotEmpty == true ? widget.selectedTeams!.first : null,  // Convert list to single team
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
                  // Use the simplified analytics dashboard
                  DraftAnalyticsDashboard(
                    completedPicks: _draftPicks.where((pick) => pick.selectedPlayer != null).toList(),
                    draftedPlayers: _players.where((player) => 
                      _draftPicks.any((pick) => pick.selectedPlayer?.id == player.id)).toList(),
                    executedTrades: _executedTrades,
                    teamNeeds: _teamNeeds,
                    userTeam: widget.selectedTeams?.isNotEmpty == true ? widget.selectedTeams!.first : null,  // Convert list to single team
                  )
                ],
            ),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: DraftControlButtons(
        isDraftRunning: _isDraftRunning,
        hasTradeOffers: hasTradeOffers,
        onToggleDraft: _toggleDraft,
        onRestartDraft: _restartDraft,
        onRequestTrade: _requestTrade,
      ),
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