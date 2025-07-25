// lib/screens/draft_overview_screen.dart - Updated with trade integration
import 'package:flutter/material.dart';
import 'package:mds_home/utils/theme_manager.dart';
import 'package:provider/provider.dart';
import '../models/player.dart';
import '../models/draft_pick.dart';
import '../models/team_need.dart';
import '../models/trade_package.dart';
import '../services/data_service.dart';
import '../services/draft_grade_service.dart';
import '../services/draft_pick_grade_service.dart';
import '../services/draft_service.dart';
import '../services/draft_value_service.dart';
import '../services/player_descriptions_service.dart';
import '../utils/constants.dart';
import '../widgets/trade/user_trade_dialog.dart';
import '../widgets/trade/trade_response_dialog.dart';
import '../widgets/trade/user_trade_tabs_dialog.dart';
import '../widgets/analytics/draft_analytics_dashboard.dart';

import 'available_players_tab.dart';
import 'draft_summary_screen.dart';
import 'team_needs_tab.dart';
import 'draft_order_tab.dart';
import 'team_selection_screen.dart';

import '../widgets/draft/draft_control_buttons.dart';
import '../widgets/trade/trade_dialog_wrapper.dart';
import '../services/firebase_service.dart';
import '../widgets/draft/draft_action_dialog.dart';

// Add breakpoint constant at the top of the file after imports
const double kDesktopBreakpoint = 1100.0;

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
  final List<List<dynamic>>? customTeamNeeds;
  final List<List<dynamic>>? customPlayerRankings;
  final double tradeFrequency;
  final double needVsValueBalance;


  const DraftApp({
  super.key,
  this.randomnessFactor = AppConstants.defaultRandomnessFactor,
  this.numberOfRounds = 1,
  this.speedFactor = 1.0,
  this.selectedTeams,
  this.draftYear = 2025,
  this.enableTrading = true,
  this.enableUserTradeProposals = true,
  this.enableQBPremium = true,
  this.showAnalytics = true,
  this.customTeamNeeds,
  this.customPlayerRankings,
  this.tradeFrequency = 0.5,
  this.needVsValueBalance = 0.4,
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
  List<List<dynamic>> _availablePlayersLists = [];
  List<List<dynamic>> _teamNeedsLists = [];

  String? _activeUserTeam;

  @override
void initState() {
  super.initState();
  _tabController = TabController(length: 4, vsync: this);
  
  // Add listener to tab controller to handle tab changes
  _tabController.addListener(_handleTabChange);
  
  // Set up the scroll controller with proper disposal
  _draftOrderScrollController.addListener(() {
    // Add a listener to debug scroll positions
    if (_draftService?.getNextPick() != null) {
      double position = _draftOrderScrollController.position.pixels;
      double max = _draftOrderScrollController.position.maxScrollExtent;
      double viewportDimension = _draftOrderScrollController.position.viewportDimension;
      
      // Only log occasionally to reduce spam
      if (position % 50 < 1) {
        debugPrint("Scroll position: $position / $max (viewport: $viewportDimension)");
      }
    }
  });
  
  _initializeServices();
}

  // Add a method to update the active user team 
  void _updateActiveUserTeam() {
  if (_draftService == null || widget.selectedTeams == null || widget.selectedTeams!.isEmpty) {
    setState(() {
      _activeUserTeam = null;
    });
    return;
  }
  
  // First check if the next pick belongs to a user team
  DraftPick? nextPick = _draftService!.getNextPick();
  if (nextPick != null && widget.selectedTeams!.contains(nextPick.teamName)) {
    if (_activeUserTeam != nextPick.teamName) {
      setState(() {
        _activeUserTeam = nextPick.teamName;
      });
      debugPrint("Active user team updated to: $_activeUserTeam (next pick)");
    }
    return;
  }
  
  // If the next pick is not a user team, but we have _userNextPick set
  if (_userNextPick != null && widget.selectedTeams!.contains(_userNextPick!.teamName)) {
    if (_activeUserTeam != _userNextPick!.teamName) {
      setState(() {
        _activeUserTeam = _userNextPick!.teamName;
      });
      debugPrint("Active user team updated to: $_activeUserTeam (user next pick)");
    }
    return;
  }
  
  // If we can't determine an active team from the current draft state,
  // fallback to the first selected team
  if (_activeUserTeam == null || !widget.selectedTeams!.contains(_activeUserTeam)) {
    setState(() {
      _activeUserTeam = widget.selectedTeams!.first;
    });
    debugPrint("Active user team fallback to: $_activeUserTeam (first selected)");
  }
}

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange); // Remove listener
    _tabController.dispose();
    _draftOrderScrollController.dispose();
    super.dispose();
  }

  void _scrollToCurrentPick() {
  if (!_draftOrderScrollController.hasClients || _draftService == null) {
    debugPrint("ScrollToCurrentPick: Controller not ready or draft service null");
    return;
  }

  // Get the current pick
  DraftPick? currentPick = _draftService!.getNextPick();
  if (currentPick == null) {
    debugPrint("ScrollToCurrentPick: No current pick found");
    return;
  }
  
  // Get only active (displayed) picks for correct indexing
  final displayedPicks = _draftPicks.where((pick) => pick.isActiveInDraft).toList();
  
  // Find the index of the current pick in the displayed picks list
  int currentPickIndex = displayedPicks.indexWhere(
    (pick) => pick.pickNumber == currentPick.pickNumber
  );
  
  if (currentPickIndex == -1) {
    debugPrint("ScrollToCurrentPick: Current pick #${currentPick.pickNumber} not found in displayed picks");
    return;
  }
  
  // Calculate the actual item height dynamically (better than hardcoding)
  // This is a defensive approach that adapts to different screen sizes and densities
  double totalContentHeight = _draftOrderScrollController.position.maxScrollExtent + 
                              _draftOrderScrollController.position.viewportDimension;
  double estimatedItemHeight = totalContentHeight / displayedPicks.length;
  
  // Use a minimum reasonable height as fallback
  double itemHeight = estimatedItemHeight > 0 ? estimatedItemHeight : 72.0;
  
  debugPrint("ScrollToCurrentPick: Calculated item height: $itemHeight for pick #${currentPick.pickNumber}");
  
  // Calculate the target scroll position to center the current pick
  double viewportHeight = _draftOrderScrollController.position.viewportDimension;
  
  // Calculate position with the current pick exactly centered
  double targetPosition = (currentPickIndex * itemHeight) - (viewportHeight / 2) + (itemHeight / 2);
  
  // Ensure the position is within valid scroll bounds
  targetPosition = targetPosition.clamp(
    0.0, 
    _draftOrderScrollController.position.maxScrollExtent
  );
  
  debugPrint("ScrollToCurrentPick: Scrolling to position $targetPosition for pick #${currentPick.pickNumber} (index: $currentPickIndex)");
  
  // Use a smoother scroll animation
  _draftOrderScrollController.animateTo(
    targetPosition,
    duration: const Duration(milliseconds: 600),
    curve: Curves.easeOutCubic,
  );
}

void _ensureScrollControllerReady() {
  // If we already have clients, we're ready to go
  if (_draftOrderScrollController.hasClients) {
    _scrollToCurrentPick();
    return;
  }
  
  // Otherwise wait for the controller to attach to a scroll view
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (_draftOrderScrollController.hasClients) {
      // Now that we have clients, try to scroll
      _scrollToCurrentPick();
    } else {
      // Still no clients, try again next frame
      _ensureScrollControllerReady();
    }
  });
}

// Enhanced tab change handler
void _handleTabChange() {
  // When tab changes to draft order tab (index 0), scroll to current pick
  if (_tabController.index == 0) {
    // Use a slightly longer delay to ensure the tab view is fully rendered
    Future.delayed(const Duration(milliseconds: 150), () {
      _ensureScrollControllerReady();
    });
  }
}

/// Builds the content for the status bar based on context
Widget _buildStatusBarContent() {
  final isDarkMode = Theme.of(context).brightness == Brightness.dark;
  
  // Check if it's currently the user's turn to pick
  DraftPick? nextPick = _draftService?.getNextPick();
  bool isUserPicking = nextPick != null && 
                       widget.selectedTeams != null && 
                       widget.selectedTeams!.contains(nextPick.teamName);
  
  // Only show team needs when it's the user's turn to pick
  if (isUserPicking && _activeUserTeam != null) {
    // Get team needs for the active team
    List<String> teamNeeds = [];
    for (var need in _teamNeeds) {
      if (need.teamName == _activeUserTeam) {
        teamNeeds = need.needs.take(5).toList(); // Take top 3 needs
        break;
      }
    }
    
    return Row(
      children: [
        Icon(
          Icons.sports_football, 
          size: 16,
          color: isDarkMode ? Colors.white70 : Colors.black54
        ),
        const SizedBox(width: 4),
        
        // Team name
        Text(
          _activeUserTeam!,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: TextConstants.kCardSubtitleSize,
            color: isDarkMode ? Colors.white70 : Colors.black87,
          ),
        ),
        
        const SizedBox(width: 8),
        
        // Display team needs as chips
        if (teamNeeds.isNotEmpty) ...[
          Text(
            'Needs:',
            style: TextStyle(
              fontSize: TextConstants.kCardSubtitleSize - 1,
              color: isDarkMode ? Colors.white60 : Colors.black54,
            ),
          ),
          const SizedBox(width: 4),
          
          // Team need chips in a row
          ...teamNeeds.map((need) => 
            Padding(
              padding: const EdgeInsets.only(right: 3),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: _getPositionColor(need).withOpacity(isDarkMode ? 0.3 : 0.2),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: _getPositionColor(need).withOpacity(isDarkMode ? 0.6 : 0.5),
                    width: 1,
                  ),
                ),
                child: Text(
                  need,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: _getPositionColor(need),
                  ),
                ),
              ),
            )
          ),
        ],
      ],
    );
  } 
  // For all other cases, show the status message
  else {
    return Text(
      _statusMessage,
      style: TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: TextConstants.kCardSubtitleSize,
        color: isDarkMode ? Colors.white : Colors.black87,
      ),
      textAlign: TextAlign.center,
      overflow: TextOverflow.ellipsis,
    );
  }
}

// Add this helper method for position colors if it doesn't already exist
Color _getPositionColor(String position) {
  final isDarkMode = Theme.of(context).brightness == Brightness.dark;
  
  // Different colors for different position groups with dark mode adjustments
  if (['QB', 'RB', 'FB'].contains(position)) {
    return isDarkMode ? Colors.blue.shade400 : Colors.blue.shade700; // Backfield
  } else if (['WR', 'TE'].contains(position)) {
    return isDarkMode ? Colors.green.shade400 : Colors.green.shade700; // Receivers
  } else if (['OT', 'IOL', 'OL', 'G', 'C'].contains(position)) {
    return isDarkMode ? Colors.purple.shade400 : Colors.purple.shade700; // Offensive line
  } else if (['EDGE', 'IDL', 'DT', 'DE'].contains(position)) {
    return isDarkMode ? Colors.red.shade400 : Colors.red.shade700; // Defensive line
  } else if (['LB', 'ILB', 'OLB'].contains(position)) {
    return isDarkMode ? Colors.orange.shade400 : Colors.orange.shade700; // Linebackers
  } else if (['CB', 'S', 'FS', 'SS'].contains(position)) {
    return isDarkMode ? Colors.teal.shade400 : Colors.teal.shade700; // Secondary
  } else {
    return isDarkMode ? Colors.grey.shade400 : Colors.grey.shade700; // Special teams, etc.
  }
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

 Map<String, List<String>> _getTeamSelectedPositions() {
  // Create a map of team name -> list of drafted positions
  Map<String, List<String>> teamPositions = {};
  
  if (widget.selectedTeams != null) {
    // Initialize map for all selected teams
    for (String teamName in widget.selectedTeams!) {
      teamPositions[teamName] = [];
    }
    
    // Find all picks from all teams that have been made
    for (var pick in _draftPicks.where((p) => p.selectedPlayer != null && p.isSelected)) {
      String teamName = pick.teamName;
      // Only track for user-controlled teams
      if (widget.selectedTeams != null && widget.selectedTeams!.contains(teamName)) {
        if (pick.selectedPlayer?.position != null) {
          teamPositions[teamName] ??= []; // Ensure list exists
          teamPositions[teamName]!.add(pick.selectedPlayer!.position);
        }
      }
    }
  }
  
  // Debug log the result
  if (widget.selectedTeams != null && widget.selectedTeams!.isNotEmpty) {
    debugPrint("==== TEAM POSITIONS MAP ====");
    teamPositions.forEach((team, positions) {
      debugPrint("$team drafted positions: ${positions.join(", ")}");
    });
    if (_userNextPick != null) {
      debugPrint("Current picking team: ${_userNextPick!.teamName}");
    }
    debugPrint("==========================");
  }
  
  return teamPositions;
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

    // Variables to store loaded data
    List<Player> players;
    List<DraftPick> allDraftPicks;
    List<TeamNeed> teamNeeds;
    
    // Load default draft order
    allDraftPicks = await DataService.loadDraftOrder(year: widget.draftYear);
    
    // Mark which picks are active in the current draft (based on selected rounds)
    for (var pick in allDraftPicks) {
      int round = DraftValueService.getRoundForPick(pick.pickNumber);
      pick.isActiveInDraft = round <= widget.numberOfRounds;
    }
    
    // Use custom team needs if provided
    if (widget.customTeamNeeds != null) {
      debugPrint("Using custom team needs data");
      
      // Convert team needs lists back to model objects
      teamNeeds = [];
      
      // Skip header row (index 0)
      for (int i = 1; i < widget.customTeamNeeds!.length; i++) {
        try {
          List<dynamic> row = widget.customTeamNeeds![i];
          if (row.length < 2) continue;
          
          String teamName = row[1].toString();
          List<String> needs = [];
          
          // Get needs from columns 2 onwards (need1, need2, etc.)
          for (int j = 2; j < row.length && j < 9; j++) {
            String need = row[j].toString();
            if (need.isNotEmpty && need != "-") {
              needs.add(need);
            }
          }
          
          teamNeeds.add(TeamNeed(teamName: teamName, needs: needs));
        } catch (e) {
          debugPrint("Error parsing custom team need: $e");
        }
      }
    } else {
      // Load default team needs
      teamNeeds = await DataService.loadTeamNeeds(year: widget.draftYear);
    }

    TeamNeedsSnapshot.initialize(teamNeeds);
    
    // Use custom player rankings if provided
    if (widget.customPlayerRankings != null) {
      debugPrint("Using custom player rankings data");
      
      // Convert player rankings back to model objects
      players = [];
      
      // Get column indices from header row
      Map<String, int> columnIndices = {};
      if (widget.customPlayerRankings!.isNotEmpty) {
        List<String> headers = widget.customPlayerRankings![0].map<String>((dynamic col) => 
            col.toString().toUpperCase()).toList();
        
        for (int i = 0; i < headers.length; i++) {
          columnIndices[headers[i]] = i;
        }
      }
      
      // Skip header row (index 0)
      for (int i = 1; i < widget.customPlayerRankings!.length; i++) {
        try {
          List<dynamic> row = widget.customPlayerRankings![i];
          if (row.isEmpty) continue;
          
          // Get indices for required columns
          int idIndex = columnIndices['ID'] ?? 0;
          int nameIndex = columnIndices['NAME'] ?? 1;
          int positionIndex = columnIndices['POSITION'] ?? 2;
          int schoolIndex = columnIndices['SCHOOL'] ?? 3;
          int rankIndex = columnIndices['RANK_COMBINED'] ?? columnIndices['RANK'] ?? 
                          (row.length > 10 ? row.length - 1 : 5); // Default to last column
          
          // Parse values
          int id = idIndex < row.length ? 
                  (int.tryParse(row[idIndex].toString()) ?? 0) : 0;
          
          String name = nameIndex < row.length ? row[nameIndex].toString() : "";
          String position = positionIndex < row.length ? row[positionIndex].toString() : "";
          String school = schoolIndex < row.length ? row[schoolIndex].toString() : "";
          
          int rank = rankIndex < row.length ? 
                    (int.tryParse(row[rankIndex].toString()) ?? 999) : 999;
          
          // Skip empty or invalid rows
          if (name.isEmpty || position.isEmpty) continue;
          
          players.add(Player(
            id: id,
            name: name,
            position: position,
            rank: rank,
            school: school,
          ));
        } catch (e) {
          debugPrint("Error parsing custom player: $e");
        }
      }
      
      // Sort players by rank
      players.sort((a, b) => a.rank.compareTo(b.rank));
    } else {
      // Load default player rankings
      players = await DataService.loadAvailablePlayers(year: widget.draftYear);
    }
    
    // Filter display picks for draft order tab
    final displayDraftPicks = allDraftPicks.where((pick) => pick.isActiveInDraft).toList();
    
    // Create draft service 
    final draftService = DraftService(
      availablePlayers: List.from(players),
      draftOrder: allDraftPicks,
      teamNeeds: teamNeeds,
      randomnessFactor: widget.randomnessFactor,
      userTeams: widget.selectedTeams,
      numberRounds: widget.numberOfRounds,
      enableTrading: widget.enableTrading,
      enableUserTradeProposals: widget.enableUserTradeProposals,
      enableQBPremium: widget.enableQBPremium,
      tradeFrequency: widget.tradeFrequency,
      needVsValueBalance: widget.needVsValueBalance,
    );

    // Convert models to lists for the existing UI components
    DataService.draftPicksToLists(displayDraftPicks);
    final availablePlayersLists = widget.customPlayerRankings ?? DataService.playersToLists(players);
    final teamNeedsLists = widget.customTeamNeeds ?? DataService.teamNeedsToLists(teamNeeds);

    setState(() {
      _players = players;
      _draftPicks = allDraftPicks;
      _teamNeeds = teamNeeds;
      _draftService = draftService;
      
      // Reset trade tracking
      _executedTrades = [];
      
      // Set list versions for UI compatibility
      _availablePlayersLists = availablePlayersLists;
      _teamNeedsLists = teamNeedsLists;
      
      _isDataLoaded = true;
      _statusMessage = "Update live picks w lock button";
    });

    // Apply any live picks from CSV
    await _applyLivePicks();

    // Update active user team after loading data
    _updateActiveUserTeam();

    // Ensure proper scrolling after loading data
    if (_tabController.index == 0) {
      // Give UI time to render before scrolling
      Future.delayed(const Duration(milliseconds: 250), () {
        _ensureScrollControllerReady();
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

  // Save draft analytics when draft is complete
    if (widget.selectedTeams?.isNotEmpty == true) {
      FirebaseService.saveDraftAnalytics(
        userTeam: widget.selectedTeams!.first,
        completedPicks: _draftPicks,
        executedTrades: _executedTrades,
        year: widget.draftYear,
      );
    }
  
  if (widget.showAnalytics) {
    // First change to the analytics tab
    _tabController.animateTo(3); 
    
    // Force showing the summary immediately
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        _showDraftSummary(draftComplete: true);
      }
    });
  }
  return;
}

  // Update active user team before processing the pick
  _updateActiveUserTeam();

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
        _statusMessage = "${nextPick.teamName} Pick: Select from the Available Players tab";
        _isUserPickMode = true;
        _userNextPick = nextPick;
      });
      
      // Trigger scroll on state change to highlight user's current pick
      Future.delayed(const Duration(milliseconds: 100), () {
        _scrollToCurrentPick();
      });
      
      // Switch to the available players tab
      _tabController.animateTo(1);
      
      return;
    }
    
    // Process the next pick using the enhanced algorithm
    _draftService!.processDraftPick();
    
    // Check if a trade was executed
    _executedTrades = _draftService!.executedTrades;
    
    // Update the UI with newly processed data
    setState(() {
      // Refresh the list representations for UI
      _availablePlayersLists = DataService.playersToLists(_draftService!.availablePlayers);
      _teamNeedsLists = DataService.teamNeedsToLists(_teamNeeds);
      
      _statusMessage = _draftService!.statusMessage;
    });

    // After updating state, ensure proper scrolling if in draft order tab
    if (_tabController.index == 0) {
      // Use a slightly longer delay to allow state updates to complete
      Future.delayed(const Duration(milliseconds: 150), () {
        _scrollToCurrentPick();
      });
    }
    
    if (_draftService != null) {
      _draftService!.cleanupTradeOffers();
    }

    // Continue the draft loop with delay
    if (_isDraftRunning) {
      // Adjust delay based on speed factor (lower is faster)
      int delay = (AppConstants.defaultDraftSpeed / (widget.speedFactor * widget.speedFactor)).round();
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


// In draft_overview_screen.dart, inside the DraftAppState class
void _initiateUserTradeProposal() {
  if (_draftService == null || widget.selectedTeams == null) {
    debugPrint("Draft service or selected team is null");
    return;
  }
  
  // Generate offers for user picks if needed
  _draftService!.generateUserTradeOffers();

  // Use active user team rather than first team in list
  String activeTeam = _activeUserTeam ?? widget.selectedTeams!.first;
  
  // Get user's available picks for the active team - including latest future picks
  final List<DraftPick> userPicks = _draftService!.getTeamPicks(activeTeam);
  
  // Debug output to verify future picks
  debugPrint("Future picks available for $activeTeam:");
  List<int> futurePicks = _draftService!.getAvailableFuturePickRounds(activeTeam);
  debugPrint("Available future rounds: ${futurePicks.join(', ')}");
  
  List<DraftPick> otherTeamPicks;
  
  // Special handling when user controls all teams
  bool controlsAllTeams = widget.selectedTeams!.length == NFLTeams.allTeams.length;
  
  if (controlsAllTeams) {
    // When controlling all teams, get picks from all teams EXCEPT active team
    otherTeamPicks = _draftService!.draftOrder.where((pick) => 
      pick.teamName != activeTeam && !pick.isSelected
    ).toList();
  } else {
    // Normal case: Get picks from non-user teams
    otherTeamPicks = _draftService!.getOtherTeamPicks(widget.selectedTeams);
  }
  
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
      userTeam: activeTeam,
      userPicks: userPicks,
      targetPicks: otherTeamPicks,
      pendingOffers: _draftService!.pendingUserOffers,
      draftService: _draftService,
      onAcceptOffer: (offer) {
        Navigator.pop(context); // Close dialog
        
        // Execute the trade
        _draftService!.executeUserSelectedTrade(offer);
        
        setState(() {
          _executedTrades = _draftService!.executedTrades;
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
          
          // Update UI
          setState(() {
            _executedTrades = _draftService!.executedTrades;
            _statusMessage = "Trade accepted: ${package.tradeDescription}";


            // Reset user pick mode
            _isUserPickMode = false;
            _userNextPick = null;
            
            // IMPORTANT: Set draft to running to continue automatically
            _isDraftRunning = true;
          });
                    
          // IMPORTANT: Continue the draft after a brief pause
          Future.delayed(
            Duration(milliseconds: (AppConstants.defaultDraftSpeed / widget.speedFactor).round()), 
            _processDraftPick
          );
        },
        onReject: () {
          
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
          // Get all available picks for both teams
          final receivingTeamPicks = _draftService!.getTeamPicks(package.teamReceiving);
          final offeringTeamPicks = _draftService!.getTeamPicks(package.teamOffering);
          
          // Show counter offer dialog with all picks available and original ones pre-selected
          showDialog(
            context: context,
            builder: (context) => UserTradeProposalDialog(
              userTeam: package.teamReceiving,
              userPicks: receivingTeamPicks, // All receiving team's picks
              targetPicks: offeringTeamPicks, // All offering team's picks
              draftService: _draftService,  // Add this line
              initialSelectedUserPicks: [package.targetPick, ...package.additionalTargetPicks], // Pre-select original offer
              initialSelectedTargetPicks: package.picksOffered, // Pre-select original offer
              hasLeverage: true, // Add this line to indicate leverage
              onPropose: (counterPackage) {
                Navigator.pop(context); // Close dialog
                
                // Process the counter offer with leverage premium
                final originalPackage = package; // Original AI-initiated offer
                final accepted = _draftService!.evaluateCounterOffer(originalPackage, counterPackage);

  // Show response dialog
  showDialog(
    context: context,
    builder: (context) => TradeResponseDialog(
      tradePackage: counterPackage,
      wasAccepted: accepted,
      rejectionReason: accepted ? null : _draftService!.getTradeRejectionReason(counterPackage),
      onClose: () {
        Navigator.pop(context);
        
        // Update UI if trade was accepted
        if (accepted) {
          setState(() {
            _executedTrades = _draftService!.executedTrades;
            _statusMessage = _draftService!.statusMessage;
            
            // Reset user pick mode
            _isUserPickMode = false;
            _userNextPick = null;
            
            // IMPORTANT: Set draft to running to continue automatically
            _isDraftRunning = true;
          });
          
          // Continue the draft after a brief pause
          Future.delayed(
            Duration(milliseconds: (AppConstants.defaultDraftSpeed / widget.speedFactor).round()), 
            _processDraftPick
          );
        } else if (widget.selectedTeams != null && widget.selectedTeams!.contains(pick.teamName)) {
          // If trade was rejected and this is user's pick, show player selection
          _showPlayerSelectionDialog(pick);
        }
      },
    ),
  );
},
              onCancel: () => Navigator.pop(context),
          
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

// Add this method to the DraftAppState class
void _showLockPickDialog() {
  // Controllers for the form
  final pickController = TextEditingController();
  final nameController = TextEditingController();
  final positionController = TextEditingController();
  final schoolController = TextEditingController();
  
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Lock Real-Life Pick'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: pickController,
              decoration: const InputDecoration(labelText: 'Pick Number'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Player Name'),
            ),
            TextField(
              controller: positionController,
              decoration: const InputDecoration(labelText: 'Position'),
            ),
            TextField(
              controller: schoolController,
              decoration: const InputDecoration(labelText: 'School'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            // Parse the pick number
            int? pickNumber = int.tryParse(pickController.text);
            if (pickNumber == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Invalid pick number')),
              );
              return;
            }
            
            // Lock the pick
            _lockRealLifePick(
              pickNumber,
              nameController.text,
              positionController.text,
              schoolController.text,
            );
            
            Navigator.of(context).pop();
          },
          child: const Text('Lock Pick'),
        ),
      ],
    ),
  );
}

// Define the lockRealLifePick method (note the underscore to make it private)
void _lockRealLifePick(int pickNumber, String playerName, String position, String school) {
  if (_draftService == null || _players.isEmpty) return;
  
  // Find the pick by number
  DraftPick pickToLock = _draftPicks.firstWhere(
    (pick) => pick.pickNumber == pickNumber,
    orElse: () => DraftPick(
      pickNumber: -1,
      teamName: "",
      round: ""
    )
  );
  
  if (pickToLock.pickNumber == -1) {
    debugPrint("Could not find pick #$pickNumber to lock");
    return;
  }
  
  // Find or create the player
  Player? selectedPlayer;
  
  // First try to find an existing player with matching name
  try {
    selectedPlayer = _players.firstWhere(
      (p) => p.name.toLowerCase() == playerName.toLowerCase()
    );
  } catch (_) {
    // If not found, create a new player
    selectedPlayer = Player(
      id: 10000 + pickNumber, // Use a high number unlikely to conflict
      name: playerName,
      position: position,
      rank: pickNumber, // Use pick number as approximate rank
      school: school,
    );
    
    // Add to available players (this helps ensure the player exists in the model)
    _players.add(selectedPlayer);
  }
  
  // Lock the pick with the selected player
  pickToLock.selectedPlayer = selectedPlayer;
  pickToLock.isLocked = true;
  
  // Remove player from available players if they were in the list
  _draftService!.availablePlayers.removeWhere((p) => p.name.toLowerCase() == playerName.toLowerCase());
  
  // Update team needs for the picking team - IMPROVED VERSION
  TeamNeed? teamNeed = _teamNeeds.firstWhere(
    (need) => need.teamName == pickToLock.teamName,
    orElse: () => TeamNeed(teamName: pickToLock.teamName, needs: [])
  );
  
  // Only update needs if position is valid and we found the team need
  if (position.isNotEmpty && teamNeed.teamName != 'Unknown Team') {
    // Check if this exact position exists in the needs list
    bool exactPositionMatch = teamNeed.needs.contains(position);
    
    if (exactPositionMatch) {
      // Perfect match - just remove it
      teamNeed.removeNeed(position);
      debugPrint("Removed exact position need: $position");
    } else {
      // Try to find a partial match (e.g., "CB" should match "CB | WR")
      String matchedNeed = "";
      
      // Split the player position in case it has multiple positions (e.g., "CB | WR")
      List<String> playerPositions = position.split('|').map((p) => p.trim()).toList();
      
      // Check each player position against each team need
      for (String playerPos in playerPositions) {
        for (String need in List.from(teamNeed.needs)) {
          // Check if need contains this position or vice versa
          if (need.contains(playerPos) || playerPos.contains(need)) {
            matchedNeed = need;
            break;
          }
        }
        if (matchedNeed.isNotEmpty) break;
      }
      
      if (matchedNeed.isNotEmpty) {
        // Found a matching need - remove it
        teamNeed.removeNeed(matchedNeed);
        debugPrint("Removed matching need: $matchedNeed for position: $position");
      } else {
        // No match found - add the position to selectedPositions without removing anything
        teamNeed.selectedPositions.add(position);
        debugPrint("No matching need found. Added $position to selected positions.");
      }
    }
    
    debugPrint("Updated team needs for ${pickToLock.teamName}: Player: $playerName, Position: $position");
    debugPrint("Remaining needs: ${teamNeed.needs.join(', ')}");
    debugPrint("Selected positions: ${teamNeed.selectedPositions.join(', ')}");
  }
  
  // Update UI
  setState(() {
    _availablePlayersLists = DataService.playersToLists(_draftService!.availablePlayers);
    _teamNeedsLists = DataService.teamNeedsToLists(_teamNeeds);  // This updates the team needs display
    _statusMessage = "Locked pick #$pickNumber: $playerName ($position)";
  });
  
  // Scroll to the current pick
  Future.delayed(const Duration(milliseconds: 150), () {
    _scrollToCurrentPick();
  });
}

/// Apply live picks from CSV to the current draft
Future<void> _applyLivePicks() async {
  if (_draftService == null) return;
  
  // Load the live picks from CSV
  final livePicks = await DataService.loadLivePicks(year: widget.draftYear);
  
  // If no live picks, nothing to do
  if (livePicks.isEmpty) {
    debugPrint("No live picks to apply");
    return;
  }
  
  debugPrint("Applying ${livePicks.length} live picks...");
  
  // Apply each pick in order
  for (var pickData in livePicks) {
    int? pickNumber = int.tryParse(pickData['PICK'] ?? '');
    String playerName = pickData['PLAYER'] ?? '';
    String position = pickData['POSITION'] ?? '';
    String school = pickData['SCHOOL'] ?? '';
    
    if (pickNumber != null && playerName.isNotEmpty) {
      _lockRealLifePick(pickNumber, playerName, position, school);
      debugPrint("Applied live pick #$pickNumber: $playerName");
    }
  }
  
  // Update the UI to reflect the changes
  setState(() {
    _availablePlayersLists = DataService.playersToLists(_draftService!.availablePlayers);
    _teamNeedsLists = DataService.teamNeedsToLists(_teamNeeds);  // Update team needs display
    _statusMessage = "Applied ${livePicks.length} live picks";
  });
  
  // Also make sure we update the DraftService's internal state
  if (_draftService != null) {
    _draftService!.cleanupTradeOffers();
  }
}

void _showDraftSummary({bool draftComplete = false}) {
  if (_draftService == null) return;
  
  // Get all unique team names for filtering
  final allTeams = _draftPicks
      .map((pick) => pick.teamName)
      .toSet()
      .toList();
  
  // Sort alphabetically for better UX
  allTeams.sort();
  
  // Determine initial filter
  // - If draft is complete, use user team instead of "All Teams"
  // - Otherwise, use user team if available
  String? initialFilter = draftComplete && widget.selectedTeams?.isNotEmpty == true 
      ? widget.selectedTeams!.first
      : (widget.selectedTeams?.isNotEmpty == true ? widget.selectedTeams!.first : null);
  
  // Show the dialog with the appropriate filter
  showDialog(
    context: context,
    barrierDismissible: true,
    builder: (context) => DraftSummaryScreen(
      completedPicks: _draftPicks.where((pick) => pick.selectedPlayer != null).toList(),
      draftedPlayers: _players.where((player) => 
        _draftPicks.any((pick) => pick.selectedPlayer?.id == player.id)).toList(),
      executedTrades: _executedTrades,
      allTeams: allTeams,
      userTeam: widget.selectedTeams?.isNotEmpty == true ? widget.selectedTeams!.first : null,
      allDraftPicks: _draftPicks,
      initialFilter: initialFilter,
      teamNeeds: _teamNeeds,
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
  
  // Filter available players
  final topPlayers = _draftService!.availablePlayers.take(10).toList();
  
  // Mark players that fill needs
  final needPositions = teamNeed.needs;
  
  showDialog(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) {
        // Track which player is being hovered
        int? hoveredPlayerIndex;
        
        return AlertDialog(
          title: Text('Select a Player for ${pick.teamName}'),
          content: SizedBox(
            width: double.maxFinite,
            height: 400,
            child: ListView.builder(
              itemCount: topPlayers.length,
              itemBuilder: (context, index) {
                final player = topPlayers[index];
                final isNeed = needPositions.contains(player.position);
                
                // Calculate pick grade
                Map<String, dynamic> gradeInfo = DraftPickGradeService.calculatePickGrade(
                  DraftPick(
                    pickNumber: pick.pickNumber,
                    teamName: pick.teamName,
                    round: pick.round,
                    selectedPlayer: player,
                  ),
                  _teamNeeds,
                );
                
                final letterGrade = gradeInfo['letter'];
                final colorScore = gradeInfo['colorScore'];
                
                return InkWell(
                  onTap: () {
                    Navigator.pop(context);
                    // Execute the player selection
                    _selectPlayer(pick, player);
                  },
                  onHover: (isHovered) {
                    setState(() {
                      hoveredPlayerIndex = isHovered ? index : null;
                    });
                  },
                  child: Container(
                    color: hoveredPlayerIndex == index ? 
                        Colors.grey.withOpacity(0.1) : null,
                    child: ListTile(
                      title: Row(
                        children: [
                          Expanded(
                            child: Text(
                              player.name,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          if (hoveredPlayerIndex == index)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    _getGradientColor(colorScore, 0.2),
                                    _getGradientColor(colorScore, 0.3),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                  color: _getGradientColor(colorScore, 0.8),
                                  width: 0.5,
                                ),
                              ),
                              child: Text(
                                letterGrade,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: _getGradientColor(colorScore, 1.0),
                                ),
                              ),
                            ),
                        ],
                      ),
                      subtitle: Row(
                        children: [
                          Text('${player.position} - Rank: ${player.rank}'),
                          const Spacer(),
                          if (hoveredPlayerIndex == index)
                            Text(
                              'Value: ${pick.pickNumber - player.rank > 0 ? "+" : ""}${pick.pickNumber - player.rank}',
                              style: TextStyle(
                                color: pick.pickNumber - player.rank >= 0 ? 
                                    Colors.green.shade700 : Colors.red.shade700,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                        ],
                      ),
                      trailing: isNeed 
                        ? Chip(
                            label: const Text('Need'),
                            backgroundColor: Colors.green.shade100,
                          )
                        : null,
                    ),
                  ),
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
        );
      }
    ),
  );
}

// Helper method to get gradient color based on score
Color _getGradientColor(int score, double opacity) {
  // A grades (green)
  if (score > 95) return Colors.green.shade700.withOpacity(opacity);  // A+
  if (score == 95) return Colors.green.shade600.withOpacity(opacity);  // A
  if (score >= 90) return Colors.green.shade500.withOpacity(opacity);  // A-
  
  // B grades (blue)
  if (score > 85) return Colors.blue.shade700.withOpacity(opacity);   // B+
  if (score == 85) return Colors.blue.shade600.withOpacity(opacity);   // B
  if (score >= 80) return Colors.blue.shade500.withOpacity(opacity);   // B-
  
  // C grades (yellow)
  if (score > 75) return Colors.amber.shade500.withOpacity(opacity);  // C+
  if (score == 75) return Colors.amber.shade600.withOpacity(opacity);  // C
  if (score >= 70) return Colors.amber.shade700.withOpacity(opacity);  // C-

  // D grades (orange)
  if (score >= 60) return Colors.amber.shade900.withOpacity(opacity);  // C-

  // F grades (red)
  if (score >= 30) return Colors.red.shade600.withOpacity(opacity);    // D+/D
  return Colors.red.shade700.withOpacity(opacity);                     // F
}

  
void _selectPlayer(DraftPick pick, Player player) {
  if (_draftService == null) return;
  
  // Check if this is a user team selection to track for undo
  bool isUserSelection = widget.selectedTeams != null && widget.selectedTeams!.contains(pick.teamName);
  
  // If user selection, take a snapshot of state before changing anything
  if (isUserSelection) {
    // Create deep copy of available players
    List<Player> availablePlayersSnapshot = List.from(_draftService!.availablePlayers);
    
    // Record this selection in history using the public method
    _draftService!.recordUserSelection(pick, player, availablePlayersSnapshot);
  }
  
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
    _availablePlayersLists = DataService.playersToLists(_draftService!.availablePlayers);
    _teamNeedsLists = DataService.teamNeedsToLists(_teamNeeds);
    _statusMessage = "Pick #${pick.pickNumber}: ${pick.teamName} selects ${player.name} (${player.position})";
    
    // Reset user pick mode
    _isUserPickMode = false;
    _userNextPick = null;
    
    // IMPORTANT: Set draft to running to continue automatically
    _isDraftRunning = true;
  });
  
  // Update active user team after player selection
  _updateActiveUserTeam();
  
  // Switch to draft order tab to see the selection
  _tabController.animateTo(0);
  
  // Continue the draft after a brief pause
  Future.delayed(const Duration(milliseconds: 150), () {
    _scrollToCurrentPick();
    
    // IMPORTANT: Add this to continue the draft after a brief delay
    // This delay is important to allow UI updates to complete
    Future.delayed(
      Duration(milliseconds: (AppConstants.defaultDraftSpeed / widget.speedFactor).round()), 
      _processDraftPick
    );
  });
}

void _autoSelectPlayer(DraftPick pick) {
  if (_draftService == null) return;
  
  // Let the draft service select the best player 
  final player = _draftService!.selectBestPlayerForTeam(pick.teamName);
  
  _selectPlayer(pick, player); 
}

void executeUserSelectedTrade(TradePackage package) {
  if (_draftService == null) return;
  
  _draftService!.executeUserSelectedTrade(package);
  
  setState(() {
    _executedTrades = _draftService!.executedTrades;
    _statusMessage = "Trade executed: ${package.tradeDescription}";
    
    // Reset user pick mode
    _isUserPickMode = false;
    _userNextPick = null;
    
    // IMPORTANT: Set draft to running to continue automatically
    _isDraftRunning = true;
  });
  
  // Update active user team after trade execution
  _updateActiveUserTeam();
  
  // Switch to draft order tab
  _tabController.animateTo(0);
  
  // Continue the draft after a brief pause
  Future.delayed(const Duration(milliseconds: 150), () {
    _scrollToCurrentPick();
    
    // IMPORTANT: Add this to continue the draft after a brief delay
    Future.delayed(
      Duration(milliseconds: (AppConstants.defaultDraftSpeed / widget.speedFactor).round()), 
      _processDraftPick
    );
  });
}

bool _shouldShowTeamInfo() {
  // Only show team info when it's the user's turn to pick
  DraftPick? nextPick = _draftService?.getNextPick();
  
  // Check if it's a user team's turn AND we have an active user team
  return nextPick != null && 
         widget.selectedTeams != null && 
         widget.selectedTeams!.contains(nextPick.teamName) &&
         _activeUserTeam != null;
}

  // In lib/screens/draft_overview_screen.dart, update the _restartDraft method

void _restartDraft() {
  // Show the actions dialog with both options
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return DraftActionDialog(
        canUndo: _draftService?.canUndo() ?? false,
        onRestart: () {
          // Reset the draft state
          setState(() {
            _isDraftRunning = false;
            _isUserPickMode = false;
            _userNextPick = null;
            _summaryShown = false;
            
            // Reload data to reset the draft
            _loadData();
          });
        },
        // In the onUndo callback within the _restartDraft method

onUndo: () {
  if (_draftService != null && _draftService!.canUndo()) {
    // Execute the undo operation
    final success = _draftService!.undoLastUserSelection();
    
    if (success) {
      setState(() {
        // Update UI state
        _availablePlayersLists = DataService.playersToLists(_draftService!.availablePlayers);
        _teamNeedsLists = DataService.teamNeedsToLists(_teamNeeds);
        _statusMessage = "Undid your last pick. You're back to pick #${_draftService!.getNextPick()?.pickNumber ?? 'N/A'}";
        
        // Set draft state back to user pick mode
        _isDraftRunning = false;
        _isUserPickMode = true;
        
        // Find the pick that was just undone
        _userNextPick = _draftService!.getNextPick();
        
        // Update active user team
        _updateActiveUserTeam();
        
        // Scroll to the current pick
        Future.delayed(const Duration(milliseconds: 150), () {
          _tabController.animateTo(0); // First switch to the draft order tab
          _scrollToCurrentPick(); // Then scroll to the correct position
        });
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not undo the last action'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }
},
      );
    },
  );
}

  // Find this method in draft_overview_screen.dart and replace it
  void _requestTrade() {
  if (_draftService == null) return;
  
  // If user has selected a team, show user trade proposal UI
  if (widget.selectedTeams != null) {
    // This is the key fix - regenerate user trade offers to get latest pick data
    _draftService!.generateUserTradeOffers();
    
    // Get the latest picks from the draft service
    String activeTeam = _activeUserTeam ?? widget.selectedTeams!.first;
    final userPicks = _draftService!.getTeamPicks(activeTeam);
    
    // Get other teams' picks
    bool controlsAllTeams = widget.selectedTeams!.length == NFLTeams.allTeams.length;
    
    if (controlsAllTeams) {
    } else {
    }
    
    // Debug log to check picks
    debugPrint("User team $activeTeam has ${userPicks.length} draft picks");
    
    // Show the proper dialog with refreshed picks
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

@override
void didUpdateWidget(DraftApp oldWidget) {
  super.didUpdateWidget(oldWidget);
  
  if (_draftService != null && 
      _draftService!.isDraftComplete() && 
      !_isDraftRunning && 
      _isDataLoaded &&
      !_summaryShown) {
    _summaryShown = true;
    
    // First switch to the Recap tab
    if (widget.showAnalytics) {
      _tabController.animateTo(3); // Index 3 is the Stats tab
    }
    
    // Then immediately trigger the "Your Picks" dialog
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        // This is specifically showing the "Your Picks" dialog
        _showDraftSummary(draftComplete: true);
      }
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

  // Calculate trade offers count
  int tradeOffersCount = 0;
  if (_draftService != null && widget.selectedTeams != null) {
    // Count all pending offers for user teams
    tradeOffersCount = _draftService!.pendingUserOffers.values
        .expand((offers) => offers)
        .where((offer) => widget.selectedTeams!.contains(offer.teamReceiving))
        .length;
  }

  bool hasTradeOffers = false;
  if (_draftService != null && widget.selectedTeams != null) {
    // Check if there are any pending offers for the user team
    hasTradeOffers = _draftService!.pendingUserOffers.values
      .expand((offers) => offers)
      .any((offer) => widget.selectedTeams!.contains(offer.teamReceiving));
    
    // Specifically check for the current pick
    DraftPick? nextPick = _draftService!.getNextPick();
    if (nextPick != null && widget.selectedTeams!.contains(nextPick.teamName)) {
      hasTradeOffers = hasTradeOffers || _draftService!.hasOffersForPick(nextPick.pickNumber);
    }
  }

  // Get screen width for responsive layout
  final screenWidth = MediaQuery.of(context).size.width;
  final isDesktop = screenWidth > kDesktopBreakpoint;

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
          'StickToTheModel Draft Sim',
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

          // Refresh live picks button
          IconButton(
            icon: const Icon(Icons.refresh, size: 20),
            tooltip: "Reload Live Picks",
            onPressed: () async {
              await _applyLivePicks();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Reloaded live picks'))
              );
            },
          ),
          // New lock pick button
          IconButton(
            icon: const Icon(Icons.lock_outline, size: 20),
            onPressed: () {
              _showLockPickDialog();
            },
          ),
        ],
        // Always show TabBar, regardless of screen size
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(40),
          child: TabBar(
            controller: _tabController,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            labelStyle: const TextStyle(fontSize: TextConstants.kTabLabelSize),
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
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
                      Text('Recap'),
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
                colors: _shouldShowTeamInfo() 
                  ? _getTeamGradientColors(_activeUserTeam!)
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
                // Dynamic left side of the banner
                Expanded(
                  child: _buildStatusBarContent(),
                ),
                
                // Draft recap button - keeps the same on the right side
                OutlinedButton.icon(
                  onPressed: () => _showDraftSummary(draftComplete: false),
                  icon: const Icon(Icons.summarize, size: 14),
                  label: const Text('Your Picks'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    visualDensity: VisualDensity.compact,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ],
            ),
          ),
          
          // Main content area
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Draft Order Tab
                isDesktop 
                  ? Row(
                      children: [
                        // Left side - Draft Order
                        Expanded(
                          child: DraftOrderTab(
                            draftOrder: _draftPicks.where((pick) => pick.isActiveInDraft).toList(),
                            userTeam: widget.selectedTeams?.isNotEmpty == true ? widget.selectedTeams!.first : null,
                            scrollController: _draftOrderScrollController,
                            teamNeeds: _teamNeedsLists,
                            currentPickNumber: _draftService?.getNextPick()?.pickNumber,
                          ),
                        ),
                        // Right side - Available Players
                        Expanded(
                          child: AvailablePlayersTab(
                            availablePlayers: _availablePlayersLists,
                            selectionEnabled: _isUserPickMode && _draftService != null && 
                                           _userNextPick != null && 
                                           widget.selectedTeams != null &&
                                           widget.selectedTeams!.contains(_draftService!.getNextPick()?.teamName),
                            userTeam: _userNextPick?.teamName,
                            teamSelectedPositions: _getTeamSelectedPositions(),
                            onPlayerSelected: (playerIndex) {
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
                        ),
                      ],
                    )
                  : DraftOrderTab(
                      draftOrder: _draftPicks.where((pick) => pick.isActiveInDraft).toList(),
                      userTeam: widget.selectedTeams?.isNotEmpty == true ? widget.selectedTeams!.first : null,
                      scrollController: _draftOrderScrollController,
                      teamNeeds: _teamNeedsLists,
                      currentPickNumber: _draftService?.getNextPick()?.pickNumber,
                    ),
                // Available Players Tab
                AvailablePlayersTab(
                  availablePlayers: _availablePlayersLists,
                  selectionEnabled: _isUserPickMode && _draftService != null && 
                                 _userNextPick != null && 
                                 widget.selectedTeams != null &&
                                 widget.selectedTeams!.contains(_draftService!.getNextPick()?.teamName),
                  userTeam: _userNextPick?.teamName,
                  teamSelectedPositions: _getTeamSelectedPositions(),
                  onPlayerSelected: (playerIndex) {
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
                // Team Needs Tab
                TeamNeedsTab(teamNeeds: _teamNeedsLists),
                // Analytics Tab
                if (widget.showAnalytics)
                  DraftAnalyticsDashboard(
                    completedPicks: _draftPicks.where((pick) => pick.selectedPlayer != null).toList(),
                    draftedPlayers: _players.where((player) => 
                      _draftPicks.any((pick) => pick.selectedPlayer?.id == player.id)).toList(),
                    executedTrades: _executedTrades,
                    teamNeeds: _teamNeeds,
                    userTeam: widget.selectedTeams?.isNotEmpty == true ? widget.selectedTeams!.first : null,
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
        tradeOffersCount: tradeOffersCount,
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
      if (!pick.isSelected && pick.isActiveInDraft) {
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