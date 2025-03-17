// lib/screens/team_selection_screen.dart
import 'package:flutter/material.dart';
import '../models/team.dart';
import '../providers/auth_provider.dart';
import '../utils/constants.dart';
import '../widgets/auth/header_auth_button.dart';
import '../widgets/common/user_feedback_banner.dart';
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
  double _randomness = 0.5;
  String? _selectedTeam;
  int _selectedYear = 2025;
  final List<int> _availableYears = [2023, 2024, 2025];

  bool _enableTrading = true;
  bool _enableUserTradeProposals = true;
  bool _enableQBPremium = true;
  bool _showAnalytics = true;
  bool _showFeedbackBanner = true;  // Define this in your state class


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
  if (_selectedTeam == null && user.favoriteTeams != null && user.favoriteTeams!.isNotEmpty) {
    setState(() {
      // Set the first favorite team as the selected team
      _selectedTeam = user.favoriteTeams!.first;
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
        userTeam: _selectedTeam,
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
            _selectedYear = settings['selectedYear']; // Update selectedYear
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
        title: const Text('NFL Draft Simulator'),
        actions: [
          // Add the auth button here
          const HeaderAuthButton(),
          // Theme toggle button
          Consumer<ThemeManager>(
            builder: (context, themeManager, _) => IconButton(
              icon: Icon(
                themeManager.themeMode == ThemeMode.light
                    ? Icons.dark_mode
                    : Icons.light_mode,
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

            // Team selection indicator if a team is selected
            if (_selectedTeam != null)
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
                      'You are controlling: $_selectedTeam',
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
                                        final isSelected = _selectedTeam == team;
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
                                                            _selectedTeam = team;
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
                                        final isSelected = _selectedTeam == team;
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
                                                            _selectedTeam = team;
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
                        // Rounds row
                        Row(
                          children: [
                            // Rounds label
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
                          ],
                        ),
                        
                        const SizedBox(height: 8.0),
                        
                        // Speed row - more compact for mobile
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
                                  trackHeight: 3.0, // Smaller track
                                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6.0), // Smaller thumb
                                  overlayShape: const RoundSliderOverlayShape(overlayRadius: 12.0), // Smaller overlay
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
                      ],
                    )
                  :
                    // Regular layout (horizontal)
                    Row(
                      children: [
                        // Rounds buttons
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
                        
                        const SizedBox(width: 16.0),
                        
                        // Speed slider (compact)
                        const Text(
                          'Speed:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold, 
                            fontSize: 12.0
                          ),
                        ),
                        const SizedBox(width: 8.0),
                        Expanded(
                          child: SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              trackHeight: 4.0,
                              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6.0),
                              overlayShape: const RoundSliderOverlayShape(overlayRadius: 14.0),
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
                  
                  const SizedBox(height: 8.0),
                  
                  // Bottom row with Advanced button and Start button
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
                            onPressed: _selectedTeam != null ? _startDraft : null,
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
    debugPrint("Starting draft for year: $_selectedYear");
    debugPrint("Selected team (full name): $_selectedTeam");
    
    // Determine the team identifier to use
    String? teamIdentifier;
    if (_selectedTeam != null) {
      // If a full team name is selected, use its abbreviation if available
      teamIdentifier = NFLTeamMappings.fullNameToAbbreviation[_selectedTeam];
      
      // If no abbreviation found, use the full name
      teamIdentifier ??= _selectedTeam;
      
      debugPrint("Using team identifier: $teamIdentifier");
    }
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DraftApp(
          randomnessFactor: _randomness,
          numberOfRounds: _numberOfRounds,
          speedFactor: _speed,
          selectedTeam: teamIdentifier,
          draftYear: _selectedYear,
          enableTrading: _enableTrading,
          enableUserTradeProposals: _enableUserTradeProposals,
          enableQBPremium: _enableQBPremium,
          showAnalytics: _showAnalytics,
        ),
      ),
    );
  }
}