// lib/screens/team_selection_screen.dart
import 'package:flutter/material.dart';
import 'package:mds_home/models/blog_post.dart';
import 'package:mds_home/services/blog_service.dart';
import '../models/team.dart';
import '../providers/auth_provider.dart';
import '../services/analytics_service.dart';
import '../utils/constants.dart';
import '../widgets/auth/header_auth_button.dart';
import '../widgets/common/user_feedback_banner.dart';
import 'blog_list_screen.dart';
import 'draft_overview_screen.dart';
import 'draft_settings_screen.dart';
import 'package:provider/provider.dart';
import '../utils/theme_manager.dart';

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
  double _tradeFrequency = 0.5;
  double _needVsValueBalance = 0.3;

  bool _enableTrading = true;
  bool _enableUserTradeProposals = true;
  bool _enableQBPremium = true;
  bool _showAnalytics = true;
  bool _showFeedbackBanner = true;  // Define this in your state class
  List<List<dynamic>>? _customTeamNeeds;
  List<List<dynamic>>? _customPlayerRankings;

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
  _loadUserPreferences();
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
        // Pass new settings
        tradeFrequency: _tradeFrequency,
        needVsValueBalance: _needVsValueBalance,
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
            
            // Handle new settings
            _tradeFrequency = settings['tradeFrequency'];
            _needVsValueBalance = settings['needVsValueBalance'];
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
    
    return Scaffold(
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
    TextButton.icon(
    onPressed: () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const BlogListScreen(),
        ),
      );
    },
    icon: const Icon(Icons.article, size: 16),
    label: const Text('Blog'),
    style: TextButton.styleFrom(
      foregroundColor: isDarkMode ? Colors.white : Colors.white,
    ),
  ),
    // Add the auth button here
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

            // Add Select All toggle
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
                                                              color: Color(0x668bb5d9),  // Changed from Colors.amber.withOpacity(0.4)
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
                      child: Column(
                        children: [
                          // NFC header
                          Container(
                            color: nfcColor,
                            padding: EdgeInsets.symmetric(
                              horizontal: sectionPadding, 
                              vertical: 6.0
                            ),
                            width: double.infinity,
                            child: const Text(
                              'NFC',
                              style: TextStyle(
                                fontSize: 16.0,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          
                          // NFC divisions
                          Expanded(
                            child: ListView(
                              padding: EdgeInsets.symmetric(
                                horizontal: sectionPadding / 2,
                                vertical: sectionPadding / 2
                              ),
                              children: _nfcDivisions.entries.map((entry) {
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
                                        division.substring(4), // Remove 'NFC ' prefix
                                        style: TextStyle(
                                          fontSize: fontSize,
                                          fontWeight: FontWeight.bold,
                                          color: isDarkMode ? Colors.white : nfcColor,
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
                                                              color: Color(0x668bb5d9),  // Changed from Colors.amber.withOpacity(0.4)
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
                ],
              ),
            ),
            
            // Compact settings bar at bottom
            // Compact settings bar at bottom
            Container(
            padding: EdgeInsets.symmetric(
              horizontal: sectionPadding,
              vertical: 8.0
            ),
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.grey[850] : Colors.grey[100],
              border: Border(top: BorderSide(color: isDarkMode ? Colors.grey[600]! : Colors.grey[300]!)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Draft settings in a responsive layout
                isSmallScreen ?
                  // Small screen layout (vertical stacking)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Rounds row with Year on the right
                      Row(
                        children: [
                          // Rounds label and buttons (left side)
                          SizedBox(
                            width: 50,
                            child: Text(
                              'Rounds:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold, 
                                fontSize: 12.0,
                                color: isDarkMode ? Colors.white : Colors.black,
                              ),
                            ),
                          ),
                          
                          // Round selection buttons
                          Expanded(
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: List.generate(7, (index) {
                                  final roundNum = index + 1;
                                  final isSelected = _numberOfRounds == roundNum;
                                  
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 4.0),
                                    child: Material(
                                      color: isSelected ? Colors.blue : isDarkMode ? Colors.grey[700] : Colors.grey[200],
                                      borderRadius: BorderRadius.circular(4.0),
                                      child: InkWell(
                                        onTap: () {
                                          setState(() {
                                            _numberOfRounds = roundNum;
                                          });
                                        },
                                        borderRadius: BorderRadius.circular(4.0),
                                        child: Container(
                                          width: 24.0,
                                          height: 24.0,
                                          alignment: Alignment.center,
                                          child: Text(
                                            '$roundNum',
                                            style: TextStyle(
                                              color: isSelected ? Colors.white : isDarkMode ? Colors.white70 : Colors.black87,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12.0,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                }),
                              ),
                            ),
                          ),
                          
                          // Year selection (right side)
                          const SizedBox(width: 8.0),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Year:',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold, 
                                  fontSize: 12.0,
                                  color: isDarkMode ? Colors.white : Colors.black,
                                ),
                              ),
                              const SizedBox(width: 4.0),
                              DropdownButton<int>(
                                value: _selectedYear,
                                underline: Container(height: 1, color: isDarkMode ? Colors.grey[600] : Colors.grey[400]),
                                isDense: true,
                                items: _availableYears.map((int year) {
                                  return DropdownMenuItem<int>(
                                    value: year,
                                    child: Text(
                                      year.toString(),
                                      style: TextStyle(
                                        fontSize: 12.0,
                                        color: isDarkMode ? Colors.white : Colors.black,
                                      ),
                                    ),
                                  );
                                }).toList(),
                                onChanged: (int? newValue) {
                                  if (newValue != null) {
                                    setState(() {
                                      _selectedYear = newValue;
                                    });
                                  }
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 8.0),
                      
                      // Speed row
                      Row(
                        children: [
                          // Speed label
                          SizedBox(
                            width: 50,
                            child: Text(
                              'Speed:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold, 
                                fontSize: 12.0,
                                color: isDarkMode ? Colors.white : Colors.black,
                              ),
                            ),
                          ),
                          // Speed slider
                          Expanded(
                            child: SliderTheme(
                              data: SliderTheme.of(context).copyWith(
                                trackHeight: 3.0,
                                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6.0),
                                overlayShape: const RoundSliderOverlayShape(overlayRadius: 12.0),
                              ),
                              child: Slider(
                                value: _speed,
                                min: 1.0,
                                max: 5.0,
                                divisions: 4,
                                activeColor: Colors.green[700],
                                onChanged: (value) {
                                  setState(() {
                                    _speed = value;
                                  });
                                },
                              ),
                            ),
                          ),
                          Text('${_speed.toInt()}', style: const TextStyle(fontSize: 12.0)),
                        ],
                      ),
                      // Randomness row
                      Row(
                        children: [
                          // Randomness label
                          SizedBox(
                            width: 50,
                            child: Text(
                              'Random:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold, 
                                fontSize: 12.0,
                                color: isDarkMode ? Colors.white : Colors.black,
                              ),
                            ),
                          ),
                          // Randomness slider
                          Expanded(
                            child: SliderTheme(
                              data: SliderTheme.of(context).copyWith(
                                trackHeight: 3.0,
                                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6.0),
                                overlayShape: const RoundSliderOverlayShape(overlayRadius: 12.0),
                              ),
                              child: Slider(
                                value: _randomness * 5, // Convert to 1-5 scale for UI
                                min: 1.0,
                                max: 5.0,
                                divisions: 4,
                                activeColor: Colors.green[700], // Use a different color than speed
                                onChanged: (value) {
                                  setState(() {
                                    _randomness = value / 5.0; // Convert back to 0-1 scale
                                  });
                                },
                              ),
                            ),
                          ),
                          Text('${(_randomness * 5).toInt()}', style: const TextStyle(fontSize: 12.0)),
                        ],
                      ),
                    ],
                  )
                :
                  // Regular layout (horizontal)
                  Column(
                    children: [
                      // Top row with rounds and year
                      Row(
                        children: [
                          // Rounds section (left side)
                          const Text(
                            'Rounds:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold, 
                              fontSize: 12.0
                            ),
                          ),
                          const SizedBox(width: 8.0),
                          // Round selection buttons
                          Row(
                            children: List.generate(7, (index) {
                              final roundNum = index + 1;
                              final isSelected = _numberOfRounds == roundNum;
                              
                              return Padding(
                                padding: const EdgeInsets.only(right: 4.0),
                                child: Material(
                                  color: isSelected ? Colors.blue : isDarkMode ? Colors.grey[700] : Colors.grey[200],
                                  borderRadius: BorderRadius.circular(4.0),
                                  child: InkWell(
                                    onTap: () {
                                      setState(() {
                                        _numberOfRounds = roundNum;
                                      });
                                    },
                                    borderRadius: BorderRadius.circular(4.0),
                                    child: Container(
                                      width: 24.0,
                                      height: 24.0,
                                      alignment: Alignment.center,
                                      child: Text(
                                        '$roundNum',
                                        style: TextStyle(
                                          color: isSelected ? Colors.white : isDarkMode ? Colors.white70 : Colors.black87,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12.0,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ),
                          
                          // Spacer to push Year dropdown to the right
                          const Spacer(),
                          
                          // Year dropdown (right side)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Year:',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold, 
                                  fontSize: 12.0,
                                  color: isDarkMode ? Colors.white : Colors.black,
                                ),
                              ),
                              const SizedBox(width: 8.0),
                              DropdownButton<int>(
                                value: _selectedYear,
                                underline: Container(height: 1, color: isDarkMode ? Colors.grey[600] : Colors.grey[400]),
                                isDense: true,
                                items: _availableYears.map((int year) {
                                  return DropdownMenuItem<int>(
                                    value: year,
                                    child: Text(
                                      year.toString(),
                                      style: TextStyle(
                                        fontSize: 12.0,
                                        color: isDarkMode ? Colors.white : Colors.black,
                                      ),
                                    ),
                                  );
                                }).toList(),
                                onChanged: (int? newValue) {
                                  if (newValue != null) {
                                    setState(() {
                                      _selectedYear = newValue;
                                    });
                                  }
                                },
                              ),
                            ],
                          ),
                        ],
                      ),

                      // Add speed slider in a separate row below
                      const SizedBox(height: 8.0),
                      Row(
                        children: [
                          // Speed label
                          SizedBox(
                            width: 50,
                            child: Text(
                              'Speed:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold, 
                                fontSize: 12.0,
                                color: isDarkMode ? Colors.white : Colors.black,
                              ),
                            ),
                          ),
                          // Speed slider
                          Expanded(
                            child: SliderTheme(
                              data: SliderTheme.of(context).copyWith(
                                trackHeight: 3.0,
                                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6.0),
                                overlayShape: const RoundSliderOverlayShape(overlayRadius: 12.0),
                              ),
                              child: Slider(
                                value: _speed,
                                min: 1.0,
                                max: 5.0,
                                divisions: 4,
                                activeColor: Colors.green[700],
                                onChanged: (value) {
                                  setState(() {
                                    _speed = value;
                                  });
                                },
                              ),
                            ),
                          ),
                          Text('${_speed.toInt()}', style: const TextStyle(fontSize: 12.0)),
                        ],
                      ),

                      // Add randomness slider below speed slider
                      const SizedBox(height: 8.0),
                      Row(
                        children: [
                          // Randomness label
                          SizedBox(
                            width: 50,
                            child: Text(
                              'Random:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold, 
                                fontSize: 12.0,
                                color: isDarkMode ? Colors.white : Colors.black,
                              ),
                            ),
                          ),
                          // Randomness slider
                          Expanded(
                            child: SliderTheme(
                              data: SliderTheme.of(context).copyWith(
                                trackHeight: 3.0,
                                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6.0),
                                overlayShape: const RoundSliderOverlayShape(overlayRadius: 12.0),
                              ),
                              child: Slider(
                                value: _randomness * 5, // Convert to 1-5 scale for UI
                                min: 1.0,
                                max: 5.0,
                                divisions: 4,
                                activeColor: Colors.green[700], // Use a different color than speed
                                onChanged: (value) {
                                  setState(() {
                                    _randomness = value / 5.0; // Convert back to 0-1 scale
                                  });
                                },
                              ),
                            ),
                          ),
                          Text('${(_randomness * 5).toInt()}', style: const TextStyle(fontSize: 12.0)),
                        ],
                      ),
                    ],
                  ),
                
                // Bottom row with Advanced button and Start button
                const SizedBox(height: 8.0),
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
          ],
        ),
      ),
    );
  }
  
  void _startDraft() {
  // Log analytics
  AnalyticsService.logEvent('draft_started', parameters: {
    'teams': _selectedTeams.join(','),
    'team_count': _selectedTeams.length,
    'rounds': _numberOfRounds,
    'year': _selectedYear,
    'trade_frequency': _tradeFrequency,
    'need_vs_value_balance': _needVsValueBalance,
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
        tradeFrequency: _tradeFrequency,
        needVsValueBalance: _needVsValueBalance,
      ),
    ),
  );
}
// Add this to TeamSelectionScreen build method
Widget _buildBlogPreview() {
  return Card(
    margin: const EdgeInsets.all(16.0),
    child: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Latest from our Blog',
                style: TextStyle(
                  fontSize: 18.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/blog');
                },
                child: const Text('View All'),
              ),
            ],
          ),
          const SizedBox(height: 12.0),
          FutureBuilder<List<BlogPost>>(
            future: BlogService.getAllPosts(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Text('No blog posts available');
              }
              
              // Display the most recent post
              final latestPost = snapshot.data!.first;
              return InkWell(
                onTap: () {
                  Navigator.pushNamed(context, '/blog/${latestPost.id}');
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (latestPost.thumbnailUrl != null)
                      Image.network(
                        latestPost.thumbnailUrl!,
                        height: 180,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    const SizedBox(height: 8.0),
                    Text(
                      latestPost.title,
                      style: const TextStyle(
                        fontSize: 16.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4.0),
                    Text(
                      latestPost.shortDescription,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8.0),
                    Text(
                      'Read More',
                      style: TextStyle(
                        color: Theme.of(context).primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    ),
  );
}
}