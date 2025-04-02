// lib/screens/team_selection_screen.dart
import 'package:flutter/material.dart';
import '../models/team.dart';
import '../providers/auth_provider.dart';
import '../services/analytics_service.dart';
import '../utils/constants.dart';
import '../widgets/auth/header_auth_button.dart';
import '../widgets/common/user_feedback_banner.dart';
import 'draft_overview_screen.dart';
import 'draft_settings_screen.dart';
import 'package:provider/provider.dart';
import '../utils/theme_manager.dart';
import '../services/walkthrough_service.dart';
import '../widgets/walkthrough/welcome_dialog.dart';
import '../widgets/walkthrough/walkthrough_overlay.dart';
import '../services/walkthrough_service.dart';
import '../widgets/walkthrough/welcome_dialog.dart';
import '../widgets/walkthrough/walkthrough_overlay.dart';

class TeamSelectionScreen extends StatefulWidget {
  const TeamSelectionScreen({super.key});

  @override
  TeamSelectionScreenState createState() => TeamSelectionScreenState();
}

class TeamSelectionScreenState extends State<TeamSelectionScreen> {
  int _numberOfRounds = 1;
  double _speed = 2.0;
  double _randomness = 0.4;
  final Set<String> _selectedTeams = {};
  int _selectedYear = 2025;
  final List<int> _availableYears = [2023, 2024, 2025];

  bool _enableTrading = true;
  bool _enableUserTradeProposals = true;
  bool _enableQBPremium = true;
  bool _showAnalytics = true;
  bool _showFeedbackBanner = true;  // Define this in your state class
  List<List<dynamic>>? _customTeamNeeds;
  List<List<dynamic>>? _customPlayerRankings;

  // Add these fields for walkthrough
  final GlobalKey _draftOrderTabKey = GlobalKey();
  final GlobalKey _playersTabKey = GlobalKey();
  final GlobalKey _needsTabKey = GlobalKey();
  final GlobalKey _analyticsTabKey = GlobalKey();
  final GlobalKey _draftControlsKey = GlobalKey();
  final GlobalKey _tradeButtonKey = GlobalKey();
  final bool _showDraftWalkthrough = false;
  late WalkthroughService _walkthroughService;

  void _toggleSelectAll() {
    setState(() {
      if (_selectedTeams.length == NFLTeams.allTeams.length) {
        // If all teams are selected, deselect all
        _selectedTeams.clear();
      } else {
        // Otherwise, select all teams
        _selectedTeams.clear();
        _selectedTeams.addAll(NFLTeams.allTeams);
      }
    });
  }

  // NFL divisions and conferences
  final Map<String, List<String>> _afcDivisions = {
    'AFC East': ['Buffalo Bills', 'Miami Dolphins', 'New England Patriots', 'New York Jets'],
    'AFC North': ['Baltimore Ravens', 'Cincinnati Bengals', 'Cleveland Browns', 'Pittsburgh Steelers'],
    'AFC South': ['Houston Texans', 'Indianapolis Colts', 'Jacksonville Jaguars', 'Tennessee Titans'],
    'AFC West': ['Denver Broncos', 'Kansas City Chiefs', 'Las Vegas Raiders', 'Los Angeles Chargers'],
  };
  
  final Map<String, List<String>> _nfcDivisions = {
    'NFC East': ['Dallas Cowboys', 'New York Giants', 'Philadelphia Eagles', 'Washington Commanders'],
    'NFC North': ['Chicago Bears', 'Detroit Lions', 'Green Bay Packers', 'Minnesota Vikings'],
    'NFC South': ['Atlanta Falcons', 'Carolina Panthers', 'New Orleans Saints', 'Tampa Bay Buccaneers'],
    'NFC West': ['Arizona Cardinals', 'Los Angeles Rams', 'San Francisco 49ers', 'Seattle Seahawks'],
  };

  // Inside TeamSelectionScreenState

@override
void initState() {
  super.initState();
  _initializeServices();
  _loadUserPreferences();
}

Future<void> _initializeServices() async {
  _walkthroughService = WalkthroughService();
  await _walkthroughService.initialize();
  
  // Check if we should show the walkthrough
  if (!_walkthroughService.hasSeenWalkthrough) {
    // Delay to ensure the widgets are built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showWelcomeDialog();
    });
  }
}

Future<void> _loadUserPreferences() async {
  final authProvider = Provider.of<AuthProvider>(context, listen: false);
  if (!authProvider.isLoggedIn) return; // Only load for logged in users
  
  final user = authProvider.user;
  if (user == null) return;
  
  // Load favorite teams if none selected yet
  if (_selectedTeams.isEmpty && user.favoriteTeams != null && user.favoriteTeams!.isNotEmpty) {
    setState(() {
      // Set the first favorite team as the selected team
      _selectedTeams.add(user.favoriteTeams!.first);
    });
  }
  
  // Load draft preferences
  if (user.draftPreferences != null) {
    final prefs = user.draftPreferences!;
    setState(() {
      _numberOfRounds = prefs['defaultRounds'] ?? _numberOfRounds;
      _speed = prefs['defaultSpeed'] ?? _speed;
      _randomness = prefs['defaultRandomness'] ?? _randomness;
      _enableTrading = prefs['enableTrading'] ?? true;
      _enableUserTradeProposals = prefs['enableUserTradeProposals'] ?? true;
      _enableQBPremium = prefs['enableQBPremium'] ?? true;
      _showAnalytics = prefs['showAnalytics'] ?? true;
      _selectedYear = prefs['defaultYear'] ?? _selectedYear;
    });
  }
}

void _showWelcomeDialog() {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => WelcomeDialog(
      onGetStarted: () {
        Navigator.pop(context);
        setState(() {
          _showWalkthrough = true;
        });
      },
      onSkip: () async {
        Navigator.pop(context);
        await _walkthroughService.markWalkthroughAsSeen();
      },
    ),
  );
}

void _startWalkthrough() {
  setState(() {
    _showWalkthrough = true;
  });
}

void _completeWalkthrough() async {
  setState(() {
    _showWalkthrough = false;
  });
  await _walkthroughService.markWalkthroughAsSeen();
}

List<WalkthroughStep> _getWalkthroughSteps() {
  return [
    WalkthroughStep(
      title: "Select Your Team",
      description: "Tap on one or more NFL teams that you want to control in the draft. Selected teams will be highlighted with a blue border.",
      targetKey: _teamGridKey,
      position: WalkthroughPosition.top,
    ),
    WalkthroughStep(
      title: "Draft Settings",
      description: "Adjust the number of rounds to draft, simulation speed, and other settings here before starting.",
      targetKey: _settingsKey,
      position: WalkthroughPosition.bottom,
    ),
    WalkthroughStep(
      title: "Start the Draft",
      description: "Once you've selected your team(s) and adjusted the settings, tap START DRAFT to begin!",
      targetKey: _startButtonKey,
      position: WalkthroughPosition.bottom,
    ),
  ];
}

  void _openDraftSettings() {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => DraftSettingsScreen(
        numberOfRounds: _numberOfRounds,
        randomnessFactor: _randomness,
        draftSpeed: _speed,
        userTeam: _selectedTeams.isNotEmpty ? _selectedTeams.first : null,
        // Default values for new settings
        enableTrading: _enableTrading,
        enableUserTradeProposals: _enableUserTradeProposals,
        enableQBPremium: _enableQBPremium,
        showAnalytics: _showAnalytics,
        // Pass year settings
        selectedYear: _selectedYear,
        availableYears: _availableYears,
        onSettingsSaved: (settings) {
          // Update settings when saved
          setState(() {
            _numberOfRounds = settings['numberOfRounds'];
            _randomness = settings['randomnessFactor'];
            _speed = settings['draftSpeed'];
            _enableTrading = settings['enableTrading'];
            _enableUserTradeProposals = settings['enableUserTradeProposals'];
            _enableQBPremium = settings['enableQBPremium'];
            _showAnalytics = settings['showAnalytics'];
            _selectedYear = settings['selectedYear'];
            
            // Store custom data
            _customTeamNeeds = settings['customTeamNeeds'];
            _customPlayerRankings = settings['customPlayerRankings'];
          });
        },
      ),
    ),
  );
}

  @override
Widget build(BuildContext context) {
  final screenSize = MediaQuery.of(context).size;
  final bool isSmallScreen = screenSize.width < 600;
  final bool isVerySmallScreen = screenSize.width < 360;
  final isDarkMode = Theme.of(context).brightness == Brightness.dark;
  
  // Responsive values - adjusted for better mobile and desktop view
  final double teamLogoSize = isSmallScreen ? 
      (isVerySmallScreen ? 42.0 : 48.0) : 56.0; // Larger logo sizes for all screens
  final double fontSize = isSmallScreen ? 
      (isVerySmallScreen ? 9.0 : 10.0) : 11.0;
  final double sectionPadding = isSmallScreen ? 4.0 : 8.0; // Reduced padding for more space
  const double teamButtonSpacing = 1.0; // Minimized spacing
  
  // Define theme colors - adjusting for dark mode
  final Color afcColor = isDarkMode ? const Color(0xFFFF6B6B) : const Color(0xFFD50A0A);  // Brighter red for dark mode
  final Color nfcColor = isDarkMode ? const Color(0xFF4D90E8) : const Color(0xFF002244);  // Brighter blue for dark mode
  
  // Background and text colors based on theme
  final Color cardBackground = isDarkMode ? Colors.grey[800]! : Colors.white;
  final Color cardBorder = isDarkMode ? Colors.grey[600]! : Colors.grey[300]!;
  final Color labelTextColor = isDarkMode ? Colors.white : Colors.black;
  
  return Stack(
    children: [
      Scaffold(
        appBar: AppBar(
          title: const Text(
            'NFL Draft Simulator',
            style: TextStyle(fontSize: TextConstants.kAppBarTitleSize),
          ),
          toolbarHeight: 48,
          centerTitle: true,
          titleSpacing: 8,
          elevation: 0,
          actions: [
            // Add help button
            IconButton(
              icon: const Icon(Icons.help_outline),
              tooltip: 'Show Tutorial',
              onPressed: _startWalkthrough,
            ),
            // Auth button
            const HeaderAuthButton(),
            // Theme toggle button
            Consumer<ThemeManager>(
              builder: (context, themeManager, _) => IconButton(
                icon: Icon(
                  themeManager.themeMode == ThemeMode.light
                      ? Icons.dark_mode
                      : Icons.light_mode,
                  size: 20,
                ),
                tooltip: themeManager.themeMode == ThemeMode.light
                    ? 'Switch to Dark Mode'
                    : 'Switch to Light Mode',
                onPressed: () {
                  themeManager.toggleTheme();
                },
              ),
            ),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [            
              if (_showFeedbackBanner)
                UserFeedbackBanner(
                  onDismiss: () {
                    setState(() {
                      _showFeedbackBanner = false;
                    });
                  },
                ),

              // Select All toggle
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 16.0),
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark ? 
                    Colors.grey.shade800.withOpacity(0.7) : Colors.grey.shade100,
                  border: Border(
                    bottom: BorderSide(
                      color: Theme.of(context).brightness == Brightness.dark ? 
                        Colors.grey.shade700 : Colors.grey.shade300,
                      width: 0.5,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      height: 18,
                      width: 18,
                      child: Checkbox(
                        value: _selectedTeams.isNotEmpty && _selectedTeams.length == NFLTeams.allTeams.length,
                        onChanged: (_) => _toggleSelectAll(),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                    const SizedBox(width: 4),
                    GestureDetector(
                      onTap: _toggleSelectAll,
                      child: Text(
                        'Select All Teams',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).brightness == Brightness.dark ? 
                            Colors.blue.shade300 : Colors.blue.shade700,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${_selectedTeams.length} teams selected',
                      style: TextStyle(
                        fontSize: 11,
                        color: Theme.of(context).brightness == Brightness.dark ? 
                          Colors.grey.shade400 : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),

              // Team selection indicator if a team is selected
              if (_selectedTeams.isNotEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 6.0),
                  color: Colors.green.shade50,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.sports_football, color: Colors.green, size: 16.0),
                      const SizedBox(width: 8.0),
                      Text(
                        'You are controlling: ${_selectedTeams.length} ${_selectedTeams.length == 1 ? 'team' : 'teams'}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                          fontSize: 14.0,
                        ),
                      ),
                    ],
                  ),
                ),
              // Team selection area (expanded)
              Expanded(
                key: _teamGridKey, // Add this key for walkthrough targeting
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // AFC (left column)
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: isDarkMode ? Colors.grey.shade900 : Colors.grey.shade100,
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(8),
                          ),
                        ),
                        child: Column(
                          children: [
                            // AFC header
                            Container(
                              color: afcColor,
                              padding: EdgeInsets.symmetric(
                                horizontal: sectionPadding, 
                                vertical: 6.0
                              ),
                              width: double.infinity,
                              child: const Text(
                                'AFC',
                                style: TextStyle(
                                  fontSize: 16.0,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            
                            // AFC divisions
                            Expanded(
                              child: ListView(
                                padding: EdgeInsets.symmetric(
                                  horizontal: sectionPadding / 2,
                                  vertical: sectionPadding / 2
                                ),
                                children: _afcDivisions.entries.map((entry) {
                                  final String division = entry.key;
                                  final List<String> teams = entry.value;
                                  
                                  return Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Division header
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 4.0, 
                                          vertical: 2.0
                                        ),
                                        child: Text(
                                          division.substring(4), // Remove 'AFC ' prefix
                                          style: TextStyle(
                                            fontSize: fontSize,
                                            fontWeight: FontWeight.bold,
                                            color: isDarkMode ? Colors.white : afcColor, // Ensure visibility in dark mode
                                          ),
                                        ),
                                      ),
                                      
                                      // Team row (all 4 teams in one row)
                                      Row(
                                        children: teams.map((team) {
                                          final isSelected = _selectedTeams.contains(team);
                                          final abbr = NFLTeamMappings.fullNameToAbbreviation[team] ?? '';
                                          
                                          return Expanded(
                                            child: Center( // Center the content to maximize logo visibility
                                              child: Container(
                                                margin: const EdgeInsets.all(teamButtonSpacing),
                                                padding: EdgeInsets.zero, // No internal padding
                                                decoration: BoxDecoration(
                                                  border: isSelected 
                                                    ? Border.all(color: Colors.blue, width: 2.0) 
                                                    : Border.all(color: Colors.transparent), // Transparent border when not selected
                                                  borderRadius: BorderRadius.circular(isSelected ? 8.0 : 0),
                                                  color: Colors.transparent, // Transparent background
                                                ),
                                                child: Stack(
                                                  alignment: Alignment.center,
                                                  children: [
                                                    // Main content
                                                    Column(
                                                      mainAxisAlignment: MainAxisAlignment.center,
                                                      children: [
                                                        // Logo container - larger and with subtle background only when selected
                                                        Container(
                                                          width: teamLogoSize + (isSelected ? 6 : 0), // Slightly larger when selected
                                                          height: teamLogoSize + (isSelected ? 6 : 0),
                                                          decoration: BoxDecoration(
                                                            shape: BoxShape.circle,
                                                            color: isSelected 
                                                              ? (isDarkMode ? Colors.blue.withOpacity(0.15) : Colors.blue.withOpacity(0.05))
                                                              : Colors.transparent,
                                                            boxShadow: isSelected ? [
                                                              const BoxShadow(
                                                                color: Color(0x668bb5d9),
                                                                blurRadius: 6,
                                                                spreadRadius: 2
                                                              )
                                                            ] : null,

                                                          ),
                                                          child: Padding(
                                                            padding: const EdgeInsets.all(1.0),
                                                            child: ClipOval(
                                                              child: Image.network(
                                                                'https://a.espncdn.com/i/teamlogos/nfl/500/${abbr.toLowerCase()}.png',
                                                                fit: BoxFit.contain,
                                                                errorBuilder: (context, error, stackTrace) => 
                                                                  Center(
                                                                    child: Text(
                                                                      abbr,
                                                                      style: TextStyle(
                                                                        fontWeight: FontWeight.bold,
                                                                        fontSize: teamLogoSize / 3,
                                                                      ),
                                                                    ),
                                                                  ),
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                        // Team abbreviation
                                                        Padding(
                                                          padding: const EdgeInsets.only(top: 2.0),
                                                          child: Text(
                                                            abbr,
                                                            style: TextStyle(
                                                              fontSize: fontSize,
                                                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                                              color: isSelected ? Colors.blue : null,
                                                            ),
                                                            textAlign: TextAlign.center,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    
                                                    // Ripple effect for better touch feedback - full size container
                                                    Positioned.fill(
                                                      child: Material(
                                                        color: Colors.transparent,
                                                        child: InkWell(
                                                          borderRadius: BorderRadius.circular(isSelected ? 8.0 : 24.0),
                                                          onTap: () {
                                                            setState(() {
                                                              if (_selectedTeams.contains(team)) {
                                                                _selectedTeams.remove(team);
                                                              } else {
                                                                _selectedTeams.add(team);
                                                              }
                                                            });
                                                          },
                                                          splashColor: Colors.blue.withOpacity(0.2),
                                                          highlightColor: Colors.blue.withOpacity(0.1),
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          );
                                        }).toList(),
                                      ),
                                      SizedBox(height: isSmallScreen ? 4.0 : 8.0),
                                    ],
                                  );
                                }).toList(),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    // Space between conferences
                    SizedBox(
                      width: 6, // Wider separator
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: isDarkMode 
                              ? [Colors.grey.shade800, Colors.grey.shade900, Colors.grey.shade800] 
                              : [Colors.grey.shade200, Colors.white, Colors.grey.shade200],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                    ),
                    
                    // NFC (right column)
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: isDarkMode ? Colors.grey.shade900 : Colors.grey.shade100,
                          borderRadius: const BorderRadius.only(
                            bottomRight: Radius.circular(8),
                          ),
                        ),
                        child: const Column(
                          children: [
                            // Rest of your NFC UI...
                            // ...
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Compact settings bar at bottom
              Container(
                key: _settingsKey, // Add this key for walkthrough targeting
                padding: EdgeInsets.symmetric(
                  horizontal: sectionPadding,
                  vertical: 8.0
                ),
                decoration: BoxDecoration(
                  color: isDarkMode ? Colors.grey[850] : Colors.grey[100],
                  border: Border(top: BorderSide(color: isDarkMode ? Colors.grey[600]! : Colors.grey[300]!)),
                ),
                child: const Column(
                  // Your settings content
                  // ...
                ),
              ),
              // Bottom row with start button
              Row(
                children: [
                  // Advanced settings button
                  OutlinedButton.icon(
                    onPressed: _openDraftSettings,
                    icon: const Icon(Icons.settings, size: 16),
                    label: const Text('Advanced'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12, 
                        vertical: 8
                      ),
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                  
                  const SizedBox(width: 12.0),
                  
                  // Start button (expanded width)
                  Expanded(
                    child: SizedBox(
                      key: _startButtonKey, // Add this key for walkthrough targeting
                      height: 40.0,
                      child: ElevatedButton(
                        onPressed: _selectedTeams.isNotEmpty ? _startDraft : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green[700],
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: Colors.grey[300],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4.0),
                          ),
                        ),
                        child: const Text(
                          'START DRAFT',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16.0,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      
      // Walkthrough overlay
      if (_showWalkthrough)
        WalkthroughOverlay(
          steps: _getWalkthroughSteps(),
          onComplete: _completeWalkthrough,
          onSkip: _completeWalkthrough,
        ),
    ],
  );
}
  void _startDraft() {
  // Log analytics
  AnalyticsService.logEvent('draft_started', parameters: {
    'teams': _selectedTeams.join(','),
    'team_count': _selectedTeams.length,
    'rounds': _numberOfRounds,
    'year': _selectedYear,
  });

  // Convert to list of team identifiers
  List<String> teamIdentifiers = _selectedTeams.map((team) {
    return NFLTeamMappings.fullNameToAbbreviation[team] ?? team;
  }).toList();
  
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => DraftApp(
        randomnessFactor: _randomness,
        numberOfRounds: _numberOfRounds,
        speedFactor: _speed,
        selectedTeams: teamIdentifiers, // Pass list instead of single team
        draftYear: _selectedYear,
        enableTrading: _enableTrading,
        enableUserTradeProposals: _enableUserTradeProposals,
        enableQBPremium: _enableQBPremium,
        showAnalytics: _showAnalytics,
        customTeamNeeds: _customTeamNeeds,
        customPlayerRankings: _customPlayerRankings,
      ),
    ),
  );
}
}