// lib/screens/team_selection_screen.dart
import 'package:flutter/material.dart';
import '../models/team.dart';
import '../utils/constants.dart';
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
  double _speed = 3.0;
  double _randomness = 0.5;
  String? _selectedTeam;
  int _selectedYear = 2025;
  final List<int> _availableYears = [2023, 2024, 2025];

  final bool _enableTrading = true;
  final bool _enableUserTradeProposals = true;
  final bool _enableQBPremium = true;
  final bool _showAnalytics = true;

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
          enableTrading: true,
          enableUserTradeProposals: true,
          enableQBPremium: true,
          showAnalytics: true,
          onSettingsSaved: (settings) {
            // Update settings when saved
            setState(() {
              _numberOfRounds = settings['numberOfRounds'];
              _randomness = settings['randomnessFactor'];
              _speed = settings['draftSpeed'];
              // Store the other settings to be passed to the draft screen
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
    
    // Responsive values
    final double teamLogoSize = isSmallScreen ? 
        (isVerySmallScreen ? 24.0 : 30.0) : 40.0;
    final double fontSize = isSmallScreen ? 
        (isVerySmallScreen ? 9.0 : 10.0) : 12.0;
    final double sectionPadding = isSmallScreen ? 6.0 : 12.0;
    
    // Define theme colors - adjusting for dark mode
    final Color afcColor = isDarkMode ? const Color(0xFFFF6B6B) : const Color(0xFFD50A0A);  // Brighter red for dark mode
    final Color nfcColor = isDarkMode ? const Color(0xFF4D90E8) : const Color(0xFF002244);  // Brighter blue for dark mode
    
    // Background and text colors based on theme
    final Color cardBackground = isDarkMode ? Colors.grey[800]! : Colors.white;
    final Color cardBorder = isDarkMode ? Colors.grey[600]! : Colors.grey[300]!;
    final Color labelTextColor = isDarkMode ? Colors.white : Colors.black;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('NFL Draft Setup'),
        actions: [
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
            // Year selector - prominent at the top
            Container(
              padding: EdgeInsets.symmetric(
                vertical: 8.0, 
                horizontal: sectionPadding
              ),
              color: Colors.blue.shade700,
              child: Row(
                children: [
                  const Text(
                    'Draft Year:',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: _availableYears.map((year) {
                        final isSelected = year == _selectedYear;
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4.0),
                          child: ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _selectedYear = year;
                              });
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isSelected 
                                  ? Colors.white 
                                  : Colors.blue.shade600,
                              foregroundColor: isSelected 
                                  ? Colors.blue.shade800 
                                  : Colors.white,
                              padding: EdgeInsets.symmetric(
                                horizontal: isSmallScreen ? 12.0 : 16.0,
                                vertical: 8.0
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4.0),
                              ),
                            ),
                            child: Text(
                              year.toString(),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: isSmallScreen ? 14.0 : 16.0,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
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
                                      
                                      return Expanded(
                                        child: GestureDetector(
                                          onTap: () {
                                            setState(() {
                                              _selectedTeam = team;
                                            });
                                          },
                                          child: Container(
                                            margin: const EdgeInsets.all(2.0),
                                            padding: const EdgeInsets.all(2.0),
                                            decoration: BoxDecoration(
                                              border: isSelected 
                                                ? Border.all(color: Colors.blue, width: 3.0) 
                                                : Border.all(color: Colors.grey[300]!),
                                              borderRadius: BorderRadius.circular(8.0),
                                            ),
                                            child: Column(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Container(
                                                  width: teamLogoSize,
                                                  height: teamLogoSize,
                                                  decoration: BoxDecoration(
                                                    image: DecorationImage(
                                                      image: NetworkImage(
                                                        'https://a.espncdn.com/i/teamlogos/nfl/500/${NFLTeamMappings.fullNameToAbbreviation[team]?.toLowerCase()}.png',
                                                      ),
                                                      fit: BoxFit.contain,
                                                    ),
                                                    shape: BoxShape.circle,
                                                  ),
                                                ),
                                                const SizedBox(height: 2.0),
                                                Text(
                                                  NFLTeamMappings.fullNameToAbbreviation[team] ?? team,
                                                  style: TextStyle(
                                                    fontSize: fontSize,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                  textAlign: TextAlign.center,
                                                  overflow: TextOverflow.ellipsis,
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
                  
                  // Divider between conferences
                  const VerticalDivider(width: 1, thickness: 1),
                  
                  // NFC (right column)
                  Expanded(
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
                                        color: nfcColor,
                                      ),
                                    ),
                                  ),
                                  
                                  // Team row (all 4 teams in one row)
                                  Row(
                                    children: teams.map((team) {
                                      final isSelected = _selectedTeam == team;
                                      
                                      return Expanded(
                                        child: GestureDetector(
                                          onTap: () {
                                            setState(() {
                                              _selectedTeam = team;
                                            });
                                          },
                                          child: Container(
                                            margin: const EdgeInsets.all(2.0),
                                            padding: const EdgeInsets.all(2.0),
                                            decoration: BoxDecoration(
                                              border: isSelected 
                                                ? Border.all(color: Colors.blue, width: 3.0) 
                                                : Border.all(color: Colors.grey[300]!),
                                              borderRadius: BorderRadius.circular(8.0),
                                            ),
                                            child: Column(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Container(
                                                  width: teamLogoSize,
                                                  height: teamLogoSize,
                                                  decoration: BoxDecoration(
                                                    image: DecorationImage(
                                                      image: NetworkImage(
                                                        'https://a.espncdn.com/i/teamlogos/nfl/500/${NFLTeamMappings.fullNameToAbbreviation[team]?.toLowerCase()}.png',
                                                      ),
                                                      fit: BoxFit.contain,
                                                    ),
                                                    shape: BoxShape.circle,
                                                  ),
                                                ),
                                                const SizedBox(height: 2.0),
                                                Text(
                                                  NFLTeamMappings.fullNameToAbbreviation[team] ?? team,
                                                  style: TextStyle(
                                                    fontSize: fontSize,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                  textAlign: TextAlign.center,
                                                  overflow: TextOverflow.ellipsis,
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
                                        color: isSelected ? Colors.blue : Colors.grey[200],
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
                                                color: isSelected ? Colors.white : Colors.black,
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
                        
                        // Speed row
                        Row(
                          children: [
                            // Speed label
                            const SizedBox(
                              width: 50,
                              child: Text(
                                'Speed:',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold, 
                                  fontSize: 12.0
                                ),
                              ),
                            ),
                            // Speed slider
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
                                color: isSelected ? Colors.blue : Colors.grey[200],
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
                                        color: isSelected ? Colors.white : Colors.black,
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